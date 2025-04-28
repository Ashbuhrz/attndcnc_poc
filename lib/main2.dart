import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _enabled = true;
  int _status = 0;
  List<DateTime> _events = [];
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text(
            'BackgroundFetch Example',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.amberAccent,
        ),
        body: Container(color: Colors.black, child: Text("data")),
        bottomNavigationBar: BottomAppBar(
          child: Row(
            children: <Widget>[
              Container(
                child: Text("NICE APP"),
                margin: EdgeInsets.only(left: 20.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
