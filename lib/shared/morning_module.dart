import 'package:flutter/widgets.dart';
import '../models/module_config.dart';

abstract class MorningModule {
  MorningModuleId get id;
  String get title;
  IconData get icon;
  bool get isEnabled;
  Widget buildCard();
  Future<void> refresh();
}
