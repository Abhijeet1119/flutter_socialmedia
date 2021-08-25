//import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:flutter/material.dart';
//import '../functions/image_post.dart';
//import 'dart:async';
//import '../main.dart';
//import 'dart:io';
//import 'dart:convert';
//import 'package:shared_preferences/shared_preferences.dart';
//
//class Feed extends StatefulWidget {
//  _Feed createState() => _Feed();
//}
//
//class _Feed extends State<Feed> with AutomaticKeepAliveClientMixin<Feed> {
//  List<ImagePost> feedData;
//
//  @override
//  void initState() {
//    super.initState();
//    this._loadFeed();
//  }
//
//  buildFeed() {
//    if (feedData != null) {
//      return ListView(
//        children: feedData,
//      );
//    } else {
//      return Container(
//          alignment: FractionalOffset.center,
//          child: CircularProgressIndicator());
//    }
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    super.build(context); // reloads state when opened again
//
//    return Scaffold(
//      appBar: AppBar(
//        title: const Text('Fluttergram',
//            style: const TextStyle(
//                fontFamily: "Billabong", color: Colors.black, fontSize: 35.0)),
//        centerTitle: true,
//        backgroundColor: Colors.white,
//      ),
//      body: RefreshIndicator(
//        onRefresh: _refresh,
//        child: buildFeed(),
//      ),
//    );
//  }
//
//  Future<Null> _refresh() async {
//    await _getFeed();
//
//    setState(() {});
//
//    return;
//  }
//
//  _loadFeed() async {
//    SharedPreferences prefs = await SharedPreferences.getInstance();
//    String json = prefs.getString("feed");
//
//    if (json != null) {
//      List<Map<String, dynamic>> data =
//      jsonDecode(json).cast<Map<String, dynamic>>();
//      List<ImagePost> listOfPosts = _generateFeed(data);
//      setState(() {
//        feedData = listOfPosts;
//      });
//    } else {
//      _getFeed();
//    }
//  }
//
//  _getFeed() async {
//    print("Staring getFeed");
//
//    SharedPreferences prefs = await SharedPreferences.getInstance();
//
//    String userId = googleSignIn.currentUser.id.toString();
//    var url =
//        'https://us-central1-mp-rps.cloudfunctions.net/getFeed?uid=' + userId;
//    var httpClient = HttpClient();
//
//    List<ImagePost> listOfPosts;
//    String result;
//    try {
//      var request = await httpClient.getUrl(Uri.parse(url));
//      var response = await request.close();
//      if (response.statusCode == HttpStatus.ok) {
//        String json = await response.transform(utf8.decoder).join();
//        prefs.setString("feed", json);
//        List<Map<String, dynamic>> data =
//        jsonDecode(json).cast<Map<String, dynamic>>();
//        listOfPosts = _generateFeed(data);
//        result = "Success in http request for feed";
//      } else {
//        result =
//        'Error getting a feed: Http status ${response.statusCode} | userId $userId';
//      }
//    } catch (exception) {
//      result = 'Failed invoking the getFeed function. Exception: $exception';
//    }
//    print(result);
//
//    setState(() {
//      feedData = listOfPosts;
//    });
//  }
//
//  List<ImagePost> _generateFeed(List<Map<String, dynamic>> feedData) {
//    List<ImagePost> listOfPosts = [];
//
//    for (var postData in feedData) {
//      listOfPosts.add(ImagePost.fromJSON(postData));
//    }
//
//    return listOfPosts;
//  }
//
//  // ensures state is kept when switching pages
//  @override
//  bool get wantKeepAlive => true;
//}
//
//
//
//
//

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../image_post.dart';
import 'dart:async';
import '../main.dart';

class Feed extends StatefulWidget {
  const Feed({this.userId});

  final String userId;

  _Feed createState() => _Feed(this.userId);
}

class _Feed extends State<Feed> with AutomaticKeepAliveClientMixin<Feed> {
  final String profileId;
  String currentUserId = googleSignIn.currentUser.id;
  int postCount = 0;
  _Feed(this.profileId);
  TextStyle boldStyle = TextStyle(
    color: Colors.black,
    fontWeight: FontWeight.bold,
  );
  String ownerId;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Container buildUserPosts() {
      Future<List<ImagePost>> getPosts() async {
        List<ImagePost> posts = [];
        var snap = await FirebaseFirestore.instance
            .collection('instagram_posts')
            .orderBy('timestamp',descending: false)
            .get();
        for (var doc in snap.docs) {
          posts.add(ImagePost.fromDocument(doc));
        }
        setState(() {
          postCount = snap.docs.length;
        });

        return posts.reversed.toList();
      }
      return Container(
        child: FutureBuilder<List<ImagePost>>(
          future: getPosts(),
          // ignore: missing_return
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return Container(
                  alignment: FractionalOffset.center,
                  padding: const EdgeInsets.only(top: 10.0),
                  child: CircularProgressIndicator());
            else {
              return Column(
                  children: snapshot.data.map(
                (ImagePost imagePost) {
                  return GridTile(child: imagePost);
                },
              ).toList());
            }
          },
        ),
      );
    }



    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('insta_users')
            .doc(profileId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Container(
                alignment: FractionalOffset.center,
                child: CircularProgressIndicator());
          return Scaffold(
            appBar: AppBar(
              title: const Text('Fluttergram',
                  style: const TextStyle(
                      fontFamily: "Billabong",
                      color: Colors.black,
                      fontSize: 35.0)),
              centerTitle: true,
              backgroundColor: Colors.white,
            ),
            body: ListView(
              children: <Widget>[
                buildUserPosts(),
              ],
            ),
          );
        });
  }

  @override
  bool get wantKeepAlive => true;
}

class ImageTile extends StatelessWidget {
  final ImagePost imagePost;

  ImageTile(this.imagePost);

  clickedImage(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<bool>(builder: (BuildContext context) {
      return Center(
        child: Scaffold(
            appBar: AppBar(
              title: Text('Photo',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
            ),
            body: ListView(
              children: <Widget>[
                Container(
                  child: imagePost,
                ),
              ],
            )),
      );
    }));
  }

  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => clickedImage(context),
        child: Image.network(imagePost.mediaUrl, fit: BoxFit.cover));
  }
}

void openProfile(BuildContext context, String userId) {
  Navigator.of(context)
      .push(MaterialPageRoute<bool>(builder: (BuildContext context) {
    return Feed(userId: userId);
  }));
}
