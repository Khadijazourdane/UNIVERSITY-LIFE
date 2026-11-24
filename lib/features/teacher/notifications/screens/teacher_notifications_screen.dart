import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_segmented_tabs.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/screen_header.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/teacher_notification_provider.dart';

class TeacherNotificationsScreen extends StatefulWidget {
  const TeacherNotificationsScreen({super.key});

  @override
  State<TeacherNotificationsScreen> createState() =>
      _TeacherNotificationsScreenState();
}

class _TeacherNotificationsScreenState
    extends State<TeacherNotificationsScreen> {
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeacherNotificationProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherNotificationProvider>();
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenHeader(
              title: 'Notifications',
              subtitle: 'Les dernières nouvelles du campus',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.phoneHorizontalMargin,
                vertical: AppDimensions.space8,
              ),
              child: AppSegmentedTabs<bool>(
                values: const [false, true],
                labelOf: (unread) => unread ? 'Non lues' : 'Toutes',
                selected: _unreadOnly,
                onChanged: (v) => setState(() => _unreadOnly = v),
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (provider.isLoading) return const LoadingView();
                  if (provider.error != null) {
                    return ErrorView(provider.error!);
                  }
                  final items = provider.notifications
                      .where((n) => !_unreadOnly || !n.isRead)
                      .toList();
                  if (items.isEmpty) {
                    return const ErrorView('Aucune notification.');
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(
                      AppDimensions.phoneHorizontalMargin,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppDimensions.space12),
                    itemBuilder: (context, index) {
                      final n = items[index];
                      return AppCard(
                        onTap: n.isRead
                            ? null
                            : () => provider.markAsRead(n.id),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    n.title,
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: n.isRead
                                          ? FontWeight.w400
                                          : FontWeight.w700,
                                    ),
                                  ),
                                ),
                                // Non lu : libellé écrit, pas seulement une couleur.
                                if (!n.isRead) ...[
                                  const SizedBox(width: AppDimensions.space8),
                                  const StatusBadge('Non lu'),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(n.body, style: AppTextStyles.compactBody),
                            const SizedBox(height: 4),
                            Text(
                              dateFormat.format(n.date),
                              style: AppTextStyles.caption,
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
