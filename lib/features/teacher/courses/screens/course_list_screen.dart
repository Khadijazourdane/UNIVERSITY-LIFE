import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/screen_header.dart';
import '../../modules/models/teacher_module_model.dart';
import '../providers/teacher_course_provider.dart';
import 'publish_course_screen.dart';

/// « Mes supports » : cours PDF publiés pour un module.
class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key, required this.module});

  final TeacherModule module;

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeacherCourseProvider>().load(widget.module.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherCourseProvider>();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final module = widget.module;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: 'Mes supports',
              subtitle: '${module.name} · ${module.groups.join(', ')}',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.phoneHorizontalMargin,
                vertical: AppDimensions.space8,
              ),
              child: AppButton(
                label: '+ Publier un cours',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PublishCourseScreen(module: module),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (provider.isLoading) return const LoadingView();
                  if (provider.courses.isEmpty) {
                    return ErrorView(provider.error ?? 'Aucun cours publié.');
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(
                      AppDimensions.phoneHorizontalMargin,
                    ),
                    itemCount: provider.courses.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppDimensions.space12),
                    itemBuilder: (context, index) {
                      final c = provider.courses[index];
                      return AppCard(
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf_outlined),
                            const SizedBox(width: AppDimensions.space12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.title,
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${c.fileName} · ${c.group} · ${dateFormat.format(c.publishedAt)}',
                                    style: AppTextStyles.compactBody,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Supprimer',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  provider.delete(module.id, c.id),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
