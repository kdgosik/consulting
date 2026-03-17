// lib/models/pipeline.dart

import 'gatk_tool.dart';

class PipelineStep {
  final String id;
  final GatkTool tool;
  bool enabled;
  String? label;

  PipelineStep({
    required this.id,
    required this.tool,
    this.enabled = true,
    this.label,
  });

  String get displayLabel => label ?? tool.name;

  /// Build the CLI argument list for this step
  List<String> buildArgs(String jarPath) {
    final args = <String>['-jar', jarPath, tool.name];
    for (final arg in tool.arguments) {
      if (arg.value.isNotEmpty) {
        args.add('--${arg.name}');
        if (arg.type != 'boolean') {
          args.add(arg.value);
        }
      }
    }
    return args;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tool': tool.toJson(),
        'enabled': enabled,
        'label': label,
      };

  factory PipelineStep.fromJson(Map<String, dynamic> json) => PipelineStep(
        id: json['id'],
        tool: GatkTool.fromJson(json['tool']),
        enabled: json['enabled'] ?? true,
        label: json['label'],
      );
}

class Pipeline {
  String id;
  String name;
  String? description;
  List<PipelineStep> steps;
  DateTime createdAt;
  DateTime updatedAt;

  Pipeline({
    required this.id,
    required this.name,
    this.description,
    required this.steps,
    required this.createdAt,
    required this.updatedAt,
  });

  Pipeline copyWith({
    String? name,
    String? description,
    List<PipelineStep>? steps,
  }) =>
      Pipeline(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        steps: steps ?? this.steps,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'steps': steps.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Pipeline.fromJson(Map<String, dynamic> json) => Pipeline(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        steps: (json['steps'] as List? ?? [])
            .map((s) => PipelineStep.fromJson(s))
            .toList(),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}
