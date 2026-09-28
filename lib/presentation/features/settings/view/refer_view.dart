import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../widgets/widgets.dart';
import '../../profile/profile.dart';
import '../../refer/refer.dart';

class ReferView extends StatelessWidget {
  final Function? changeView;
  const ReferView({super.key, this.changeView});

  @override
  Widget build(BuildContext context) {
    const palette = AppDesign.referral;
    return ColoredBox(
      color: palette.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: palette.text),
                ),
                Expanded(
                  child: Text(
                    'Refer Friends',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppDesign.titleSize,
                      fontWeight: FontWeight.w700,
                      color: palette.text,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            Expanded(
              child: BlocBuilder<ReferBloc, ReferState>(
                builder: (context, state) {
                  if (state is! ReferLoaded) return LoadingWidget();
                  final referral = state.userRefer;
                  final code = referral.code ?? '';
                  final link = referral.link ?? '';
                  final message = referral.text ?? '';
                  final qr = referral.codeString ?? '';
                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      24,
                      24,
                      24 + MediaQuery.paddingOf(context).bottom,
                    ),
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: colorBlueDidik.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.people_outline,
                          color: palette.action,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: AppDesign.spaceXl),
                      Text(
                        'Invite your friends',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppDesign.headingSize,
                          fontWeight: FontWeight.w700,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(height: AppDesign.spaceXl),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        builder: (context, profile) {
                          final points =
                              profile is ProfileLoaded
                                  ? profile.userProfile.profile?.points
                                  : null;
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colorBlueDidik.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppDesign.cardRadius,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    pointLabelTitle,
                                    style: TextStyle(color: palette.muted),
                                  ),
                                ),
                                const SizedBox(width: AppDesign.spaceLg),
                                Flexible(
                                  child: Text(
                                    points ?? '—',
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontSize: AppDesign.headingSize,
                                      fontWeight: FontWeight.w700,
                                      color: palette.action,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppDesign.spaceXl),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: palette.border),
                          borderRadius: BorderRadius.circular(
                            AppDesign.cardRadius,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Your referral code',
                              style: TextStyle(color: palette.muted),
                            ),
                            const SizedBox(height: AppDesign.spaceMd),
                            SelectableText(
                              code.isEmpty ? 'Unavailable' : code,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: AppDesign.headingSize,
                                fontWeight: FontWeight.w700,
                                color: palette.text,
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: palette.action,
                              ),
                              onPressed:
                                  code.isEmpty
                                      ? null
                                      : () async {
                                        await Clipboard.setData(
                                          ClipboardData(text: code),
                                        );
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Referral code copied',
                                              ),
                                            ),
                                          );
                                      },
                              icon: const Icon(Icons.copy_outlined, size: 18),
                              label: const Text('Copy Code'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDesign.spaceXl),
                      Builder(
                        builder:
                            (shareContext) => ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: palette.action,
                                foregroundColor: palette.onAction,
                                elevation: 0,
                                minimumSize: const Size.fromHeight(54),
                                shape: const StadiumBorder(),
                              ),
                              onPressed:
                                  link.isEmpty
                                      ? null
                                      : () async {
                                        final box =
                                            shareContext.findRenderObject()
                                                as RenderBox?;
                                        try {
                                          await Share.share(
                                            '$message\n\n$link',
                                            sharePositionOrigin:
                                                box == null
                                                    ? null
                                                    : box.localToGlobal(
                                                          Offset.zero,
                                                        ) &
                                                        box.size,
                                          );
                                        } catch (_) {
                                          if (context.mounted) {
                                            showErrorToast(
                                              'Unable to open sharing. Please try again.',
                                              context,
                                            );
                                          }
                                        }
                                      },
                              icon: const Icon(Icons.ios_share_outlined),
                              label: const Text('Share with friends'),
                            ),
                      ),
                      const SizedBox(height: AppDesign.spaceXxl),
                      Text(
                        'Let a friend scan your code',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(height: AppDesign.spaceLg),
                      if (qr.isNotEmpty)
                        Center(
                          child: Container(
                            width: 240,
                            padding: const EdgeInsets.all(AppDesign.spaceLg),
                            color: Colors.white,
                            child: PrettyQrView.data(
                              data: qr,
                              decoration: const PrettyQrDecoration(
                                quietZone: PrettyQrQuietZone.standart,
                              ),
                              errorCorrectLevel: QrErrorCorrectLevel.Q,
                            ),
                          ),
                        )
                      else
                        Text(
                          'QR code unavailable',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: palette.muted),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
