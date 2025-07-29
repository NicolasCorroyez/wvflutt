/* import 'package:flutter/material.dart';
import 'webview_page.dart';
import 'settings_page.dart';
import 'barcode_scanner_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Ouvrir WebView"),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WebViewExample()),
                  ),
            ),
            ElevatedButton(
              child: const Text("Paramétrage"),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  ),
            ),
            ElevatedButton(
              child: const Text("Scanner un code-barres"),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BarcodeScannerPage(),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
 */
