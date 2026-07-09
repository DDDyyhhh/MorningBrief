import 'package:flutter/material.dart';

class ModuleLoadingWidget extends StatelessWidget {
  const ModuleLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        SizedBox(width: 12),
        Text('加载中...'),
      ],
    );
  }
}
