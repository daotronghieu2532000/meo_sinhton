import 'package:flutter/material.dart';
import 'package:meo_sinhton/app/constants.dart';

class LogoPlaceholder extends StatelessWidget {
  const LogoPlaceholder({super.key});

  static const double _logoSize = 56;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        logoAssetPath,
        width: _logoSize,
        height: _logoSize,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: _logoSize,
            height: _logoSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: const Icon(Icons.image_not_supported_outlined, size: 22),
          );
        },
      ),
    );
  }
}
