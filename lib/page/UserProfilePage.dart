import 'package:flutter/material.dart';

/**
 * Created by guoshuyu
 * Date: 2018-08-08
 */

class UserProfile extends StatefulWidget {
  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {

  _renderList() {
    return [

    ];
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      color: Colors.white,
      child: new SingleChildScrollView(
        child: new Column(
          children: _renderList(),
        ),
      ),
    );
  }
}
