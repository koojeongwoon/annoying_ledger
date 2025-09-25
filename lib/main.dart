import 'package:flutter/material.dart';

import 'package:annoying_ledger/app.dart';
import 'package:annoying_ledger/core/storage/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final tokenStorage = await TokenStorage.create();
  runApp(App(tokenStorage: tokenStorage));
}
