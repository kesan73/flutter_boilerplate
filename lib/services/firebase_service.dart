import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/exceptions.dart';

abstract class FirebaseService {
  Future<void> initialize();
  Future<Map<String, dynamic>?> getDocument(String collection, String docId);
  Future<void> setDocument(
      String collection, String docId, Map<String, dynamic> data);
  Future<void> updateDocument(
      String collection, String docId, Map<String, dynamic> data);
  Future<void> deleteDocument(String collection, String docId);
  Future<List<Map<String, dynamic>>> getCollection(String collection);
}

class FirebaseServiceImpl implements FirebaseService {
  final FirebaseFirestore _firestore;

  FirebaseServiceImpl(this._firestore);

  @override
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      throw ServerException(
          message: 'Firebase initialization failed: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>?> getDocument(
      String collection, String docId) async {
    try {
      final doc = await _firestore.collection(collection).doc(docId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw ServerException(message: 'Failed to get document: ${e.toString()}');
    }
  }

  @override
  Future<void> setDocument(
      String collection, String docId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(docId).set(data);
    } catch (e) {
      throw ServerException(message: 'Failed to set document: ${e.toString()}');
    }
  }

  @override
  Future<void> updateDocument(
      String collection, String docId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(docId).update(data);
    } catch (e) {
      throw ServerException(
          message: 'Failed to update document: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteDocument(String collection, String docId) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
    } catch (e) {
      throw ServerException(
          message: 'Failed to delete document: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    try {
      final querySnapshot = await _firestore.collection(collection).get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw ServerException(
          message: 'Failed to get collection: ${e.toString()}');
    }
  }
}
