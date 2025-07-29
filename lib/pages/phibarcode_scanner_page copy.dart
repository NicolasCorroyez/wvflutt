import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class PhiBarcodeScannerPage extends StatefulWidget {
  const PhiBarcodeScannerPage({super.key});

  @override
  State<PhiBarcodeScannerPage> createState() => _PhiBarcodeScannerPage();
}

class _PhiBarcodeScannerPage extends State<PhiBarcodeScannerPage> {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;
  String? _barcode;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _checkExistingConnection();
  }

  void _checkExistingConnection() async {
    try {
      List<BluetoothDevice> connectedDevices =
          await FlutterBluePlus.connectedDevices;
      print("connectedDevices: $connectedDevices");
      for (BluetoothDevice device in connectedDevices) {
        if (device.platformName.contains("BS30")) {
          _device = device;
          print(device);
          print("Already connected to ${device.platformName}");
          _connectToDevice(device);
          return;
        }
      }
      _startScan();
    } catch (e) {
      print("Error checking existing connection: $e");
    }
  }

  void _startScan() async {
    setState(() {
      _isScanning = true;
    });

    try {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      print("Scan started");

      FlutterBluePlus.scanResults.listen(
        (results) async {
          for (ScanResult r in results) {
            /* print("Device: ${r.device.platformName}");
            print("advertisementData: ${r.advertisementData.serviceUuids}"); */

            if (r.device.platformName.contains("BS30") &&
                r.advertisementData.serviceUuids.isNotEmpty) {
              print("Device found: ${r.device.platformName}");
              await FlutterBluePlus.stopScan();
              setState(() {
                _isScanning = false;
              });
              _connectToDevice(r.device);
              break;
            }
          }
        },
        onDone: () {
          setState(() {
            _isScanning = false;
          });
          print("Scan finished without finding the device.");
        },
      );
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      print("Error during scan: $e");
    }
  }

  void _connectToDevice(BluetoothDevice device) async {
    _device = device;

    try {
      print("Connecting to ${device.platformName}...");
      await device.connect();
      print("Connected to device ${device.platformName}.");
      await Future.delayed(
        const Duration(seconds: 2),
      ); // Laisse le temps à l'appareil

      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        /* print("🔧 Service: ${service.uuid}"); */
        for (BluetoothCharacteristic c in service.characteristics) {
          /*  print("  ▶ Characteristic UUID: ${c.uuid}");
          print("     ➤ notify: ${c.properties.notify}");
          print("     ➤ read: ${c.properties.read}");
          print("     ➤ write: ${c.properties.write}");
          print(
            "     ➤ writeWithoutResponse: ${c.properties.writeWithoutResponse}",
          ); */

          // Lecture automatique si possible
          if (c.properties.read) {
            try {
              List<int> readValue = await c.read();
              print("     ➤ Read value: $readValue");
            } catch (e) {
              print("     ➤ Error reading: $e");
            }
          }

          // Écriture de test
          if (c.properties.write || c.properties.writeWithoutResponse) {
            try {
              await c.write([0x01]); // Valeur d'init générique à adapter
              print("     ➤ Test write sent.");
            } catch (e) {
              print("     ➤ Error writing: $e");
            }
          }

          // Notification si disponible
          if (c.properties.notify) {
            print("     ➤ Listening to notifications...");
            await c.setNotifyValue(true);
            _characteristic = c;

            c.lastValueStream.listen(
              (value) {
                print("     ➤ Notification received: $value");
                if (value.isNotEmpty) {
                  String data = String.fromCharCodes(value);
                  String hexData = value
                      .map((b) => b.toRadixString(16).padLeft(2, '0'))
                      .join(' ');
                  print("     ➤ Decoded string: $data");

                  if (data.length > 10) {
                    setState(() {
                      _barcode = data;
                    });
                  }
                } else {
                  print("     ➤ Empty value received, ignored.");
                }
              },
              onError: (e) {
                print("Notification stream error: $e");
              },
            );
          }
        }
      }

      if (_characteristic == null) {
        setState(() {
          _barcode = "Aucune caractéristique avec notify trouvée.";
        });
      }
    } catch (e) {
      print("Error connecting to device: $e");
      setState(() {
        _barcode = "Erreur lors de la connexion au périphérique.";
      });
    }
  }

  @override
  void dispose() {
    _device?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan un code-barres BLE')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _isScanning
                  ? const CircularProgressIndicator()
                  : const SizedBox.shrink(),
              const SizedBox(height: 20),
              _barcode == null
                  ? const Text("Aucun code-barres scanné.")
                  : Text("Code-barres scanné :"),
              Text("$_barcode"),
            ],
          ),
        ),
      ),
    );
  }
}
/* Last good */