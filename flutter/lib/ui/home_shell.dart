import 'package:flutter/material.dart';

import '../app/editor_controller.dart';
import 'service_editor/service_editor_page.dart';
import 'template_editor/template_editor_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final EditorController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('XML Service Editor'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Service bearbeiten'),
            Tab(text: 'Vorlagen bearbeiten'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          ServiceEditorPage(controller: widget.controller),
          TemplateEditorPage(controller: widget.controller),
        ],
      ),
    );
  }
}
