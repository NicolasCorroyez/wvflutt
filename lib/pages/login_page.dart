import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();

  Future<void> _handleLogin() async {
    if (_username.text.isNotEmpty && _password.text.isNotEmpty) {
      await context.read<AuthProvider>().login();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Remplis les champs")));
    }
  }

  Future<void> _handleBiometricLogin() async {
    final canCheckBiometrics = await auth.canCheckBiometrics;
    final isDeviceSupported = await auth.isDeviceSupported();

    if (!canCheckBiometrics || !isDeviceSupported) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Biométrie non disponible")));
      return;
    }

    try {
      final authenticated = await auth.authenticate(
        localizedReason: 'Authentifiez-vous pour continuer',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (authenticated) {
        await context.read<AuthProvider>().login();
      }
    } catch (e) {
      debugPrint("Erreur biométrie : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Connexion", style: TextStyle(fontSize: 24)),
              TextField(
                controller: _username,
                decoration: const InputDecoration(labelText: "Identifiant"),
              ),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Mot de passe"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _handleLogin,
                child: const Text("Connexion"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _handleBiometricLogin,
                icon: const Icon(Icons.fingerprint),
                label: const Text("Connexion biométrique"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
