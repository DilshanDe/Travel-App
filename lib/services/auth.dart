import 'package:traveltest_app/home.dart';
import 'package:traveltest_app/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart';

class AuthMethods {
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<User?> getCurrentUser() async {
    return auth.currentUser;
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleSignInAuthentication.idToken,
          accessToken: googleSignInAuthentication.accessToken,
        );

        UserCredential result = await auth.signInWithCredential(credential);
        User? userDetails = result.user;

        if (userDetails != null) {
          Map<String, dynamic> userInfoMap = {
            "email": userDetails.email,
            "name": userDetails.displayName,
            "imgUrl": userDetails.photoURL,
            "id": userDetails.uid,
          };

          await DatabaseMethods()
              .addUserDetails(userInfoMap, userDetails.uid)
              .then((value) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Home()),
            );
          });
        }
      }
    } catch (e) {
      print("Google Sign-In Error: $e");
    }
  }

  Future<User?> signInWithApple({List<Scope> scopes = const []}) async {
    try {
      final AuthorizationResult result = await TheAppleSignIn.performRequests(
          [AppleIdRequest(requestedScopes: scopes)]);

      switch (result.status) {
        case AuthorizationStatus.authorized:
          final AppleIdCredential appleIdCredential = result.credential!;
          final OAuthProvider oAuthProvider = OAuthProvider('apple.com');
          final AuthCredential credential = oAuthProvider.credential(
            idToken: String.fromCharCodes(appleIdCredential.identityToken!),
          );

          UserCredential userCredential =
              await auth.signInWithCredential(credential);
          User? firebaseUser = userCredential.user;

          if (firebaseUser != null && scopes.contains(Scope.fullName)) {
            final PersonNameComponents? fullName = appleIdCredential.fullName;
            if (fullName != null &&
                fullName.givenName != null &&
                fullName.familyName != null) {
              final String displayName =
                  '${fullName.givenName} ${fullName.familyName}';
              await firebaseUser.updateDisplayName(displayName);
            }
          }
          return firebaseUser;

        case AuthorizationStatus.error:
          throw PlatformException(
              code: 'ERROR_AUTHORIZATION_DENIED',
              message: result.error.toString());

        case AuthorizationStatus.cancelled:
          throw PlatformException(
              code: 'ERROR_ABORTED_BY_USER',
              message: 'Sign in aborted by user');

        default:
          throw UnimplementedError();
      }
    } catch (e) {
      print("Apple Sign-In Error: $e");
      return null;
    }
  }
}
