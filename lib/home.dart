import 'package:flutter/material.dart';

class HomeWidget extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<HomeWidget> {
  bool _enabled = true;
  int _status = 0;
  List<DateTime> _events = [];

  @override
  void initState() {
    super.initState();
  }

  void _onClickEnable(enabled) {}

  void _onClickStatus() async {}

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
          actions: <Widget>[Switch(value: _enabled, onChanged: _onClickEnable)],
        ),
        body: Container(
          color: Colors.black,
          child: new ListView.builder(
            itemCount: _events.length,
            itemBuilder: (BuildContext context, int index) {
              DateTime timestamp = _events[index];
              return InputDecorator(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.only(
                    left: 10.0,
                    top: 10.0,
                    bottom: 0.0,
                  ),
                  labelStyle: TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 20.0,
                  ),
                  labelText: "[background fetch event]",
                ),
                child: new Text(
                  timestamp.toString(),
                  style: TextStyle(color: Colors.white, fontSize: 16.0),
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Row(
            children: <Widget>[
              ElevatedButton(onPressed: _onClickStatus, child: Text('Status')),
              Container(
                child: Text("$_status"),
                margin: EdgeInsets.only(left: 20.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
