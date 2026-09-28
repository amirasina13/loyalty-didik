import 'package:barcode_widget/barcode_widget.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../../app_setting/app_setting.dart';

/* Widget class for promotional reward success dialog. */
class VoucherSuccessDialog extends StatelessWidget {
  final Map data;
  final VoidCallback onTap;

  const VoucherSuccessDialog({
    super.key,
    required this.data,
    required this.onTap,
  });

  Map _voucher() {
    final payload = data['data'];
    if (payload is Map && payload['voucher'] is Map) {
      return Map<Object?, Object?>.from(payload['voucher'] as Map);
    }
    return <Object?, Object?>{};
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppDesign.voucherDetails;
    final voucher = _voucher();
    final qrValue = voucher['codeString']?.toString() ?? '';
    final couponCode = voucher['code']?.toString() ?? '';
    final redeemedAt = voucher['redeemAt']?.toString() ?? '';
    final isQr = scanning == 'qr';

    return Material(
      color: palette.background,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: palette.background,
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              AppDesign.spaceXl,
              20,
              AppDesign.spaceXl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: SizedBox(
                    width: 92,
                    height: 92,
                    child: Image.asset(
                      'assets/image/redeem_success.webp',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: AppDesign.spaceXl),
                Text(
                  'Redeemed!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: thirdColor,
                    fontFamily: fontFamilyMain,
                    fontWeight: FontWeight.w500,
                    fontSize: AppDesign.heroSize,
                  ),
                ),
                const SizedBox(height: AppDesign.spaceXxl),
                Divider(height: 1, color: palette.border),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDesign.spaceXl,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date & Time',
                        style: TextStyle(
                          color: palette.muted,
                          fontFamily: fontFamilyMain,
                          fontSize: AppDesign.bodySize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: AppDesign.spaceLg),
                      Expanded(
                        child: Text(
                          redeemedAt,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: palette.text,
                            fontFamily: fontFamilyMain,
                            fontSize: AppDesign.bodySize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _CodePreviewCard(isQr: isQr, value: qrValue),
                const SizedBox(height: AppDesign.spaceXl),
                DottedBorder(
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(8),
                  dashPattern: const [8, 8],
                  color: palette.text,
                  strokeWidth: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDesign.spaceLg,
                      vertical: AppDesign.spaceLg,
                    ),
                    child: Text(
                      couponCode,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.text,
                        fontFamily: fontFamilyMain,
                        fontSize: AppDesign.bodyLargeSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 52),
                SizedBox(
                  height: AppDesign.setupButtonHeight,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.action,
                      foregroundColor: palette.onAction,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: fontFamilyMain,
                        fontSize: AppDesign.bodyLargeSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Call this future after a successful redemption.
  static Future showVoucherSuccessDialog(
    BuildContext context,
    Map data,
    VoidCallback onTap,
  ) {
    return showGeneralDialog(
      context: context,
      barrierColor: Colors.black38,
      barrierLabel: 'Redemption complete',
      barrierDismissible: false,
      pageBuilder:
          (_, __, ___) => PopScope(
            canPop: false,
            child: VoucherSuccessDialog(data: data, onTap: onTap),
          ),
    );
  }
}

class _CodePreviewCard extends StatelessWidget {
  final bool isQr;
  final String value;

  const _CodePreviewCard({required this.isQr, required this.value});

  @override
  Widget build(BuildContext context) {
    final palette = AppDesign.voucherDetails;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorWhiteQrLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: isQr ? 1 : 1.85,
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.all(isQr ? 20 : AppDesign.spaceLg),
              decoration: BoxDecoration(
                color: palette.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  isQr
                      ? (value.isEmpty
                          ? Icon(
                            Icons.qr_code_2_rounded,
                            size: 100,
                            color: palette.muted,
                          )
                          : PrettyQrView.data(
                            data: value,
                            decoration: const PrettyQrDecoration(
                              image: PrettyQrDecorationImage(
                                image: AssetImage(
                                  'assets/logo/order_splash_logo.png',
                                ),
                              ),
                              quietZone: PrettyQrQuietZone.zero,
                            ),
                            errorCorrectLevel: QrErrorCorrectLevel.Q,
                          ))
                      : BarcodeWidget(
                        barcode: Barcode.code128(),
                        data: value.isEmpty ? '-' : value,
                        drawText: false,
                        padding: const EdgeInsets.all(AppDesign.spaceMd),
                      ),
            ),
          ),
          const SizedBox(height: AppDesign.spaceLg),
          Text(
            'This coupon code is for single use only.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.muted,
              fontFamily: fontFamilyMain,
              fontSize: AppDesign.bodySize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
