import 'package:flutter/material.dart';

import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

/// Message centré : erreur, ou état vide (« Aucun module affecté. »).
class ErrorView extends StatelessWidget {
  const ErrorView(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.body,
        ),
      ),
    );
  }
}
