import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/calendar_event.dart';
import '../../shared/module_state.dart';
import '../../shared/widgets/module_card.dart';
import '../../shared/widgets/module_empty_widget.dart';
import '../../shared/widgets/module_error_widget.dart';
import '../../shared/widgets/module_loading_widget.dart';
import 'calendar_provider.dart';

class CalendarCard extends StatelessWidget {
  const CalendarCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    return ModuleCard(
      title: '日历与日程',
      icon: Icons.event_note_outlined,
      child: _CalendarBody(state: provider.state, provider: provider),
    );
  }
}

class _CalendarBody extends StatelessWidget {
  const _CalendarBody({required this.state, required this.provider});

  final ModuleState<List<CalendarEvent>> state;
  final CalendarProvider provider;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) return const ModuleLoadingWidget();
    if (state.hasError) return ModuleErrorWidget(message: state.error!.message, onRetry: provider.loadToday);
    if (state.isEmpty) return const ModuleEmptyWidget(message: '今天还没有日程');
    final events = state.data ?? [];
    return Column(
      children: [
        for (final event in events)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: event.isCompleted,
            title: Text(event.title),
            subtitle: Text(DateFormat('HH:mm').format(event.startsAt)),
            onChanged: (value) => provider.toggleCompleted(event.id!, value ?? false),
          ),
      ],
    );
  }
}
