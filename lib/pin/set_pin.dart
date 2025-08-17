import 'package:file_manager/pin/applock_service.dart';
import 'package:flutter/material.dart';

class SetPin extends StatefulWidget {
  const SetPin({super.key});

  @override
  State<SetPin> createState() => _SetPinState();
}

class _SetPinState extends State<SetPin> {
  TextEditingController pinController = TextEditingController();
  final TextEditingController cpinController = TextEditingController();
  final TextEditingController answer1Controller = TextEditingController();
  final TextEditingController answer2Controller = TextEditingController();

  bool obscurePass = true;
  bool obscureCPass = true;
  final List<String> hintQuestions = [
    "What is your Favourite Book?",
    "What is your Favourite Place?",
    "What is your Favourite Food?",
    "What city were you born in?",
    "What is your favorite place to vacation?",
    "What is your Favourite Movie?",
    "What is your Pet Name?",
  ];

  String? selectedQuestion = "What is your Favourite Book?";
  String? selectedQuestion2 = "What is your Favourite Place?";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Password'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: obscurePass,
              decoration: InputDecoration(
                hintText: 'Enter password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: Colors.black, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePass ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePass = !obscurePass;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 20),

            TextField(
              controller: cpinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: obscureCPass,
              decoration: InputDecoration(
                hintText: 'Confirm password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: Colors.black, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureCPass ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      obscureCPass = !obscureCPass;
                    });
                  },
                ),

              ),
            ),

            SizedBox(height: 10),
            Divider(thickness: 1, color: Colors.grey),
            SizedBox(height: 10),

            Text(
              'Security Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 4),
            Text(
              'These questions will help you when you forget your password. All your security answers will be encrypted and stored only in the local device.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),

            DropdownButton<String>(
              value: selectedQuestion,
              onChanged: (value) {
                setState(() {
                  selectedQuestion = value!;
                });
              },
              padding: EdgeInsets.only(left: 20),
              underline: SizedBox(),
              borderRadius: BorderRadius.circular(10),
              isExpanded: true,
              items:
                  hintQuestions.map((questions) {
                    return DropdownMenuItem(
                      value: questions,
                      child: Text(questions),
                    );
                  }).toList(),
            ),

            SizedBox(height: 10),

            TextField(
              controller: answer1Controller,
              decoration: InputDecoration(
                hintText: "Your answer",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.blue,
                    width: 2,
                  ),
                ),
              ),
            ),

            DropdownButton<String>(
              value: selectedQuestion2,
              onChanged: (value) {
                setState(() {
                  selectedQuestion2 = value!;
                });
              },
              padding: EdgeInsets.only(left: 20),
              underline: SizedBox(),
              borderRadius: BorderRadius.circular(10),
              isExpanded: true,
              items:
                  hintQuestions.map((question) {
                    return DropdownMenuItem(
                      value: question,
                      child: Text(question),
                    );
                  }).toList(),
            ),

            SizedBox(height: 10),

            TextField(
              controller: answer2Controller,
              decoration: InputDecoration(
                hintText: "Your answer",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.blue,
                    width: 2,
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            Container(
              width: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ElevatedButton(
                onPressed: () async {
                  final pin = pinController.text.trim();
                  final confirmPin = cpinController.text.trim();
                  final answer1 = answer1Controller.text.trim();
                  final answer2 = answer2Controller.text.trim();

                  if (pin.isEmpty ||
                      confirmPin.isEmpty ||
                      answer1.isEmpty ||
                      answer2.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please fill all fields')),
                    );
                    return;
                  }

                  if (pin != confirmPin) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Passwords do not match')),
                    );
                    return;
                  }

                  await AppLockService.setPin(pin);
                  await AppLockService.setHintQuestion(selectedQuestion ?? '');
                  await AppLockService.setHintAnswer(answer1);

                  await AppLockService.setHintQuestion2(selectedQuestion2 ?? '');
                  await AppLockService.setHintAnswer2(answer2);


                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('App lock saved successfully')),
                  );
                  Navigator.pop(context, true);
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'SAVE',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
