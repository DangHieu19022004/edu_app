import 'package:edu_app_flutter/services/api_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FacebookAuthProfile {
  const FacebookAuthProfile({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
  });

  final String uid;
  final String displayName;
  final String photoUrl;
}

class FacebookAuthService {
  Future<FacebookAuthProfile?> loginAndGetProfile() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final result = await FacebookAuth.instance.login(
        permissions: const ['public_profile'],
      );

      if (result.status == LoginStatus.cancelled) {
        return null;
      }

      if (result.status != LoginStatus.success) {
        final message = result.message?.trim();
        throw ApiException(
          message: message == null || message.isEmpty
              ? 'Dang nhap Facebook that bai.'
              : message,
        );
      }

      final accessToken = result.accessToken;
      if (accessToken == null || accessToken.tokenString.isEmpty) {
        throw const ApiException(
          message: 'Khong lay duoc Facebook access token.',
        );
      }

      final credential = FacebookAuthProvider.credential(
        accessToken.tokenString,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw const ApiException(
          message: 'Firebase khong tra ve thong tin nguoi dung Facebook.',
        );
      }

      var uid = '';
      if (accessToken is ClassicToken) {
        uid = accessToken.userId.trim();
      } else if (accessToken is LimitedToken) {
        uid = accessToken.userId.trim();
      }
      var displayName = (firebaseUser.displayName ?? '').trim();
      var photoUrl = (firebaseUser.photoURL ?? '').trim();

      // Graph call is optional. Some app setups can return Graph errors even
      // when the access token is valid and Firebase sign-in has succeeded.
      try {
        final userData = await FacebookAuth.instance.getUserData(
          fields: 'id,name,picture.width(300)',
        );
        final picture = userData['picture'];

        if (displayName.isEmpty) {
          displayName = (userData['name'] ?? '').toString().trim();
        }

        if (picture is Map) {
          final data = picture['data'];
          if (data is Map && photoUrl.isEmpty) {
            photoUrl = (data['url'] ?? '').toString().trim();
          }
        }

        if (uid.isEmpty) {
          uid = (userData['id'] ?? '').toString().trim();
        }
      } catch (_) {
        // Ignore Graph profile fetch errors and continue with Firebase/token data.
      }

      if (uid.isEmpty) {
        uid = firebaseUser.uid.trim();
      }

      if (displayName.isEmpty) {
        displayName = 'Facebook User';
      }

      if (uid.isEmpty || displayName.isEmpty) {
        throw const ApiException(
          message: 'Khong lay duoc thong tin tai khoan Facebook.',
        );
      }

      return FacebookAuthProfile(
        uid: uid,
        displayName: displayName,
        photoUrl: photoUrl,
      );
    } on PlatformException catch (e) {
      final message = e.message?.trim();
      throw ApiException(
        message: message == null || message.isEmpty
            ? 'Facebook SDK loi xac thuc.'
            : message,
      );
    } on FirebaseAuthException catch (e) {
      final message = e.message?.trim();
      throw ApiException(
        message: message == null || message.isEmpty
            ? 'Firebase xac thuc Facebook that bai.'
            : message,
      );
    } on FirebaseException catch (e) {
      final message = e.message?.trim();
      throw ApiException(
        message: message == null || message.isEmpty
            ? 'Firebase chua duoc cau hinh dung.'
            : message,
      );
    } catch (e) {
      throw ApiException(
        message: 'Facebook login that bai. Chi tiet: ${e.toString()}',
      );
    }
  }
}
