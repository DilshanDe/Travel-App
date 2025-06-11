import 'package:shared_preferences/shared_preferences.dart';

class SharedpreferenceHelper {
  static String userIdKey = "USERKEY";
  static String userNameKey = "USERNAMEKEY";
  static String userEmailKey = "USEREMAILKEY";
  static String userImageKey = "USERIMAGEKEY";
  static String userDisplayNameKey = "USERDISPLAYNAMEKEY";

  // ==================== SAVE METHODS ====================

  // Save user ID
  Future<bool> saveUserId(String getUserId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userIdKey, getUserId);
  }

  // Save user name
  Future<bool> saveUserName(String getUserName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userNameKey, getUserName);
  }

  // Save user email
  Future<bool> saveUserEmail(String getUserEmail) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userEmailKey, getUserEmail);
  }

  // Save user profile image
  Future<bool> saveUserImage(String getUserImage) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userImageKey, getUserImage);
  }

  // Save user display name
  Future<bool> saveUserDisplayName(String getUserDisplayName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(userDisplayNameKey, getUserDisplayName);
  }

  // ==================== GET METHODS ====================

  // Get user ID
  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userIdKey);
  }

  // Get user name
  Future<String?> getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userNameKey);
  }

  // Get user email
  Future<String?> getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userEmailKey);
  }

  // Get user profile image
  Future<String?> getUserImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userImageKey);
  }

  // Get user display name
  Future<String?> getUserDisplayName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userDisplayNameKey);
  }

  // ==================== UPDATE METHODS ====================

  // Update user ID
  Future<bool> updateUserId(String newUserId) async {
    return await saveUserId(newUserId);
  }

  // Update user name
  Future<bool> updateUserName(String newUserName) async {
    return await saveUserName(newUserName);
  }

  // Update user email
  Future<bool> updateUserEmail(String newUserEmail) async {
    return await saveUserEmail(newUserEmail);
  }

  // Update user profile image
  Future<bool> updateUserImage(String newUserImage) async {
    return await saveUserImage(newUserImage);
  }

  // Update user display name
  Future<bool> updateUserDisplayName(String newUserDisplayName) async {
    return await saveUserDisplayName(newUserDisplayName);
  }

  // Update multiple user profile fields at once
  Future<bool> updateUserProfile({
    String? userId,
    String? name,
    String? email,
    String? image,
    String? displayName,
  }) async {
    bool success = true;

    if (userId != null) {
      success = success && await updateUserId(userId);
    }
    if (name != null) {
      success = success && await updateUserName(name);
    }
    if (email != null) {
      success = success && await updateUserEmail(email);
    }
    if (image != null) {
      success = success && await updateUserImage(image);
    }
    if (displayName != null) {
      success = success && await updateUserDisplayName(displayName);
    }

    return success;
  }

  // ==================== CLEAR METHODS ====================

  // Clear specific user data
  Future<bool> clearUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.remove(userIdKey);
  }

  Future<bool> clearUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.remove(userNameKey);
  }

  Future<bool> clearUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.remove(userEmailKey);
  }

  Future<bool> clearUserImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.remove(userImageKey);
  }

  Future<bool> clearUserDisplayName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.remove(userDisplayNameKey);
  }

  // Clear all user data
  Future<bool> clearUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Remove all user-related keys
    await prefs.remove(userIdKey);
    await prefs.remove(userNameKey);
    await prefs.remove(userEmailKey);
    await prefs.remove(userImageKey);
    await prefs.remove(userDisplayNameKey);

    return true;
  }

  // ==================== UTILITY METHODS ====================

  // Check if user data exists (for auto-login purposes)
  Future<bool> hasUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(userIdKey) && prefs.containsKey(userEmailKey);
  }

  // Get all user data at once
  Future<Map<String, String?>> getAllUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return {
      'userId': prefs.getString(userIdKey),
      'userName': prefs.getString(userNameKey),
      'userEmail': prefs.getString(userEmailKey),
      'userImage': prefs.getString(userImageKey),
      'userDisplayName': prefs.getString(userDisplayNameKey),
    };
  }

  // Check if specific user field exists
  Future<bool> hasUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(userIdKey);
  }

  Future<bool> hasUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(userNameKey);
  }

  Future<bool> hasUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(userEmailKey);
  }

  Future<bool> hasUserImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(userImageKey);
  }

  Future<bool> hasUserDisplayName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(userDisplayNameKey);
  }

  // ==================== BATCH OPERATIONS ====================

  // Save all user data at once
  Future<bool> saveAllUserData({
    required String userId,
    required String userName,
    required String userEmail,
    String? userImage,
    String? userDisplayName,
  }) async {
    bool success = true;

    success = success && await saveUserId(userId);
    success = success && await saveUserName(userName);
    success = success && await saveUserEmail(userEmail);

    if (userImage != null) {
      success = success && await saveUserImage(userImage);
    }
    if (userDisplayName != null) {
      success = success && await saveUserDisplayName(userDisplayName);
    }

    return success;
  }

  // Get user data with default values
  Future<Map<String, String>> getUserDataWithDefaults({
    String defaultUserId = '',
    String defaultUserName = '',
    String defaultUserEmail = '',
    String defaultUserImage = '',
    String defaultUserDisplayName = '',
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return {
      'userId': prefs.getString(userIdKey) ?? defaultUserId,
      'userName': prefs.getString(userNameKey) ?? defaultUserName,
      'userEmail': prefs.getString(userEmailKey) ?? defaultUserEmail,
      'userImage': prefs.getString(userImageKey) ?? defaultUserImage,
      'userDisplayName':
          prefs.getString(userDisplayNameKey) ?? defaultUserDisplayName,
    };
  }
}
