import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

/// Onglets en pastilles (« Toutes / Non lues », « Présent / Absent »).
class AppSegmentedTabs<T> extends StatelessWidget {
  const AppSegmentedTabs({
    super.key,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
    this.compact = false,
  });

  final List<T> values;
  final String Function(T value) labelOf;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Version réduite, à l'intérieur d'une ligne de liste.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 36.0 : 44.0;
    final radius = BorderRadius.circular(AppDimensions.buttonRadius);
    final children = <Widget>[];

    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final isSelected = value == selected;
      final pill = Semantics(
        button: true,
        selected: isSelected,
        child: Material(
          color: isSelected ? AppColors.slate : AppColors.powderLilac,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: () => onChanged(value),
            child: SizedBox(
              height: height,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 8),
                child: Center(
                  child: Text(
                    labelOf(value),
                    style: AppTextStyles.compactBody.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.white : AppColors.slate,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      children.add(compact ? pill : Expanded(child: pill));
      if (i < values.length - 1) children.add(const SizedBox(width: 8));
    }

    return Row(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      children: children,
    );
  }
}
