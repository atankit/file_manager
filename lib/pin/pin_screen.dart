import 'package:file_manager/first_screen.dart';
import 'package:file_manager/pin/applock_service.dart';
import 'package:file_manager/pin/set_pin.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinScreen extends StatefulWidget {
  final bool isVerifyMode;

  const PinScreen({super.key, this.isVerifyMode = true});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final TextEditingController pinController = TextEditingController();
  bool obscure = true;
  String error = '';
  bool isBiometricEnabled = false;

  void _onSubmit() async {
    final pin = pinController.text.trim();

    if (widget.isVerifyMode) {
      final isValid = await AppLockService.validatePin(pin);
      if (isValid) {
        setState(() => error = '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PIN Verified')));
        Navigator.push(context, MaterialPageRoute(builder: (context)=> FirstScreen()));
      } else {
        setState(() {
          error = 'Incorrect PIN';
          pinController.clear();
        });
      }

  } else {
      await AppLockService.setPin(pin);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PIN Set Successfully')));
      Navigator.pop(context);
    }
  }

  void _showForgotPinWithAnswers() async {
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
      builder: (_) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('Forgot Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Answer the security questions to reveal your password.',
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
                  hintText:  storedQ2 ?? 'Question 2',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              if (showError)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Incorrect answers. Please try again.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),


          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () async {
                final a1 = answer1Controller.text.trim().toLowerCase();
                final a2 = answer2Controller.text.trim().toLowerCase();

                if (a1 == (storedA1 ?? '').toLowerCase() &&
                    a2 == (storedA2 ?? '').toLowerCase()) {
                  // final pin = await AppLockService.getPin();
                  // Navigator.pop(context);
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   SnackBar(content: Text('Your PIN is: $pin')),
                  // );
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> SetPin()));
                } else {
                  setState(() => showError = true);
                }
              },
              child: Text('OK', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      }),
    );
  }

  void _onBiometricAuth() async {
    bool isAvailable = await AppLockService.isBiometricAvailable();

    if (isAvailable) {
      bool success = await AppLockService.authenticateWithBiometrics();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Biometric Auth Successful')));
        Navigator.push(context, MaterialPageRoute(builder: (_) => FirstScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Biometric Auth Failed')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Biometric not available')));
    }
  }

  void clearError() {
    if (error.isNotEmpty) {
      setState(() => error = '');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadBiometricSetting();
  }

  void _loadBiometricSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('biometric_enabled') ?? false;
    setState(() => isBiometricEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 100,),

          Text(
              "Enter your 4-digit PIN",
              style: TextStyle(fontSize: 20),
            ),

           SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: error.isNotEmpty
                        ? Colors.red
                        : index < pinController.text.length
                        ? Colors.teal
                        : Colors.grey.shade400,
                  ),
                );
              }),
            ),

            SizedBox(height: 20,),
            // Error message
            Text(error.isNotEmpty ? error : '', style: TextStyle(color: Colors.red)),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  // Digits 1-9
                  for (var i = 1; i <= 9; i++)
                    GestureDetector(
                      onTap: () {
                        if (pinController.text.length < 4) {
                          setState(() {
                            error = '';
                            pinController.text += i.toString();
                          });
                        }
                      },

                      child: Container(
                        margin: EdgeInsets.all(8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(i.toString(), style: TextStyle(fontSize: 24)),
                      ),
                    ),

                  isBiometricEnabled
                      ? GestureDetector(
                    onTap: _onBiometricAuth,
                    child: Container(
                      margin: EdgeInsets.all(8),
                      alignment: Alignment.center,
                      child: Icon(Icons.fingerprint, size: 40, color: Colors.teal),
                    ),
                  )
                      // : SizedBox.shrink(),
                 : GestureDetector(
                    onTap: (){
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Fingerprint is currently disabled.'
                              ' Turn it on in Protected Application settings.')
                          ));
                    },
                    child: Container(
                      margin: EdgeInsets.all(8),
                      alignment: Alignment.center,
                      child: Icon(Icons.fingerprint, size: 40, color: Colors.grey),
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      if (pinController.text.length < 4) {
                        setState(() => pinController.text += "0");
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.all(8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text("0", style: TextStyle(fontSize: 24)),
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      if (pinController.text.isNotEmpty) {
                        setState(() {
                          error = '';
                          pinController.text = pinController.text.substring(0, pinController.text.length - 1);
                        });
                      }
                    },

                    child: Container(
                      margin: EdgeInsets.all(8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.backspace_outlined),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Forgot PIN
                Padding(
                  padding: const EdgeInsets.only(left: 2.0),
                  child: TextButton(
                    onPressed: _showForgotPinWithAnswers,
                    child: Text(" FORGOT\nPIN CODE?", style: TextStyle(color: Colors.blue)),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(right: 2.0),
                  child: ElevatedButton(
                    onPressed: _onSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('Verify', style: TextStyle(color: Colors.white),),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
