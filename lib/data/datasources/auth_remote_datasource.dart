import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

import '../../core/constants/firebase_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/services/logger_service.dart';
import '../models/auth_model.dart';

abstract class AuthRemoteDataSource {
  // 기본 인증
  Future<AuthModel> login({required String email, required String password});
  Future<AuthModel> register(
      {required String email, required String password, required String name});
  Future<void> logout();
  Future<AuthModel?> getCurrentUser();
  Future<void> resetPassword({required String email});
  Future<void> verifyEmail();

  // 추가된 메서드들
  Future<void> refreshUser();
  Future<void> changePassword(
      {required String currentPassword, required String newPassword});
  Future<void> deleteAccount();
  Future<void> updateProfile({String? displayName, String? photoURL});

  // 소셜 로그인
  Future<AuthModel> signInWithGoogle();
  Future<AuthModel> signInWithApple();
  Future<AuthModel> signInWithFacebook();

  Stream<AuthModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final GoogleSignIn googleSignIn;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
    required this.googleSignIn,
  });

  @override
  Future<AuthModel> login(
      {required String email, required String password}) async {
    try {
      LoggerService.debug('Attempting Firebase login');
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw const AuthException(message: 'Login failed - no user returned');
      }

      // 로그인 시간 업데이트
      await _updateLastLoginTime(userCredential.user!.uid);

      return AuthModel.fromFirebaseUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      LoggerService.error('Firebase login error: ${e.code}', e);
      throw AuthException(message: e.message ?? 'Login failed', code: e.code);
    } catch (e) {
      LoggerService.error('Unexpected login error', e);
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<AuthModel> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      LoggerService.debug('Attempting Firebase registration');
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw const AuthException(
            message: 'Registration failed - no user returned');
      }

      // 사용자 프로필 업데이트
      await userCredential.user!.updateDisplayName(name);

      // Firestore에 사용자 문서 생성
      await _createUserDocument(userCredential.user!, name, 'email');

      return AuthModel.fromFirebaseUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      LoggerService.error('Firebase registration error: ${e.code}', e);
      throw AuthException(
          message: e.message ?? 'Registration failed', code: e.code);
    } catch (e) {
      LoggerService.error('Unexpected registration error', e);
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      LoggerService.debug('Attempting Firebase logout');

      // Google 로그인이 활성화된 경우 Google 로그아웃도 수행
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      // Facebook 로그아웃
      await FacebookAuth.instance.logOut();

      // Firebase 로그아웃
      await firebaseAuth.signOut();

      LoggerService.info('Logout completed successfully');
    } on FirebaseAuthException catch (e) {
      LoggerService.error('Firebase logout error: ${e.code}', e);
      throw AuthException(message: e.message ?? 'Logout failed', code: e.code);
    } catch (e) {
      LoggerService.error('Unexpected logout error', e);
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<AuthModel?> getCurrentUser() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) return null;

      return AuthModel.fromFirebaseUser(user);
    } catch (e) {
      LoggerService.error('Error getting current user', e);
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      LoggerService.debug('Sending password reset email to: $email');
      await firebaseAuth.sendPasswordResetEmail(email: email);
      LoggerService.info('Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      LoggerService.error('Firebase password reset error: ${e.code}', e);
      throw AuthException(
          message: e.message ?? 'Password reset failed', code: e.code);
    } catch (e) {
      LoggerService.error('Unexpected password reset error', e);
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<void> verifyEmail() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException(message: 'No user logged in');
      }

      LoggerService.debug('Sending email verification');
      await user.sendEmailVerification();
      LoggerService.info('Email verification sent successfully');
    } on FirebaseAuthException catch (e) {
      LoggerService.error('Firebase email verification error: ${e.code}', e);
      throw AuthException(
          message: e.message ?? 'Email verification failed', code: e.code);
    } catch (e) {
      LoggerService.error('Unexpected email verification error', e);
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<void> refreshUser() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException(message: 'No user logged in');
      }

      LoggerService.debug('Refreshing user data');
      await user.reload();
      LoggerService.debug('User data refreshed successfully');
    } on FirebaseAuthException catch (e) {
      LoggerService.error('Firebase user refresh error: ${e.code}', e);
      throw AuthException(
          message: e.message ?? 'User refresh failed', code: e.code);
    } catch (e) {
      LoggerService.error('Unexpected user refresh error', e);
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException(message: 'No user logged in');
      }

      LoggerService.debug('Attempting password change');

      // 현재 비밀번호로 재인증
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // 새 비밀번호로 업데이트
      await user.updatePassword(newPassword);

      LoggerService.info('Password changed successfully');
    } on FirebaseAuthException catch (e) {
      LoggerService.error('Firebase password change error: ${e.code}', e);
      throw AuthException(
          message: e.message ?? 'Password change failed', code: e.code);
    } catch (e) {
      LoggerService.error('Unexpected password change error', e);
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException(message: 'No user logged in');
      }

      LoggerService.debug('Attempting account deletion');

      // Firestore 사용자 문서 삭제
      await firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .delete();

      // Firebase Auth 계정 삭제
      await user.delete();

      LoggerService.info('Account deleted successfully');
    } on FirebaseAuthException catch (e) {
      LoggerService.error('Firebase account deletion error: ${e.code}', e);
      throw AuthException(
          message: e.message ?? 'Account deletion failed', code: e.code);
    } catch (e) {
      LoggerService.error('Unexpected account deletion error', e);
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException(message: 'No user logged in');
      }

      LoggerService.debug('Updating user profile');

      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Firestore 사용자 문서도 업데이트
      await _updateUserDocument(user.uid, {
        if (displayName != null) FirebaseConstants.nameField: displayName,
        if (photoURL != null) FirebaseConstants.profileImageUrlField: photoURL,
        FirebaseConstants.updatedAtField: FieldValue.serverTimestamp(),
      });

      LoggerService.info('Profile updated successfully');
    } on FirebaseAuthException catch (e) {
      LoggerService.error('Firebase profile update error: ${e.code}', e);
      throw AuthException(
          message: e.message ?? 'Profile update failed', code: e.code);
    } catch (e) {
      LoggerService.error('Unexpected profile update error', e);
      throw AuthException(message: e.toString());
    }
  }

// Google 로그인 구현 상세 설명
/*
==========================================
Google 로그인 설정 방법
==========================================

1. pubspec.yaml 의존성 추가:
dependencies:
  google_sign_in: ^6.1.5

2. Android 설정:
   - android/app/google-services.json 파일 추가
   - Firebase Console에서 SHA-1 지문 등록
   - android/app/build.gradle에 설정 추가

3. iOS 설정:
   - ios/Runner/GoogleService-Info.plist 파일 추가
   - ios/Runner/Info.plist에 URL Scheme 추가
   - Firebase Console에서 iOS 앱 등록

4. GoogleSignIn 인스턴스 설정:
   - 의존성 주입에서 scopes 설정
   - 필요한 권한 범위 지정 (email, profile 등)

==========================================
보안 고려사항
==========================================

1. 토큰 보안:
   - Access Token과 ID Token은 자동으로 만료됨
   - 서버에서 ID Token 검증 필요 시 firebase-admin SDK 사용

2. 사용자 데이터 보호:
   - 민감한 정보는 Firestore Security Rules로 보호
   - 클라이언트에서는 최소한의 정보만 캐싱

3. 에러 처리:
   - 네트워크 오류, 계정 충돌 등 다양한 시나리오 대응
   - 사용자에게 친화적인 에러 메시지 제공

==========================================
일반적인 에러 상황들
==========================================

1. account-exists-with-different-credential:
   - 동일한 이메일로 다른 로그인 방법 사용 시 발생
   - 계정 연결 로직 필요

2. credential-already-in-use:
   - 이미 다른 계정에 연결된 Google 계정 사용 시

3. network-request-failed:
   - 네트워크 연결 문제

4. Google Sign-In SDK 관련 오류:
   - 설정 파일 누락 (google-services.json, GoogleService-Info.plist)
   - SHA-1 지문 불일치 (Android)
   - URL Scheme 설정 오류 (iOS)
*/
  @override
  Future<AuthModel> signInWithGoogle() async {
    try {
      LoggerService.debug('Attempting Google sign in');

      // ==========================================
      // 1단계: Google Sign-In 프로세스 시작
      // ==========================================
      // GoogleSignIn.signIn()을 호출하면:
      // - Android: Google Play Services를 통해 계정 선택 다이얼로그 표시
      // - iOS: Safari View Controller 또는 Google 앱을 통해 인증 진행
      // - 사용자가 계정을 선택하고 권한을 승인하면 GoogleSignInAccount 반환
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // 사용자가 로그인을 취소한 경우 (뒤로가기 버튼 또는 취소 버튼 클릭)
      if (googleUser == null) {
        throw const AuthException(message: 'Google sign in was cancelled');
      }

      // ==========================================
      // 2단계: 인증 토큰 획득
      // ==========================================
      // Google 서버로부터 Access Token과 ID Token을 받아옵니다
      // - accessToken: Google API 호출에 사용
      // - idToken: 사용자 신원 확인에 사용 (JWT 형태)
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // ==========================================
      // 3단계: Firebase 인증 자격증명 생성
      // ==========================================
      // Google에서 받은 토큰들을 Firebase가 인식할 수 있는
      // AuthCredential 객체로 변환
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, // Google API 접근용 토큰
        idToken: googleAuth.idToken, // 사용자 신원 확인용 토큰
      );

      // ==========================================
      // 4단계: Firebase 인증 수행
      // ==========================================
      // Firebase Auth에 Google 자격증명을 전달하여 실제 인증 수행
      // 이 과정에서 Firebase는:
      // 1. Google ID Token의 유효성 검증
      // 2. 새 사용자라면 Firebase Auth에 계정 생성
      // 3. 기존 사용자라면 계정 연결 또는 로그인 처리
      final UserCredential userCredential =
          await firebaseAuth.signInWithCredential(credential);

      // Firebase 인증이 실패한 경우
      if (userCredential.user == null) {
        throw const AuthException(message: 'Google sign in failed');
      }

      // ==========================================
      // 5단계: 사용자 데이터 Firestore 저장
      // ==========================================
      // Firebase Auth는 인증만 담당하고, 추가 사용자 정보는
      // Firestore에 별도로 저장해야 합니다
      await _saveUserToFirestore(userCredential.user!, 'google');

      LoggerService.info('Google sign in successful');

      // ==========================================
      // 6단계: AuthModel 반환
      // ==========================================
      // Firebase User 객체를 앱에서 사용하는 AuthModel로 변환하여 반환
      return AuthModel.fromFirebaseUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      // Firebase 인증 과정에서 발생하는 오류들
      // 예: account-exists-with-different-credential,
      //     credential-already-in-use 등
      LoggerService.error('Firebase Google sign in error: ${e.code}', e);
      throw AuthException(
          message: e.message ?? 'Google sign in failed', code: e.code);
    } catch (e) {
      // 그 외 예상치 못한 오류들
      // 예: 네트워크 오류, 플랫폼 오류 등
      LoggerService.error('Unexpected Google sign in error', e);
      throw AuthException(message: 'Google sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<AuthModel> signInWithApple() async {
    try {
      LoggerService.debug('Attempting Apple sign in');

      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final UserCredential userCredential =
          await firebaseAuth.signInWithCredential(oauthCredential);

      if (userCredential.user == null) {
        throw const AuthException(message: 'Apple sign in failed');
      }

      // Apple에서 제공되는 추가 정보 처리
      Map<String, dynamic>? additionalData;
      if (appleCredential.givenName != null ||
          appleCredential.familyName != null) {
        additionalData = {
          'givenName': appleCredential.givenName,
          'familyName': appleCredential.familyName,
          'fullName':
              '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                  .trim(),
        };
      }

      await _saveUserToFirestore(
        userCredential.user!,
        'apple',
        additionalData: additionalData,
      );

      LoggerService.info('Apple sign in successful');
      return AuthModel.fromFirebaseUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      LoggerService.error('Firebase Apple sign in error: ${e.code}', e);
      throw AuthException(
          message: e.message ?? 'Apple sign in failed', code: e.code);
    } catch (e) {
      LoggerService.error('Unexpected Apple sign in error', e);
      throw AuthException(message: 'Apple sign in failed: ${e.toString()}');
    }
  }

/*
==========================================
Facebook 로그인 설정 방법 (flutter_facebook_auth 7.x)
==========================================

1. pubspec.yaml 의존성:
dependencies:
  flutter_facebook_auth: ^7.1.2

2. Android 설정:
   a) android/app/src/main/res/values/strings.xml:
   <resources>
       <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
       <string name="fb_login_protocol_scheme">fbYOUR_FACEBOOK_APP_ID</string>
   </resources>
   
   b) android/app/src/main/AndroidManifest.xml:
   <application>
       <meta-data 
           android:name="com.facebook.sdk.ApplicationId" 
           android:value="@string/facebook_app_id"/>
       
       <activity 
           android:name="com.facebook.FacebookActivity" 
           android:configChanges="keyboard|keyboardHidden|screenLayout|screenSize|orientation"
           android:label="@string/app_name" />
       
       <activity 
           android:name="com.facebook.CustomTabActivity" 
           android:exported="true">
           <intent-filter>
               <action android:name="android.intent.action.VIEW" />
               <category android:name="android.intent.category.DEFAULT" />
               <category android:name="android.intent.category.BROWSABLE" />
               <data android:scheme="@string/fb_login_protocol_scheme" />
           </intent-filter>
       </activity>
   </application>

3. iOS 설정:
   a) ios/Runner/Info.plist:
   <dict>
       <key>CFBundleURLTypes</key>
       <array>
           <dict>
               <key>CFBundleURLName</key>
               <string>facebook</string>
               <key>CFBundleURLSchemes</key>
               <array>
                   <string>fbYOUR_FACEBOOK_APP_ID</string>
               </array>
           </dict>
       </array>
       
       <key>FacebookAppID</key>
       <string>YOUR_FACEBOOK_APP_ID</string>
       <key>FacebookDisplayName</key>
       <string>YOUR_APP_NAME</string>
   </dict>

4. Facebook Developer Console 설정:
   - 앱 등록 및 Facebook 로그인 제품 추가
   - Android/iOS 플랫폼 설정
   - 키 해시 등록 (Android)
   - Bundle ID 등록 (iOS)

==========================================
주요 변경사항 (flutter_facebook_auth 7.x)
==========================================

1. AccessToken API 변경:
   - 이전: result.accessToken!.token
   - 현재: result.accessToken!.tokenString

2. 권한 요청 개선:
   - login() 메서드에 permissions 파라미터 명시

3. 에러 처리 강화:
   - LoginStatus enum을 통한 구체적인 상태 확인
   - 더 자세한 에러 메시지 제공

4. 사용자 데이터 가져오기:
   - getUserData() 메서드로 추가 정보 획득
   - Graph API fields 파라미터로 필요한 정보만 요청
*/
  @override
  Future<AuthModel> signInWithFacebook() async {
    try {
      LoggerService.debug('Attempting Facebook sign in');

      // ==========================================
      // 1단계: Facebook 로그인 요청
      // ==========================================
      // 필요한 권한과 함께 Facebook 로그인 시작
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'], // 명시적으로 권한 지정
      );

      // ==========================================
      // 2단계: 로그인 결과 확인
      // ==========================================
      if (result.status != LoginStatus.success) {
        // 로그인 상태에 따른 구체적인 에러 처리
        switch (result.status) {
          case LoginStatus.cancelled:
            throw const AuthException(
                message: 'Facebook sign in was cancelled');
          case LoginStatus.failed:
            throw AuthException(
              message:
                  'Facebook sign in failed: ${result.message ?? 'Unknown error'}',
            );
          case LoginStatus.operationInProgress:
            throw const AuthException(
                message: 'Facebook sign in operation already in progress');
          default:
            throw const AuthException(message: 'Facebook sign in failed');
        }
      }

      // ==========================================
      // 3단계: Access Token 확인 및 추출
      // ==========================================
      final accessToken = result.accessToken;
      if (accessToken == null) {
        throw const AuthException(message: 'Facebook access token is null');
      }

      // flutter_facebook_auth 7.x에서는 tokenString 사용
      final String tokenString = accessToken.tokenString;

      LoggerService.debug(
          'Facebook access token obtained: ${tokenString.substring(0, 10)}...');

      // ==========================================
      // 4단계: Firebase 인증 자격증명 생성
      // ==========================================
      final OAuthCredential facebookAuthCredential =
          FacebookAuthProvider.credential(tokenString);

      // ==========================================
      // 5단계: Firebase 인증 수행
      // ==========================================
      final UserCredential userCredential =
          await firebaseAuth.signInWithCredential(facebookAuthCredential);

      if (userCredential.user == null) {
        throw const AuthException(
            message: 'Facebook sign in failed - no user returned');
      }

      // ==========================================
      // 6단계: 추가 사용자 정보 가져오기 (선택사항)
      // ==========================================
      // Facebook Graph API를 통해 더 자세한 사용자 정보 가져오기
      try {
        final userData = await FacebookAuth.instance.getUserData(
          fields: "name,email,picture.width(200)",
        );
        LoggerService.debug('Facebook user data: $userData');

        // 필요시 추가 정보를 Firestore에 저장할 수 있음
        await _saveUserToFirestore(
          userCredential.user!,
          'facebook',
          additionalData: userData,
        );
      } catch (e) {
        LoggerService.warning('Failed to get additional Facebook user data', e);
        // 기본 사용자 정보만으로 저장
        await _saveUserToFirestore(userCredential.user!, 'facebook');
      }

      LoggerService.info('Facebook sign in successful');
      return AuthModel.fromFirebaseUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      LoggerService.error('Firebase Facebook sign in error: ${e.code}', e);

      // Firebase Auth 관련 구체적인 에러 처리
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage =
              'An account already exists with the same email but different sign-in credentials.';
          break;
        case 'credential-already-in-use':
          errorMessage =
              'This Facebook account is already linked to another user.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid Facebook credentials.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Facebook sign-in is not enabled for this app.';
          break;
        default:
          errorMessage = e.message ?? 'Facebook sign in failed';
      }

      throw AuthException(message: errorMessage, code: e.code);
    } on AuthException {
      // AuthException은 그대로 재전달
      rethrow;
    } catch (e) {
      LoggerService.error('Unexpected Facebook sign in error', e);
      throw AuthException(message: 'Facebook sign in failed: ${e.toString()}');
    }
  }

// ==========================================
// Helper 메서드: 개선된 Firestore 사용자 정보 저장
// ==========================================
  Future<void> _saveUserToFirestore(
    User user,
    String loginMethod, {
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final userDoc =
          firestore.collection(FirebaseConstants.usersCollection).doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // ==========================================
        // 신규 사용자인 경우: 완전한 사용자 문서 생성
        // ==========================================
        final userData = <String, dynamic>{
          FirebaseConstants.emailField: user.email,
          FirebaseConstants.nameField:
              user.displayName ?? additionalData?['name'] ?? '',
          FirebaseConstants.profileImageUrlField:
              user.photoURL ?? additionalData?['picture']?['data']?['url'],
          FirebaseConstants.createdAtField: FieldValue.serverTimestamp(),
          FirebaseConstants.updatedAtField: FieldValue.serverTimestamp(),
          FirebaseConstants.isActiveField: true,
          FirebaseConstants.emailVerifiedField: user.emailVerified,
          FirebaseConstants.loginMethodField: loginMethod,
          FirebaseConstants.lastLoginField: FieldValue.serverTimestamp(),
        };

        // Facebook에서 가져온 추가 정보 저장
        if (additionalData != null) {
          if (additionalData['email'] != null &&
              userData[FirebaseConstants.emailField] == null) {
            userData[FirebaseConstants.emailField] = additionalData['email'];
          }
        }

        await userDoc.set(userData);
        LoggerService.debug(
            'New user document created in Firestore with Facebook data');
      } else {
        // ==========================================
        // 기존 사용자인 경우: 필요한 정보만 업데이트
        // ==========================================
        final updateData = <String, dynamic>{
          FirebaseConstants.lastLoginField: FieldValue.serverTimestamp(),
        };

        // 프로필 이미지가 변경되었을 수 있으므로 업데이트
        if (user.photoURL != null) {
          updateData[FirebaseConstants.profileImageUrlField] = user.photoURL;
        } else if (additionalData?['picture']?['data']?['url'] != null) {
          updateData[FirebaseConstants.profileImageUrlField] =
              additionalData!['picture']['data']['url'];
        }

        await userDoc.update(updateData);
        LoggerService.debug('Existing user login time updated');
      }
    } catch (e) {
      LoggerService.error('Failed to save user to Firestore', e);
      // Firestore 저장 실패는 인증 성공에 영향을 주지 않도록
      // 예외를 다시 던지지 않음 (로그만 남김)
    }
  }

  @override
  Stream<AuthModel?> get authStateChanges {
    return firebaseAuth.authStateChanges().map(
      (user) {
        if (user != null) {
          LoggerService.debug('Auth state changed: User logged in');
          return AuthModel.fromFirebaseUser(user);
        } else {
          LoggerService.debug('Auth state changed: User logged out');
          return null;
        }
      },
    );
  }

  // Private helper methods
  Future<void> _createUserDocument(
      User user, String name, String loginMethod) async {
    try {
      await firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .set({
        FirebaseConstants.emailField: user.email,
        FirebaseConstants.nameField: name,
        FirebaseConstants.profileImageUrlField: user.photoURL,
        FirebaseConstants.createdAtField: FieldValue.serverTimestamp(),
        FirebaseConstants.updatedAtField: FieldValue.serverTimestamp(),
        FirebaseConstants.isActiveField: true,
        FirebaseConstants.emailVerifiedField: user.emailVerified,
        FirebaseConstants.loginMethodField: loginMethod,
        FirebaseConstants.lastLoginField: FieldValue.serverTimestamp(),
      });
      LoggerService.debug('User document created in Firestore');
    } catch (e) {
      LoggerService.error('Failed to create user document', e);
      // 사용자 문서 생성 실패는 치명적이지 않으므로 로그만 남김
    }
  }

  Future<void> _updateLastLoginTime(String uid) async {
    try {
      await firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(uid)
          .update({
        FirebaseConstants.lastLoginField: FieldValue.serverTimestamp(),
      });
      LoggerService.debug('Last login time updated');
    } catch (e) {
      LoggerService.error('Failed to update last login time', e);
    }
  }

  Future<void> _updateUserDocument(
      String uid, Map<String, dynamic> data) async {
    try {
      await firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(uid)
          .update(data);
      LoggerService.debug('User document updated in Firestore');
    } catch (e) {
      LoggerService.error('Failed to update user document', e);
    }
  }

  // Apple 로그인용 nonce 생성
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
