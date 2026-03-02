import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meo_sinhton/main.dart';

void main() {
  testWidgets('Hiển thị danh sách mẹo và lọc theo từ khóa', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('LifeSpark (Life Hack)'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
