// lib/widgets/log_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/app_controller.dart';
import '../theme.dart';

class LogPanel extends GetView<AppController> {
  const LogPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: const BoxDecoration(
        color: AppTheme.bg,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildLogList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Obx(() {
            final running = controller.isRunning.value;
            return Row(
              children: [
                if (running) ...[
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppTheme.accentGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RUNNING — Step ${controller.currentRunStep.value + 1}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentGreen,
                      letterSpacing: 1,
                    ),
                  ),
                ] else ...[
                  const Icon(Icons.terminal,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'OUTPUT LOG',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ],
            );
          }),
          const Spacer(),
          Obx(() => Text(
                '${controller.logEntries.length} lines',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 10, color: AppTheme.textMuted),
              )),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _copyLog,
            icon: const Icon(Icons.copy, size: 14),
            tooltip: 'Copy log',
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
          IconButton(
            onPressed: controller.clearLog,
            icon: const Icon(Icons.delete_outline, size: 14),
            tooltip: 'Clear',
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
          IconButton(
            onPressed: () => controller.showLogPanel.value = false,
            icon: const Icon(Icons.keyboard_arrow_down, size: 16),
            tooltip: 'Hide log',
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    return Obx(() {
      final entries = controller.logEntries;
      if (entries.isEmpty) {
        return Center(
          child: Text('No output yet. Run the pipeline to see logs.',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 11, color: AppTheme.textMuted)),
        );
      }

      final scrollCtrl = ScrollController();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollCtrl.hasClients) {
          scrollCtrl.jumpTo(scrollCtrl.position.maxScrollExtent);
        }
      });

      return ListView.builder(
        controller: scrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: entries.length,
        itemBuilder: (ctx, i) {
          final entry = entries[i];
          return _LogLine(entry: entry);
        },
      );
    });
  }

  void _copyLog() {
    final text = controller.logEntries
        .map((e) => '[${e.timestamp.toIso8601String()}] ${e.message}')
        .join('\n');
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar('Copied', 'Log copied to clipboard',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1));
  }
}

class _LogLine extends StatelessWidget {
  final LogEntry entry;
  const _LogLine({required this.entry});

  @override
  Widget build(BuildContext context) {
    Color color;
    String prefix;

    if (entry.isError) {
      color = AppTheme.accentRed;
      prefix = 'ERR';
    } else if (entry.message.startsWith('═══')) {
      color = AppTheme.accent;
      prefix = 'INF';
    } else if (entry.message.startsWith('✓')) {
      color = AppTheme.accentGreen;
      prefix = 'OK ';
    } else {
      color = AppTheme.textSecondary;
      prefix = 'OUT';
    }

    final time =
        '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$time ',
            style: GoogleFonts.jetBrainsMono(
                fontSize: 10, color: AppTheme.textMuted),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              prefix,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.message,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
