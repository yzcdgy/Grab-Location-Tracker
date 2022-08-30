import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'mymap.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final loc.Location location = loc.Location();
  StreamSubscription<loc.LocationData>? _locationSubscription;

  Color noteColor = Colors.red;
  String textHolder = 'Tracking OFF';
  changeTextEnabled() {
    setState(() {
      textHolder = 'Tracking ON ' + dropdownValue;
      noteColor = Colors.green;
    });
  }
  changeTextDisabled() {
    setState(() {
      textHolder = 'Tracking OFF ' + dropdownValue;
      noteColor = Colors.red;
    });
  }
  @override
  void initState() {
    super.initState();
    _requestPermission();
    location.changeSettings(interval: 120000, accuracy: loc.LocationAccuracy.high, distanceFilter: 10);
    location.enableBackgroundMode(enable: true);
  }
  String dropdownValue = "Darwin Mina";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location tracker'),
      ),
      body: Column(
        children: [
          DropdownButton<String>(
          value: dropdownValue,
          hint: Text("Choose name"),
          icon: const Icon(Icons.arrow_downward),
          elevation: 16,
          style: const TextStyle(color: Colors.deepPurple),
          underline: Container(
            height: 2,
            color: Colors.deepPurpleAccent,
          ),
          onChanged: (String? newValue) {
            setState(() {
              dropdownValue = newValue!;
            });
          },
          items: <String>['Darwin Mina', 'Vhernon Mina', 'Arnold Mina', 'Ericson Mayo', 'Benito Butron', 'Homer Bisno', 'Mhel Montemolin']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
              );
            }).toList(),
          ),
          TextButton(
              onPressed: () {
                _listenLocation();
                changeTextEnabled();
              },
              child: Text('Enable live location')),
          TextButton(
              onPressed: () {
                _stopListening();
                changeTextDisabled();
              },
              child: Text('Stop live location')),
          Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Text('$textHolder',
              style: TextStyle(fontSize: 16, color:noteColor))),
          Expanded(
              child: StreamBuilder(
                stream:
                FirebaseFirestore.instance.collection('location').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  return ListView.builder(
                      itemCount: snapshot.data?.docs.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title:
                          Text(snapshot.data!.docs[index]['name'].toString()),
                          subtitle: Row(
                            children: [
                              Text(snapshot.data!.docs[index]['latitude']
                                  .toString()),
                              SizedBox(
                                width: 20,
                              ),
                              Text(snapshot.data!.docs[index]['longitude']
                                  .toString()),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.directions),
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) =>
                                      MyMap(snapshot.data!.docs[index].id)));
                            },
                          ),
                        );
                      });
                },
              )),
        ],
      ),
    );
  }

  Future<void> _listenLocation() async {
    _locationSubscription = location.onLocationChanged.handleError((onError) {
      print(onError);
      _locationSubscription?.cancel();
      setState(() {
        _locationSubscription = null;
      });
    }).listen((loc.LocationData currentlocation) async {
      await FirebaseFirestore.instance.collection('location').doc(dropdownValue).set({
        'latitude': currentlocation.latitude,
        'longitude': currentlocation.longitude,
        'name': dropdownValue,
        'time_date': DateTime.now().toString(),
      }, SetOptions(merge: true));
    });
  }

  _stopListening() {
    _locationSubscription?.cancel();
    setState(() {
      _locationSubscription = null;
    });
  }

  _requestPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      print('done');
    } else if (status.isDenied) {
      _requestPermission();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }
}