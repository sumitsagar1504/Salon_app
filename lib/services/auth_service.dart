import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../models/user_model.dart';

class AuthService {
  // Existing owner account. The matching UID is enforced in firestore.rules.
  static const ownerUid = 'NIgb3JbjMBXGzaQaGKNfgGwNxyv1';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  static String errorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'network-request-failed':
          return 'Could not connect to Firebase. Check your internet connection, disable any VPN or blocker, then try again.';
        case 'invalid-credential':
        case 'user-not-found':
        case 'wrong-password':
          return 'The email or password is incorrect.';
        case 'email-already-in-use':
          return 'An account already exists for this email.';
        case 'weak-password':
          return 'Choose a stronger password with at least 6 characters.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait and try again.';
        case 'user-disabled':
          return 'This account has been disabled.';
      }
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Your account signed in, but salon data access was denied. Please contact the salon administrator.';
        case 'unavailable':
        case 'deadline-exceeded':
          return 'Salon data is temporarily unavailable. Check your connection and try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  Future<UserModel?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;

    final profile = UserModel.fromMap(doc.data()!);
    // The original owner existed before /admins records were introduced.
    // Avoid a needless lookup that older published rules may deny.
    final isPrimaryOwner = _auth.currentUser?.uid == uid && uid == ownerUid;
    final isAdmin =
        isPrimaryOwner ||
        (await _firestore.collection('admins').doc(uid).get()).exists;
    return UserModel(
      uid: uid,
      email: profile.email,
      name: profile.name,
      role: isAdmin ? 'admin' : 'customer',
    );
  }

  Future<UserModel?> signUp(
    String email,
    String password,
    String name, {
    bool requestAdminAccess = false,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    User? user = userCredential.user;
    if (user != null) {
      UserModel newUser = UserModel(
        uid: user.uid,
        email: normalizedEmail,
        name: name.trim(),
        role: 'customer',
      );

      final batch = _firestore.batch();
      batch.set(_firestore.collection('users').doc(user.uid), newUser.toMap());
      if (requestAdminAccess) {
        batch.set(_firestore.collection('adminRequests').doc(user.uid), {
          'uid': user.uid,
          'email': normalizedEmail,
          'name': name.trim(),
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      try {
        await batch.commit();
      } catch (_) {
        await user.delete();
        rethrow;
      }
      await _auth.signOut();
      return newUser;
    }
    return null;
  }

  Future<UserModel?> signIn(String email, String password) async {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = userCredential.user;
    if (user != null) {
      return await getUserData(user.uid);
    }
    return null;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAdmins() {
    return _firestore.collection('admins').orderBy('name').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAdminRequests() {
    return _firestore
        .collection('adminRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<bool> hasPendingAdminRequest(String uid) async {
    final request = await _firestore.collection('adminRequests').doc(uid).get();
    return request.exists && request.data()?['status'] == 'pending';
  }

  Future<void> approveAdminRequest(Map<String, dynamic> request) async {
    final creator = _auth.currentUser;
    if (creator == null) throw StateError('You must be signed in.');
    final uid = request['uid'] as String;
    final userRef = _firestore.collection('users').doc(uid);
    final adminRef = _firestore.collection('admins').doc(uid);
    final requestRef = _firestore.collection('adminRequests').doc(uid);
    final batch = _firestore.batch();
    batch.update(userRef, {'role': 'admin'});
    batch.set(adminRef, {
      'uid': uid,
      'email': request['email'],
      'name': request['name'],
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': creator.uid,
    });
    batch.delete(requestRef);
    await batch.commit();
  }

  Future<bool> createAdminAccount({
    required String name,
    required String email,
  }) async {
    final creator = _auth.currentUser;
    if (creator == null) throw StateError('You must be signed in.');

    final normalizedEmail = email.trim().toLowerCase();
    final appName = 'admin-${DateTime.now().microsecondsSinceEpoch}';
    final secondaryApp = await Firebase.initializeApp(
      name: appName,
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
    User? newUser;

    try {
      final random = Random.secure();
      const characters =
          'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%';
      final temporaryPassword = List.generate(
        24,
        (_) => characters[random.nextInt(characters.length)],
      ).join();
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: temporaryPassword,
      );
      newUser = credential.user;
      if (newUser == null) {
        throw StateError('Firebase did not create the user.');
      }

      final profile = UserModel(
        uid: newUser.uid,
        email: normalizedEmail,
        name: name.trim(),
        role: 'admin',
      );
      final batch = _firestore.batch();
      batch.set(
        _firestore.collection('users').doc(newUser.uid),
        profile.toMap(),
      );
      batch.set(_firestore.collection('admins').doc(newUser.uid), {
        'uid': newUser.uid,
        'email': normalizedEmail,
        'name': name.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': creator.uid,
      });

      try {
        await batch.commit();
      } catch (_) {
        await newUser.delete();
        rethrow;
      }

      try {
        await secondaryAuth.sendPasswordResetEmail(email: normalizedEmail);
        return true;
      } catch (_) {
        return false;
      }
    } finally {
      await secondaryAuth.signOut();
      await secondaryApp.delete();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
