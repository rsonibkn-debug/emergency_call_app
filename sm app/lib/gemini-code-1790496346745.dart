import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';

void main() {
  runApp(const EmergencyConfigApp());
}

class EmergencyConfigApp extends StatelessWidget {
  const EmergencyConfigApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Emergency Device Configurator',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        useMaterial3: true,
      ),
      home: const ConfigHomeScreen(),
    );
  }
}

class ConfigHomeScreen extends StatefulWidget {
  const ConfigHomeScreen({Key? key}) : super(key: key);

  @override
  State<ConfigHomeScreen> createState() => _ConfigHomeScreenState();
}

class _ConfigHomeScreenState extends State<ConfigHomeScreen> {
  final Telephony telephony = Telephony.instance;

  final TextEditingController _deviceSimController = TextEditingController();
  final TextEditingController _phoneNumController = TextEditingController();

  int _selectedSlot = 1;
  final String _securityPass = "1234";

  final Map<int, String> _slotLabels = {
    1: '1 - Doctor',
    2: '2 - Driver',
    3: '3 - Relative 1',
    4: '4 - Relative 2',
  };

  void _sendConfigurationSMS() async {
    String deviceSim = _deviceSimController.text.trim();
    String newPhoneNum = _phoneNumController.text.trim();

    if (deviceSim.isEmpty || newPhoneNum.isEmpty) {
      _showSnackBar("कृपया डिवाइस का SIM नंबर और नया फ़ोन नंबर दर्ज करें!", Colors.red);
      return;
    }

    if (newPhoneNum.length < 10) {
      _showSnackBar("कृपया सही 10-अंकीय मोबाइल नंबर दर्ज करें!", Colors.red);
      return;
    }

    // Check SMS Permission
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;

    if (permissionsGranted == true) {
      // Protocol Format: 1234#POS#NUMBER
      String smsBody = "$_securityPass#$_selectedSlot#$newPhoneNum";

      try {
        await telephony.sendSms(
          to: deviceSim,
          message: smsBody,
        );
        _showSnackBar("SMS भेजा जा रहा है: $smsBody", Colors.green);
        _phoneNumController.clear();
      } catch (e) {
        _showSnackBar("SMS भेजने में विफल: $e", Colors.red);
      }
    } else {
      _showSnackBar("SMS भेजने की अनुमति (Permission) नहीं मिली!", Colors.orange);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Device Config"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              color: Colors.amberAccent,
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  "नोट: इस ऐप का उपयोग करके आप GSM डिवाइस में 4 बटन के लिए आपातकालीन नंबर अपडेट कर सकते हैं।",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Device SIM Input
            TextField(
              controller: _deviceSimController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Device SIM Number",
                hintText: "Enter SIM number inside Arduino",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sim_card),
              ),
            ),
            const SizedBox(height: 20),

            // Slot Dropdown
            DropdownButtonFormField<int>(
              value: _selectedSlot,
              decoration: const InputDecoration(
                labelText: "Select Button Slot",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.touch_app),
              ),
              items: _slotLabels.entries.map((entry) {
                return DropdownMenuItem<int>(
                  value: entry.key,
                  text: Text(entry.value),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedSlot = val;
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            // New Phone Number Input
            TextField(
              controller: _phoneNumController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: "New Mobile Number",
                hintText: "Enter 10 digit number to store",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 25),

            // Send Button
            ElevatedButton.icon(
              onPressed: _sendConfigurationSMS,
              icon: const Icon(Icons.send),
              label: const Text(
                "Update Configuration via SMS",
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}