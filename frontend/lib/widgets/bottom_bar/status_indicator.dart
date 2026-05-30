import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

/// Enhanced status bar with real-time indicators
class StatusIndicator extends StatelessWidget {
  const StatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        // Determine color based on state
        final statusColor = appProvider.isExecuting
            ? const Color(0xFFCA5100)
            : const Color(0xFF007ACC);

        return Container(
          height: 24,
          decoration: BoxDecoration(
            color: statusColor,
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
              // Animated status indicator
              _buildStatusIndicator(appProvider.isExecuting),
              const SizedBox(width: 8),
              
              // Status text
              Text(
                appProvider.isExecuting ? 'Executing...' : 'Ready',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Current file
              if (appProvider.activeFile != null)
                Expanded(
                  child: Text(
                    appProvider.activeFile!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              
              const Spacer(),
              
              // Right indicators
              const Text(
                'Ln 1, Col 1',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
              _buildDivider(),
              const Text(
                'UTF-8',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
              _buildDivider(),
              const Text(
                'CRLF',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(bool isExecuting) {
    if (isExecuting) {
      return const SizedBox(
        width: 10,
        height: 10,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      );
    }
    
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Container(
        width: 1,
        color: Colors.white.withOpacity(0.3),
      ),
    );
  }
}
