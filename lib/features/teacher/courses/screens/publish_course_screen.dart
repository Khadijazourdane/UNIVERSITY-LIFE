import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/screen_header.dart';
import '../../modules/models/teacher_module_model.dart';
import '../providers/teacher_course_provider.dart';

/// Publication d'un support PDF : module, groupe, titre, fichier.
class PublishCourseScreen extends StatefulWidget {
  const PublishCourseScreen({super.key, required this.module});

  final TeacherModule module;

  @override
  State<PublishCourseScreen> createState() => _PublishCourseScreenState();
}

class _PublishCourseScreenState extends State<PublishCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  late String _group = widget.module.groups.first;
  String? _fileName;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

 
  void _pickPdf() {
    setState(() => _fileName = 'cours_${_titleController.text.trim()}.pdf');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fileName == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Joignez un fichier PDF.')));
      return;
    }
    setState(() => _isSubmitting = true);
    final provider = context.read<TeacherCourseProvider>();
    final ok = await provider.publish(
      moduleId: widget.module.id,
      title: _titleController.text.trim(),
      fileName: _fileName!,
      group: _group,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cours publié.')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.error ?? 'Erreur.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenHeader(
              title: 'Publier un cours',
              subtitle: 'Supports pour vos groupes',
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(
                    AppDimensions.phoneHorizontalMargin,
                  ),
                  children: [
                    AppTextField(
                      label: 'Module',
                      initialValue: widget.module.name,
                      readOnly: true,
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    const AppFieldLabel('Groupe destinataire'),
                    DropdownButtonFormField<String>(
                      initialValue: _group,
                      decoration: appInputDecoration(),
                      items: [
                        for (final g in widget.module.groups)
                          DropdownMenuItem(value: g, child: Text(g)),
                      ],
                      onChanged: (v) => setState(() => _group = v ?? _group),
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    AppTextField(
                      label: 'Titre du cours',
                      controller: _titleController,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Le titre est obligatoire.'
                          : null,
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    const AppFieldLabel('Fichier'),
                    AppCard(
                      color: AppColors.powderLilac,
                      onTap: _pickPdf,
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_outlined),
                          const SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: Text(
                              _fileName ?? 'Joindre un PDF',
                              style: AppTextStyles.body,
                            ),
                          ),
                          const Icon(Icons.attach_file),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space24),
                    AppButton(
                      label: 'Publier le cours',
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
