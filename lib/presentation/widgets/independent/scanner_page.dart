import 'dart:developer';
import 'dart:io';

import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app_setting/app_setting.dart';
import '../../../locator.dart';
import '../../features/authentication/authentication.dart';
import '../../features/maintenance/maintenance.dart';
import '../../features/rewards/reward.dart';
import '../../features/settings/setting.dart';
import '../../features/voucher/voucher.dart';
import '../widgets.dart';

/* Widget class for barcode/ qrcode scanner.  */

/// AppBarcodeScannerWidget
class AppBarcodeScannerWidget extends StatefulWidget {
  final String tabFor;

  const AppBarcodeScannerWidget.defaultStyle({super.key, required this.tabFor});

  @override
  State<AppBarcodeScannerWidget> createState() => _AppBarcodeState();
}

class _AppBarcodeState extends State<AppBarcodeScannerWidget> {
  // ignore: unused_field
  bool _isGranted = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      TargetPlatform platform = Theme.of(context).platform;
      // if (!kIsWeb) {
      if (platform == TargetPlatform.android ||
          platform == TargetPlatform.iOS) {
        _listenForPermissionStatus();
      } else {
        setState(() {
          _isGranted = true;
        });
      }
    });

    // Permission.camera.status.then((value) async {
    //   print('PERMISSION CAMERA: $value');
    //   if (value == PermissionStatus.granted) {
    //     _isGranted = true;
    //   } else if (value == PermissionStatus.denied) {
    //     _listenForPermissionStatus();
    //   }
    // });
  }

  void _listenForPermissionStatus() async {
    bool isGrated = true;
    if (await Permission.camera.status.isGranted) {
      isGrated = true;
    } else {
      if (await Permission.camera.request().isGranted) {
        isGrated = true;
      }

      if (Platform.isAndroid) {
        if (await Permission.camera.isDenied ||
            await Permission.camera.isPermanentlyDenied) {
          // The user opted to never again see the permission request dialog for this
          // app. The only way to change the permission's status now is to let the
          // user manually enable it in the system settings.
          openAppSettings().then((value) {
            if (!mounted) return;
            Navigator.pop(context);
          });
        }
      }
    }
    setState(() {
      _isGranted = isGrated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // Storage().page == 'voucher'
        //     ?
        MultiBlocProvider(
          providers: [
            BlocProvider<RewardBloc>(
              create:
                  (context) =>
                      RewardBloc(context: context, rewardRepository: sl()),
            ),
            BlocProvider<VoucherBloc>(create: (context) => VoucherBloc()),
          ],
          child: Expanded(
            child:
                _isGranted == true
                    ? _BarcodeScannerWidget(tabFor: widget.tabFor)
                    : Container(),
          ),
        ),
      ],
    );
  }
}

///ScannerWidget
class _BarcodeScannerWidget extends StatefulWidget {
  final String tabFor;

  // ignore: unused_element_parameter
  const _BarcodeScannerWidget({super.key, required this.tabFor});

  @override
  State<_BarcodeScannerWidget> createState() => _AppBarcodeScannerWidgetState();
}

class _AppBarcodeScannerWidgetState extends State<_BarcodeScannerWidget> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  int selectedTabVoucher = 0;
  bool isProcessing = false;
  bool _isProcessingScan = false;
  final TextEditingController voucherCodeController = TextEditingController();
  final FocusNode voucherCodeFocus = FocusNode();

  void setProcessingStatus(bool processing) {
    setState(() {
      isProcessing = processing;
    });
  }

  @override
  void initState() {
    super.initState();

    fToast = FToast();
    fToast.init(context);
  }

  Future<void> _resumeAfterRedeemError() async {
    // _isProcessingScan = false;
    // if (!mounted) return;
    // setProcessingStatus(false);
    // await controller?.resumeCamera();

    if (!mounted) return;
    setState(() {
      result = null;
      _isProcessingScan = false;
      isProcessing = false;
    });

    // Refresh BLoC state so it doesn't stay in RewardRedeemFailed
    BlocProvider.of<RewardBloc>(context).add(RewardScannerLoad());

    // Reset camera stream session cleanly
    await controller?.pauseCamera();
    await Future.delayed(const Duration(milliseconds: 300));
    await controller?.resumeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    voucherCodeController.dispose();
    voucherCodeFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(systemNavigationBarColor: colorWhite),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (widget.tabFor == 'voucher') {
            Navigator.of(context).pushNamedAndRemoveUntil(
              OderRoutes.voucher,
              (Route<dynamic> route) => false,
              arguments: VoucherParameters(
                selectedTab: 0,
                filterBy: 'all',
                filterValue: '1',
              ),
            );
          } else {
            Navigator.pop(context);
          }
        },
        child: Scaffold(
          backgroundColor: colorTransparent,
          extendBodyBehindAppBar: true,
          body: BlocConsumer<RewardBloc, RewardState>(
            listener: (context, rewardState) {
              if (rewardState is RewardRedeemSuccess) {
                selectedTabVoucher = 0;
                RewardSuccessDialog.showRewardSuccessDialog(
                  context,
                  rewardState.redeemResponse,
                  // '${rewardState.redeemResponse['message']} \n\n ${rewardState.redeemResponse['data']['message']}',
                  () {
                    if (rewardState.redeemResponse['data']['type'] ==
                        'voucher') {
                      BlocProvider.of<VoucherBloc>(context).add(
                        VoucherCategoriesLoad(
                          filterBy: 'all',
                          filterValue: 'all',
                        ),
                      );
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        OderRoutes.voucher,
                        (Route<dynamic> route) => false,
                        arguments: VoucherParameters(
                          selectedTab: 1,
                          filterBy: 'all',
                          filterValue: '0',
                        ),
                      );
                    } else if (rewardState.redeemResponse['data']['type'] ==
                        'point') {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        OderRoutes.history,
                        (Route<dynamic> route) => false,
                        arguments: HistoryParameters(selectedTab: 1),
                      );
                    } else {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        OderRoutes.history,
                        (Route<dynamic> route) => false,
                        arguments: HistoryParameters(selectedTab: 0),
                      );
                    }
                  },
                );
              }
              if (rewardState is RewardRedeemFailed) {
                Storage().rewardReload = 'yes';
                _resumeAfterRedeemError();

                showErrorScannerToast(
                  rewardState.redeemResponse['message']?.toString() ??
                      'Unable to redeem this QR code.',
                  context,
                );
              }
              if (rewardState is RewardError) {
                _resumeAfterRedeemError();
                showErrorToast(rewardState.error, context);
              }
              if (rewardState is RewardNetworkError) {
                _resumeAfterRedeemError();
                showErrorToast(rewardState.error, context);
              }
              if (rewardState is RewardSessionError) {
                sessionExpiredLogOut(rewardState.error);
              }
              /* --------------------------------------------------------------- Listen to maintenance error, navigate to maintenance page */
              if (rewardState is RewardMaintenanceError) {
                Navigator.pushAndRemoveUntil<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder:
                        (BuildContext context) => MaintenanceScreen(
                          parameters: MaintenanceParameters(
                            message: rewardState.message,
                          ),
                        ),
                  ),
                  ModalRoute.withName('/'),
                );
              }
            },
            builder: (context, state) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(child: _buildQrView(context)),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(child: _buildScannerHeader(context)),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildScannerActions(context),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildScannerHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDesign.spaceLg,
        AppDesign.spaceMd,
        AppDesign.spaceLg,
        AppDesign.spaceMd,
      ),
      child: Row(
        children: [
          _scannerIconButton(
            icon: Icons.arrow_back_rounded,
            label: 'Close scanner',
            onPressed: () => _closeScanner(context),
          ),
          Expanded(
            child: Text(
              _isQrScan ? 'Scan QR code' : 'Scan barcode',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: colorWhite,
                fontFamily: fontFamilyMain,
                fontSize: AppDesign.sectionTitleSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          FutureBuilder<bool?>(
            future: controller?.getFlashStatus(),
            builder: (context, snapshot) {
              final flashOn = snapshot.data == true;
              return _scannerIconButton(
                icon:
                    flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                label: flashOn ? 'Turn off flash' : 'Turn on flash',
                iconColor: flashOn ? AppDesign.scanner.action : colorWhite,
                onPressed: () async {
                  await controller?.toggleFlash();
                  if (mounted) setState(() {});
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _scannerIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color iconColor = colorWhite,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.black.withValues(alpha: 0.48),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: iconColor, size: 23),
          ),
        ),
      ),
    );
  }

  Widget _buildScannerActions(BuildContext context) {
    final isVoucherScanner = Storage().page == 'voucher';
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 44, 20, AppDesign.spaceLg),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Color(0xE6000000)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _scanInstruction,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: colorWhite,
                fontFamily: fontFamilyMain,
                fontSize: AppDesign.bodySize,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isVoucherScanner) ...[
              const SizedBox(height: AppDesign.spaceLg),
              SizedBox(
                width: double.infinity,
                height: AppDesign.setupButtonHeight,
                child: ElevatedButton.icon(
                  onPressed:
                      isProcessing ? null : () => _openManualEntry(context),
                  icon: const Icon(Icons.keyboard_alt_outlined, size: 19),
                  label: const Text('Enter Promo Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppDesign.scanner.action,
                    foregroundColor: AppDesign.scanner.onAction,
                    disabledBackgroundColor: AppDesign.setupDisabled,
                    disabledForegroundColor: AppDesign.scanner.muted,
                    elevation: 0,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontFamily: fontFamilyMain,
                      fontSize: AppDesign.bodySize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _isQrScan =>
      Storage().page == 'voucher' ||
      Storage().page == 'redeemVoucher' ||
      scanning == 'qr';

  String get _scanInstruction =>
      _isQrScan
          ? 'Place the QR code inside the frame'
          : 'Place the barcode inside the frame';

  void _closeScanner(BuildContext context) {
    if (widget.tabFor == 'voucher') {
      Navigator.of(context).pushNamedAndRemoveUntil(
        OderRoutes.voucher,
        (Route<dynamic> route) => false,
        arguments: VoucherParameters(
          selectedTab: 0,
          filterBy: 'all',
          filterValue: '1',
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _openManualEntry(BuildContext context) async {
    if (!mounted) return;

    // Pause the camera before presenting the sheet. This prevents the QR stream
    // from redeeming a code while the user is entering one manually.
    await controller?.pauseCamera();
    if (!context.mounted) return;

    await launchManual(context);
  }

  Widget _buildQrView(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scanArea = (size.width * 0.74).clamp(220.0, 320.0).toDouble();

    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: AppDesign.scanner.action,
        borderRadius: 18,
        borderLength: 34,
        borderWidth: 7,
        cutOutSize: scanArea,
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      controller.resumeCamera();
      this.controller = controller;
    });

    controller.scannedDataStream.listen((scanData) async {
      if (!mounted) return;

      if (_isProcessingScan ||
          scanData.code == null ||
          scanData.code!.isEmpty) {
        return;
      }

      setState(() {
        _isProcessingScan = true;
        result = scanData;

        // if (result!.code!.isNotEmpty) {
        //   // controller.pauseCamera();
        //   // controller.stopCamera();

        //   if (Storage().page == 'voucher') {
        //     BlocProvider.of<RewardBloc>(
        //       context,
        //     ).add(RewardRedeemQrLoad(code: result!.code!));
        //   } else if (Storage().page == 'referral') {
        //     controller.stopCamera();
        //     Future.delayed(Duration.zero, () {
        //       if (!mounted) return;
        //       Navigator.pop(context, result!.code!);
        //     });
        //   } else {
        //     controller.stopCamera();
        //     Future.delayed(Duration.zero, () {
        //       if (!mounted) return;
        //       Navigator.popAndPushNamed(
        //         context,
        //         OderRoutes.voucherDesc,
        //         result: result!.code!.toString(),
        //       );
        //       // Navigator.pushNamedAndRemoveUntil(
        //       //     context, OderRoutes.voucherDesc, (route) => false);
        //     });
        //   }
        // }
      });

      if (Storage().page == 'voucher') {
        // Pause camera to stop stream emissions while redeeming voucher
        await controller.pauseCamera();

        if (!mounted) return;
        setProcessingStatus(true);
        BlocProvider.of<RewardBloc>(
          context,
        ).add(RewardRedeemQrLoad(code: result!.code!));
      } else if (Storage().page == 'referral') {
        await controller.stopCamera();

        Future.delayed(Duration.zero, () {
          if (!mounted) return;
          Navigator.pop(context, result!.code!);
        });
      } else {
        // Default / fallback behavior for voucherDesc navigation
        await controller.stopCamera();

        Future.delayed(Duration.zero, () {
          if (!mounted) return;
          Navigator.popAndPushNamed(
            context,
            OderRoutes.voucherDesc,
            result: result!.code!.toString(),
          );
        });
      }
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('no Permission')));
    }
  }

  Future<void> launchManual(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final rewardBloc = context.read<RewardBloc>();
    final code = await showAccountSheet<String>(
      context,
      AppDesign.scanner,
      Builder(
        builder: (sheetContext) {
          return Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sheetTitle('Enter Promo Code', AppDesign.scanner),
                const SizedBox(height: AppDesign.spaceSm),
                Text(
                  'Enter the code from your promotion to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppDesign.scanner.muted,
                    fontFamily: fontFamilyMain,
                    fontSize: AppDesign.bodySize,
                  ),
                ),
                const SizedBox(height: AppDesign.spaceXl),
                TextFormField(
                  controller: voucherCodeController,
                  focusNode: voucherCodeFocus,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(
                    color: AppDesign.scanner.text,
                    fontFamily: fontFamilyMain,
                    fontSize: AppDesign.bodyLargeSize,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: outlinedAccountField(
                    const InputDecoration(
                      labelText: 'Promo code',
                      hintText: 'Enter code',
                    ),
                    AppDesign.scanner,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a promo code';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    if (formKey.currentState?.validate() == true) {
                      Navigator.pop(
                        sheetContext,
                        voucherCodeController.text.trim(),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppDesign.spaceXl),
                AccountPrimaryButton(
                  label: 'Redeem code',
                  palette: AppDesign.voucherDetails,
                  onPressed: () {
                    if (formKey.currentState?.validate() == true) {
                      Navigator.pop(
                        sheetContext,
                        voucherCodeController.text.trim(),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppDesign.spaceSm),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: TextButton.styleFrom(
                    foregroundColor: AppDesign.scanner.text,
                    textStyle: const TextStyle(
                      fontFamily: fontFamilyMain,
                      fontSize: AppDesign.bodySize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (!mounted) return;

    voucherCodeController.clear();
    voucherCodeFocus.unfocus();

    if (code == null || code.trim().isEmpty) {
      _isProcessingScan = false;
      setProcessingStatus(false);
      await controller?.resumeCamera();
      return;
    }

    // Keep the camera paused while the manual code is being redeemed. The
    // reward listener resumes it after an error and navigates away on success.
    _isProcessingScan = true;
    setProcessingStatus(true);
    rewardBloc.add(RewardRedeemQrLoad(code: code.trim()));
  }

  void sessionExpiredLogOut(String error) {
    setState(() {
      fToast = FToast();
      fToast.init(context);
    });

    showErrorToast('$error\nYou will be logged out.', context);
    BlocProvider.of<AuthenticationBloc>(context).add(AuthenticationLoggedOut());
    Navigator.of(context).pushNamedAndRemoveUntil(
      OderRoutes.login,
      (Route<dynamic> route) => false,
    );
  }
}
