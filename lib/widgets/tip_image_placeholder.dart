import 'package:flutter/material.dart';
import 'package:meo_sinhton/app/app_strings.dart';

class TipImagePlaceholder extends StatelessWidget {
  const TipImagePlaceholder({
    super.key,
    required this.imageAsset,
    required this.isEnglish,
  });

  final String? imageAsset;
  final bool isEnglish;

  @override
  Widget build(BuildContext context) {
    if (imageAsset != null && imageAsset!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(imageAsset!, height: 180, fit: BoxFit.cover),
      );
    }

    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      alignment: Alignment.center,
      child: Text(AppStrings.imagePlaceholder(isEnglish)),
    );
  }
}
