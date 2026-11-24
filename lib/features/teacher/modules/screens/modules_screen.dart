import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_banner.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/screen_header.dart';
import '../models/teacher_module_model.dart';
import '../providers/teacher_module_provider.dart';
import 'module_detail_screen.dart';

/// Accueil du professeur : module à la une + liste de ses modules.
class ModulesScreen extends StatefulWidget {
  const ModulesScreen({super.key});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  // TODO : remplacer par le nom du compte connecté (auth).
  static const _teacherName = 'Leila';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeacherModuleProvider>().load();
    });
  }

  void _open(BuildContext context, TeacherModule module) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ModuleDetailScreen(module: module),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherModuleProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: 'Bonjour, $_teacherName.',
              subtitle: 'Espace enseignement',
            ),
            Expanded(child: _buildBody(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(TeacherModuleProvider provider) {
    if (provider.isLoading) return const LoadingView();
    if (provider.error != null) return ErrorView(provider.error!);
    if (provider.modules.isEmpty) {
      return const ErrorView('Aucun module affecté.');
    }

    final featured = provider.modules.first;
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.phoneHorizontalMargin,
        vertical: AppDimensions.space8,
      ),
      children: [
        AppBanner(
          eyebrow: 'Module à la une',
          title: featured.name,
          subtitle: '${featured.code} · Groupes : ${featured.groups.join(', ')}',
          onTap: () => _open(context, featured),
        ),
        const SizedBox(height: AppDimensions.space24),
        Text(
          'Mes modules (${provider.modules.length})',
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(height: AppDimensions.space12),
        for (final module in provider.modules) ...[
          AppCard(
            onTap: () => _open(context, module),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.name,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${module.code} · Groupes : ${module.groups.join(', ')}',
                        style: AppTextStyles.compactBody,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space12),
        ],
      ],
    );
  }
}
