import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuardianScreen extends StatefulWidget {
  const GuardianScreen({super.key});

  @override
  State<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends State<GuardianScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGuardian();
  }

  _loadGuardian() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameCtrl.text = prefs.getString('g_name') ?? "";
      _phoneCtrl.text = prefs.getString('g_phone') ?? "";
    });
  }

  _saveGuardian() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('g_name', _nameCtrl.text);
    await prefs.setString('g_phone', _phoneCtrl.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Guardian Saved!")));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Guardian Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Name")),
          TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: "Phone Number"), keyboardType: TextInputType.phone),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _saveGuardian, child: const Text("Save Guardian"))
        ],
      ),
    );
  }
}