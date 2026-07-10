import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/colors.dart';
import '../../models/stock_item.dart';
import '../../shared/module_state.dart';
import '../../shared/widgets/module_card.dart';
import '../../shared/widgets/module_empty_widget.dart';
import '../../shared/widgets/module_error_widget.dart';
import '../../shared/widgets/module_loading_widget.dart';
import 'stocks_provider.dart';

class StocksCard extends StatelessWidget {
  const StocksCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StocksProvider>();
    final state = provider.state;
    return ModuleCard(
      title: '股票财经',
      icon: Icons.show_chart,
      offline: state.isOffline,
      child: _StocksBody(state: state, onRetry: provider.refresh),
    );
  }
}

class _StocksBody extends StatelessWidget {
  const _StocksBody({required this.state, required this.onRetry});

  final ModuleState<List<StockItem>> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const ModuleLoadingWidget();
    }
    if (state.hasError) {
      return ModuleErrorWidget(message: state.error!.message, onRetry: onRetry);
    }
    final quotes = state.data;
    if (state.isEmpty || quotes == null || quotes.isEmpty) {
      return const ModuleEmptyWidget(message: '暂无行情');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < quotes.length; index++) ...[
          if (index > 0) const Divider(height: 24),
          _StockQuoteRow(quote: quotes[index]),
        ],
      ],
    );
  }
}

class _StockQuoteRow extends StatelessWidget {
  const _StockQuoteRow({required this.quote});

  final StockItem quote;

  @override
  Widget build(BuildContext context) {
    final displayedChange = double.parse(quote.change.toStringAsFixed(2));
    final changeColor = switch (displayedChange) {
      > 0 => AppColors.profitRed,
      < 0 => AppColors.lossGreen,
      _ => null,
    };
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quote.symbol,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(quote.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                quote.price.toStringAsFixed(2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${_signed(quote.change)} '
                '(${_signed(quote.changePercent)}%)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: changeColor == null
                    ? null
                    : (Theme.of(context).textTheme.bodyMedium ??
                              const TextStyle())
                          .copyWith(
                            color: changeColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _signed(double value) {
    final formatted = value.toStringAsFixed(2);
    if (double.parse(formatted) == 0) return '0.00';
    return value > 0 ? '+$formatted' : formatted;
  }
}
