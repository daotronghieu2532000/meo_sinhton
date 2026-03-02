import 'package:flutter/material.dart';
import 'package:meo_sinhton/app/app_controller.dart';
import 'package:meo_sinhton/app/app_i18n.dart';
import 'package:meo_sinhton/screens/tip_feed_view.dart';

class TipCategoryScreen extends StatelessWidget {
  const TipCategoryScreen({
    super.key,
    required this.category,
    required this.appController,
    required this.isEnglish,
  });

  final String category;
  final AppController appController;
  final bool isEnglish;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppI18n.category(category, isEnglish))),
      body: TipFeedView(
        lockedCategory: category,
        showCategoryChips: false,
        appController: appController,
        isEnglish: isEnglish,
      ),
    );
  }
}
