import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
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
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyP, control: true, shift: true): () {
          CommandPalette.show(context);
        },
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          appProvider.saveActiveFile();
        },
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          appProvider.addNewFile();
        },
        const SingleActivator(LogicalKeyboardKey.keyW, control: true): () {
          if (appProvider.activeFileIndex >= 0) {
            appProvider.closeFile(appProvider.activeFileIndex);
          }
        },
        const SingleActivator(LogicalKeyboardKey.f5): () {
          appProvider.runActiveFile();
        },
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
          appProvider.runActiveFile();
        },
      },
      child: Focus(
        autofocus: true,
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
      ),
    );
  }
}

