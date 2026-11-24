import 'package:flutter/material.dart';
import 'package:university_life/core/theme/app_colors.dart';
import 'package:university_life/core/theme/app_dimensions.dart';
import 'package:university_life/core/theme/app_text_styles.dart';
import 'package:university_life/features/admin/widgets/admin_dialogs.dart';
import 'package:university_life/shared/widgets/app_button.dart';

class AdminListView<T> extends StatefulWidget {
  const AdminListView({
    required this.load,
    required this.titleOf,
    this.subtitleOf,
    this.icon = Icons.folder_outlined,
    this.addLabel = 'Ajouter',
    this.onCreate,
    this.onEdit,
    this.onDelete,
    this.onView,
    this.trailingBuilder,
    this.emptyMessage = 'Aucun élément pour le moment.',
    this.errorMessage = 'Impossible de charger les données.',
    super.key,
  });

  final Future<List<T>> Function() load;
  final String Function(T item) titleOf;
  final String Function(T item)? subtitleOf;
  final IconData icon;
  final String addLabel;
  final Future<bool> Function(BuildContext context)? onCreate;
  final Future<bool> Function(BuildContext context, T item)? onEdit;
  final Future<void> Function(T item)? onDelete;
  final Future<void> Function(BuildContext context, T item)? onView;
  final Widget? Function(
      BuildContext context,
      T item,
      Future<void> Function() reload,
      )?
  trailingBuilder;
  final String emptyMessage;
  final String errorMessage;

  @override
  State<AdminListView<T>> createState() => _AdminListViewState<T>();
}

class _AdminListViewState<T> extends State<AdminListView<T>> {
  late Future<List<T>> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.load();
  }

  Future<void> _reload() async {
    if (!mounted) return;
    setState(() {
      _items = widget.load();
    });
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opération impossible. Réessayez.')),
      );
    }
  }

  Future<void> _create() => _guard(() async {
    final changed = await widget.onCreate!(context);
    if (changed) await _reload();
  });

  Future<void> _edit(T item) => _guard(() async {
    final changed = await widget.onEdit!(context, item);
    if (changed) await _reload();
  });

  Future<void> _view(T item) => _guard(() => widget.onView!(context, item));

  Future<void> _delete(T item) async {
    final confirmed = await confirmAdminAction(
      context,
      title: 'Confirmer la suppression',
      message: 'Voulez-vous vraiment supprimer « ${widget.titleOf(item)} » ?',
      confirmLabel: 'Supprimer',
    );
    if (!confirmed) return;

    await _guard(() async {
      await widget.onDelete!(item);
      await _reload();
    });
  }

  Widget? _trailing(BuildContext context, T item) {
    final custom = widget.trailingBuilder?.call(context, item, _reload);
    if (custom != null) return custom;

    final actions = <Widget>[
      if (widget.onEdit != null)
        IconButton(
          tooltip: 'Modifier',
          icon: const Icon(Icons.edit_outlined, color: AppColors.slate),
          onPressed: () => _edit(item),
        ),
      if (widget.onDelete != null)
        IconButton(
          tooltip: 'Supprimer',
          icon: const Icon(Icons.delete_outline, color: AppColors.slate),
          onPressed: () => _delete(item),
        ),
    ];
    if (actions.isEmpty) return null;

    return Row(mainAxisSize: MainAxisSize.min, children: actions);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: _items,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.space20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.errorMessage, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: _reload,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        final items = snapshot.data ?? <T>[];

        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.space20),
            children: [
              if (widget.onCreate != null) ...[
                AppButton(label: widget.addLabel, onPressed: _create),
                const SizedBox(height: AppDimensions.space16),
              ],
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppDimensions.space24),
                  child: Text(
                    widget.emptyMessage,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body,
                  ),
                ),
              for (final item in items) _buildCard(context, item),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, T item) {
    final subtitle = widget.subtitleOf?.call(item) ?? '';
    final VoidCallback? onTap = widget.onView != null
        ? () => _view(item)
        : widget.onEdit != null
        ? () => _edit(item)
        : null;

    return Card(
      child: ListTile(
        leading: Icon(widget.icon, color: AppColors.slate),
        title: Text(widget.titleOf(item), style: AppTextStyles.body),
        subtitle: subtitle.isEmpty
            ? null
            : Text(subtitle, style: AppTextStyles.compactBody),
        trailing: _trailing(context, item),
        onTap: onTap,
      ),
    );
  }
}
