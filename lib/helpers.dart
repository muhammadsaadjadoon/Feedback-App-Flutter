import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

String friendlyError(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-credential' || 'wrong-password' || 'user-not-found' => 'Email or password is incorrect.',
      'email-already-in-use' => 'An account already exists with this email.',
      'weak-password' => 'Use a stronger password with at least 8 characters.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'network-request-failed' => 'Check your internet connection and try again.',
      'requires-recent-login' => 'Please sign in again and retry this security change.',
      'operation-not-allowed' => 'This account action is disabled in your Firebase project.',
      'invalid-email' => 'Please enter a valid email address.',
      _ => 'Authentication failed. Please try again.',
    };
  }
  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'Access was denied. Check your workspace permissions and try again.';
  }
  return 'We could not complete this action. Check your connection and try again.';
}
void notice(BuildContext context, String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
String? requiredText(String? v, {int min = 1}) => (v?.trim().length ?? 0) < min ? 'Enter at least $min characters.' : null;
String? emailCheck(String? v) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v?.trim() ?? '') ? null : 'Enter a valid email address.';
