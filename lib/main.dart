import 'dart:async';
import 'dart:io';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  List<CameraDescription> cameras = [];
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint("Camera error: $e");
  }
  runApp(EchoHerApp(cameras: cameras));
}

class EchoHerApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const EchoHerApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink, primary: Colors.pinkAccent),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFF5F8),
      ),
      home: HomeScreen(cameras: cameras),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const HomeScreen({super.key, required this.cameras});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      SafetyView(cameras: widget.cameras),
      const NearbyView(),
      const GuardianView(),
    ];
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.sms, 
      Permission.location, 
      Permission.camera, 
      Permission.microphone
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("E C H O  H E R", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.pinkAccent,
        elevation: 4,
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.security_rounded), label: "Safety"),
          NavigationDestination(icon: Icon(Icons.map_rounded), label: "Safe Map"),
          NavigationDestination(icon: Icon(Icons.favorite_rounded), label: "Guardian"),
        ],
      ),
    );
  }
}

// --- TAB 1: SAFETY (SHAKE + SOS + BLACK BOX) ---
class SafetyView extends StatefulWidget {
  final List<CameraDescription> cameras;
  const SafetyView({super.key, required this.cameras});
  @override
  State<SafetyView> createState() => _SafetyViewState();
}

class _SafetyViewState extends State<SafetyView> with SingleTickerProviderStateMixin {
  static const platform = MethodChannel('com.echoher.app/sms');
  bool _isArmed = false;
  StreamSubscription? _accelSub;
  FlutterSoundRecorder? _recorder = FlutterSoundRecorder();
  bool _isRecorderInit = false;
  CameraController? _camController;
  DateTime _lastAlert = DateTime.now().subtract(const Duration(seconds: 30));
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  Future<void> _initRecorder() async {
    await _recorder!.openRecorder();
    _isRecorderInit = true;
  }

  void _toggleSafety() {
    setState(() => _isArmed = !_isArmed);
    if (_isArmed) {
      _accelSub = accelerometerEventStream().listen((event) {
        double gForce = Math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        if (gForce > 13.0) _triggerEmergency("SHAKE DETECTED");
      });
    } else {
      _accelSub?.cancel();
    }
  }

  Future<void> _triggerEmergency(String source) async {
    if (DateTime.now().difference(_lastAlert).inSeconds < 20) return;
    _lastAlert = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    String? phone = prefs.getString('g_phone');
    if (phone == null || phone.isEmpty) return;

    try {
      Position pos = await Geolocator.getCurrentPosition();
      String msg = "EMERGENCY! $source. Location: https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}";
      await platform.invokeMethod('sendDirectSms', {"phone": phone, "message": msg});
      _showSnackBar("🚨 SOS SENT TO GUARDIAN");
    } catch (e) {
      debugPrint("SMS Error: $e");
    }
    _startBlackBoxCapture();
  }

  Future<void> _startBlackBoxCapture() async {
    try {
      if (!_isRecorderInit) return;
      final dir = await getApplicationDocumentsDirectory();
      final audioPath = '${dir.path}/evidence_${DateTime.now().millisecondsSinceEpoch}.aac';
      await _recorder!.startRecorder(toFile: audioPath, codec: Codec.aacADTS);
      Future.delayed(const Duration(seconds: 20), () async {
        await _recorder!.stopRecorder();
        debugPrint("Evidence Saved: $audioPath");
      });

      if (widget.cameras.isNotEmpty) {
        _camController = CameraController(widget.cameras.last, ResolutionPreset.medium, enableAudio: false);
        await _camController!.initialize();
        XFile image = await _camController!.takePicture();
        debugPrint("Photo Saved: ${image.path}");
        await _camController!.dispose();
      }
    } catch (e) {
      debugPrint("Black Box Error: $e");
    }
  }

  void _showFakeCall() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Column(
              children: [
                CircleAvatar(radius: 55, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 70, color: Colors.white)),
                SizedBox(height: 25),
                Text("Emergency Contact", style: TextStyle(color: Colors.white, fontSize: 32, decoration: TextDecoration.none)),
                Text("Calling...", style: TextStyle(color: Colors.white70, fontSize: 18, decoration: TextDecoration.none)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton.large(onPressed: () => Navigator.pop(context), backgroundColor: Colors.redAccent, child: const Icon(Icons.call_end, color: Colors.white, size: 40)),
                FloatingActionButton.large(onPressed: () => Navigator.pop(context), backgroundColor: Colors.greenAccent, child: const Icon(Icons.call, color: Colors.white, size: 40)),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: Colors.pinkAccent));
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _recorder!.closeRecorder();
    _camController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: Icon(Icons.security, color: _isArmed ? Colors.green : Colors.pinkAccent),
            title: Text(_isArmed ? "BLACK BOX ARMED" : "SYSTEM STANDBY", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Sensors & Background Recording Ready"),
          ),
        ),
        const Spacer(),
        ScaleTransition(
          scale: _isArmed ? Tween(begin: 1.0, end: 1.15).animate(_pulseController) : const AlwaysStoppedAnimation(1.0),
          child: GestureDetector(
            onLongPress: () => _triggerEmergency("MANUAL SOS"),
            child: Container(
              height: 220, width: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isArmed ? Colors.pinkAccent : Colors.white,
                border: Border.all(color: Colors.pinkAccent, width: 6),
                boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.3), blurRadius: 30, spreadRadius: 10)],
              ),
              child: Icon(Icons.shield, size: 100, color: _isArmed ? Colors.white : Colors.pinkAccent),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text("Long Press Shield for SOS", style: TextStyle(color: Colors.pink, fontWeight: FontWeight.w500)),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: _toggleSafety, 
                icon: Icon(_isArmed ? Icons.lock_open : Icons.lock),
                label: Text(_isArmed ? "DISARM SYSTEM" : "ARM PROTECTION"),
                style: ElevatedButton.styleFrom(backgroundColor: _isArmed ? Colors.black87 : Colors.pinkAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55)),
              ),
              const SizedBox(height: 15),
              OutlinedButton.icon(
                onPressed: _showFakeCall, 
                icon: const Icon(Icons.call),
                label: const Text("TRIGGER FAKE CALL"),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.pinkAccent, minimumSize: const Size(double.infinity, 50), side: const BorderSide(color: Colors.pinkAccent)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// --- TAB 2: SAFE MAP (NEARBY POLICE) ---
class NearbyView extends StatelessWidget {
  const NearbyView({super.key});

  Future<void> _findPolice() async {
    final Uri url = Uri.parse("https://www.google.com/maps/search/Police+Stations+near+me");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callEmergency() async {
    final Uri tel = Uri.parse("tel:100");
    if (await canLaunchUrl(tel)) await launchUrl(tel);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Safe Havens", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
          const Text("Find the nearest help in seconds.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: InkWell(
              onTap: _findPolice,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade700]),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.local_police, color: Colors.white, size: 45),
                    SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Police Finder", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text("Get directions in Maps", style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              onTap: _callEmergency,
              contentPadding: const EdgeInsets.all(15),
              leading: const CircleAvatar(radius: 25, backgroundColor: Colors.red, child: Icon(Icons.phone, color: Colors.white)),
              title: const Text("Emergency Helpline (100)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: const Text("Immediate connection to Police"),
              trailing: const Icon(Icons.call_made),
            ),
          ),
          
          const Spacer(),
          const Center(child: Text("Data is updated based on your current GPS.", style: TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }
}

// --- TAB 3: GUARDIAN SETUP ---
class GuardianView extends StatefulWidget {
  const GuardianView({super.key});
  @override
  State<GuardianView> createState() => _GuardianViewState();
}

class _GuardianViewState extends State<GuardianView> {
  final _phone = TextEditingController();
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _phone.text = prefs.getString('g_phone') ?? "";
      _name.text = prefs.getString('g_name') ?? "";
    });
  }

  _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('g_phone', _phone.text);
    await prefs.setString('g_name', _name.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Guardian successfully saved!")));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Trusted Guardian", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
              const Divider(height: 40),
              TextField(controller: _name, decoration: const InputDecoration(labelText: "Name", prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 15),
              TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Phone Number", prefixIcon: Icon(Icons.phone))),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: _save, 
                child: const Text("SAVE CONTACT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
              ),
            ],
          ),
        ),
      ),
    );
  }
}