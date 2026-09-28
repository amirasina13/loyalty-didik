import 'package:flutter/material.dart';
import '../../../app_setting/app_setting.dart';
import '../../../data/data.dart';
import '../independent/account_history_row.dart';

extension View on CreditTransaction {
  Widget getCreditTransactionTile({
    required BuildContext context,
  }) => AccountHistoryRow(
    title: method ?? '',
    date: date ?? '',
    time: time ?? '',
    unit: creditLabelAlign == 'left' ? null : creditLabelText,
    incoming: type == 'debit',
    amount:
        '${type == 'debit' ? '+' : '-'} ${creditLabelAlign == 'left' ? '$creditLabelText $amount' : '$amount'}',
  );
}
