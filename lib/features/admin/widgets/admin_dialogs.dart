import 'package:flutter/material.dart';
import 'package:university_life/core/theme/app_dimensions.dart';
import 'package:university_life/core/theme/app_text_styles.dart';
import 'package:university_life/shared/widgets/app_text_field.dart';

enum AdminFieldType { text, email, password, multiline, dropdown, date, time }

class AdminOption {
  const AdminOption({required this.value, required this.label});

  final String value;
  final String label;
}

/// Description d'un champ de formulaire. [key] correspond à la clé JSON
/// envoyée au backend.
class AdminField {
  const AdminField({
    required this.key,
    required this.label,
    this.type = AdminFieldType.text,
    this.required = true,
    this.initialValue,
    this.options = const [],
    this.hintText,
    this.validator,
  });

  final String key;
  final String label;
  final AdminFieldType type;
  final bool required;
  final String? initialValue;
  final List<AdminOption> options;
  final String? hintText;
  final String? Function(String value)? validator;
}

/// Affiche un formulaire et renvoie les valeurs saisies, ou null si annulé.
///
/// [formValidator] permet un contrôle entre plusieurs champs
/// (par exemple heure de fin après heure de début).
Future<Map<String, String>?> showAdminFormDialog(
    BuildContext context, {
      required String title,
      required List<AdminField> fields,
      String submitLabel = 'Enregistrer',
      String? Function(Map<String, String> values)? formValidator,
    }) {
  return showDialog<Map<String, String>>(
    context: context,
    builder: (dialogContext) => _AdminFormDialog(
      title: title,
      fields: fields,
      submitLabel: submitLabel,
      formValidator: formValidator,
    ),
  );
}

Future<bool> confirmAdminAction(
    BuildContext context, {
      required String title,
      required String message,
      String confirmLabel = 'Confirmer',
    }) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<void> showAdminDetailsDialog(
    BuildContext context, {
      required String title,
      required Map<String, String> rows,
    }) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in rows.entries) ...[
              Text(
                entry.key,
                style: AppTextStyles.compactBody.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                entry.value.isEmpty ? '—' : entry.value,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppDimensions.space12),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}

String formatAdminDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-$month-$day';
}

String formatAdminTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

TimeOfDay? _parseTime(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

class _AdminFormDialog extends StatefulWidget {
  const _AdminFormDialog({
    required this.title,
    required this.fields,
    required this.submitLabel,
    required this.formValidator,
  });

  final String title;
  final List<AdminField> fields;
  final String submitLabel;
  final String? Function(Map<String, String> values)? formValidator;

  @override
  State<_AdminFormDialog> createState() => _AdminFormDialogState();
}

class _AdminFormDialogState extends State<_AdminFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in widget.fields)
        field.key: TextEditingController(text: _initialTextFor(field)),
    };
  }

  String _initialTextFor(AdminField field) {
    final initial = field.initialValue ?? '';
    if (field.type == AdminFieldType.dropdown &&
        !field.options.any((option) => option.value == initial)) {
      return '';
    }
    return initial;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validate(AdminField field, String? raw) {
    final value = (raw ?? '').trim();
    if (field.required && value.isEmpty) {
      return field.type == AdminFieldType.dropdown
          ? 'Veuillez faire un choix.'
          : 'Ce champ est obligatoire.';
    }
    if (value.isEmpty) return null;
    return field.validator?.call(value);
  }

  Map<String, String> _values() => {
    for (final entry in _controllers.entries)
      entry.key: entry.value.text.trim(),
  };

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final values = _values();
    final error = widget.formValidator?.call(values);
    if (error != null) {
      setState(() => _formError = error);
      return;
    }

    Navigator.of(context).pop(values);
  }

  Future<void> _pickDate(AdminField field) async {
    final controller = _controllers[field.key]!;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    controller.text = formatAdminDate(picked);
  }

  Future<void> _pickTime(AdminField field) async {
    final controller = _controllers[field.key]!;
    final picked = await showTimePicker(
      context: context,
      initialTime:
      _parseTime(controller.text) ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked == null) return;
    controller.text = formatAdminTime(picked);
  }

  Widget _labeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AppDimensions.space8),
        Semantics(label: label, child: child),
      ],
    );
  }

  Widget _buildField(AdminField field) {
    final controller = _controllers[field.key]!;

    switch (field.type) {
      case AdminFieldType.text:
      case AdminFieldType.email:
      case AdminFieldType.password:
        return AppTextField(
          label: field.label,
          controller: controller,
          hintText: field.hintText,
          obscureText: field.type == AdminFieldType.password,
          keyboardType: field.type == AdminFieldType.email
              ? TextInputType.emailAddress
              : TextInputType.text,
          validator: (value) => _validate(field, value),
        );
      case AdminFieldType.multiline:
        return _labeled(
          field.label,
          TextFormField(
            controller: controller,
            minLines: 3,
            maxLines: 6,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(hintText: field.hintText),
            validator: (value) => _validate(field, value),
          ),
        );
      case AdminFieldType.dropdown:
        return _labeled(
          field.label,
          DropdownButtonFormField<String>(
            initialValue:
            field.options.any((option) => option.value == controller.text)
                ? controller.text
                : null,
            isExpanded: true,
            decoration: InputDecoration(hintText: field.hintText),
            items: [
              for (final option in field.options)
                DropdownMenuItem<String>(
                  value: option.value,
                  child: Text(option.label, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) => controller.text = value ?? '',
            validator: (value) => _validate(field, value),
          ),
        );
      case AdminFieldType.date:
      case AdminFieldType.time:
        final isDate = field.type == AdminFieldType.date;
        return _labeled(
          field.label,
          TextFormField(
            controller: controller,
            readOnly: true,
            onTap: () => isDate ? _pickDate(field) : _pickTime(field),
            decoration: InputDecoration(
              hintText: field.hintText ?? (isDate ? 'AAAA-MM-JJ' : 'HH:MM'),
              suffixIcon: Icon(
                isDate ? Icons.calendar_today_outlined : Icons.schedule,
              ),
            ),
            validator: (value) => _validate(field, value),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final field in widget.fields) ...[
                  _buildField(field),
                  const SizedBox(height: AppDimensions.space16),
                ],
                if (_formError != null)
                  Text(
                    _formError!,
                    style: AppTextStyles.compactBody.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        TextButton(onPressed: _submit, child: Text(widget.submitLabel)),
      ],
    );
  }
}
