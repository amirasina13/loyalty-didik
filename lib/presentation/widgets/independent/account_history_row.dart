import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app_setting/app_setting.dart';

class AccountHistoryRow extends StatelessWidget {
  final String title, date, time, amount;
  final bool incoming;
  final String? unit;
  const AccountHistoryRow({
    super.key,
    required this.title,
    required this.date,
    required this.time,
    required this.amount,
    required this.incoming,
    this.unit,
  });
  @override
  Widget build(BuildContext context) {
    const palette = AppDesign.history;
    final timestamp = DateTime.tryParse('$date $time');
    final dateLabel =
        timestamp == null
            ? '$date $time'
            : '${DateFormat(appDateFormat).format(timestamp)}  ${DateFormat(appTimeFormat).format(timestamp)}';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDesign.spaceXl),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateLabel,
            style: TextStyle(
              fontSize: AppDesign.smallSize,
              color: palette.muted,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: AppDesign.bodySize,
                    color: palette.text,
                  ),
                ),
              ),
              const SizedBox(width: AppDesign.spaceLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: AppDesign.bodySize,
                        fontWeight: FontWeight.w600,
                        color:
                            incoming
                                ? AppDesign.historyIncoming
                                : AppDesign.historyOutgoing,
                      ),
                    ),
                    if (unit != null)
                      Text(
                        unit!,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: AppDesign.captionSize,
                          color: palette.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String historyMonth(String? date) {
  final parsed = DateTime.tryParse(date ?? '');
  return parsed == null
      ? (date ?? '')
      : DateFormat('MMM yyyy').format(parsed).toUpperCase();
}

class HistoryMonthHeader extends StatelessWidget {
  final String month;
  const HistoryMonthHeader(this.month, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: AppDesign.pagePadding,
      vertical: AppDesign.spaceLg,
    ),
    color: colorBlueDidik.withValues(alpha: 0.1),
    child: Text(
      month,
      style: TextStyle(
        fontSize: AppDesign.bodySize,
        fontWeight: FontWeight.w700,
        color: AppDesign.history.action,
      ),
    ),
  );
}

class HistoryBalanceTab extends StatelessWidget {
  const HistoryBalanceTab({
    super.key,
    required this.label,
    required this.amount,
    required this.selected,
    required this.onTap,
  });
  final String label, amount;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    const p = AppDesign.history;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colorBlueDidik.withValues(alpha: 0.1) : p.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? p.action : p.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: AppDesign.spaceLg,
            ),
            child: Column(
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppDesign.smallSize,
                    color: selected ? p.action : p.muted,
                  ),
                ),
                const SizedBox(height: AppDesign.spaceSm),
                SizedBox(
                  height: 32,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      amount,
                      style: TextStyle(
                        fontSize: AppDesign.headingSize,
                        fontWeight: FontWeight.w500,
                        color: selected ? p.action : p.text,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
