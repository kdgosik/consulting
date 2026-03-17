// lib/widgets/step_config_sheet.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../controllers/app_controller.dart';
import '../models/gatk_tool.dart';
import '../models/pipeline.dart';
import '../theme.dart';

class StepConfigSheet extends GetView<AppController> {
  final PipelineStep step;
  const StepConfigSheet({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final catColor = AppTheme.categoryColor(step.tool.category);
    final maxH = MediaQuery.of(context).size.height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(catColor),
          const Divider(height: 1, color: AppTheme.border),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (step.tool.description != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              size: 14, color: AppTheme.accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              step.tool.description!,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  _buildIntrospectButton(),
                  const SizedBox(height: 16),
                  if (step.tool.arguments.isEmpty)
                    _buildNoArgsState()
                  else
                    _buildArgsList(),
                  const SizedBox(height: 24),
                  _buildCommandPreview(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 36,
      height: 4,
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(Color catColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: catColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.tool.name,
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                Text(step.tool.category,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: catColor.withOpacity(0.8))),
              ],
            ),
          ),
          IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.close, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildIntrospectButton() {
    return Obx(() {
      final loading =
          controller.appState.value == AppState.loading;
      return OutlinedButton.icon(
        onPressed: loading
            ? null
            : () => controller.introspectToolArgs(step.id),
        icon: loading
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5))
            : const Icon(Icons.refresh, size: 14),
        label: Text(loading ? 'Loading args...' : 'Introspect args from JAR',
            style: GoogleFonts.inter(fontSize: 12)),
      );
    });
  }

  Widget _buildNoArgsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const Icon(Icons.settings_outlined,
                color: AppTheme.textMuted, size: 32),
            const SizedBox(height: 8),
            Text('No arguments loaded',
                style: GoogleFonts.inter(color: AppTheme.textMuted)),
            const SizedBox(height: 4),
            Text('Click "Introspect args" to load from JAR',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildArgsList() {
    final required =
        step.tool.arguments.where((a) => a.required).toList();
    final optional =
        step.tool.arguments.where((a) => !a.required).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (required.isNotEmpty) ...[
          _sectionLabel('Required Arguments', AppTheme.accentRed),
          const SizedBox(height: 8),
          ...required.map((a) => _ArgField(step: step, arg: a)),
          const SizedBox(height: 16),
        ],
        if (optional.isNotEmpty) ...[
          _sectionLabel('Optional Arguments', AppTheme.textSecondary),
          const SizedBox(height: 8),
          ...optional.map((a) => _ArgField(step: step, arg: a)),
        ],
      ],
    );
  }

  Widget _sectionLabel(String label, Color color) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: color.withOpacity(0.3))),
      ],
    );
  }

  Widget _buildCommandPreview() {
    return Obx(() {
      // Recompute from current pipeline state
      final currentStep = controller.pipeline.value?.steps
          .firstWhereOrNull((s) => s.id == step.id);
      if (currentStep == null) return const SizedBox();

      final args = controller.hasJar
          ? currentStep.buildArgs(controller.jarPath.value).join(' ')
          : '(select JAR first)';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Command Preview', AppTheme.accent),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.bg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              'java $args',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: AppTheme.accentGreen,
                height: 1.6,
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _ArgField extends GetView<AppController> {
  final PipelineStep step;
  final GatkArgument arg;

  const _ArgField({required this.step, required this.arg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '--${arg.name}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: arg.required
                      ? AppTheme.accentOrange
                      : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  arg.type,
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 10, color: AppTheme.accent),
                ),
              ),
              if (arg.required)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text('required',
                      style: GoogleFonts.inter(
                          fontSize: 10, color: AppTheme.accentRed)),
                ),
            ],
          ),
          if (arg.description != null) ...[
            const SizedBox(height: 2),
            Text(
              arg.description!,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
          const SizedBox(height: 6),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    if (arg.type == 'boolean') {
      return Row(
        children: [
          Obx(() {
            final currentStep = controller.pipeline.value?.steps
                .firstWhereOrNull((s) => s.id == step.id);
            final currentArg = currentStep?.tool.arguments
                .firstWhereOrNull((a) => a.name == arg.name);
            final val = currentArg?.value == 'true';
            return Switch(
              value: val,
              onChanged: (v) => controller.updateStepArgument(
                  step.id, arg.name, v ? 'true' : ''),
              activeColor: AppTheme.accentGreen,
            );
          }),
        ],
      );
    }

    if (arg.type == 'enum' && arg.enumValues != null) {
      return Obx(() {
        final currentStep = controller.pipeline.value?.steps
            .firstWhereOrNull((s) => s.id == step.id);
        final currentArg = currentStep?.tool.arguments
            .firstWhereOrNull((a) => a.name == arg.name);
        final currentVal = currentArg?.value ?? '';

        return DropdownButtonFormField<String>(
          value: arg.enumValues!.contains(currentVal) ? currentVal : null,
          hint: Text('Select ${arg.name}',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppTheme.textMuted)),
          dropdownColor: AppTheme.surfaceHigh,
          style: GoogleFonts.jetBrainsMono(
              fontSize: 12, color: AppTheme.textPrimary),
          decoration: const InputDecoration(),
          items: arg.enumValues!
              .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text(v),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              controller.updateStepArgument(step.id, arg.name, v);
            }
          },
        );
      });
    }

    if (arg.type == 'file') {
      return Row(
        children: [
          Expanded(
            child: Obx(() {
              final currentStep = controller.pipeline.value?.steps
                  .firstWhereOrNull((s) => s.id == step.id);
              final currentArg = currentStep?.tool.arguments
                  .firstWhereOrNull((a) => a.name == arg.name);

              return TextField(
                controller: TextEditingController(
                    text: currentArg?.value ?? ''),
                onChanged: (v) =>
                    controller.updateStepArgument(step.id, arg.name, v),
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 12, color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: '/path/to/file',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.folder_open, size: 16),
                    onPressed: () => _pickFile(),
                    color: AppTheme.accent,
                  ),
                ),
              );
            }),
          ),
        ],
      );
    }

    // Default string/int/float input
    return Obx(() {
      final currentStep = controller.pipeline.value?.steps
          .firstWhereOrNull((s) => s.id == step.id);
      final currentArg = currentStep?.tool.arguments
          .firstWhereOrNull((a) => a.name == arg.name);

      return TextField(
        controller:
            TextEditingController(text: currentArg?.value ?? ''),
        keyboardType: arg.type == 'int' || arg.type == 'float'
            ? TextInputType.number
            : TextInputType.text,
        onChanged: (v) =>
            controller.updateStepArgument(step.id, arg.name, v),
        style: GoogleFonts.jetBrainsMono(
            fontSize: 12, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: arg.defaultValue ?? 'Enter ${arg.type} value...',
        ),
      );
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select file for --${arg.name}',
    );
    if (result != null && result.files.single.path != null) {
      controller.updateStepArgument(
          step.id, arg.name, result.files.single.path!);
    }
  }
}
