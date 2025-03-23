import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addUserDetails(
      Map<String, dynamic> userInfoMap, String id) async {
    try {
      await _firestore.collection("users").doc(id).set(userInfoMap);
    } catch (e) {
      print("Error adding user details: $e");
    }
  }

  Future<QuerySnapshot> getUserByEmail(String email) async {
    return await _firestore
        .collection("users")
        .where("email", isEqualTo: email)
        .get();
  }

  Future<void> addPost(Map<String, dynamic> postInfo, String id) async {
    try {
      await _firestore.collection("Posts").doc(id).set(postInfo);
    } catch (e) {
      print("Error adding post: $e");
    }
  }

  Stream<QuerySnapshot> getPosts() {
    return _firestore.collection("Posts").snapshots();
  }

  Future<void> addLike(String postId, String userId) async {
    try {
      await _firestore.collection("Posts").doc(postId).update({
        'Like': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      print("Error adding like: $e");
    }
  }

  Future<void> addComment(
      Map<String, dynamic> commentData, String postId) async {
    try {
      await _firestore
          .collection("Posts")
          .doc(postId)
          .collection("Comment")
          .add(commentData);
    } catch (e) {
      print("Error adding comment: $e");
    }
  }

  Stream<QuerySnapshot> getComments(String postId) {
    return _firestore
        .collection("Posts")
        .doc(postId)
        .collection("Comment")
        .snapshots();
  }

  Stream<QuerySnapshot> getPostsPlace(String place) {
    return _firestore
        .collection("Posts")
        .where("CityName", isEqualTo: place)
        .snapshots();
  }

  Future<QuerySnapshot> search(String updatedName) async {
    return await _firestore
        .collection("Location")
        .where("SearchKey",
            isEqualTo: updatedName.substring(0, 1).toUpperCase())
        .get();
  }
}
