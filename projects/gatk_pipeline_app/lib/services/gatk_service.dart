// lib/services/gatk_service.dart

import 'dart:convert';
import 'dart:io';
import '../models/gatk_tool.dart';

class GatkService {
  /// Discovers all available tools from a GATK jar by running:
  ///   java -jar <jar> --list
  /// Returns a list of [GatkTool] with their arguments parsed.
  static Future<List<GatkTool>> discoverTools(String jarPath) async {
    try {
      final result = await Process.run(
        'java',
        ['-jar', jarPath, '--list'],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      final output = result.stdout as String;
      return _parseToolList(output, jarPath);
    } catch (e) {
      throw GatkServiceException('Failed to introspect GATK jar: $e');
    }
  }

  /// Parses the --list output from GATK to extract tool names + categories
  static List<GatkTool> _parseToolList(String output, String jarPath) {
    final tools = <GatkTool>[];
    String currentCategory = 'Uncategorized';

    for (final line in output.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Category headers look like "-------------- Tools ---------------"
      if (trimmed.startsWith('---') || trimmed.endsWith('---')) {
        final cat = trimmed.replaceAll(RegExp(r'-+'), '').trim();
        if (cat.isNotEmpty) currentCategory = cat;
        continue;
      }

      // Tool lines are usually indented or start with a name
      if (!trimmed.startsWith('-') && trimmed.contains(RegExp(r'[A-Z]'))) {
        final parts = trimmed.split(RegExp(r'\s{2,}'));
        final toolName = parts.first.trim();

        if (toolName.isNotEmpty && !toolName.contains(' ')) {
          tools.add(GatkTool(
            name: toolName,
            category: currentCategory,
            description: parts.length > 1 ? parts[1].trim() : null,
            arguments: [],
          ));
        }
      }
    }

    // If parsing fails, return a helpful set of well-known GATK4 tools
    if (tools.isEmpty) {
      return _wellKnownTools();
    }

    return tools;
  }

  /// Introspect a specific tool's arguments via `java -jar <jar> <tool> --help`
  static Future<GatkTool> introspectTool(String jarPath, GatkTool tool) async {
    try {
      final result = await Process.run(
        'java',
        ['-jar', jarPath, tool.name, '--help'],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      final helpText = '${result.stdout}\n${result.stderr}';
      final args = _parseHelpArgs(helpText);

      return GatkTool(
        name: tool.name,
        category: tool.category,
        description: tool.description,
        arguments: args,
      );
    } catch (e) {
      // Return tool with common args as fallback
      return GatkTool(
        name: tool.name,
        category: tool.category,
        description: tool.description,
        arguments: _commonArgs(),
      );
    }
  }

  static List<GatkArgument> _parseHelpArgs(String helpText) {
    final args = <GatkArgument>[];
    final argPattern = RegExp(
        r'--(\w[\w-]*)\s+(\w+)?\s*(?:\[.*?\])?\s*(.*?)(?=\n--|$)',
        multiLine: true);

    for (final match in argPattern.allMatches(helpText)) {
      final name = match.group(1)!;
      final type = _normalizeType(match.group(2) ?? 'string');
      final desc = match.group(3)?.trim();

      if (_shouldSkipArg(name)) continue;

      args.add(GatkArgument(
        name: name,
        type: type,
        description: desc,
        required: helpText.contains('--$name') &&
            helpText.contains('Required') &&
            helpText.indexOf('Required') <
                helpText.indexOf('--$name') + 200,
      ));
    }

    return args.isEmpty ? _commonArgs() : args;
  }

  static String _normalizeType(String raw) {
    switch (raw.toLowerCase()) {
      case 'int':
      case 'integer':
        return 'int';
      case 'float':
      case 'double':
        return 'float';
      case 'boolean':
      case 'bool':
        return 'boolean';
      case 'file':
      case 'path':
        return 'file';
      default:
        return 'string';
    }
  }

  static bool _shouldSkipArg(String name) {
    const skip = {'help', 'version', 'verbosity', 'QUIET'};
    return skip.contains(name);
  }

  /// Run a sequence of pipeline steps.
  /// Yields log lines through [onLog].
  static Future<int> runPipelineStep({
    required String jarPath,
    required List<String> args,
    required void Function(String line, bool isError) onLog,
  }) async {
    final proc = await Process.start('java', args);

    proc.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => onLog(line, false));

    proc.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => onLog(line, true));

    return proc.exitCode;
  }

  static List<GatkArgument> _commonArgs() => [
        GatkArgument(
            name: 'input', type: 'file', description: 'Input file', required: true),
        GatkArgument(
            name: 'output', type: 'file', description: 'Output file', required: true),
        GatkArgument(
            name: 'reference',
            type: 'file',
            description: 'Reference genome (.fasta)'),
        GatkArgument(
            name: 'tmp-dir',
            type: 'string',
            description: 'Temporary directory path'),
      ];

  /// Well-known GATK4 tools as fallback when jar introspection fails
  static List<GatkTool> _wellKnownTools() => [
        GatkTool(
          name: 'HaplotypeCaller',
          category: 'Variant Calling',
          description: 'Call germline SNPs and indels via local re-assembly',
          arguments: [
            GatkArgument(
                name: 'input',
                type: 'file',
                description: 'Input BAM/CRAM',
                required: true),
            GatkArgument(
                name: 'output',
                type: 'file',
                description: 'Output VCF',
                required: true),
            GatkArgument(
                name: 'reference',
                type: 'file',
                description: 'Reference FASTA',
                required: true),
            GatkArgument(
                name: 'emit-ref-confidence',
                type: 'enum',
                description: 'Reference confidence mode',
                enumValues: ['NONE', 'BP_RESOLUTION', 'GVCF'],
                defaultValue: 'NONE'),
            GatkArgument(
                name: 'sample-name',
                type: 'string',
                description: 'Override sample name'),
          ],
        ),
        GatkTool(
          name: 'GenotypeGVCFs',
          category: 'Variant Calling',
          description: 'Perform joint genotyping on GVCFs',
          arguments: [
            GatkArgument(
                name: 'variant',
                type: 'file',
                description: 'Input GVCF',
                required: true),
            GatkArgument(
                name: 'output',
                type: 'file',
                description: 'Output VCF',
                required: true),
            GatkArgument(
                name: 'reference',
                type: 'file',
                description: 'Reference FASTA',
                required: true),
          ],
        ),
        GatkTool(
          name: 'BaseRecalibrator',
          category: 'Base Quality Score Recalibration',
          description: 'Generate recalibration table for BQSR',
          arguments: [
            GatkArgument(
                name: 'input',
                type: 'file',
                description: 'Input BAM',
                required: true),
            GatkArgument(
                name: 'output',
                type: 'file',
                description: 'Output recalibration table',
                required: true),
            GatkArgument(
                name: 'reference',
                type: 'file',
                description: 'Reference FASTA',
                required: true),
            GatkArgument(
                name: 'known-sites',
                type: 'file',
                description: 'Known variant sites VCF'),
          ],
        ),
        GatkTool(
          name: 'ApplyBQSR',
          category: 'Base Quality Score Recalibration',
          description: 'Apply base quality score recalibration',
          arguments: [
            GatkArgument(
                name: 'input',
                type: 'file',
                description: 'Input BAM',
                required: true),
            GatkArgument(
                name: 'output',
                type: 'file',
                description: 'Output BAM',
                required: true),
            GatkArgument(
                name: 'reference',
                type: 'file',
                description: 'Reference FASTA',
                required: true),
            GatkArgument(
                name: 'bqsr-recal-file',
                type: 'file',
                description: 'Recalibration table',
                required: true),
          ],
        ),
        GatkTool(
          name: 'MarkDuplicates',
          category: 'Read Data Manipulation',
          description: 'Mark duplicate reads',
          arguments: [
            GatkArgument(
                name: 'input',
                type: 'file',
                description: 'Input BAM',
                required: true),
            GatkArgument(
                name: 'output',
                type: 'file',
                description: 'Output BAM',
                required: true),
            GatkArgument(
                name: 'metrics-file',
                type: 'file',
                description: 'Duplication metrics output',
                required: true),
            GatkArgument(
                name: 'remove-duplicates',
                type: 'boolean',
                description: 'Remove duplicates instead of marking'),
          ],
        ),
        GatkTool(
          name: 'SortSam',
          category: 'Read Data Manipulation',
          description: 'Sorts a SAM/BAM/CRAM file',
          arguments: [
            GatkArgument(
                name: 'input',
                type: 'file',
                description: 'Input SAM/BAM',
                required: true),
            GatkArgument(
                name: 'output',
                type: 'file',
                description: 'Output sorted BAM',
                required: true),
            GatkArgument(
                name: 'sort-order',
                type: 'enum',
                description: 'Sort order',
                enumValues: [
                  'coordinate',
                  'queryname',
                  'duplicate',
                  'unsorted'
                ],
                defaultValue: 'coordinate'),
          ],
        ),
        GatkTool(
          name: 'SelectVariants',
          category: 'Variant Filtering',
          description: 'Select a subset of variants from a VCF',
          arguments: [
            GatkArgument(
                name: 'variant',
                type: 'file',
                description: 'Input VCF',
                required: true),
            GatkArgument(
                name: 'output',
                type: 'file',
                description: 'Output VCF',
                required: true),
            GatkArgument(
                name: 'reference',
                type: 'file',
                description: 'Reference FASTA',
                required: true),
            GatkArgument(
                name: 'select-type-to-include',
                type: 'enum',
                description: 'Type of variants to select',
                enumValues: ['SNP', 'INDEL', 'MIXED', 'MNP', 'SYMBOLIC', 'NO_VARIATION']),
            GatkArgument(
                name: 'sample-name',
                type: 'string',
                description: 'Samples to include'),
          ],
        ),
        GatkTool(
          name: 'VariantFiltration',
          category: 'Variant Filtering',
          description: 'Filter variant calls based on expressions',
          arguments: [
            GatkArgument(
                name: 'variant',
                type: 'file',
                description: 'Input VCF',
                required: true),
            GatkArgument(
                name: 'output',
                type: 'file',
                description: 'Output VCF',
                required: true),
            GatkArgument(
                name: 'reference',
                type: 'file',
                description: 'Reference FASTA',
                required: true),
            GatkArgument(
                name: 'filter-expression',
                type: 'string',
                description: 'Filter expression (e.g. "QD < 2.0")'),
            GatkArgument(
                name: 'filter-name',
                type: 'string',
                description: 'Filter name to apply'),
          ],
        ),
        GatkTool(
          name: 'Mutect2',
          category: 'Somatic Variant Calling',
          description: 'Call somatic SNVs and indels',
          arguments: [
            GatkArgument(
                name: 'input',
                type: 'file',
                description: 'Input BAM (tumor)',
                required: true),
            GatkArgument(
                name: 'output',
                type: 'file',
                description: 'Output VCF',
                required: true),
            GatkArgument(
                name: 'reference',
                type: 'file',
                description: 'Reference FASTA',
                required: true),
            GatkArgument(
                name: 'tumor-sample',
                type: 'string',
                description: 'Tumor sample name'),
            GatkArgument(
                name: 'normal-sample',
                type: 'string',
                description: 'Normal sample name (optional)'),
            GatkArgument(
                name: 'germline-resource',
                type: 'file',
                description: 'Population germline resource VCF'),
          ],
        ),
        GatkTool(
          name: 'CollectAlignmentSummaryMetrics',
          category: 'Diagnostics and Quality Control',
          description: 'Produces alignment summary metrics',
          arguments: [
            GatkArgument(
                name: 'input',
                type: 'file',
                description: 'Input BAM',
                required: true),
            GatkArgument(
                name: 'output',
                type: 'file',
                description: 'Output metrics file',
                required: true),
            GatkArgument(
                name: 'reference',
                type: 'file',
                description: 'Reference FASTA'),
          ],
        ),
      ];
}

class GatkServiceException implements Exception {
  final String message;
  GatkServiceException(this.message);

  @override
  String toString() => 'GatkServiceException: $message';
}
