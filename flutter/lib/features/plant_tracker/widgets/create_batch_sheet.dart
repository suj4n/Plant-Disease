import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_stats.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Bottom sheet to create or edit a plant batch.
class CreateBatchSheet extends StatefulWidget {
  const CreateBatchSheet({
    super.key,
    this.initialName,
    this.initialPlantType,
    this.initialPlantedDate,
    this.title = 'New plant batch',
    this.submitLabel = 'Save batch',
  });

  final String? initialName;
  final String? initialPlantType;
  final DateTime? initialPlantedDate;
  final String title;
  final String submitLabel;

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    String? initialName,
    String? initialPlantType,
    DateTime? initialPlantedDate,
    String title = 'New plant batch',
    String submitLabel = 'Save batch',
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: CreateBatchSheet(
          initialName: initialName,
          initialPlantType: initialPlantType,
          initialPlantedDate: initialPlantedDate,
          title: title,
          submitLabel: submitLabel,
        ),
      ),
    );
  }

  @override
  State<CreateBatchSheet> createState() => _CreateBatchSheetState();
}

class _CreateBatchSheetState extends State<CreateBatchSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _plantType;
  late DateTime _plantedDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _plantType = widget.initialPlantType ?? AppStats.supportedCrops.first;
    _plantedDate = widget.initialPlantedDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plantedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              surface: AppColors.cardElevated,
              onSurface: AppColors.foreground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _plantedDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'name': _nameController.text.trim(),
      'plantType': _plantType,
      'plantedDate': _plantedDate,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(widget.title, style: AppTextStyles.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Batch name',
                hintText: 'e.g. North field tomatoes',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a batch name' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Plant type', style: AppTextStyles.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: AppStats.supportedCrops.map((crop) {
                final selected = _plantType == crop;
                return FilterChip(
                  label: Text(crop),
                  selected: selected,
                  onSelected: (_) => setState(() => _plantType = crop),
                  selectedColor: AppColors.primary,
                  checkmarkColor: AppColors.onPrimary,
                  labelStyle: AppTextStyles.chipText.copyWith(
                    color: selected
                        ? AppColors.onPrimary
                        : AppColors.mutedForeground,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Planted date',
                  suffixIcon: Icon(Icons.calendar_month_outlined),
                ),
                child: Text(
                  DateFormat.yMMMd().format(_plantedDate),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.foreground,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _submit,
              child: Text(widget.submitLabel),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
