import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  // Existing owner account. The matching UID is enforced in firestore.rules.
  static const ownerUid = 'NIgb3JbjMBXGzaQaGKNfgGwNxyv1';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final profile = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        final isAdmin = _auth.currentUser?.uid == uid && uid == ownerUid;
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
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

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

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
