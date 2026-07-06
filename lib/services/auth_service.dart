import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'database_service.dart';
import 'storage_service.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _db = DatabaseService();
  final StorageService _storage = StorageService();

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  bool _hasProfile = false;
  bool get hasProfile => _hasProfile;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  AuthService() {
    debugPrint('AuthService: Initializing authStateChanges listener...');
    _auth.authStateChanges().listen((User? user) async {
      debugPrint('AuthService: authStateChange detected. User logged in: ${user != null}');
      if (user != null) {
        debugPrint('AuthService: Fetching user data for ${user.uid}...');
        _userModel = await _db.getUserData(user.uid);
        debugPrint('AuthService: UserModel fetched: ${_userModel?.role}');
        
        if (_userModel != null) {
          if (_userModel!.role == 'student') {
            final p = await _db.getStudentProfile(user.uid);
            _hasProfile = p != null;
            debugPrint('AuthService: Student profile found: $_hasProfile');
          } else if (_userModel!.role == 'startup') {
            final p = await _db.getStartupProfile(user.uid);
            _hasProfile = p != null;
            debugPrint('AuthService: Startup profile found: $_hasProfile');
          }
        } else {
          debugPrint('AuthService: UserModel missing, creating temporary role-selection state');
          _userModel = UserModel(uid: user.uid, email: user.email ?? '', role: '');
          _hasProfile = false;
        }
      } else {
        _userModel = null;
        _hasProfile = false;
      }
      _isInitialized = true;
      debugPrint('AuthService: Initialization Complete');
      notifyListeners();
    });
  }

  // Auth change user stream
  Stream<User?> get user => _auth.authStateChanges();

  // Manually update profile status after setup
  Future<void> markProfileComplete() async {
    _hasProfile = true;
    notifyListeners(); // Update UI immediately so router sees hasProfile = true
    
    final user = _auth.currentUser;
    if (user != null) {
      _userModel = await _db.getUserData(user.uid);
      debugPrint('AuthService: Profile marked complete and data refreshed for ${_userModel?.role}');
      notifyListeners();
    }
  }

  // Refresh user data manually (useful after role selection)
  Future<void> refreshUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      _userModel = await _db.getUserData(user.uid);
      if (_userModel != null) {
        if (_userModel!.role == 'student') {
          final p = await _db.getStudentProfile(user.uid);
          _hasProfile = p != null;
        } else if (_userModel!.role == 'startup') {
          final p = await _db.getStartupProfile(user.uid);
          _hasProfile = p != null;
        }
      }
      notifyListeners();
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      debugPrint("AuthService SignIn Error: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("AuthService Generic SignIn Error: $e");
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword(String email, String password, String role) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      if (user != null) {
        await _db.updateUserData(UserModel(
          uid: user.uid,
          email: email,
          role: role,
        ));
      }
      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint("AuthService Register Error: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("AuthService Generic Register Error: $e");
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint("AuthService Reset Error: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("AuthService Generic Reset Error: $e");
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("AuthService Google SignIn Error: $e");
      rethrow;
    }
  }

  // Re-authenticate user (required for sensitive operations like deletion)
  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    }
  }

  // Delete Account
  Future<void> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null && _userModel != null) {
        final uid = user.uid;
        final role = _userModel!.role;
        
        // 1. Re-authenticate first to ensure we can delete the Auth account
        await reauthenticate(password);
        
        // 2. Delete Storage files (CVs, Logos)
        try {
          await _storage.deleteUserFiles(uid);
        } catch (e) {
          debugPrint("AuthService Storage Cleanup Error (continuing): $e");
        }

        // 3. Delete Firestore data
        await _db.deleteUserData(uid, role);
        
        // 4. Delete Auth user
        await user.delete();
        
        // Reset local state
        _userModel = null;
        _hasProfile = false;
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("AuthService Delete Error: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("AuthService Generic Delete Error: $e");
      rethrow;
    }
  }
}
