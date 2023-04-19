import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late IO.Socket socket;
  Location location = Location();
  bool _serviceEnabled = false;
  late PermissionStatus _permissionGranted;
  late LocationData _locationData;

  Future<void> getLocationPermission() async {
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    } else if (_permissionGranted == PermissionStatus.deniedForever) {
      _permissionGranted = await location.requestPermission();
    }
  }

  Future<void> getLocation() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }
    if (_serviceEnabled) {
      await getLocationPermission();
      _locationData = await location.getLocation();

      socket.emit('location', {
        'longitude': _locationData.longitude,
        'latitude': _locationData.latitude
      });
    }
  }

  @override
  void initState() {
    connectSocketIO();
    getLocation().whenComplete(() => listenToCurrentLocation());
    super.initState();
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  listenToCurrentLocation() {
    location.onLocationChanged.listen((LocationData currentLocation) {
      socket.emit('location', {
        'longitude': currentLocation.longitude,
        'latitude': currentLocation.latitude
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Text("MPA"),
          ),
        ),
      ),
    );
  }

  void connectSocketIO() {
    try {
      // socket = IO.io('https://location-service-mpa.herokuapp.com',
      //     IO.OptionBuilder().setTransports(['websocket']).build());
      socket = IO.io('http://192.168.18.127:5050',
          IO.OptionBuilder().setTransports(['websocket']).build());
      socket.onConnect((_) {
        print('SOCKET connected');
      });
      socket.onDisconnect((_) {
        print('SOCKET: ${socket.id}');
      });
      socket.onDisconnect((_) => print('disconnect'));
    } catch (ex) {
      print(ex);
    }
  }
}
