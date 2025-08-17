import 'package:file_manager/pin/applock_service.dart';
import 'package:file_manager/pin/set_pin.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProtectedScreen extends StatefulWidget {
  const ProtectedScreen({super.key});

  @override
  State<ProtectedScreen> createState() => _ProtectedScreenState();
}
class _ProtectedScreenState extends State<ProtectedScreen> {

  bool isPinSet = false;
  bool isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
    _loadBiometricPreference();
  }

  Future<void> _checkPinStatus() async {
    final pinExists = await AppLockService.isPinSet();
    setState(() {
      isPinSet = pinExists;
    });
  }

  void _onToggle() async {
    if (isPinSet) {
      final enteredPin = await _askPinInputDialog();
      if (enteredPin != null) {
        final removed = await AppLockService.removePin(enteredPin);
        if (removed) {
          setState(() {
            isPinSet = false;
            isBiometricEnabled = false;
          });

          await AppLockService.disableBiometric();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PIN removed and biometric disabled')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Incorrect PIN')),
          );
        }
      }
    } else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SetPin()),
      );

      if (result == true) {
        _checkPinStatus();

        final isAvailable = await AppLockService.isBiometricAvailable();
        final prefs = await SharedPreferences.getInstance();

        if (isAvailable) {
          await prefs.setBool('biometric_enabled', true);
          setState(() => isBiometricEnabled = true);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Biometric enabled automatically")),
          );
        }
      }
    }
  }

  Future<String?> _askPinInputDialog() async {
    TextEditingController controller = TextEditingController();
    bool showError = false;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: Text('Enter password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Please enter the password created in app setting.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      errorText: showError ? 'Incorrect password' : null,
                    ),
                  ),

                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showForgotPasswordDialog();
                  },
                  child: Text('FORGOT?', style: TextStyle(color: Colors.blue)),
                ),

                TextButton(
                  onPressed: (){Navigator.pop(context);},
                  child: Text('CANCEL', style: TextStyle(color: Colors.blue)),
                ),
                TextButton(
                  onPressed: () {
                    final entered = controller.text.trim();
                    if (entered.isEmpty) {
                      setState(() => showError = true);
                    } else {
                      Navigator.pop(context, entered);
                    }
                  },
                  child: Text('OK', style: TextStyle(color: Colors.blue)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showForgotPasswordDialog() async {
    final storedQ1 = await AppLockService.getHintQuestion();
    final storedQ2 = await AppLockService.getHintQuestion2();
    final storedA1 = await AppLockService.getHintAnswer();
    final storedA2 = await AppLockService.getHintAnswer2();

    TextEditingController answer1Controller = TextEditingController();
    TextEditingController answer2Controller = TextEditingController();
    bool showError = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text('Forgot Password'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Forget your Password? No issues just answer the security questions correctly and you can reset your password.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: answer1Controller,
                    decoration: InputDecoration(
                      hintText: storedQ1 ?? 'Question 1',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: answer2Controller,
                    decoration: InputDecoration(
                      hintText: storedQ2 ?? 'Question 2',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  if (showError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('Incorrect answers. Try again.',
                          style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('CANCEL', style: TextStyle(color: Colors.blue)),
              ),
              TextButton(
                onPressed: () {
                  final a1 = answer1Controller.text.trim().toLowerCase();
                  final a2 = answer2Controller.text.trim().toLowerCase();

                  if (a1 == (storedA1 ?? '').toLowerCase() &&
                      a2 == (storedA2 ?? '').toLowerCase()   ) {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>SetPin() ));
                  } else {
                    setState(() => showError = true);
                  }
                },
                child: Text('OK', style: TextStyle(color: Colors.blue)),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _loadBiometricPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    });
  }


  Future<void> _toggleBiometric(bool value) async {
    print("Toggle biometric called with value: $value");
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      final isAvailable = await AppLockService.isBiometricAvailable();

      if (isAvailable) {
        await prefs.setBool('biometric_enabled', true);
        setState(() => isBiometricEnabled = true);
        print("Biometric is available, enabled now");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Biometric not available on this device")),
        );
        setState(() => isBiometricEnabled = false);
      }
    } else {
      await prefs.setBool('biometric_enabled', false);
      setState(() => isBiometricEnabled = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App Lock'),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          ListTile(
            title: Text(
              'Security Settings',
              style: TextStyle(color: Colors.blue),
            ),
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('Protect App'),
            subtitle: Text('Enable or Disable password protection'),
            trailing: Switch(
              value: isPinSet,
              onChanged: (value) {
                _onToggle();
              },
              activeColor: Colors.white,
              activeTrackColor: Colors.indigoAccent,
            ),
            onTap: _onToggle,
          ),

          ListTile(
            leading: Icon(Icons.edit_document),
            title: Text('Change Password'),
            subtitle: Text('Click to update your existing password'),
            onTap: () async {
              final isPinSet = await AppLockService.isPinSet();

              if (isPinSet) {
                final enteredPin = await _askPinInputDialog();
                if (enteredPin != null) {
                  final isValid = await AppLockService.validatePin(enteredPin);
                  if (isValid) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SetPin()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Incorrect PIN')),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No password is currently set')),
                );
              }
            },
          ),

          ListTile(
            leading: Icon(Icons.fingerprint),
            title: Text('Enable Biometric'),
            subtitle: Text('Click to enable your Fingerprint verification'),
            trailing: Switch(
              value: isBiometricEnabled,
              onChanged: isPinSet
                  ? (value) => _toggleBiometric(value)
                  : null,
              activeColor: Colors.white,
              activeTrackColor: Colors.indigoAccent,
            ),
          ),
        ],
      ),
    );
  }
}
