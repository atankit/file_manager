import 'package:file_manager/protected_screen.dart';
import 'package:flutter/material.dart';


class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setting'),
        backgroundColor: Colors.indigo,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.lock, color: Colors.grey,),
            title: Text('Protect Application', style: TextStyle(fontSize: 20),),
            subtitle: Text('Enable and disable password protection, Forget or Change password'),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=> ProtectedScreen()));
            },
          ),
        ],
      )
        
    );
  }
}
