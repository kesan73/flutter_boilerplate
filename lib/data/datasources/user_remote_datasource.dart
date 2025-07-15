import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class UserRemoteDataSource {
  Future<UserModel> getUserProfile(String userId);
  Future<UserModel> updateUserProfile(
      {required String userId, required Map<String, dynamic> data});
  Future<void> deleteUserProfile(String userId);
  Future<List<UserModel>> getAllUsers({int? limit, String? lastUserId});
  Future<List<UserModel>> searchUsers({required String query, int? limit});
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final FirebaseFirestore firestore;

  UserRemoteDataSourceImpl({required this.firestore});

  @override
  Future<UserModel> getUserProfile(String userId) async {
    try {
      final doc = await firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        throw const ServerException(message: 'User not found');
      }

      return UserModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to get user profile');
    } catch (e) {
      // 수정된 부분: 더 구체적인 에러 메시지 제공
      throw ServerException(
          message: 'Failed to get user profile: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final updateData = Map<String, dynamic>.from(data);
      updateData[FirebaseConstants.updatedAtField] =
          FieldValue.serverTimestamp();

      await firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update(updateData);

      return await getUserProfile(userId);
    } on FirebaseException catch (e) {
      throw ServerException(
          message: e.message ?? 'Failed to update user profile');
    } catch (e) {
      // 수정된 부분: 더 구체적인 에러 메시지 제공
      throw ServerException(
          message: 'Failed to update user profile: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteUserProfile(String userId) async {
    try {
      await firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .delete();
    } on FirebaseException catch (e) {
      throw ServerException(
          message: e.message ?? 'Failed to delete user profile');
    } catch (e) {
      // 수정된 부분: 더 구체적인 에러 메시지 제공
      throw ServerException(
          message: 'Failed to delete user profile: ${e.toString()}');
    }
  }

  @override
  Future<List<UserModel>> getAllUsers({int? limit, String? lastUserId}) async {
    try {
      Query query = firestore
          .collection(FirebaseConstants.usersCollection)
          .orderBy(FirebaseConstants.createdAtField, descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      if (lastUserId != null) {
        final lastDoc = await firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(lastUserId)
            .get();

        // 수정된 부분: lastDoc이 존재하는지 확인
        if (!lastDoc.exists) {
          throw const ServerException(message: 'Last user document not found');
        }

        query = query.startAfterDocument(lastDoc);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to get users');
    } catch (e) {
      // 수정된 부분: 더 구체적인 에러 메시지 제공
      throw ServerException(message: 'Failed to get users: ${e.toString()}');
    }
  }

  @override
  Future<List<UserModel>> searchUsers(
      {required String query, int? limit}) async {
    try {
      // 수정된 부분: 검색 쿼리 검증 추가
      if (query.trim().isEmpty) {
        throw const ServerException(message: 'Search query cannot be empty');
      }

      final normalizedQuery = query.trim().toLowerCase();

      Query firestoreQuery = firestore
          .collection(FirebaseConstants.usersCollection)
          .where(FirebaseConstants.nameField,
              isGreaterThanOrEqualTo: normalizedQuery)
          .where(FirebaseConstants.nameField,
              isLessThan: normalizedQuery + '\uf8ff')
          .orderBy(FirebaseConstants.nameField);

      if (limit != null) {
        firestoreQuery = firestoreQuery.limit(limit);
      }

      final querySnapshot = await firestoreQuery.get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to search users');
    } catch (e) {
      // 수정된 부분: 더 구체적인 에러 메시지 제공
      throw ServerException(message: 'Failed to search users: ${e.toString()}');
    }
  }
}
