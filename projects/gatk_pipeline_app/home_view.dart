// lib/views/home_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/app_controller.dart';
import '../theme.dart';
import '../widgets/tool_panel.dart';
import '../widgets/pipeline_canvas.dart';
import '../widgets/log_panel.dart';

class HomeView extends GetView<AppController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Row(
              children: [
                Obx(() =>
                    controller.appState.value != AppState.idle
                        ? const ToolPanel()
                        : const SizedBox()),
                Expanded(
                  child: Obx(() {
                    if (controller.appState.value == AppState.idle) {
                      return _WelcomeScreen();
                    }
                    if (controller.appState.value == AppState.loading) {
                      return _LoadingScreen();
                    }
                    return const PipelineCanvas();
                  }),
                ),
              ],
            ),
          ),
          Obx(() => controller.showLogPanel.value
              ? const LogPanel()
              : const SizedBox()),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: AppTheme.accent.withOpacity(0.4)),
                ),
                child: const Icon(Icons.account_tree,
                    size: 14, color: AppTheme.accent),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GATK',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: 1,
                      )),
                  Text('Pipeline Builder',
                      style: GoogleFonts.inter(
                          fontSize: 10, color: AppTheme.textMuted)),
                ],
              ),
            ],
          ),

          const SizedBox(width: 24),

          // JAR selector
          Obx(() => _JarSelector()),

          const Spacer(),

          // Progress bar (when running)
          Obx(() {
            if (!controller.isRunning.value) return const SizedBox();
            return Expanded(
              flex: 0,
              child: SizedBox(
                width: 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Step ${controller.currentRunStep.value + 1}',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 10, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: controller.runProgress.value,
                      backgroundColor: AppTheme.border,
                      valueColor: const AlwaysStoppedAnimation(
                          AppTheme.accentGreen),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(width: 16),

          // Actions
          Obx(() {
            if (controller.appState.value == AppState.idle) {
              return const SizedBox();
            }
            return Row(
              children: [
                IconButton(
                  onPressed: () => controller.showLogPanel.toggle(),
                  icon: Obx(() => Icon(
                        controller.showLogPanel.value
                            ? Icons.terminal
                            : Icons.terminal_outlined,
                        size: 18,
                      )),
                  tooltip: 'Toggle log',
                ),
                IconButton(
                  onPressed: () => _showSavedPipelines(),
                  icon: const Icon(Icons.folder_open_outlined, size: 18),
                  tooltip: 'Load pipeline',
                ),
                IconButton(
                  onPressed: controller.savePipeline,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  tooltip: 'Save pipeline',
                ),
                IconButton(
                  onPressed: () {
                    Get.dialog(_NewPipelineDialog());
                  },
                  icon: const Icon(Icons.add, size: 18),
                  tooltip: 'New pipeline',
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _showSavedPipelines() {
    Get.bottomSheet(
      _SavedPipelinesSheet(),
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: AppTheme.border),
      ),
    );
  }
}

class _JarSelector extends GetView<AppController> {
  @override
  Widget build(BuildContext context) {
    final hasJar = controller.hasJar;

    return GestureDetector(
      onTap: controller.pickJarFile,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: hasJar
              ? AppTheme.accentGreen.withOpacity(0.08)
              : AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: hasJar ? AppTheme.accentGreen.withOpacity(0.4) : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasJar ? Icons.check_circle_outline : Icons.upload_file,
              size: 14,
              color: hasJar ? AppTheme.accentGreen : AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Text(
                hasJar
                    ? controller.jarPath.value.split('/').last
                    : 'Select GATK JAR...',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: hasJar ? AppTheme.textPrimary : AppTheme.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeScreen extends GetView<AppController> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppTheme.accent.withOpacity(0.3), width: 1.5),
            ),
            child: const Icon(Icons.account_tree_outlined,
                size: 36, color: AppTheme.accent),
          ),
          const SizedBox(height: 24),
          Text(
            'GATK Pipeline Builder',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Load a GATK jar to discover tools and build your pipeline',
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: controller.pickJarFile,
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('Select GATK JAR File'),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              textStyle: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Supports GATK 4.x — requires Java on PATH',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.accent),
          const SizedBox(height: 16),
          Text(
            'Discovering GATK tools...',
            style: GoogleFonts.inter(
                fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Running: java -jar gatk.jar --list',
            style: GoogleFonts.jetBrainsMono(
                fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _NewPipelineDialog extends GetView<AppController> {
  @override
  Widget build(BuildContext context) {
    final nameCtrl = TextEditingController(text: 'New Pipeline');
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Text('New Pipeline',
          style: GoogleFonts.spaceGrotesk(
              color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Any unsaved changes will be lost.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Pipeline name'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: Get.back,
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary))),
        ElevatedButton(
          onPressed: () {
            controller.newPipeline();
            if (nameCtrl.text.isNotEmpty) {
              controller.renamePipeline(nameCtrl.text);
            }
            Get.back();
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _SavedPipelinesSheet extends GetView<AppController> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                Text('Saved Pipelines',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const Spacer(),
                IconButton(
                    onPressed: Get.back,
                    icon: const Icon(Icons.close,
                        color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          Expanded(
            child: Obx(() {
              final pipelines = controller.savedPipelines;
              if (pipelines.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder_open,
                          color: AppTheme.textMuted, size: 36),
                      const SizedBox(height: 12),
                      Text('No saved pipelines',
                          style: GoogleFonts.inter(
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: pipelines.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final p = pipelines[i];
                  return Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.account_tree,
                          color: AppTheme.accent),
                      title: Text(p.name,
                          style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary)),
                      subtitle: Text(
                        '${p.steps.length} steps · Updated ${_formatDate(p.updatedAt)}',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppTheme.textMuted),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () => controller.loadPipeline(p),
                            child: const Text('Load'),
                          ),
                          IconButton(
                            onPressed: () =>
                                controller.deleteSavedPipeline(p.id),
                            icon: const Icon(Icons.delete_outline,
                                size: 16, color: AppTheme.accentRed),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
