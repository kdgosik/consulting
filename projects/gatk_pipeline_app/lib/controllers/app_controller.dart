// lib/controllers/app_controller.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/gatk_tool.dart';
import '../models/pipeline.dart';
import '../services/gatk_service.dart';

enum AppState { idle, loading, ready, running }

class LogEntry {
  final String message;
  final bool isError;
  final DateTime timestamp;
  final int stepIndex;

  LogEntry({
    required this.message,
    required this.isError,
    required this.timestamp,
    required this.stepIndex,
  });
}

class AppController extends GetxController {
  // ─── State ────────────────────────────────────────────────
  final appState = AppState.idle.obs;
  final jarPath = ''.obs;
  final availableTools = <GatkTool>[].obs;
  final toolsByCategory = <String, List<GatkTool>>{}.obs;
  final selectedCategory = ''.obs;
  final toolSearch = ''.obs;

  // ─── Pipeline ─────────────────────────────────────────────
  final pipeline = Rxn<Pipeline>();
  final savedPipelines = <Pipeline>[].obs;

  // ─── Run State ────────────────────────────────────────────
  final logEntries = <LogEntry>[].obs;
  final currentRunStep = 0.obs;
  final runProgress = 0.0.obs;
  final isRunning = false.obs;
  Process? _runningProcess;

  // ─── UI ───────────────────────────────────────────────────
  final showToolPanel = true.obs;
  final showLogPanel = false.obs;

  final _uuid = const Uuid();

  @override
  void onInit() {
    super.onInit();
    _loadSavedPipelines();
    _createNewPipeline();
  }

  // ─── JAR Management ───────────────────────────────────────

  Future<void> pickJarFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jar'],
      dialogTitle: 'Select GATK JAR file',
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      await loadJar(path);
    }
  }

  Future<void> loadJar(String path) async {
    jarPath.value = path;
    appState.value = AppState.loading;
    availableTools.clear();
    toolsByCategory.clear();

    try {
      final tools = await GatkService.discoverTools(path);
      availableTools.assignAll(tools);
      _groupToolsByCategory(tools);

      if (toolsByCategory.isNotEmpty) {
        selectedCategory.value = toolsByCategory.keys.first;
      }

      appState.value = AppState.ready;
      Get.snackbar(
        'JAR Loaded',
        '${tools.length} GATK tools discovered',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E4A2E),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      appState.value = AppState.idle;
      Get.snackbar(
        'Error Loading JAR',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4A1E1E),
        colorText: Colors.white,
      );
    }
  }

  void _groupToolsByCategory(List<GatkTool> tools) {
    final grouped = <String, List<GatkTool>>{};
    for (final tool in tools) {
      grouped.putIfAbsent(tool.category, () => []).add(tool);
    }
    toolsByCategory.assignAll(grouped);
  }

  // ─── Pipeline Management ──────────────────────────────────

  void _createNewPipeline() {
    pipeline.value = Pipeline(
      id: _uuid.v4(),
      name: 'New Pipeline',
      steps: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void addToolToPipeline(GatkTool tool) {
    if (pipeline.value == null) _createNewPipeline();

    final step = PipelineStep(
      id: _uuid.v4(),
      tool: tool,
    );

    final updated = pipeline.value!.copyWith(
      steps: [...pipeline.value!.steps, step],
    );
    pipeline.value = updated;

    Get.snackbar(
      '+ ${tool.name}',
      'Added to pipeline',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
      backgroundColor: const Color(0xFF1B3A4B),
      colorText: Colors.white,
    );
  }

  void removeStep(String stepId) {
    if (pipeline.value == null) return;
    final updated = pipeline.value!.copyWith(
      steps: pipeline.value!.steps.where((s) => s.id != stepId).toList(),
    );
    pipeline.value = updated;
  }

  void reorderSteps(int oldIndex, int newIndex) {
    if (pipeline.value == null) return;
    final steps = [...pipeline.value!.steps];
    if (newIndex > oldIndex) newIndex--;
    final step = steps.removeAt(oldIndex);
    steps.insert(newIndex, step);
    pipeline.value = pipeline.value!.copyWith(steps: steps);
  }

  void toggleStepEnabled(String stepId) {
    if (pipeline.value == null) return;
    final steps = pipeline.value!.steps.map((s) {
      if (s.id == stepId) {
        return PipelineStep(
          id: s.id,
          tool: s.tool,
          enabled: !s.enabled,
          label: s.label,
        );
      }
      return s;
    }).toList();
    pipeline.value = pipeline.value!.copyWith(steps: steps);
  }

  void updateStepArgument(String stepId, String argName, String value) {
    if (pipeline.value == null) return;
    final steps = pipeline.value!.steps.map((s) {
      if (s.id == stepId) {
        final updatedArgs = s.tool.arguments.map((a) {
          if (a.name == argName) return a.copyWith(value: value);
          return a;
        }).toList();
        final updatedTool = GatkTool(
          name: s.tool.name,
          category: s.tool.category,
          description: s.tool.description,
          arguments: updatedArgs,
        );
        return PipelineStep(
          id: s.id,
          tool: updatedTool,
          enabled: s.enabled,
          label: s.label,
        );
      }
      return s;
    }).toList();
    pipeline.value = pipeline.value!.copyWith(steps: steps);
  }

  void renamePipeline(String name) {
    pipeline.value = pipeline.value?.copyWith(name: name);
  }

  Future<void> introspectToolArgs(String stepId) async {
    if (pipeline.value == null || jarPath.value.isEmpty) return;

    final stepIdx =
        pipeline.value!.steps.indexWhere((s) => s.id == stepId);
    if (stepIdx == -1) return;

    final step = pipeline.value!.steps[stepIdx];
    appState.value = AppState.loading;

    try {
      final enriched =
          await GatkService.introspectTool(jarPath.value, step.tool);
      final steps = [...pipeline.value!.steps];
      steps[stepIdx] = PipelineStep(
        id: step.id,
        tool: enriched,
        enabled: step.enabled,
        label: step.label,
      );
      pipeline.value = pipeline.value!.copyWith(steps: steps);
    } finally {
      appState.value = AppState.ready;
    }
  }

  // ─── Save / Load Pipelines ────────────────────────────────

  Future<void> savePipeline() async {
    if (pipeline.value == null) return;

    final idx = savedPipelines.indexWhere((p) => p.id == pipeline.value!.id);
    if (idx >= 0) {
      savedPipelines[idx] = pipeline.value!;
    } else {
      savedPipelines.add(pipeline.value!);
    }

    await _persistPipelines();
    Get.snackbar('Saved', 'Pipeline "${pipeline.value!.name}" saved',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2));
  }

  Future<void> loadPipeline(Pipeline p) async {
    pipeline.value = p;
    Get.back();
  }

  void newPipeline() {
    _createNewPipeline();
  }

  Future<void> deleteSavedPipeline(String id) async {
    savedPipelines.removeWhere((p) => p.id == id);
    await _persistPipelines();
  }

  Future<void> _persistPipelines() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/gatk_pipelines.json');
      final json =
          jsonEncode(savedPipelines.map((p) => p.toJson()).toList());
      await file.writeAsString(json);
    } catch (_) {}
  }

  Future<void> _loadSavedPipelines() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/gatk_pipelines.json');
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString()) as List;
        savedPipelines
            .assignAll(json.map((j) => Pipeline.fromJson(j)).toList());
      }
    } catch (_) {}
  }

  // ─── Run Pipeline ─────────────────────────────────────────

  Future<void> runPipeline() async {
    if (pipeline.value == null || jarPath.isEmpty) return;

    final activeSteps =
        pipeline.value!.steps.where((s) => s.enabled).toList();
    if (activeSteps.isEmpty) {
      Get.snackbar('No Steps', 'Add steps to the pipeline first',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isRunning.value = true;
    showLogPanel.value = true;
    logEntries.clear();
    currentRunStep.value = 0;
    runProgress.value = 0;

    try {
      for (var i = 0; i < activeSteps.length; i++) {
        final step = activeSteps[i];
        currentRunStep.value = i;
        runProgress.value = i / activeSteps.length;

        _log('═══ Step ${i + 1}/${activeSteps.length}: ${step.tool.name} ═══', false, i);

        final args = step.buildArgs(jarPath.value);
        _log('Running: java ${args.join(' ')}', false, i);

        final exitCode = await GatkService.runPipelineStep(
          jarPath: jarPath.value,
          args: args,
          onLog: (line, isError) => _log(line, isError, i),
        );

        if (exitCode != 0) {
          _log('Step exited with code $exitCode', true, i);
          if (i < activeSteps.length - 1) {
            _log('Stopping pipeline due to non-zero exit code', true, i);
            break;
          }
        } else {
          _log('✓ Step ${i + 1} completed successfully', false, i);
        }
      }
    } finally {
      isRunning.value = false;
      runProgress.value = 1.0;
      _log('Pipeline finished.', false, currentRunStep.value);
    }
  }

  void stopPipeline() {
    _runningProcess?.kill();
    isRunning.value = false;
    _log('Pipeline stopped by user.', true, currentRunStep.value);
  }

  void _log(String message, bool isError, int stepIndex) {
    logEntries.add(LogEntry(
      message: message,
      isError: isError,
      timestamp: DateTime.now(),
      stepIndex: stepIndex,
    ));
  }

  void clearLog() => logEntries.clear();

  // ─── Getters ──────────────────────────────────────────────

  List<GatkTool> get filteredTools {
    final q = toolSearch.value.toLowerCase();
    final cat = selectedCategory.value;
    final tools = cat.isEmpty
        ? availableTools
        : (toolsByCategory[cat] ?? <GatkTool>[]);
    if (q.isEmpty) return tools;
    return tools
        .where((t) =>
            t.name.toLowerCase().contains(q) ||
            (t.description?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  bool get hasJar => jarPath.value.isNotEmpty;
  bool get hasPipelineSteps =>
      (pipeline.value?.steps.isNotEmpty) ?? false;
}
