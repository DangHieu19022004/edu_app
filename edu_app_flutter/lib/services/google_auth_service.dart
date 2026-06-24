import 'package:edu_app_flutter/services/api_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  GoogleAuthService({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  final GoogleSignIn _googleSignIn;

  Future<String?> getFirebaseIdToken() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        return null;
      }

      final googleAuth = await googleAccount.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw const ApiException(message: 'Khong lay duoc Google ID token.');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final firebaseIdToken = await userCredential.user?.getIdToken(true);

      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw const ApiException(
          message: 'Khong lay duoc Firebase ID token tu tai khoan Google.',
        );
      }

      return firebaseIdToken;
    } on FirebaseException catch (e) {
      throw ApiException(
        message: e.message ?? 'Loi Firebase. Vui long kiem tra cau hinh.',
      );
    } on FirebaseAuthException catch (e) {
      throw ApiException(
        message: e.message ?? 'Xac thuc Google that bai. Vui long thu lai.',
      );
    } on PlatformException catch (e) {
      throw ApiException(
        message: e.message ?? 'Google Sign-In bi loi nen tang.',
      );
    } catch (e) {
      throw ApiException(
        message:
            'Google Sign-In that bai. Chi tiet: ${e.toString()}',
      );
    }
  }
}
