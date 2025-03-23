import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:traveltest_app/services/database.dart';

class CommentPage extends StatefulWidget {
  String username, userimage, postid;
  CommentPage(
      {required this.userimage, required this.username, required this.postid});

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  TextEditingController commentcontroller = new TextEditingController();
  Stream? commentStream;

  getontheload() async {
    commentStream = await DatabaseMethods().getComments(widget.postid);
    setState(() {});
  }

  @override
  void initState() {
    getontheload();
    super.initState();
  }

  Widget allComments() {
    return StreamBuilder(
        stream: commentStream,
        builder: (context, AsyncSnapshot snapshot) {
          return snapshot.hasData
              ? ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: snapshot.data.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot ds = snapshot.data.docs[index];

                    return Container(
                      margin: EdgeInsets.only(bottom: 20.0),
                      child: Material(
                        elevation: 3.0,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: Image.network(
                                  ds["UserImage"],
                                  height: 70,
                                  width: 70,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(
                                width: 20.0,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ds["UserName"],
                                    style: TextStyle(
                                        color:
                                            const Color.fromARGB(169, 0, 0, 0),
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width / 1.5,
                                    child: Text(
                                      ds["Comment"],
                                      style: TextStyle(
                                          color: Color.fromARGB(230, 0, 0, 0),
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  })
              : Container();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0, top: 40.0),
              child: SingleChildScrollView(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Material(
                        elevation: 3.0,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(30)),
                            child: Icon(
                              Icons.arrow_back_ios_new_outlined,
                              color: Colors.white,
                            )),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 7,
                    ),
                    Text(
                      "Add Comment",
                      style: TextStyle(
                          color: Colors.blue,
                          fontSize: 26.0,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 30.0,
            ),
            Expanded(
                child: Material(
                    elevation: 3.0,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30)),
                    child: Container(
                        padding:
                            EdgeInsets.only(left: 20.0, right: 10.0, top: 30.0),
                        decoration: BoxDecoration(
                            color: Color.fromARGB(186, 250, 247, 247),
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30))),
                        width: MediaQuery.of(context).size.width,
                        child: Column(
                          children: [
                            Container(
                                height:
                                    MediaQuery.of(context).size.height / 1.4,
                                child: allComments()),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.only(left: 20.0),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                            color: Colors.black45, width: 2.0),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: TextField(
                                      controller: commentcontroller,
                                      decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: "Write a Comment..."),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 10.0,
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    Map<String, dynamic> addComment = {
                                      "UserImage": widget.userimage,
                                      "UserName": widget.username,
                                      "Comment": commentcontroller.text
                                    };
                                    await DatabaseMethods()
                                        .addComment(addComment, widget.postid);
                                    commentcontroller.text = "";
                                    setState(() {});
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Icon(
                                      Icons.send,
                                      color: Colors.white,
                                      size: 30.0,
                                    ),
                                  ),
                                )
                              ],
                            )
                          ],
                        ))))
          ],
        ),
      ),
    );
  }
}
