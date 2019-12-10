import 'package:flutter/material.dart';
import 'package:wifi_connect/wifi_connect.dart';

void main() => runApp(Wrapper(child: MyApp()));

class Wrapper extends StatelessWidget {
  final Widget child;

  const Wrapper({Key key, @required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(10),
          child: child,
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        Divider(),
        RaisedButton(
          child: Text("connect"),
          onPressed: connect,
        ),
        Divider(),
        Text("Connected to: $connectedTo"),
        Text('Connect success: $connectSuccess'),
      ],
    );
  }

  String connectSuccess;
  String connectedTo;

  @override
  void initState() {
    super.initState();
    statusListener();
  }

  Future<void> statusListener() async {
    while (true) {
      var _connectedTo = await WifiConnect.getConnectedSSID();
      setState(() {
        connectedTo = _connectedTo;
      });
      await Future.delayed(Duration(seconds: 1));
    }
  }

  void showMessage(String msg) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(msg),
        );
      },
    );
  }

  Future<void> connect() async {
    setState(() {
      connectSuccess = '...';
    });
    var status = await WifiConnect.connect(
      context,
      ssid: 'Gecko1234',
      password: 'password',
    );
    setState(() {
      connectSuccess = status.toString();
    });
  }
}
