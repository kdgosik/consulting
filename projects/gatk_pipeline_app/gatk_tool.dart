// lib/models/gatk_tool.dart

class GatkArgument {
  final String name;
  final String type; // 'string' | 'int' | 'float' | 'boolean' | 'file' | 'enum'
  final String? description;
  final bool required;
  final List<String>? enumValues;
  final String? defaultValue;
  String value;

  GatkArgument({
    required this.name,
    required this.type,
    this.description,
    this.required = false,
    this.enumValues,
    this.defaultValue,
    String? value,
  }) : value = value ?? defaultValue ?? '';

  GatkArgument copyWith({String? value}) => GatkArgument(
        name: name,
        type: type,
        description: description,
        required: required,
        enumValues: enumValues,
        defaultValue: defaultValue,
        value: value ?? this.value,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'description': description,
        'required': required,
        'enumValues': enumValues,
        'defaultValue': defaultValue,
        'value': value,
      };

  factory GatkArgument.fromJson(Map<String, dynamic> json) => GatkArgument(
        name: json['name'],
        type: json['type'] ?? 'string',
        description: json['description'],
        required: json['required'] ?? false,
        enumValues: (json['enumValues'] as List?)?.cast<String>(),
        defaultValue: json['defaultValue'],
        value: json['value'] ?? '',
      );
}

class GatkTool {
  final String name;
  final String category;
  final String? description;
  final List<GatkArgument> arguments;

  GatkTool({
    required this.name,
    required this.category,
    this.description,
    required this.arguments,
  });

  GatkTool copyWithValues(Map<String, String> argValues) {
    return GatkTool(
      name: name,
      category: category,
      description: description,
      arguments: arguments.map((a) {
        final v = argValues[a.name];
        return v != null ? a.copyWith(value: v) : a;
      }).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'description': description,
        'arguments': arguments.map((a) => a.toJson()).toList(),
      };

  factory GatkTool.fromJson(Map<String, dynamic> json) => GatkTool(
        name: json['name'],
        category: json['category'] ?? 'Uncategorized',
        description: json['description'],
        arguments: (json['arguments'] as List? ?? [])
            .map((a) => GatkArgument.fromJson(a))
            .toList(),
      );
}
