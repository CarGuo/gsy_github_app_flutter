import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/common/style/GSYStyle.dart';

class EventItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Container(
      child: new Card(
          elevation: 5.0,
          shape: new RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(4.0))),
          color: Color(GSYColors.cardWhite),
          margin: new EdgeInsets.only(
              left: 10.0, top: 10.0, right: 10.0, bottom: 10.0),
          child: new FlatButton(
              onPressed: () => {},
              child: new Padding(
                padding: new EdgeInsets.only(
                    left: 10.0, top: 10.0, right: 10.0, bottom: 10.0),
                child: new Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    new Row(
                      children: <Widget>[
                        new Image(
                            image: new AssetImage('static/images/logo.png'),
                            width: 30.0,
                            height: 30.0),
                        new Padding(padding: EdgeInsets.all(10.0)),
                        new Expanded(child: new Text("ffffffffffffff")),
                        new Text("ffffffffffffff"),
                      ],
                    ),
                    new Container(
                        child: new Text(
                            "Ffffffffff",
                            style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, height: 1.3, color: Colors.lightBlue)
                        ),
                        margin: new EdgeInsets.only(top: 6.0, bottom: 2.0),
                        alignment: Alignment.topLeft
                    ),
                    new Container(
                        child: new Text(
                            "Fffffffffffe",
                            style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, height: 1.3, color: Colors.black)
                        ),
                        margin: new EdgeInsets.only(top: 6.0, bottom: 2.0),
                        alignment: Alignment.topLeft
                    )
                  ],
                ),
              ))),
    );
  }
}
