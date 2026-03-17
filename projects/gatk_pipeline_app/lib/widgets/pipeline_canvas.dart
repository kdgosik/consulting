// lib/widgets/pipeline_canvas.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/app_controller.dart';
import '../models/gatk_tool.dart';
import '../models/pipeline.dart';
import '../theme.dart';
import 'step_config_sheet.dart';

class PipelineCanvas extends GetView<AppController> {
  const PipelineCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final p = controller.pipeline.value;
      if (p == null || p.steps.isEmpty) {
        return _EmptyCanvas();
      }

      return DragTarget<GatkTool>(
        onAcceptWithDetails: (details) =>
            controller.addToolToPipeline(details.data),
        builder: (ctx, candidates, rejected) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: candidates.isNotEmpty
                  ? AppTheme.accent.withOpacity(0.04)
                  : Colors.transparent,
              border: candidates.isNotEmpty
                  ? Border.all(
                      color: AppTheme.accent.withOpacity(0.3), width: 2)
                  : null,
            ),
            child: Column(
              children: [
                _buildPipelineHeader(p),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    buildDefaultDragHandles: false,
                    itemCount: p.steps.length,
                    onReorder: controller.reorderSteps,
                    itemBuilder: (ctx, i) {
                      final step = p.steps[i];
                      return _StepCard(
                        key: ValueKey(step.id),
                        step: step,
                        index: i,
                        total: p.steps.length,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildPipelineHeader(pipeline) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _showRenameDialog(pipeline.name),
                  child: Row(
                    children: [
                      Obx(() => Text(
                            controller.pipeline.value?.name ?? 'Pipeline',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          )),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_outlined,
                          size: 14, color: AppTheme.textMuted),
                    ],
                  ),
                ),
                Obx(() {
                  final steps = controller.pipeline.value?.steps ?? [];
                  final enabled = steps.where((s) => s.enabled).length;
                  return Text(
                    '$enabled of ${steps.length} steps enabled',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.textMuted),
                  );
                }),
              ],
            ),
          ),
          Obx(() => _buildRunButton()),
        ],
      ),
    );
  }

  Widget _buildRunButton() {
    if (controller.isRunning.value) {
      return OutlinedButton.icon(
        onPressed: controller.stopPipeline,
        icon: const Icon(Icons.stop, size: 16, color: AppTheme.accentRed),
        label: Text('Stop',
            style: GoogleFonts.inter(color: AppTheme.accentRed)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.accentRed),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: controller.hasJar && controller.hasPipelineSteps
          ? controller.runPipeline
          : null,
      icon: const Icon(Icons.play_arrow, size: 16),
      label: const Text('Run Pipeline'),
    );
  }

  void _showRenameDialog(String current) {
    final textCtrl = TextEditingController(text: current);
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Rename Pipeline',
            style: GoogleFonts.spaceGrotesk(color: AppTheme.textPrimary)),
        content: TextField(controller: textCtrl),
        actions: [
          TextButton(
              onPressed: Get.back,
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () {
              controller.renamePipeline(textCtrl.text);
              Get.back();
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}

class _EmptyCanvas extends GetView<AppController> {
  @override
  Widget build(BuildContext context) {
    return DragTarget<GatkTool>(
      onAcceptWithDetails: (details) =>
          controller.addToolToPipeline(details.data),
      builder: (ctx, candidates, rejected) {
        final isDragging = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDragging
                ? AppTheme.accent.withOpacity(0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDragging ? AppTheme.accent : AppTheme.border,
              width: isDragging ? 2 : 1,
              style: BorderStyle.solid,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDragging ? Icons.add_circle : Icons.account_tree_outlined,
                  size: 48,
                  color: isDragging ? AppTheme.accent : AppTheme.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  isDragging ? 'Drop to add step' : 'Build your pipeline',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDragging
                        ? AppTheme.accent
                        : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isDragging
                      ? ''
                      : 'Drag tools from the panel or click to add them',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StepCard extends GetView<AppController> {
  final PipelineStep step;
  final int index;
  final int total;

  const _StepCard({
    super.key,
    required this.step,
    required this.index,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = AppTheme.categoryColor(step.tool.category);
    final isLast = index == total - 1;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: step.enabled ? AppTheme.surface : AppTheme.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: step.enabled ? catColor.withOpacity(0.4) : AppTheme.border,
            ),
          ),
          child: Column(
            children: [
              _buildHeader(catColor),
              if (step.enabled && step.tool.arguments.isNotEmpty)
                _buildArgPreview(),
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 1.5,
                  height: 24,
                  color: AppTheme.border,
                ),
              ],
            ),
          ),
        if (isLast) const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHeader(Color catColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_indicator,
                color: AppTheme.textMuted, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: catColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: catColor.withOpacity(0.3)),
            ),
            child: Text(
              '${index + 1}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: catColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.tool.name,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: step.enabled
                        ? AppTheme.textPrimary
                        : AppTheme.textMuted,
                  ),
                ),
                Text(
                  step.tool.category,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: catColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _showConfigSheet(),
                icon: const Icon(Icons.tune, size: 16),
                tooltip: 'Configure',
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              Switch(
                value: step.enabled,
                onChanged: (_) => controller.toggleStepEnabled(step.id),
                activeColor: AppTheme.accentGreen,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              IconButton(
                onPressed: () => controller.removeStep(step.id),
                icon: const Icon(Icons.close, size: 16),
                color: AppTheme.accentRed.withOpacity(0.7),
                tooltip: 'Remove',
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArgPreview() {
    final configuredArgs =
        step.tool.arguments.where((a) => a.value.isNotEmpty).toList();
    if (configuredArgs.isEmpty) {
      return InkWell(
        onTap: _showConfigSheet,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_outlined,
                  size: 13, color: AppTheme.accentOrange),
              const SizedBox(width: 6),
              Text(
                'No arguments configured — tap to configure',
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppTheme.accentOrange),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: configuredArgs.take(4).map((arg) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              '--${arg.name} ${arg.type == 'boolean' ? '' : arg.value}',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 10, color: AppTheme.textSecondary),
            ),
          );
        }).toList()
          ..addAll(configuredArgs.length > 4
              ? [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '+${configuredArgs.length - 4} more',
                      style: GoogleFonts.inter(
                          fontSize: 10, color: AppTheme.textMuted),
                    ),
                  )
                ]
              : []),
      ),
    );
  }

  void _showConfigSheet() {
    Get.bottomSheet(
      StepConfigSheet(step: step),
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: AppTheme.border),
      ),
    );
  }
}
