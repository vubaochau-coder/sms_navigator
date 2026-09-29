import 'package:flutter/material.dart';
import 'app.dart';
import 'core/di/injection.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Dependency Injection
  DependencyContainer.instance.init();

  runApp(const OtpRelayApp());
}
