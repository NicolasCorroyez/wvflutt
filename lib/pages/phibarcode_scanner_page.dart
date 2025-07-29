import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class PhiBarcodeScannerPage extends StatefulWidget {
  const PhiBarcodeScannerPage({super.key});

  @override
  State<PhiBarcodeScannerPage> createState() => _PhiBarcodeScannerPageState();
}

class _PhiBarcodeScannerPageState extends State<PhiBarcodeScannerPage> {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;
  String? _barcode;
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Guid? _savedServiceUuid;

  @override
  void initState() {
    super.initState();
    _barcode = null;
    _loadSavedServiceUuid();
  }

  Future<void> _loadSavedServiceUuid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uuidString = prefs.getString('last_service_uuid');
    if (uuidString != null) {
      setState(() {
        _savedServiceUuid = Guid(uuidString);
      });
      print("🔄 UUID sauvegardé retrouvé : $_savedServiceUuid");
    } else {
      print("⚠️ Aucun UUID sauvegardé trouvé.");
    }
    _checkConnectedDeviceOrStartScan();
  }

  void _saveServiceUuid(Guid uuid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_service_uuid', uuid.toString());
    print("💾 UUID sauvegardé : $uuid");
  }

  void _checkConnectedDeviceOrStartScan() async {
    if (_savedServiceUuid == null) {
      print("➡️ Aucun UUID sauvegardé, scan classique.");
      _startScan();
      return;
    }

    try {
      print("🔍 Vérifie si un périphérique est déjà connecté...");
      List<BluetoothDevice> connectedDevices =
          await FlutterBluePlus.connectedDevices;

      for (BluetoothDevice device in connectedDevices) {
        print(
          "ℹ️ Vérification du device déjà connecté : ${device.platformName}",
        );

        List<BluetoothService> services = await device.discoverServices();

        for (BluetoothService service in services) {
          if (service.uuid == _savedServiceUuid) {
            print("✅ Service UUID match trouvé : ${service.uuid}");
            _connectToDevice(device);
            return;
          }
        }
      }

      print(
        "❌ Aucun device connecté trouvé avec le service UUID cible. On démarre le scan.",
      );
      _startScan();
    } catch (e) {
      print("Erreur lors de la vérification des devices connectés : $e");
      _startScan(); // En fallback si erreur
    }
  }

  void _startScan() async {
    setState(() {
      _isScanning = true;
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      print("🔎 Scan started");

      await _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) async {
          for (ScanResult r in results) {
            print(
              "🔄 Scan result: ${r.device.platformName} (${r.device.remoteId.str})",
            );

            if (r.device.platformName.contains("BS30")) {
              print("✅ Device trouvé : ${r.device.platformName}");
              await FlutterBluePlus.stopScan();
              setState(() {
                _isScanning = false;
              });
              _connectToDevice(r.device);
              return;
            }
          }
        },
        onError: (e) {
          setState(() {
            _isScanning = false;
          });
          print("Erreur pendant le scan : $e");
        },
        onDone: () {
          setState(() {
            _isScanning = false;
          });
          print("Scan terminé.");
        },
      );
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      print("Erreur pendant le scan : $e");
    }
  }

  void _connectToDevice(BluetoothDevice device) async {
    _device = device;
    try {
      print("🔗 Connexion à ${device.platformName}...");
      await device.connect();
      print("✅ Connecté à ${device.platformName}.");

      await Future.delayed(const Duration(seconds: 2));

      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        print("🔧 Service trouvé : ${service.uuid}");

        // Sauvegarder le UUID la première fois qu'on le découvre
        if (_savedServiceUuid == null) {
          _saveServiceUuid(service.uuid);
          _savedServiceUuid = service.uuid;
        }

        for (BluetoothCharacteristic c in service.characteristics) {
          if (c.properties.read) {
            try {
              List<int> readValue = await c.read();
              print("     ➤ Read value: $readValue");
            } catch (e) {
              print("     ➤ Erreur lecture: $e");
            }
          }

          if (c.properties.write || c.properties.writeWithoutResponse) {
            try {
              await c.write([0x01]);
              print("     ➤ Test write envoyé.");
            } catch (e) {
              print("     ➤ Erreur écriture: $e");
            }
          }

          if (c.properties.notify) {
            print("     ➤ Notifications activées...");
            await c.setNotifyValue(true);
            _characteristic = c;

            c.lastValueStream.listen(
              (value) {
                if (value.isNotEmpty) {
                  String data = String.fromCharCodes(value);
                  String hexData = value
                      .map((b) => b.toRadixString(16).padLeft(2, '0'))
                      .join(' ');
                  print("     ➤ Données reçues : $data ($hexData)");

                  if (data.length > 5) {
                    setState(() {
                      _barcode = data;
                    });
                  }
                } else {
                  print("     ➤ Valeur vide ignorée.");
                }
              },
              onError: (e) {
                print("Erreur stream notification : $e");
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
      print("Erreur lors de la connexion : $e");
      setState(() {
        _barcode = "Erreur lors de la connexion au périphérique.";
      });
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
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
                  ? const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text("Recherche du périphérique..."),
                    ],
                  )
                  : const SizedBox.shrink(),
              const SizedBox(height: 20),
              _barcode == null
                  ? const Text("Aucun code-barres scanné.")
                  : Column(
                    children: [
                      const Text("Code-barres scanné :"),
                      Text("$_barcode"),
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
