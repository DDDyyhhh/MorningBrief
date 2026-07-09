import 'package:flutter/material.dart';

class ModuleEmptyWidget extends StatelessWidget {
  const ModuleEmptyWidget({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(message, style: Theme.of(context).textTheme.bodyMedium);
  }
}
