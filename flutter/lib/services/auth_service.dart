import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        "140829766786-vplvlhepb7lr7b0gc59qto0ok5m9gh0d.apps.googleusercontent.com",
    scopes: ['email'],
  );

  Rxn<User> firebaseUser = Rxn<User>();

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
  }

  String? _getHighResPhotoUrl(User? user) {
    if (user == null || user.photoURL == null) return null;

    String url = user.photoURL!;

    if (url.contains('googleusercontent.com')) {
      return url.replaceAll('s96-c', 's0');
    }

    if (url.contains('facebook.com')) {
      return "$url?type=large&width=1000&height=1000";
    }

    return url;
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      _showErrorSnackbar("Google Sign-In Error", e.toString());
      return null;
    }
  }

  Future<UserCredential?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final OAuthCredential credential = FacebookAuthProvider.credential(
          result.accessToken!.tokenString,
        );
        return await _auth.signInWithCredential(credential);
      }
      return null;
    } catch (e) {
      _showErrorSnackbar("Facebook Sign-In Error", e.toString());
      return null;
    }
  }

  Map<String, dynamic> getUserData(UserCredential credential) {
    final user = credential.user;
    String fullName = (user?.displayName ?? "").trim();
    List<String> parts = fullName.split(RegExp(r'\s+'));
    return {
      'uid': user?.uid,
      'email': user?.email,
      'displayName': user?.displayName,
      'firstName': parts.isNotEmpty ? parts[0] : "",
      'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : "",
      'photoUrl': _getHighResPhotoUrl(user),
    };
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await FacebookAuth.instance.logOut();
      await _auth.signOut();
    } catch (e) {
      log("Sign out error: $e");
    }
  }

  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withValues(alpha: 0.1),
      colorText: Colors.red,
      margin: const EdgeInsets.all(15),
      borderRadius: 10,
    );
  }
}
