import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:local_auth/local_auth.dart';
import 'package:webview_in_flutter/pages/barcode_scanner_page.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../pages/phibarcode_scanner_page.dart';
import '../pages/hidcodescan.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late InAppWebViewController _controller;
  final LocalAuthentication auth = LocalAuthentication();

  @override
  Widget build(BuildContext context) {
    // Configuration de la barre de statut
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 30, 32, 78),
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      body: Column(
        children: [
          // Container pour remplacer l'AppBar et éliminer la barre blanche
          Container(
            height: MediaQuery.of(context).padding.top,
            color: const Color.fromARGB(255, 30, 32, 78),
          ),
          // WebView qui prend tout l'espace restant
          Expanded(
            child: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(
            /* "http://192.168.0.243:8000/lapage.html" */ "http://192.168.0.139:5173/",
          ),
        ),
        onWebViewCreated: (controller) {
          _controller = controller;

          // Gestion des appels JS -> Flutter
          _controller.addJavaScriptHandler(
            handlerName: "afficheCamera",
            callback: (args) {
              print("hello app");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
              ).then((result) {
                if (result != null && result is String) {
                  _controller.evaluateJavascript(
                    source:
                        "window.onBarcodeScanned && window.onBarcodeScanned('$result');",
                  );
                }
              });
            },
          );
          _controller.addJavaScriptHandler(
            handlerName: "codeBarreScanne",
            callback: (args) {
              print("codeBarreScanne");
              print("args: $args");
              /* Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => const HidBarcode() /* PhiBarcodeScannerPage() */,
                ),
              ).then((result) {
                print("hello");
              }); */
            },
          );
          _controller.addJavaScriptHandler(
            handlerName: "demandeBiometrie",
            callback: (args) async {
              final canCheck = await auth.canCheckBiometrics;
              if (!canCheck) return;

              final success = await auth.authenticate(
                localizedReason: "Veuillez vous authentifier",
                options: const AuthenticationOptions(
                  stickyAuth: true,
                  biometricOnly: true,
                ),
              );

              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Authentification réussie")),
                );
              }
            },
          );
        },
        onLoadStop: (controller, url) async {
          // Injection JavaScript pour restreindre zoom, sélection, menu contextuel
          await controller.evaluateJavascript(
            source: '''
            // Empêche la sélection de texte
            const style = document.createElement('style');
            style.innerHTML = \`
              * {
                -webkit-user-select: none !important;
                -moz-user-select: none !important;
                -ms-user-select: none !important;
                user-select: none !important;
                -webkit-touch-callout: none !important;
              }
            \`;
            document.head.appendChild(style);

            // Désactive le menu contextuel (clic droit ou appui long)
            document.addEventListener('contextmenu', event => event.preventDefault());
              ''',
              );
            },
            ),
          ),
        ],
      ),
    );
  }
}
