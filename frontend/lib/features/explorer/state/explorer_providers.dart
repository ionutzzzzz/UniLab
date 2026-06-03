import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/file_node.dart';

final explorerRootProvider = FutureProvider<FileNode>((ref) async {
  // Mock data for initial UI
  await Future.delayed(const Duration(milliseconds: 200)); // Simulate IO
  
  return const FileNode(
    path: '/',
    name: 'project_root',
    isDirectory: true,
    children: [
      FileNode(
        path: '/src',
        name: 'src',
        isDirectory: true,
        children: [
          FileNode(path: '/src/main.m', name: 'main.m'),
          FileNode(path: '/src/utils.m', name: 'utils.m'),
        ],
      ),
      FileNode(
        path: '/data',
        name: 'data',
        isDirectory: true,
        children: [
          FileNode(path: '/data/dataset.csv', name: 'dataset.csv'),
        ],
      ),
      FileNode(path: '/README.md', name: 'README.md'),
    ],
  );
});

final recentFilesProvider = StateProvider<List<FileNode>>((ref) {
  return [
    const FileNode(path: '/src/main.m', name: 'main.m'),
    const FileNode(path: '/README.md', name: 'README.md'),
    const FileNode(path: '/data/dataset.csv', name: 'dataset.csv'),
  ];
});
