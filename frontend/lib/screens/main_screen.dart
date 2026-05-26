import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/layouts/main_layout.dart';
import '../widgets/top_bar/ribbon_bar.dart';
import '../widgets/top_bar/menu_bar.dart' as unilab;
import '../widgets/status_bar.dart';
import '../widgets/command_palette/command_palette.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (event) {
        if (event is RawKeyDownEvent) {
          if (event.isControlPressed && 
              event.isShiftPressed && 
              event.logicalKey == LogicalKeyboardKey.keyP) {
            CommandPalette.show(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).canvasColor,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            unilab.MenuBar(tabController: _tabController),
            const RibbonBar(),
            const Expanded(
              child: MainLayout(),
            ),
            const UniLabStatusBar(),
          ],
        ),
      ),
    );
  }
}
