import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, kasir }

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Mengambil role user berdasarkan UID dari Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection('users').doc(uid).get();
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        return data['role'] as String?;
      }
      return null;
    } catch (e) {
      print('Error fetching user role: $e');
      return null;
    }
  }

  /// Login user dengan validasi role dari Firestore
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(code: 'invalid-credential', message: 'User UID is null');
      }

      String? role = await getUserRole(user.uid);
      print('Role fetched: $role');

      if (role == UserRole.admin.name || role == UserRole.kasir.name) {
        print('Login successful for role: $role');
        return userCredential;
      } else {
        print('Unauthorized role: $role');
        await signOut();
        throw FirebaseAuthException(code: 'unauthorized-role', message: 'Your role does not have access.');
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return null;
    } catch (e) {
      print('Error during sign-in: $e');
      return null;
    }
  }

  /// Registrasi user baru dengan menyimpan data ke Firestore
  Future<UserCredential?> signUpWithEmailAndPassword(String email, String password, String role) async {
    try {
      if (!_isValidRole(role)) {
        throw Exception('Invalid role');
      }

      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('User registered with role: $role');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      throw e;
    } catch (e) {
      print('Error during sign-up: $e');
     throw e;
    }
  }

  /// Logout user
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      print('User signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  /// Validasi role berdasarkan enum
  bool _isValidRole(String role) {
    return UserRole.values.any((e) => e.name == role);
  }

  /// Penanganan error autentikasi
  void _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        print('No user found for that email.');
        break;
      case 'wrong-password':
        print('Wrong password provided for that user.');
        break;
      case 'unauthorized-role':
        print('Role unauthorized.');
        break;
      case 'invalid-credential':
        print('User UID is invalid.');
        break;
      default:
        print('Authentication error: ${e.message}');
    }
  }
}
