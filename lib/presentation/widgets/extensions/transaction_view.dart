import 'package:flutter/material.dart';
import '../../../app_setting/app_setting.dart';
import '../../../data/data.dart';
import '../independent/account_history_row.dart';

extension View on Transaction {
  Widget getTransactionTile({
    required BuildContext context,
  }) => AccountHistoryRow(
    title: desc ?? '',
    date: date ?? '',
    time: time ?? '',
    unit: pointLabelAlign == 'left' ? null : pointLabelText,
    incoming: type == 'debit',
    amount:
        '${type == 'debit' ? '+' : '-'} ${pointLabelAlign == 'left' ? '$pointLabelText $points' : '$points'}',
  );
}
