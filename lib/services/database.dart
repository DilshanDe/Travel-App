import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User Management Methods
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

  Future<void> updateUserDetails(
      Map<String, dynamic> userInfoMap, String id) async {
    try {
      await _firestore.collection("users").doc(id).update(userInfoMap);
      print("User details updated successfully");
    } catch (e) {
      print("Error updating user details: $e");
      throw e; // Re-throw to handle in calling function
    }
  }

  Future<Map<String, dynamic>?> getUserDetails(String id) async {
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection("users").doc(id).get();

      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print("Error getting user details: $e");
      return null;
    }
  }

  // Post Management Methods
  Future<void> addPost(Map<String, dynamic> postInfo, String id) async {
    try {
      // Add timestamp if not provided
      if (!postInfo.containsKey('Timestamp')) {
        postInfo['Timestamp'] = DateTime.now().millisecondsSinceEpoch;
      }
      await _firestore.collection("Posts").doc(id).set(postInfo);
    } catch (e) {
      print("Error adding post: $e");
    }
  }

  Stream<QuerySnapshot> getPosts() {
    return _firestore
        .collection("Posts")
        .orderBy("Timestamp", descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getPostsPlace(String place) {
    return _firestore
        .collection("Posts")
        .where("CityName", isEqualTo: place)
        .snapshots();
  }

  // Method to get posts by user ID
  Stream<QuerySnapshot> getPostsByUser(String userId) {
    return _firestore
        .collection("Posts")
        .where("UserId", isEqualTo: userId)
        .orderBy("Timestamp", descending: true)
        .snapshots();
  }

  // Method to delete post
  Future<void> deletePost(String postId) async {
    try {
      // First delete all comments in the post
      QuerySnapshot comments = await _firestore
          .collection("Posts")
          .doc(postId)
          .collection("Comment")
          .get();

      WriteBatch batch = _firestore.batch();

      // Delete all comments
      for (DocumentSnapshot comment in comments.docs) {
        batch.delete(comment.reference);
      }

      // Delete the post
      batch.delete(_firestore.collection("Posts").doc(postId));

      await batch.commit();
      print("Post and all comments deleted successfully");
    } catch (e) {
      print("Error deleting post: $e");
      throw e;
    }
  }

  // Method to update post
  Future<void> updatePost(
      String postId, Map<String, dynamic> updatedData) async {
    try {
      // Add update timestamp
      updatedData['UpdatedAt'] = DateTime.now().millisecondsSinceEpoch;
      await _firestore.collection("Posts").doc(postId).update(updatedData);
      print("Post updated successfully");
    } catch (e) {
      print("Error updating post: $e");
      throw e;
    }
  }

  // Like Management Methods
  Future<void> addLike(String postId, String userId) async {
    try {
      await _firestore.collection("Posts").doc(postId).update({
        'Like': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      print("Error adding like: $e");
    }
  }

  Future<void> removeLike(String postId, String userId) async {
    try {
      await _firestore.collection("Posts").doc(postId).update({
        'Like': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      print("Error removing like: $e");
    }
  }

  // Method to get posts liked by user
  Stream<QuerySnapshot> getLikedPostsByUser(String userId) {
    return _firestore
        .collection("Posts")
        .where("Like", arrayContains: userId)
        .orderBy("Timestamp", descending: true)
        .snapshots();
  }

  // Enhanced Comment Management Methods
  Future<void> addComment(
      Map<String, dynamic> commentData, String postId) async {
    try {
      // Add timestamp if not provided
      if (!commentData.containsKey('Timestamp')) {
        commentData['Timestamp'] = DateTime.now().millisecondsSinceEpoch;
      }

      await _firestore
          .collection("Posts")
          .doc(postId)
          .collection("Comment")
          .add(commentData);
      print("Comment added successfully");
    } catch (e) {
      print("Error adding comment: $e");
      throw e;
    }
  }

  Stream<QuerySnapshot> getComments(String postId) {
    return _firestore
        .collection("Posts")
        .doc(postId)
        .collection("Comment")
        .orderBy("Timestamp", descending: false)
        .snapshots();
  }

  // Method to delete comment
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await _firestore
          .collection("Posts")
          .doc(postId)
          .collection("Comment")
          .doc(commentId)
          .delete();
      print("Comment deleted successfully");
    } catch (e) {
      print("Error deleting comment: $e");
      throw e;
    }
  }

  // Method to update comment
  Future<void> updateComment(
      String postId, String commentId, Map<String, dynamic> updatedData) async {
    try {
      // Add update timestamp
      updatedData['UpdatedAt'] = DateTime.now().millisecondsSinceEpoch;

      await _firestore
          .collection("Posts")
          .doc(postId)
          .collection("Comment")
          .doc(commentId)
          .update(updatedData);
      print("Comment updated successfully");
    } catch (e) {
      print("Error updating comment: $e");
      throw e;
    }
  }

  // Method to get comment count for a post
  Future<int> getCommentCount(String postId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection("Posts")
          .doc(postId)
          .collection("Comment")
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print("Error getting comment count: $e");
      return 0;
    }
  }

  // Method to get comments by user
  Stream<QuerySnapshot> getCommentsByUser(String userId) {
    return _firestore
        .collectionGroup("Comment") // Search across all comment subcollections
        .where("UserId", isEqualTo: userId)
        .orderBy("Timestamp", descending: true)
        .snapshots();
  }

  // Search Methods
  Future<QuerySnapshot> search(String updatedName) async {
    return await _firestore
        .collection("Location")
        .where("SearchKey",
            isEqualTo: updatedName.substring(0, 1).toUpperCase())
        .get();
  }

  // Method to search posts by place name
  Future<QuerySnapshot> searchPosts(String searchTerm) async {
    return await _firestore
        .collection("Posts")
        .where("PlaceName", isGreaterThanOrEqualTo: searchTerm)
        .where("PlaceName", isLessThanOrEqualTo: searchTerm + '\uf8ff')
        .get();
  }

  // Method to search posts by city name
  Future<QuerySnapshot> searchPostsByCity(String cityName) async {
    return await _firestore
        .collection("Posts")
        .where("CityName", isGreaterThanOrEqualTo: cityName)
        .where("CityName", isLessThanOrEqualTo: cityName + '\uf8ff')
        .get();
  }

  // Advanced search method
  Future<QuerySnapshot> searchPostsAdvanced({
    String? placeName,
    String? cityName,
    String? userName,
    int? limit,
  }) async {
    Query query = _firestore.collection("Posts");

    if (placeName != null && placeName.isNotEmpty) {
      query = query
          .where("PlaceName", isGreaterThanOrEqualTo: placeName)
          .where("PlaceName", isLessThanOrEqualTo: placeName + '\uf8ff');
    }

    if (cityName != null && cityName.isNotEmpty) {
      query = query
          .where("CityName", isGreaterThanOrEqualTo: cityName)
          .where("CityName", isLessThanOrEqualTo: cityName + '\uf8ff');
    }

    if (userName != null && userName.isNotEmpty) {
      query = query
          .where("Name", isGreaterThanOrEqualTo: userName)
          .where("Name", isLessThanOrEqualTo: userName + '\uf8ff');
    }

    query = query.orderBy("Timestamp", descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return await query.get();
  }

  // Location Management Methods
  Future<void> addLocation(Map<String, dynamic> locationInfo, String id) async {
    try {
      await _firestore.collection("Location").doc(id).set(locationInfo);
    } catch (e) {
      print("Error adding location: $e");
    }
  }

  Stream<QuerySnapshot> getLocations() {
    return _firestore.collection("Location").snapshots();
  }

  // Method to get popular locations (most posted about)
  Future<QuerySnapshot> getPopularLocations() async {
    return await _firestore
        .collection("Location")
        .orderBy("PostCount", descending: true)
        .limit(10)
        .get();
  }

  // Method to increment location post count
  Future<void> incrementLocationPostCount(String locationName) async {
    try {
      QuerySnapshot locationQuery = await _firestore
          .collection("Location")
          .where("Name", isEqualTo: locationName)
          .get();

      if (locationQuery.docs.isNotEmpty) {
        // Location exists, increment count
        DocumentReference locationRef = locationQuery.docs.first.reference;
        await locationRef.update({
          'PostCount': FieldValue.increment(1),
        });
      } else {
        // Location doesn't exist, create new with count 1
        await _firestore.collection("Location").add({
          'Name': locationName,
          'PostCount': 1,
          'SearchKey': locationName.substring(0, 1).toUpperCase(),
          'CreatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      print("Error updating location post count: $e");
    }
  }

  // Follow/Following System
  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      // Add to following list
      await _firestore.collection("users").doc(currentUserId).update({
        'Following': FieldValue.arrayUnion([targetUserId])
      });

      // Add to followers list
      await _firestore.collection("users").doc(targetUserId).update({
        'Followers': FieldValue.arrayUnion([currentUserId])
      });

      // Create notification for followed user
      await addNotification({
        'Type': 'follow',
        'Message': 'started following you',
        'FromUserId': currentUserId,
        'Timestamp': DateTime.now().millisecondsSinceEpoch,
        'IsRead': false,
      }, targetUserId);
    } catch (e) {
      print("Error following user: $e");
    }
  }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      // Remove from following list
      await _firestore.collection("users").doc(currentUserId).update({
        'Following': FieldValue.arrayRemove([targetUserId])
      });

      // Remove from followers list
      await _firestore.collection("users").doc(targetUserId).update({
        'Followers': FieldValue.arrayRemove([currentUserId])
      });
    } catch (e) {
      print("Error unfollowing user: $e");
    }
  }

  // Method to get following users' posts
  Stream<QuerySnapshot> getFollowingPosts(List<String> followingList) {
    if (followingList.isEmpty) {
      // Return empty stream if not following anyone
      return Stream.empty();
    }

    return _firestore
        .collection("Posts")
        .where("UserId", whereIn: followingList)
        .orderBy("Timestamp", descending: true)
        .snapshots();
  }

  // Method to check if user is following another user
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection("users").doc(currentUserId).get();

      if (userDoc.exists) {
        List following = userDoc.get('Following') ?? [];
        return following.contains(targetUserId);
      }
      return false;
    } catch (e) {
      print("Error checking follow status: $e");
      return false;
    }
  }

  // Analytics Methods
  Future<int> getUserPostCount(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection("Posts")
          .where("UserId", isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print("Error getting post count: $e");
      return 0;
    }
  }

  Future<int> getUserLikeCount(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection("Posts")
          .where("UserId", isEqualTo: userId)
          .get();

      int totalLikes = 0;
      for (DocumentSnapshot doc in snapshot.docs) {
        List likes = doc.get('Like') ?? [];
        totalLikes += likes.length;
      }
      return totalLikes;
    } catch (e) {
      print("Error getting like count: $e");
      return 0;
    }
  }

  // Method to get user's follower count
  Future<int> getFollowerCount(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection("users").doc(userId).get();

      if (userDoc.exists) {
        List followers = userDoc.get('Followers') ?? [];
        return followers.length;
      }
      return 0;
    } catch (e) {
      print("Error getting follower count: $e");
      return 0;
    }
  }

  // Method to get user's following count
  Future<int> getFollowingCount(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection("users").doc(userId).get();

      if (userDoc.exists) {
        List following = userDoc.get('Following') ?? [];
        return following.length;
      }
      return 0;
    } catch (e) {
      print("Error getting following count: $e");
      return 0;
    }
  }

  // Notification Methods
  Future<void> addNotification(
      Map<String, dynamic> notificationData, String userId) async {
    try {
      await _firestore
          .collection("users")
          .doc(userId)
          .collection("Notifications")
          .add(notificationData);
    } catch (e) {
      print("Error adding notification: $e");
    }
  }

  Stream<QuerySnapshot> getNotifications(String userId) {
    return _firestore
        .collection("users")
        .doc(userId)
        .collection("Notifications")
        .orderBy("Timestamp", descending: true)
        .snapshots();
  }

  // Method to mark notification as read
  Future<void> markNotificationAsRead(
      String userId, String notificationId) async {
    try {
      await _firestore
          .collection("users")
          .doc(userId)
          .collection("Notifications")
          .doc(notificationId)
          .update({"IsRead": true});
    } catch (e) {
      print("Error marking notification as read: $e");
    }
  }

  // Method to get unread notification count
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection("users")
          .doc(userId)
          .collection("Notifications")
          .where("IsRead", isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print("Error getting unread notification count: $e");
      return 0;
    }
  }

  // Report/Block Methods
  Future<void> reportPost(
      String postId, String reporterId, String reason) async {
    try {
      Map<String, dynamic> reportData = {
        "PostId": postId,
        "ReporterId": reporterId,
        "Reason": reason,
        "Timestamp": DateTime.now().millisecondsSinceEpoch,
        "Status": "Pending"
      };

      await _firestore.collection("Reports").add(reportData);
    } catch (e) {
      print("Error reporting post: $e");
    }
  }

  Future<void> blockUser(String currentUserId, String blockedUserId) async {
    try {
      await _firestore.collection("users").doc(currentUserId).update({
        'BlockedUsers': FieldValue.arrayUnion([blockedUserId])
      });
    } catch (e) {
      print("Error blocking user: $e");
    }
  }

  Future<void> unblockUser(String currentUserId, String unblockedUserId) async {
    try {
      await _firestore.collection("users").doc(currentUserId).update({
        'BlockedUsers': FieldValue.arrayRemove([unblockedUserId])
      });
    } catch (e) {
      print("Error unblocking user: $e");
    }
  }

  // Method to get blocked users list
  Future<List<String>> getBlockedUsers(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection("users").doc(userId).get();

      if (userDoc.exists) {
        List<dynamic> blocked = userDoc.get('BlockedUsers') ?? [];
        return blocked.cast<String>();
      }
      return [];
    } catch (e) {
      print("Error getting blocked users: $e");
      return [];
    }
  }

  // Method to get posts excluding blocked users
  Stream<QuerySnapshot> getPostsExcludingBlocked(List<String> blockedUsers) {
    if (blockedUsers.isEmpty) {
      return getPosts();
    }

    return _firestore
        .collection("Posts")
        .where("UserId", whereNotIn: blockedUsers)
        .orderBy("Timestamp", descending: true)
        .snapshots();
  }

  // Trending and Discovery Methods
  Future<QuerySnapshot> getTrendingPosts(int days) async {
    int timestamp =
        DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;

    return await _firestore
        .collection("Posts")
        .where("Timestamp", isGreaterThan: timestamp)
        .orderBy("Timestamp", descending: false)
        .orderBy("Like", descending: true)
        .limit(20)
        .get();
  }

  // Batch Operations
  Future<void> batchUpdatePosts(
      List<String> postIds, Map<String, dynamic> updateData) async {
    try {
      WriteBatch batch = _firestore.batch();

      for (String postId in postIds) {
        DocumentReference postRef = _firestore.collection("Posts").doc(postId);
        batch.update(postRef, updateData);
      }

      await batch.commit();
      print("Batch update completed successfully");
    } catch (e) {
      print("Error in batch update: $e");
      throw e;
    }
  }

  // Clean up methods
  Future<void> deleteUserAccount(String userId) async {
    try {
      WriteBatch batch = _firestore.batch();

      // Delete user's posts and their comments
      QuerySnapshot userPosts = await _firestore
          .collection("Posts")
          .where("UserId", isEqualTo: userId)
          .get();

      for (DocumentSnapshot post in userPosts.docs) {
        // Delete all comments in each post
        QuerySnapshot comments =
            await post.reference.collection("Comment").get();
        for (DocumentSnapshot comment in comments.docs) {
          batch.delete(comment.reference);
        }
        // Delete the post
        batch.delete(post.reference);
      }

      // Delete user's comments on other posts
      QuerySnapshot userComments = await _firestore
          .collectionGroup("Comment")
          .where("UserId", isEqualTo: userId)
          .get();

      for (DocumentSnapshot comment in userComments.docs) {
        batch.delete(comment.reference);
      }

      // Delete user's notifications
      QuerySnapshot notifications = await _firestore
          .collection("users")
          .doc(userId)
          .collection("Notifications")
          .get();

      for (DocumentSnapshot notification in notifications.docs) {
        batch.delete(notification.reference);
      }

      // Delete user document
      batch.delete(_firestore.collection("users").doc(userId));

      await batch.commit();
      print("User account deleted successfully");
    } catch (e) {
      print("Error deleting user account: $e");
      throw e;
    }
  }

  // Activity Feed Methods
  Future<void> createActivityLog(
      String userId, String action, Map<String, dynamic> details) async {
    try {
      await _firestore
          .collection("users")
          .doc(userId)
          .collection("ActivityLog")
          .add({
        'Action': action,
        'Details': details,
        'Timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print("Error creating activity log: $e");
    }
  }

  Stream<QuerySnapshot> getActivityFeed(String userId, {int limit = 50}) {
    return _firestore
        .collection("users")
        .doc(userId)
        .collection("ActivityLog")
        .orderBy("Timestamp", descending: true)
        .limit(limit)
        .snapshots();
  }
}
