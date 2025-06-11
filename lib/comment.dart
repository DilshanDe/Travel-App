import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:traveltest_app/services/database.dart';
import 'package:traveltest_app/services/shared_pref.dart';

class CommentPage extends StatefulWidget {
  String username, userimage, postid;
  CommentPage({
    required this.userimage,
    required this.username,
    required this.postid,
  });

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage>
    with TickerProviderStateMixin {
  TextEditingController commentcontroller = TextEditingController();
  FocusNode _focusNode = FocusNode();
  Stream? commentStream;
  String? currentUserId;
  bool isLoading = false;
  bool isRefreshing = false;
  int commentCount = 0;

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    getontheload();
  }

  @override
  void dispose() {
    _animationController.dispose();
    commentcontroller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  getontheload() async {
    setState(() {
      isLoading = true;
    });

    commentStream = await DatabaseMethods().getComments(widget.postid);
    currentUserId = await SharedpreferenceHelper().getUserId();
    commentCount = await DatabaseMethods().getCommentCount(widget.postid);

    setState(() {
      isLoading = false;
    });

    _animationController.forward();
  }

  // Pull to refresh functionality
  Future<void> _refreshComments() async {
    setState(() {
      isRefreshing = true;
    });

    await getontheload();

    setState(() {
      isRefreshing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.refresh, color: Colors.white),
            SizedBox(width: 10),
            Text("Comments refreshed!"),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    DateTime commentTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    DateTime now = DateTime.now();
    Duration difference = now.difference(commentTime);

    if (difference.inDays > 7) {
      return "${(difference.inDays / 7).floor()}w ago";
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _deleteComment(String commentId) async {
    try {
      await DatabaseMethods().deleteComment(widget.postid, commentId);
      commentCount = await DatabaseMethods().getCommentCount(widget.postid);
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text("Comment deleted successfully"),
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
              Text("Error deleting comment: $e"),
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

  void _showDeleteConfirmation(String commentId) {
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
              Text("Delete Comment"),
            ],
          ),
          content: Text(
            "Are you sure you want to delete this comment? This action cannot be undone.",
            style: TextStyle(fontSize: 16),
          ),
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
                _deleteComment(commentId);
              },
            ),
          ],
        );
      },
    );
  }

  Widget allComments() {
    return StreamBuilder(
        stream: commentStream,
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blue),
                  SizedBox(height: 16),
                  Text("Loading comments...",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return snapshot.hasData && snapshot.data.docs.length > 0
              ? RefreshIndicator(
                  onRefresh: _refreshComments,
                  color: Colors.blue,
                  child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      shrinkWrap: true,
                      itemCount: snapshot.data.docs.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot ds = snapshot.data.docs[index];

                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              index * 0.1,
                              (index + 1) * 0.1,
                              curve: Curves.easeOutCubic,
                            ),
                          )),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 15.0),
                            child: Material(
                              elevation: 2.0,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.grey.shade200)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // User info header
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                          child: ds["UserImage"] != null &&
                                                  ds["UserImage"]
                                                      .toString()
                                                      .isNotEmpty
                                              ? Image.network(
                                                  ds["UserImage"],
                                                  height: 50,
                                                  width: 50,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Container(
                                                      height: 50,
                                                      width: 50,
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                          colors: [
                                                            Colors
                                                                .blue.shade400,
                                                            Colors
                                                                .purple.shade400
                                                          ],
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(25),
                                                      ),
                                                      child: Icon(Icons.person,
                                                          color: Colors.white,
                                                          size: 30),
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
                                                        BorderRadius.circular(
                                                            25),
                                                  ),
                                                  child: Icon(Icons.person,
                                                      color: Colors.white,
                                                      size: 30),
                                                ),
                                        ),
                                        SizedBox(width: 12.0),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                ds["UserName"] ??
                                                    "Unknown User",
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 16.0,
                                                    fontWeight:
                                                        FontWeight.w700),
                                              ),
                                              if (ds["Timestamp"] != null)
                                                Text(
                                                  _formatTimestamp(
                                                      ds["Timestamp"]),
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 12.0,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        // Show delete option only for comment owner
                                        if (ds["UserId"] == currentUserId)
                                          PopupMenuButton(
                                            icon: Icon(Icons.more_vert,
                                                color: Colors.grey, size: 20),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15)),
                                            itemBuilder: (context) => [
                                              PopupMenuItem(
                                                child: ListTile(
                                                  leading: Icon(Icons.edit,
                                                      color: Colors.blue,
                                                      size: 20),
                                                  title: Text("Edit",
                                                      style: TextStyle(
                                                          fontSize: 14)),
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                  onTap: () {
                                                    Navigator.pop(context);
                                                    // Add edit functionality here
                                                  },
                                                ),
                                              ),
                                              PopupMenuItem(
                                                child: ListTile(
                                                  leading: Icon(Icons.delete,
                                                      color: Colors.red,
                                                      size: 20),
                                                  title: Text("Delete",
                                                      style: TextStyle(
                                                          fontSize: 14)),
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                  onTap: () {
                                                    Navigator.pop(context);
                                                    _showDeleteConfirmation(
                                                        ds.id);
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 12.0),
                                    // Comment text with beautiful typography
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                            color: Colors.grey.shade200),
                                      ),
                                      child: Text(
                                        ds["Comment"] ?? "",
                                        style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.w400,
                                            height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                )
              : RefreshIndicator(
                  onRefresh: _refreshComments,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.chat_bubble_outline,
                                  size: 60, color: Colors.blue.shade300),
                            ),
                            SizedBox(height: 24),
                            Text(
                              "No comments yet",
                              style: TextStyle(
                                fontSize: 22,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              "Be the first to share your thoughts!",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                _focusNode.requestFocus();
                              },
                              icon: Icon(Icons.edit, size: 18),
                              label: Text("Write a comment"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
        });
  }

  void _addComment() async {
    if (commentcontroller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 10),
              Text("Please write a comment"),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      Map<String, dynamic> addComment = {
        "UserImage": widget.userimage,
        "UserName": widget.username,
        "Comment": commentcontroller.text.trim(),
        "UserId": currentUserId,
        "Timestamp": DateTime.now().millisecondsSinceEpoch,
      };

      await DatabaseMethods().addComment(addComment, widget.postid);
      commentcontroller.clear();
      commentCount = await DatabaseMethods().getCommentCount(widget.postid);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text("Comment added successfully!"),
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
              Text("Error adding comment: $e"),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: isLoading && commentStream == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blue),
                  SizedBox(height: 20),
                  Text("Loading comments...",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                // Enhanced Header
                Container(
                  padding: EdgeInsets.only(
                      left: 20.0, right: 20.0, top: 45.0, bottom: 20.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade200,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                "Comments",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold),
                              ),
                              if (commentCount > 0)
                                Text(
                                  "$commentCount ${commentCount == 1 ? 'comment' : 'comments'}",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14.0,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 42), // Balance the back button
                    ],
                  ),
                ),

                // Comments list
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: allComments(),
                  ),
                ),

                // Enhanced Comment input section
                Container(
                  padding: EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // User profile picture
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: widget.userimage.isNotEmpty
                            ? Image.network(
                                widget.userimage,
                                height: 44,
                                width: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 44,
                                    width: 44,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.shade400,
                                          Colors.purple.shade400
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: Icon(Icons.person,
                                        color: Colors.white, size: 24),
                                  );
                                },
                              )
                            : Container(
                                height: 44,
                                width: 44,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade400,
                                      Colors.purple.shade400
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Icon(Icons.person,
                                    color: Colors.white, size: 24),
                              ),
                      ),
                      SizedBox(width: 15.0),

                      // Comment input field
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 18.0, vertical: 8.0),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.grey.shade300)),
                          child: TextField(
                            controller: commentcontroller,
                            focusNode: _focusNode,
                            maxLines: null,
                            style: TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Write a comment...",
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade600)),
                            onSubmitted: (value) {
                              if (!isLoading) {
                                _addComment();
                              }
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 12.0),

                      // Send button
                      GestureDetector(
                        onTap: isLoading ? null : _addComment,
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isLoading
                                    ? [
                                        Colors.grey.shade400,
                                        Colors.grey.shade500
                                      ]
                                    : [
                                        Colors.blue.shade600,
                                        Colors.blue.shade400
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: isLoading
                                      ? Colors.grey.shade300
                                      : Colors.blue.shade200,
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ]),
                          child: isLoading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 22.0,
                                ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
