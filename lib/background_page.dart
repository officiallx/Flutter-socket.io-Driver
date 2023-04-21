import 'dart:isolate';
import 'dart:ui';

import 'package:background_locator_2/background_locator.dart';
import 'package:background_locator_2/location_dto.dart';
import 'package:background_locator_2/settings/android_settings.dart';
import 'package:background_locator_2/settings/ios_settings.dart';
import 'package:background_locator_2/settings/locator_settings.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'file_manager.dart';
import 'location_callback_handler.dart';
import 'location_service_repository.dart';

class BackgroundPage extends StatefulWidget {
  const BackgroundPage({super.key});

  @override
  State<BackgroundPage> createState() => _BackgroundPageState();
}

class _BackgroundPageState extends State<BackgroundPage> {
  ReceivePort port = ReceivePort();

  String logStr = '';
  bool isRunning = false;
  late LocationDto? lastLocation;

  @override
  void initState() {
    super.initState();

    if (IsolateNameServer.lookupPortByName(
            LocationServiceRepository.isolateName) !=
        null) {
      IsolateNameServer.removePortNameMapping(
          LocationServiceRepository.isolateName);
    }

    IsolateNameServer.registerPortWithName(
        port.sendPort, LocationServiceRepository.isolateName);

    port.listen(
      (dynamic data) async {
        if (data != null) {
          await updateUI(data);
        }
      },
    );
    initPlatformState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> updateUI(dynamic data) async {
    final log = await FileManager.readLogFile();

    LocationDto? locationDto =
        (data != null) ? LocationDto.fromJson(data) : null;
    await _updateNotificationText(locationDto!);

    setState(() {
      if (data != null) {
        lastLocation = locationDto;
      }
      logStr = log;
    });
  }

  Future<void> _updateNotificationText(LocationDto? data) async {
    if (data == null) {
      return;
    }
    // await BackgroundLocator.updateNotificationText(
    //   title: "Your Location is being tracked",
    //   msg: "${data.latitude}, ${data.longitude}",
    // );
  }

  Future<void> initPlatformState() async {
    await BackgroundLocator.initialize();
    logStr = await FileManager.readLogFile();
    isRunning = await BackgroundLocator.isServiceRunning();
    setState(() {
      isRunning = isRunning;
    });
  }

  @override
  Widget build(BuildContext context) {
    String msgStatus = "-";
    if (isRunning) {
      msgStatus = 'Is running';
    } else {
      msgStatus = 'Is not running';
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('MDA'),
          centerTitle: true,
        ),
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Status: $msgStatus"),
              const SizedBox(
                height: 24,
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.greenAccent),
                  fixedSize:
                      MaterialStateProperty.all<Size>(const Size(330, 30)),
                ),
                child: const Text(
                  "Start",
                  style: TextStyle(letterSpacing: 1.3, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                onPressed: () async {
                  _onStart();
                },
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.redAccent),
                  fixedSize:
                      MaterialStateProperty.all<Size>(const Size(330, 30)),
                ),
                child: const Text(
                  "Stop",
                  style: TextStyle(letterSpacing: 1.3, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                onPressed: () async {
                  onStop();
                },
              ),
              // SizedBox(
              //   width: double.maxFinite,
              //   child: ElevatedButton(
              //     child: const Text('Clear Log'),
              //     onPressed: () {
              //       FileManager.clearLogFile();
              //       setState(() {
              //         logStr = '';
              //       });
              //     },
              //   ),
              // ),
              // Text(
              //   logStr,
              // ),
            ],
          ),
        ),
      ),
    );
  }

  void onStop() async {
    await BackgroundLocator.unRegisterLocationUpdate();
    isRunning = await BackgroundLocator.isServiceRunning();
    setState(() {
      isRunning = isRunning;
    });
  }

  void _onStart() async {
    if (await _checkLocationPermission()) {
      await _startLocator();
      isRunning = await BackgroundLocator.isServiceRunning();
      setState(() {
        isRunning = isRunning;
        lastLocation = null;
      });
    } else {
      // show error
    }
  }

  Future<bool> _checkLocationPermission() async {
    final access = await Permission.location.status;
    switch (access) {
      case PermissionStatus.denied:
      case PermissionStatus.limited:
      case PermissionStatus.restricted:
        final permission = await Permission.location.request();
        if (permission == PermissionStatus.granted) {
          return true;
        } else {
          return false;
        }
      case PermissionStatus.granted:
        return true;
      default:
        return false;
    }
  }

  Future<void> _startLocator() async {
    Map<String, dynamic> data = {'countInit': 1};
    return await BackgroundLocator.registerLocationUpdate(
      LocationCallbackHandler.callback,
      initCallback: LocationCallbackHandler.initCallback,
      initDataCallback: data,
      disposeCallback: LocationCallbackHandler.disposeCallback,
      iosSettings: const IOSSettings(
          accuracy: LocationAccuracy.NAVIGATION,
          distanceFilter: 0,
          stopWithTerminate: true),
      autoStop: false,
      androidSettings: const AndroidSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        interval: 2,
        distanceFilter: 0,
        client: LocationClient.google,
        androidNotificationSettings: AndroidNotificationSettings(
            notificationChannelName: 'Location tracking',
            notificationTitle: 'Start Location Tracking',
            notificationMsg: 'Track location in background',
            notificationBigMsg:
                'Background location is on to keep the app up-tp-date with your location. This is required for main features to work properly when the app is not running.',
            notificationIconColor: Colors.indigo,
            notificationTapCallback:
                LocationCallbackHandler.notificationCallback),
      ),
    );
  }
}
