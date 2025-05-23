import 'dart:async';
import 'package:flutter/material.dart';

import 'package:background_fetch/background_fetch.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<dynamic> appGet(url) async {
  try {
    var url2 = Uri.parse(url);
    final response = await http.get(
      url2,
      headers: {'Content-Type': 'application/json'},
    );
    return response;
  } catch (e) {
    print('Failed to fetch data: $e');
    return e;
  }
}

// [Android-only] This "Headless Task" is run when the Android app is terminated with `enableHeadless: true`
// Be sure to annotate your callback function to avoid issues in release mode on Flutter >= 3.3.0
@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    // This task has exceeded its allowed running-time.
    // You must stop what you're doing and immediately .finish(taskId)
    print("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }
  print('[BackgroundFetch] Headless event received.');
  // Do your work here...
  var testResponse = await appGet('http://172.21.29.215:3001/api/test');
  print("testResponse background fetch");
  print(testResponse);

  if (taskId == 'flutter_background_fetch') {
    BackgroundFetch.scheduleTask(
      TaskConfig(
        taskId: "com.transistorsoft.customtask",
        delay: 5000,
        periodic: false,
        forceAlarmManager: false,
        stopOnTerminate: false,
        enableHeadless: true,
      ),
    );
  }
  BackgroundFetch.finish(taskId);
}

void main() {
  // Enable integration testing with the Flutter Driver extension.
  // See https://flutter.io/testing/ for more info.
  runApp(new MyApp());

  // Register to receive BackgroundFetch events after app is terminated.
  // Requires {stopOnTerminate: false, enableHeadless: true}
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
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
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Configure BackgroundFetch.
    int status = await BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 2,
        stopOnTerminate: false,
        enableHeadless: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiredNetworkType: NetworkType.ANY,
      ),
      (String taskId) async {
        // <-- Event handler
        // This is the fetch-event callback.
        print("[BackgroundFetch] Event received $taskId");
        setState(() {
          _events.insert(0, new DateTime.now());
        });
        // IMPORTANT:  You must signal completion of your task or the OS can punish your app
        // for taking too long in the background.
        BackgroundFetch.finish(taskId);
      },
      (String taskId) async {
        // <-- Task timeout handler.
        // This task has exceeded its allowed running-time.  You must stop what you're doing and immediately .finish(taskId)
        print("[BackgroundFetch] TASK TIMEOUT taskId: $taskId");
        BackgroundFetch.finish(taskId);
      },
    );
    print('[BackgroundFetch] configure success: $status');
    setState(() {
      _status = status;
    });

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  void _onClickEnable(enabled) {
    setState(() {
      _enabled = enabled;
    });
    if (enabled) {
      BackgroundFetch.start()
          .then((int status) {
            print('[BackgroundFetch] start success: $status');
          })
          .catchError((e) {
            print('[BackgroundFetch] start FAILURE: $e');
          });
    } else {
      BackgroundFetch.stop().then((int status) {
        print('[BackgroundFetch] stop success: $status');
      });
    }
  }

  void _onClickStatus() async {
    // var testResponse = await appGet('http://172.21.29.215:3001/api/test');
    // print("testResponse background fetch 7777");
    // print(testResponse);
    int status = await BackgroundFetch.status;
    print('[BackgroundFetch] status: $status');
    setState(() {
      _status = status;
    });
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
