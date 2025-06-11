import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:traveltest_app/ImageCarousel.dart';
import 'package:traveltest_app/add_page.dart';
import 'package:traveltest_app/comment.dart';
import 'package:traveltest_app/login.dart';
import 'package:traveltest_app/post_place.dart';
import 'package:traveltest_app/profile_page.dart';
import 'package:traveltest_app/top_places.dart';
import 'package:traveltest_app/services/database.dart';
import 'package:traveltest_app/services/shared_pref.dart';
import 'package:traveltest_app/travel_support_chat.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _notificationController;
  late Animation<double> _notificationAnimation;

  // Notification counters
  int notificationCount = 0;
  int messageCount = 0;
  bool hasNewPosts = false;

  @override
  void initState() {
    super.initState();
    _notificationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _notificationAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _notificationController, curve: Curves.easeInOut),
    );

    getontheload();
    _loadNotificationCounts();
  }

  @override
  void dispose() {
    _notificationController.dispose();
    searchcontroller.dispose();
    namecontroller.dispose();
    super.dispose();
  }

  // Handle back button press with logout confirmation
  Future<bool> _onWillPop() async {
    return await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.exit_to_app, color: Colors.orange, size: 28),
                  SizedBox(width: 10),
                  Text(
                    "Logout",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Are you sure you want to logout?",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "You will need to login again to access the app.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    "Logout",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    _performLogout();
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // Perform logout operations
  void _performLogout() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.blue),
                  SizedBox(height: 16),
                  Text(
                    "Logging out...",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Clear shared preferences
      await SharedpreferenceHelper().clearUserData();

      // Add a small delay for better UX
      await Future.delayed(Duration(milliseconds: 1500));

      // Navigate to login page and clear all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LogIn()),
        (Route<dynamic> route) => false,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text("Logged out successfully"),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Hide loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 10),
              Text("Error logging out: $e"),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Load notification counts
  Future<void> _loadNotificationCounts() async {
    try {
      String? userId = await SharedpreferenceHelper().getUserId();
      if (userId != null) {
        // Get unread notification count
        int unreadNotifications =
            await DatabaseMethods().getUnreadNotificationCount(userId);

        // Simulate message count (you can replace with actual implementation)
        int unreadMessages = 3; // Replace with actual message count logic

        // Check for new posts (simulate - you can implement actual logic)
        bool newPosts = true; // Replace with actual new posts check

        setState(() {
          notificationCount = unreadNotifications;
          messageCount = unreadMessages;
          hasNewPosts = newPosts;
        });
      }
    } catch (e) {
      print("Error loading notification counts: $e");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Already on home, just refresh
        _loadNotificationCounts();
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TopPlaces()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddPage()),
        ).then((value) {
          // Refresh when returning from add page
          getontheload();
          _loadNotificationCounts();
        });
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TravelSupportScreen()),
        ).then((value) {
          // Reset message count when returning from chat
          setState(() {
            messageCount = 0;
          });
        });
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

  String? name, image, id;
  TextEditingController searchcontroller = TextEditingController();
  TextEditingController namecontroller = TextEditingController();

  getthesharedpref() async {
    name = await SharedpreferenceHelper().getUserName();
    image = await SharedpreferenceHelper().getUserImage();
    id = await SharedpreferenceHelper().getUserId();
    setState(() {});
  }

  Stream? postStream;

  getontheload() async {
    await getthesharedpref();
    postStream = await DatabaseMethods().getPosts();
    setState(() {});
  }

  bool search = false;
  var queryResultSet = [];
  var tempSearchStore = [];

  initiateSearch(value) {
    if (value.length == 0) {
      setState(() {
        queryResultSet = [];
        tempSearchStore = [];
        search = false;
      });
      return;
    }

    setState(() {
      search = true;
    });

    var CapitalizedValue =
        value.substring(0, 1).toUpperCase() + value.substring(1);
    if (queryResultSet.isEmpty && value.length == 1) {
      DatabaseMethods().search(value).then((QuerySnapshot docs) {
        for (int i = 0; i < docs.docs.length; ++i) {
          queryResultSet.add(docs.docs[i].data());
        }
      });
    } else {
      tempSearchStore = [];
      queryResultSet.forEach((element) {
        if (element['Name'].startsWith(CapitalizedValue)) {
          setState(() {
            tempSearchStore.add(element);
          });
        }
      });
    }
  }

  void _navigateToTopPlacesWithSearch(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TopPlaces(searchQuery: query),
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    DateTime postTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    DateTime now = DateTime.now();
    Duration difference = now.difference(postTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _deletePost(String postId) async {
    try {
      await DatabaseMethods().deletePost(postId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text("Post deleted successfully"),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 10),
              Text("Error deleting post: $e"),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showDeleteConfirmation(String postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text("Delete Post"),
            ],
          ),
          content: Text(
              "Are you sure you want to delete this post? This action cannot be undone."),
          actions: [
            TextButton(
              child: Text("Cancel", style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Delete", style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
                _deletePost(postId);
              },
            ),
          ],
        );
      },
    );
  }

  // Method to show success message when returning from AddPage
  void _showPostSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text("Post shared successfully! 🎉"),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: EdgeInsets.all(20),
        duration: Duration(seconds: 3),
      ),
    );

    // Update notification count
    setState(() {
      hasNewPosts = true;
    });
  }

  Widget allPosts() {
    return StreamBuilder(
        stream: postStream,
        builder: (context, AsyncSnapshot snapshot) {
          return snapshot.hasData
              ? ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot ds = snapshot.data.docs[index];

                    return Container(
                      margin: const EdgeInsets.only(
                          left: 20.0, right: 20.0, bottom: 20.0),
                      child: Material(
                        elevation: 3.0,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User info header
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 15.0, left: 15.0, right: 15.0),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(25),
                                      child: ds["UserImage"] != null &&
                                              ds["UserImage"]
                                                  .toString()
                                                  .isNotEmpty
                                          ? Image.network(
                                              ds["UserImage"],
                                              height: 50,
                                              width: 50,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  height: 50,
                                                  width: 50,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.blue.shade400,
                                                        Colors.purple.shade400
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            25),
                                                  ),
                                                  child: const Icon(
                                                      Icons.person,
                                                      size: 30,
                                                      color: Colors.white),
                                                );
                                              },
                                            )
                                          : Container(
                                              height: 50,
                                              width: 50,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.blue.shade400,
                                                    Colors.purple.shade400
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                              ),
                                              child: const Icon(Icons.person,
                                                  size: 30,
                                                  color: Colors.white),
                                            ),
                                    ),
                                    const SizedBox(width: 12.0),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ds["Name"] ?? "Unknown User",
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.w700),
                                          ),
                                          if (ds["Timestamp"] != null)
                                            Text(
                                              _formatTimestamp(ds["Timestamp"]),
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12.0,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Show options menu only for current user's posts
                                    if (ds["UserId"] == id)
                                      PopupMenuButton(
                                        icon: Icon(Icons.more_vert,
                                            color: Colors.grey),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15)),
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            child: ListTile(
                                              leading: Icon(Icons.edit,
                                                  color: Colors.blue, size: 20),
                                              title: Text("Edit Post",
                                                  style:
                                                      TextStyle(fontSize: 14)),
                                              contentPadding: EdgeInsets.zero,
                                              onTap: () {
                                                Navigator.pop(context);
                                                // Add edit functionality here
                                              },
                                            ),
                                          ),
                                          PopupMenuItem(
                                            child: ListTile(
                                              leading: Icon(Icons.delete,
                                                  color: Colors.red, size: 20),
                                              title: Text("Delete Post",
                                                  style:
                                                      TextStyle(fontSize: 14)),
                                              contentPadding: EdgeInsets.zero,
                                              onTap: () {
                                                Navigator.pop(context);
                                                _showDeleteConfirmation(ds.id);
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),

                              // Location info
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 15.0, top: 10.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        color: Colors.blue, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        "${ds["PlaceName"]}, ${ds["CityName"]}",
                                        style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 15.0),

                              // Post image with double-tap to like
                              GestureDetector(
                                onDoubleTap: () async {
                                  if (!ds["Like"].contains(id)) {
                                    await DatabaseMethods().addLike(ds.id, id!);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.favorite,
                                                color: Colors.white),
                                            SizedBox(width: 10),
                                            Text("Liked! ❤️"),
                                          ],
                                        ),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                        duration: Duration(seconds: 1),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                    );
                                  }
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(0),
                                  child: Image.network(
                                    ds["Image"],
                                    height: 250,
                                    width: MediaQuery.of(context).size.width,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 250,
                                        width:
                                            MediaQuery.of(context).size.width,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 250,
                                        width:
                                            MediaQuery.of(context).size.width,
                                        color: Colors.grey.shade300,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.broken_image,
                                                size: 50, color: Colors.grey),
                                            SizedBox(height: 10),
                                            Text("Failed to load image",
                                                style: TextStyle(
                                                    color: Colors.grey)),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              // Like count
                              if (ds["Like"] != null && ds["Like"].length > 0)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 15.0, top: 10.0),
                                  child: Text(
                                    "${ds["Like"].length} ${ds["Like"].length == 1 ? 'like' : 'likes'}",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                              // Action buttons
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 15.0, right: 15.0, top: 8.0),
                                child: Row(
                                  children: [
                                    // Like button
                                    GestureDetector(
                                      onTap: () async {
                                        if (ds["Like"].contains(id)) {
                                          await DatabaseMethods()
                                              .removeLike(ds.id, id!);
                                        } else {
                                          await DatabaseMethods()
                                              .addLike(ds.id, id!);
                                        }
                                      },
                                      child: Row(
                                        children: [
                                          Icon(
                                            ds["Like"].contains(id)
                                                ? Icons.favorite
                                                : Icons.favorite_outline,
                                            color: ds["Like"].contains(id)
                                                ? Colors.red
                                                : Colors.grey.shade600,
                                            size: 24.0,
                                          ),
                                          const SizedBox(width: 6.0),
                                          Text(
                                            "Like",
                                            style: TextStyle(
                                                color: ds["Like"].contains(id)
                                                    ? Colors.red
                                                    : Colors.grey.shade700,
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 25.0),

                                    // Comment button
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    CommentPage(
                                                        userimage: image!,
                                                        username: name!,
                                                        postid: ds.id)));
                                      },
                                      child: Row(
                                        children: [
                                          Icon(Icons.chat_bubble_outline,
                                              color: Colors.grey.shade600,
                                              size: 22.0),
                                          const SizedBox(width: 6.0),
                                          Text(
                                            "Comment",
                                            style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const Spacer(),

                                    // Share button
                                    GestureDetector(
                                      onTap: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                Icon(Icons.info,
                                                    color: Colors.white),
                                                SizedBox(width: 10),
                                                Text(
                                                    "Share feature coming soon!"),
                                              ],
                                            ),
                                            backgroundColor: Colors.blue,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                          ),
                                        );
                                      },
                                      child: Icon(Icons.share_outlined,
                                          color: Colors.grey.shade600,
                                          size: 22.0),
                                    ),
                                  ],
                                ),
                              ),

                              // Caption
                              if (ds["Caption"] != null &&
                                  ds["Caption"].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 15.0, right: 15.0, top: 10.0),
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: ds["Name"] ?? "Unknown User",
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        TextSpan(
                                          text: " ${ds["Caption"]}",
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 15.0),
                            ],
                          ),
                        ),
                      ),
                    );
                  })
              : Center(
                  child: Container(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_outlined,
                            size: 60, color: Colors.grey.shade400),
                        SizedBox(height: 16),
                        Text(
                          "No posts yet",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Be the first to share your travel experience!",
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
        });
  }

  // Build notification badge
  Widget _buildNotificationBadge({required Widget child, required int count}) {
    if (count == 0) return child;

    return Stack(
      children: [
        child,
        Positioned(
          right: 0,
          top: 0,
          child: AnimatedBuilder(
            animation: _notificationAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _notificationAnimation.value,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Build new content indicator
  Widget _buildNewContentIndicator(
      {required Widget child, required bool hasNew}) {
    if (!hasNew) return child;

    return Stack(
      children: [
        child,
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            await getontheload();
            await _loadNotificationCounts();
          },
          color: Colors.blue,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ImageCarousel(),
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 40.0, right: 20.0, left: 20.0),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const TopPlaces()));
                              },
                              child: Material(
                                elevation: 3.0,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Image.asset("images/pin.jpeg",
                                      height: 40, width: 40, fit: BoxFit.cover),
                                ),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const AddPage())).then((value) {
                                  // Show success message when returning from AddPage
                                  if (value == true) {
                                    _showPostSuccessMessage();
                                  }
                                  getontheload();
                                  _loadNotificationCounts();
                                });
                              },
                              child: Material(
                                elevation: 3.0,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.add,
                                      color: Colors.blue, size: 30.0),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            GestureDetector(
                              onTap: () {
                                showMenu(
                                  context: context,
                                  position: const RelativeRect.fromLTRB(
                                      100, 80, 10, 0),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15)),
                                  items: [
                                    PopupMenuItem(
                                      child: ListTile(
                                        leading: const Icon(Icons.person,
                                            color: Colors.blue),
                                        title: const Text("Profile"),
                                        subtitle: Text(name ?? "User"),
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const ProfilePage()));
                                        },
                                      ),
                                    ),
                                    PopupMenuItem(
                                      child: ListTile(
                                        leading: Stack(
                                          children: [
                                            Icon(Icons.notifications,
                                                color: Colors.orange),
                                            if (notificationCount > 0)
                                              Positioned(
                                                right: 0,
                                                top: 0,
                                                child: Container(
                                                  padding: EdgeInsets.all(2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  constraints: BoxConstraints(
                                                      minWidth: 12,
                                                      minHeight: 12),
                                                  child: Text(
                                                    notificationCount
                                                        .toString(),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        title: const Text("Notifications"),
                                        subtitle:
                                            Text("$notificationCount new"),
                                        onTap: () {
                                          Navigator.pop(context);
                                          // Navigate to notifications page
                                          setState(() {
                                            notificationCount = 0;
                                          });
                                        },
                                      ),
                                    ),
                                    PopupMenuItem(
                                      child: ListTile(
                                        leading: const Icon(Icons.settings,
                                            color: Colors.grey),
                                        title: const Text("Settings"),
                                        onTap: () {
                                          Navigator.pop(context);
                                          // Navigate to settings
                                        },
                                      ),
                                    ),
                                    PopupMenuItem(
                                      child: ListTile(
                                        leading: const Icon(Icons.logout,
                                            color: Colors.red),
                                        title: const Text("Log Out"),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _performLogout();
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                              child: Material(
                                elevation: 3.0,
                                borderRadius: BorderRadius.circular(60),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: image != null && image!.isNotEmpty
                                      ? Image.network(
                                          image!,
                                          height: 50,
                                          width: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Image.asset(
                                                "images/boy.jpeg",
                                                height: 50,
                                                width: 50,
                                                fit: BoxFit.cover);
                                          },
                                        )
                                      : Image.asset("images/boy.jpeg",
                                          height: 50,
                                          width: 50,
                                          fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 160.0, left: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "SKYBOUND",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Lato',
                                  fontSize: 50.0,
                                  fontWeight: FontWeight.w500),
                            ),
                            Text(
                              "Travel Community App",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20.0,
                                fontWeight: FontWeight.w500,
                                shadows: [
                                  Shadow(
                                    blurRadius: 5.0,
                                    color: Colors.black.withOpacity(0.6),
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(
                            left: 20.0,
                            right: 20.0,
                            top: MediaQuery.of(context).size.height / 2.7),
                        child: Material(
                          elevation: 8.0,
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 5.0),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15)),
                            child: TextField(
                              controller: searchcontroller,
                              onChanged: (value) {
                                initiateSearch(value.toUpperCase());
                              },
                              onSubmitted: (value) {
                                if (value.isNotEmpty) {
                                  _navigateToTopPlacesWithSearch(value);
                                }
                              },
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText:
                                    "Search destinations, places, users...",
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade500),
                                prefixIcon: Icon(Icons.search,
                                    color: Colors.grey.shade600),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (searchcontroller.text.isNotEmpty)
                                      IconButton(
                                        icon: Icon(Icons.clear,
                                            color: Colors.grey),
                                        onPressed: () {
                                          searchcontroller.clear();
                                          setState(() {
                                            search = false;
                                            queryResultSet.clear();
                                            tempSearchStore.clear();
                                          });
                                        },
                                      ),
                                    IconButton(
                                      icon:
                                          Icon(Icons.tune, color: Colors.blue),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const TopPlaces(),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  search
                      ? Column(
                          children: [
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Search Results (${tempSearchStore.length})",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  if (searchcontroller.text.isNotEmpty)
                                    TextButton.icon(
                                      onPressed: () {
                                        _navigateToTopPlacesWithSearch(
                                            searchcontroller.text);
                                      },
                                      icon: Icon(Icons.arrow_forward, size: 16),
                                      label: Text("View All"),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.blue,
                                        textStyle: TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            tempSearchStore.isEmpty
                                ? Container(
                                    padding: EdgeInsets.all(40),
                                    child: Column(
                                      children: [
                                        Icon(Icons.search_off,
                                            size: 60,
                                            color: Colors.grey.shade400),
                                        SizedBox(height: 16),
                                        Text(
                                          "No results found",
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Try searching for different keywords",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10.0),
                                    primary: false,
                                    shrinkWrap: true,
                                    children: tempSearchStore.map((element) {
                                      return buildResultCard(element);
                                    }).toList(),
                                  ),
                          ],
                        )
                      : Container(child: allPosts()),
                ],
              ),
            ),
          ),
        ),

        // Enhanced bottom navigation with notification badges
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.green.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade400,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.grey.shade300,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
            items: [
              BottomNavigationBarItem(
                icon: _buildNewContentIndicator(
                  child: Icon(Icons.home),
                  hasNew: hasNewPosts,
                ),
                activeIcon: _buildNewContentIndicator(
                  child: Icon(Icons.home, size: 28),
                  hasNew: hasNewPosts,
                ),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.location_city_outlined),
                activeIcon: Icon(Icons.location_city, size: 28),
                label: 'Places',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline),
                activeIcon: Icon(Icons.add_circle, size: 28),
                label: 'Post',
              ),
              BottomNavigationBarItem(
                icon: _buildNotificationBadge(
                  child: Icon(Icons.chat_bubble_outline),
                  count: messageCount,
                ),
                activeIcon: _buildNotificationBadge(
                  child: Icon(Icons.chat_bubble, size: 28),
                  count: messageCount,
                ),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: _buildNotificationBadge(
                  child: Icon(Icons.person_outline),
                  count: notificationCount,
                ),
                activeIcon: _buildNotificationBadge(
                  child: Icon(Icons.person, size: 28),
                  count: notificationCount,
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildResultCard(data) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    PostPlace(place: data["Name"].toLowerCase())));
      },
      child: Container(
        margin: const EdgeInsets.only(left: 15.0, right: 15.0, bottom: 15.0),
        child: Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(15.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    data["Image"],
                    height: 70,
                    width: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 15.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data["Name"],
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.blue),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "Tap to explore this destination",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(25)),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.blue,
                    size: 16.0,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
