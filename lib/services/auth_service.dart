import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/models.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _users = FirebaseFirestore.instance.collection('users');

  /// Farmers sign in with a phone number or an email. Firebase email/password auth needs an email,
  /// so a phone number is mapped to <digits>@farmer.harvesta.app behind the scenes.
  static String farmerPhoneDigits(String input) =>
      input.replaceAll(RegExp(r'[^0-9]'), '');

  static String farmerEmail(String input) {
    final v = input.trim();
    if (v.contains('@')) return v.toLowerCase();
    return '${farmerPhoneDigits(v)}@farmer.harvesta.app';
  }

  static String friendly(Object e) {
    if (e is AuthException) return e.message;
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email/phone or password is incorrect.';
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'user-disabled':
          return 'This account is disabled.';
        case 'email-already-in-use':
          return 'An account already exists with these details. Try logging in.';
        case 'weak-password':
          return 'Choose a stronger password (6+ characters).';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'network-request-failed':
          return 'Network error. Check your connection and try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  /// Signs in, then checks the account really has the role of the portal being used.
  static Future<void> signIn({
    required String email,
    required String password,
    required String role,
  }) async {
    var signInEmail = email.trim();
    if (role == 'farmer' && !signInEmail.contains('@')) {
      final phoneDigits = farmerPhoneDigits(signInEmail);
      final farmers = await _users
          .where('phoneDigits', isEqualTo: phoneDigits)
          .limit(1)
          .get();
      final registeredEmail = farmers.docs.isEmpty
          ? null
          : farmers.docs.first.data()['email'];
      signInEmail = registeredEmail is String && registeredEmail.isNotEmpty
          ? registeredEmail
          : farmerEmail(signInEmail);
    }
    final cred = await _auth.signInWithEmailAndPassword(
      email: signInEmail,
      password: password,
    );
    final doc = await _users.doc(cred.user!.uid).get();
    if (doc.data()?['role'] != role) {
      await _auth.signOut();
      throw AuthException(
        role == 'admin'
            ? 'This account is not approved for the admin console.'
            : 'This account is registered under a different role. Go back and choose the right one.',
      );
    }
  }

  static Future<void> registerBusiness({
    required String email,
    required String password,
    required String phone,
    required String businessName,
    required String city,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user!.updateDisplayName(businessName.trim());
    await _users
        .doc(cred.user!.uid)
        .set(
          AppUser(
            uid: cred.user!.uid,
            role: 'business',
            name: businessName.trim(),
            email: email.trim(),
            phone: phone.trim(),
            businessName: businessName.trim(),
            city: city.trim(),
            address: city.trim(),
          ).toMap(),
        );
  }

  static Future<void> registerFarmer({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String farmName,
    required String location,
    required String farmInfo,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final cred = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    await cred.user!.updateDisplayName(fullName.trim());
    final profile = AppUser(
      uid: cred.user!.uid,
      role: 'farmer',
      name: fullName.trim(),
      email: normalizedEmail,
      phone: phone.trim(),
      farmName: farmName.trim(),
      location: location.trim(),
      farmInfo: farmInfo.trim(),
      verificationStatus: 'pending',
    ).toMap();
    profile['phoneDigits'] = farmerPhoneDigits(phone);
    await _users
        .doc(cred.user!.uid)
        .set(profile);
  }

  /// Returns true if a reset email was sent, false if a support request was filed instead
  /// (phone-based farmer accounts have no real inbox).
  static Future<bool> requestReset(String input) async {
    final v = input.trim();
    if (v.contains('@') && !v.endsWith('@farmer.harvesta.app')) {
      await _auth.sendPasswordResetEmail(email: v);
      return true;
    }
    await FirebaseFirestore.instance.collection('support_requests').add({
      'identifier': v,
      'type': 'password_reset',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return false;
  }

  static Future<void> signOut() => _auth.signOut();
}
