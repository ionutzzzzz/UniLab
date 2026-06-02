import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class UniLabStatusBar extends StatelessWidget {
  const UniLabStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    // Color changes based on execution state
    final bgColor = appProvider.isExecuting 
        ? const Color(0xFFCA5100) 
        : Theme.of(context).primaryColor;
    const textColor = Colors.white;

    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Status indicator with animation
          if (appProvider.isExecuting) ...[
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ] else ...[
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Status Text
          Text(
            appProvider.isExecuting ? 'Running' : 'Ready',
            style: const TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // File info
          if (appProvider.activeFile != null) ...[
            Text(
              appProvider.activeFile!.name,
              style: const TextStyle(
                color: textColor,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 16),
          ],
          
          const Spacer(),
          
          // Right side indicators
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (appProvider.serverInfo['version'] != null) ...[
                _buildStatusItem('v${appProvider.serverInfo['version']}'),
                _buildDivider(),
              ],
              _buildStatusItem('Ln 1, Col 1'),
              _buildDivider(),
              _buildStatusItem('CRLF'),
              _buildDivider(),
              _buildStatusItem(appProvider.activeFile != null ? 'UTF-8' : 'N/A'),
              _buildDivider(),
              _buildStatusItem('100%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Container(
        width: 1,
        color: Colors.white.withValues(alpha: 0.3),
      ),
    );
  }
}