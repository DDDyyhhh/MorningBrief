import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/shared/widgets/module_card.dart';
import 'package:morningbrief/shared/widgets/module_empty_widget.dart';
import 'package:morningbrief/shared/widgets/module_error_widget.dart';
import 'package:morningbrief/shared/widgets/module_loading_widget.dart';

void main() {
  testWidgets('ModuleCard displays title and child', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ModuleCard(title: '天气', icon: Icons.wb_sunny_outlined, child: Text('24°C')),
      ),
    ));

    expect(find.text('天气'), findsOneWidget);
    expect(find.text('24°C'), findsOneWidget);
  });

  testWidgets('ModuleErrorWidget calls retry callback', (tester) async {
    var retries = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ModuleErrorWidget(message: '网络异常', onRetry: () => retries++)),
    ));

    await tester.tap(find.text('重试'));
    expect(retries, 1);
  });

  testWidgets('Loading and empty widgets show Chinese labels', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Column(children: [ModuleLoadingWidget(), ModuleEmptyWidget(message: '暂无数据')]),
    ));

    expect(find.text('加载中...'), findsOneWidget);
    expect(find.text('暂无数据'), findsOneWidget);
  });
}
