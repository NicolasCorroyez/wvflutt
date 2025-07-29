import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan un code-barres')),
      body: MobileScanner(
        onDetect: (BarcodeCapture capture) {
          if (_isProcessing) return;

          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final String? rawValue = barcode.rawValue;
            if (rawValue != null) {
              setState(() {
                _isProcessing = true;
              });

              // Affiche le code scanné
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Code scanné : $rawValue')),
              );

              // Retourne à la WebView avec le résultat
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  Navigator.pop(context, rawValue);
                }
              });

              break;
            }
          }
        },
      ),
    );
  }
}
