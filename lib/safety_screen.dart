import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  static const platform = MethodChannel('com.echoher.app/sms');
  bool _isArmed = false;
  StreamSubscription? _accelerometerSub;
  DateTime _lastAlert = DateTime.now().subtract(const Duration(minutes: 1));

  void _toggleSafety() {
    setState(() => _isArmed = !_isArmed);
    if (_isArmed) {
      _listenToShake();
    } else {
      _accelerometerSub?.cancel();
    }
  }

    _accelSub = accelerometerEventStream().listen((event) {
      // Use the Pythagorean theorem to find the actual G-force magnitude
      // sqrt(x² + y² + z²)
      double gForce = Math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      // Normal gravity is ~9.8. 
      // A firm shake usually hits 15-20. 
      // Let's set it to 12 for high sensitivity (easy to trigger).
      if (gForce > 12) { 
        _triggerEmergency("SHAKE DETECTED");
      }
    });
  }

  Future<void> _triggerEmergency() async {
    // Prevent multiple triggers in a row
    if (DateTime.now().difference(_lastAlert).inSeconds < 15) return;
    _lastAlert = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    String? phone = prefs.getString('g_phone');
    if (phone == null || phone.isEmpty) return;

    Position pos = await Geolocator.getCurrentPosition();
    String mapUrl = "https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}";
    String timestamp = DateTime.now().toString();
    
    String message = "EMERGENCY! I need help. My location: $mapUrl. Time: $timestamp";

    try {
      await platform.invokeMethod('sendDirectSms', {"phone": phone, "message": message});
      debugPrint("SMS Sent Successfully");
    } on PlatformException catch (e) {
      debugPrint("Failed to send: ${e.message}");
    }
  }

  @override
  void dispose() {
    _accelerometerSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_isArmed ? Icons.gpp_good : Icons.gpp_maybe, size: 100, color: _isArmed ? Colors.green : Colors.red),
          const SizedBox(height: 20),
          Text(_isArmed ? "SAFETY MODE: ARMED" : "SAFETY MODE: DISARMED", 
               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _isArmed ? Colors.grey : Colors.red, foregroundColor: Colors.white),
            onPressed: _toggleSafety,
            child: Text(_isArmed ? "DISARM" : "ARM SAFETY MODE"),
          ),
        ],
      ),
    );
  }
}