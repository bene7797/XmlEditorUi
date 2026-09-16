import 'package:flutter/material.dart';

import 'app/editor_controller.dart';
import 'data/assets/app_data_store.dart';
import 'ui/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await AppDataStore.ensureInitialized();
  final controller = EditorController(store);
  runApp(XmlEditorApp(controller: controller));
}

class XmlEditorApp extends StatelessWidget {
  const XmlEditorApp({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XML Service Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B4F72),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: HomeShell(controller: controller),
    );
  }
}
