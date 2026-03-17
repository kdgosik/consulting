// lib/widgets/tool_panel.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/app_controller.dart';
import '../models/gatk_tool.dart';
import '../theme.dart';

class ToolPanel extends GetView<AppController> {
  const ToolPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearch(),
          _buildCategories(),
          const Divider(height: 1, color: AppTheme.border),
          Expanded(child: _buildToolList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.biotech_outlined, color: AppTheme.accent, size: 16),
          const SizedBox(width: 8),
          Text(
            'GATK TOOLS',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          Obx(() => Text(
                '${controller.availableTools.length}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: AppTheme.accentGreen,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        onChanged: (v) => controller.toolSearch.value = v,
        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search tools...',
          prefixIcon: const Icon(Icons.search, size: 16, color: AppTheme.textMuted),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Obx(() {
      final categories = controller.toolsByCategory.keys.toList();
      if (categories.isEmpty) return const SizedBox();

      return SizedBox(
        height: 34,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: categories.length + 1,
          itemBuilder: (ctx, i) {
            if (i == 0) {
              final isAll = controller.selectedCategory.value.isEmpty;
              return _categoryChip('All', isAll, () {
                controller.selectedCategory.value = '';
              }, AppTheme.accent);
            }
            final cat = categories[i - 1];
            final isSelected = controller.selectedCategory.value == cat;
            return _categoryChip(
              cat,
              isSelected,
              () => controller.selectedCategory.value = cat,
              AppTheme.categoryColor(cat),
            );
          },
        ),
      );
    });
  }

  Widget _categoryChip(
      String label, bool selected, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppTheme.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: selected ? color : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildToolList() {
    return Obx(() {
      final tools = controller.filteredTools;
      if (tools.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, color: AppTheme.textMuted, size: 32),
              const SizedBox(height: 8),
              Text('No tools found',
                  style: GoogleFonts.inter(color: AppTheme.textMuted)),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: tools.length,
        itemBuilder: (ctx, i) => _ToolListItem(tool: tools[i]),
      );
    });
  }
}

class _ToolListItem extends GetView<AppController> {
  final GatkTool tool;
  const _ToolListItem({required this.tool});

  @override
  Widget build(BuildContext context) {
    final catColor = AppTheme.categoryColor(tool.category);

    return Draggable<GatkTool>(
      data: tool,
      feedback: Material(
        color: Colors.transparent,
        child: _dragFeedback(catColor),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _tile(catColor)),
      child: _tile(catColor),
    );
  }

  Widget _dragFeedback(Color catColor) {
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: catColor, width: 1.5),
        boxShadow: [
          BoxShadow(color: catColor.withOpacity(0.3), blurRadius: 16),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.drag_indicator, color: catColor, size: 16),
          const SizedBox(width: 8),
          Text(tool.name,
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _tile(Color catColor) {
    return InkWell(
      onTap: () => controller.addToolToPipeline(tool),
      hoverColor: AppTheme.surfaceHigh,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 32,
              decoration: BoxDecoration(
                color: catColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool.name,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (tool.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      tool.description!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.add, size: 16, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
