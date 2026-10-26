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

  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final profile = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        final adminRecord = await _firestore.collection('admins').doc(uid).get();
        final isAdmin = (_auth.currentUser?.uid == uid && uid == ownerUid) ||
            adminRecord.exists;
        return UserModel(
          uid: uid,
          email: profile.email,
          name: profile.name,
          role: isAdmin ? 'admin' : 'customer',
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  Future<UserModel?> signUp(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;
      if (user != null) {
        UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          name: name,
          role: 'customer',
        );

        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        await _auth.signOut();
        return newUser;
      }
      return null;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<UserModel?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        return await getUserData(user.uid);
      }
      return null;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAdmins() {
    return _firestore.collection('admins').orderBy('name').snapshots();
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
      if (newUser == null) throw StateError('Firebase did not create the user.');

      final profile = UserModel(
        uid: newUser.uid,
        email: normalizedEmail,
        name: name.trim(),
        role: 'admin',
      );
      final batch = _firestore.batch();
      batch.set(_firestore.collection('users').doc(newUser.uid), profile.toMap());
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
