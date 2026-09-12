import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static final GoogleSignIn _googleSignIn =
      GoogleSignIn.instance;

  static User? get currentUser =>
      _auth.currentUser;

  static Future<UserCredential?>
  signInWithGoogle() async {
    try {
      final GoogleSignInAccount
      googleUser =
      await _googleSignIn.authenticate();

      final GoogleSignInAuthentication
      googleAuth =
          googleUser.authentication;

      final credential =
      GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return await _auth
          .signInWithCredential(
        credential,
      );
    } catch (e) {
      print(
        'Google Sign-In Error: $e',
      );
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

