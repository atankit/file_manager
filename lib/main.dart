import 'package:file_manager/first_screen.dart';
import 'package:file_manager/pin/applock_service.dart';
import 'package:file_manager/pin/pin_screen.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isPinSet = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    ifPinIsSet();
  }

  Future<void> ifPinIsSet() async {
    final pinSet = await AppLockService.isPinSet();
    setState(() {
      _isPinSet = pinSet;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      home: _isPinSet ? PinScreen(isVerifyMode: true) : FirstScreen(),
    );
  }
}
