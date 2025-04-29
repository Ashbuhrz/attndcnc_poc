import 'package:flutter/material.dart';
import 'package:poclocationupdate/helloworld.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:background_fetch/background_fetch.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

Future<dynamic> appPost(url, body) async {
  try {
    var url2 = Uri.parse("http://172.20.10.3:3001/api/test");
    // var url2 = Uri.parse("https://d530-83-110-72-198.ngrok-free.app/api/test");
    print("URL: ${url2}");
    final msg = jsonEncode(body);
    final response = await http.post(
      url2,
      headers: {'Content-Type': 'application/json'},
      body: msg,
    );
    return response;
  } catch (e) {
    print('Failed to fetch data: $e');
    return e;
  }
}

/// Receive events from BackgroundGeolocation in Headless state.
@pragma('vm:entry-point')
void backgroundGeolocationHeadlessTask(bg.HeadlessEvent headlessEvent) async {
  print('📬 --> $headlessEvent');

  switch (headlessEvent.name) {
    case bg.Event.BOOT:
      bg.State state = await bg.BackgroundGeolocation.state;
      print("📬 didDeviceReboot: ${state.didDeviceReboot}");
      break;
    case bg.Event.TERMINATE:
      bg.State state = await bg.BackgroundGeolocation.state;
      if (state.stopOnTerminate!) {
        // Don't request getCurrentPosition when stopOnTerminate: true
        return;
      }
      try {
        bg.Location location = await bg
            .BackgroundGeolocation.getCurrentPosition(
          samples: 1,
          persist: true,
          extras: {"event": "terminate", "headless": true},
        );
        print("[getCurrentPosition] Headless: $location");
      } catch (error) {
        print("[getCurrentPosition] Headless ERROR: $error");
      }

      break;
    case bg.Event.HEARTBEAT:
      try {
        bg.Location location = await bg
            .BackgroundGeolocation.getCurrentPosition(
          samples: 2,
          timeout: 10,
          extras: {"event": "heartbeat", "headless": true},
        );

        print('[getCurrentPosition] Headless: $location');
        String sssss =
            "lat : ${location.coords.latitude} | lng : ${location.coords.longitude} ";
        print("SSSSSS: $sssss");
        await appPost("url", {"location": sssss});
      } catch (error) {
        print('[getCurrentPosition] Headless ERROR: $error');
      }
      break;
    case bg.Event.LOCATION:
      bg.Location location = headlessEvent.event;
      print(location);
      break;
    case bg.Event.MOTIONCHANGE:
      bg.Location location = headlessEvent.event;
      print(location);
      break;
    case bg.Event.GEOFENCE:
      bg.GeofenceEvent geofenceEvent = headlessEvent.event;
      print(geofenceEvent);
      break;
    case bg.Event.GEOFENCESCHANGE:
      bg.GeofencesChangeEvent event = headlessEvent.event;
      print(event);
      break;
    case bg.Event.SCHEDULE:
      bg.State state = headlessEvent.event;
      print(state);
      break;
    case bg.Event.ACTIVITYCHANGE:
      bg.ActivityChangeEvent event = headlessEvent.event;
      print(event);
      break;
    case bg.Event.HTTP:
      bg.HttpEvent response = headlessEvent.event;
      print(response);
      break;
    case bg.Event.POWERSAVECHANGE:
      bool enabled = headlessEvent.event;
      print(enabled);
      break;
    case bg.Event.CONNECTIVITYCHANGE:
      bg.ConnectivityChangeEvent event = headlessEvent.event;
      print(event);
      break;
    case bg.Event.ENABLEDCHANGE:
      bool enabled = headlessEvent.event;
      print(enabled);
      break;
    case bg.Event.AUTHORIZATION:
      bg.AuthorizationEvent event = headlessEvent.event;
      print(event);
      bg.BackgroundGeolocation.setConfig(
        bg.Config(url: "http://localhost:3001/api/test"),
      );
      break;
  }
}

/// Receive events from BackgroundFetch in Headless state.
@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;

  // Is this a background_fetch timeout event?  If so, simply #finish and bail-out.
  if (task.timeout) {
    print("[BackgroundFetch] HeadlessTask TIMEOUT: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }

  print("[BackgroundFetch] HeadlessTask: $taskId");

  try {
    var location = await bg.BackgroundGeolocation.getCurrentPosition(
      samples: 2,
      extras: {"event": "background-fetch", "headless": true},
    );
    print("[location] $location");
    String sssss =
        "lat : ${location.coords.latitude} | lng : ${location.coords.longitude} ";
    print("SSSSSS: $sssss");
    await appPost("url", {"location": sssss, "from": "here1"});
  } catch (error) {
    print("[location] ERROR: $error");
  }

  SharedPreferences prefs = await SharedPreferences.getInstance();
  int count = 0;
  if (prefs.get("fetch-count") != null) {
    count = prefs.getInt("fetch-count")!;
  }
  prefs.setInt("fetch-count", ++count);
  print('[BackgroundFetch] count: $count');

  BackgroundFetch.finish(taskId);
}

void main() {
  // HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();

  /// Application selection:  Select the app to boot:
  /// - AdvancedApp
  /// - HelloWorldAp
  /// - HomeApp
  ///
  SharedPreferences.getInstance().then((SharedPreferences prefs) {
    String? appName = prefs.getString("app");

    // Sanitize old-style registration system that only required username.
    // If we find a valid username but null orgname, reverse them.
    String? orgname = prefs.getString("orgname");
    String? username = prefs.getString("username");

    if (orgname == null && username != null) {
      prefs.setString("orgname", username);
      prefs.remove("username");
    }

    runApp(new HelloWorldApp());
  });

  /// Register BackgroundGeolocation headless-task.
  bg.BackgroundGeolocation.registerHeadlessTask(
    backgroundGeolocationHeadlessTask,
  );

  /// Register BackgroundFetch headless-task.
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

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
