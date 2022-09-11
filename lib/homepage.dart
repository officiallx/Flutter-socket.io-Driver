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

  Future getLocation() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();

    socket.emit('location', {
      'longitude': _locationData.longitude,
      'latitude': _locationData.latitude
    });
  }

  @override
  void initState() {
    connectSocketIO();
    getLocation();
    location.onLocationChanged.listen((LocationData currentLocation) {
      socket.emit('location', {
        'longitude': currentLocation.longitude,
        'latitude': currentLocation.latitude
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text("Hello"),
            ],
          ),
        ),
      ),
    );
  }

  void connectSocketIO() {
    try {
      socket = IO.io('http://172.25.6.21:5000',
          IO.OptionBuilder().setTransports(['websocket']).build());
      socket.onConnect((_) {
        print('SOCKET connected');
        socket.emit('chat message', 'SOCKET connected');
      });
      socket.onDisconnect((_) {
        print('SOCKET: ${socket.id}');
        socket.emit('chat message', 'SOCKET disconnected');
      });
      socket.onDisconnect((_) => print('disconnect'));
      //socket.on('chat message', (data) => print(data));
      //socket.on('location', (data) => print(data));
    } catch (ex) {
      print(ex);
    }
  }
}
