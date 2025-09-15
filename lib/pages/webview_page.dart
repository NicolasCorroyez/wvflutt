import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:local_auth/local_auth.dart';
import 'package:galiapp/pages/barcode_scanner_page.dart';

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
    return Scaffold(
      appBar: null,
      body: Container(
        color: Colors.black,
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri(
              /* "http://192.168.0.243:8000/lapage.html" */ /* "http://192.168.0.139:5173/" */ /* "https://oyder.vercel.app" */ "http://192.168.0.190:3002/",
            ),
          ),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            domStorageEnabled: true,
            supportZoom: false,
            displayZoomControls: false,
          ),
          onWebViewCreated: (controller) {
            _controller = controller;

            // Gestion des appels JS -> Flutter
            _controller.addJavaScriptHandler(
              handlerName: "afficheCamera",
              callback: (args) {
                /* print("hello app"); */
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
                /* print("codeBarreScanne");
              print("args: $args"); */
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
            // Injection JavaScript adaptative selon le type d'appareil
            await controller.evaluateJavascript(
              source: '''
          // === 1) Sélection et menu contextuel ===
          const styleNoSelect = document.createElement('style');
          styleNoSelect.innerHTML = `
            * {
              -webkit-user-select: none !important;
              -moz-user-select: none !important;
              -ms-user-select: none !important;
              user-select: none !important;
              -webkit-touch-callout: none !important;
            }
          `;
          document.head.appendChild(styleNoSelect);

          document.addEventListener('contextmenu', event => event.preventDefault());

          // === 2) Empêcher l'overscroll horizontal (swipe nav) ===
          const styleNoOverscroll = document.createElement('style');
          styleNoOverscroll.innerHTML = `
            html, body {
              overscroll-behavior-x: none !important;
              overscroll-behavior-y: none !important;
            }
          `;
          document.head.appendChild(styleNoOverscroll);

          // === 3) Piégeage des navigations back/forward via history ===
          history.pushState(null, '', window.location.href);
          window.addEventListener('popstate', function(e) {
            history.pushState(null, '', window.location.href);
          });
          
          // === 4) Viewport adaptatif selon le type d'appareil ===
          let existingViewport = document.querySelector('meta[name=viewport]');
          if (!existingViewport) {
            existingViewport = document.createElement('meta');
            existingViewport.name = 'viewport';
            document.head.appendChild(existingViewport);
          }
          
           // Configuration adaptative pour tablettes vs téléphones avec zoom à 65%
           const isTablet = window.innerWidth > 600;
           if (isTablet) {
           // Attention sur iphone 0.65 change les breakpoints
             existingViewport.content = 'width=device-width, initial-scale=1, minimum-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover';
           } else {
             existingViewport.content = 'width=device-width, initial-scale=1, minimum-scale=1, maximum-scale=1, user-scalable=no';
           }
          
          // === 5) Optimisations pour tablettes ===
          if (isTablet) {
            // Améliorer la lisibilité sur grands écrans
            const tabletStyles = document.createElement('style');
            tabletStyles.innerHTML = `
              body {
                font-size: 16px !important;
                line-height: 1.6 !important;
              }
              @media (min-width: 768px) {
                body {
                  font-size: 18px !important;
                }
              }
            `;
            document.head.appendChild(tabletStyles);
          }
          
          ''',
            );
          },
        ),
      ),
    );
  }
}
