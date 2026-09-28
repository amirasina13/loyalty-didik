import 'dart:async';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../../data/data.dart';
import '../../../widgets/extensions/location_screen.dart';
import '../../../widgets/widgets.dart';
import '../../maintenance/maintenance.dart';
import '../../outlet/outlet_details_screen.dart';
import '../../security_pin/security_pin.dart';
import '../voucher.dart';

class VoucherDescView extends StatefulWidget {
  final Function? changeView;
  final String? title;
  final int? quantity;

  const VoucherDescView({
    super.key,
    this.changeView,
    this.title,
    this.quantity,
  });

  @override
  State<VoucherDescView> createState() => _VoucherDescViewState();
}

class _VoucherDescViewState extends State<VoucherDescView> with RouteAware {
  bool isProcessing = false;
  int redeemMethod = 1;
  int? quantity;
  String passcodePin = '', qrCode = '';
  List<RewardOutlet> vouchersOutlet = [];
  SliderButtonController slideController = SliderButtonController();
  late Timer durationLoading;
  late VoucherDetails detail;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    quantity = widget.quantity;
  }

  void setProcessingStatus(bool processing) {
    if (!mounted) return;
    setState(() {
      isProcessing = processing;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          OderRoutes.voucher,
          (Route<dynamic> route) => false,
          arguments: VoucherParameters(
            selectedTab: 1,
            filterBy: 'all',
            filterValue: '1',
          ),
        );
      },
      child: OderScaffold(
        title: Text(
          widget.title ?? 'My voucher',
          style: TextStyle(
            fontFamily: fontFamilyMain,
            color: colorBlack,
            fontWeight: FontWeight.w700,
            fontSize: AppDesign.appBarTitleSize,
            // overflow: TextOverflow.ellipsis,
          ),
          textScaler: TextScaler.linear(scaleFactor),
          textAlign: TextAlign.center,
        ),
        bottomMenuIndex: 2,
        body: SafeArea(
          child: Container(
            color: colorBackground,
            child: BlocConsumer<VoucherBloc, VoucherState>(
              listener: (context, state) {
                fToast = FToast();
                fToast.init(context);

                if (state is VoucherOutletStarted) {
                  BlocProvider.of<VoucherBloc>(
                    context,
                  ).add(VoucherDetailsLoad(voucherId: Storage().voucherId));
                }

                if (state is VoucherRedeemSuccess) {
                  VoucherSuccessDialog.showVoucherSuccessDialog(
                    context,
                    state.redeemResponse,
                    () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        OderRoutes.voucher,
                        (Route<dynamic> route) => false,
                        arguments: VoucherParameters(
                          selectedTab: 2,
                          filterBy: 'all',
                          filterValue: '1',
                        ),
                      );
                    },
                  );
                }
              },
              builder: (context, state) {
                // if (state is VoucherOutletStarted) {
                //   BlocProvider.of<VoucherBloc>(
                //     context,
                //   ).add(VoucherDetailsLoad(voucherId: Storage().voucherId));
                // }

                if (state is VoucherDetailsLoaded) {
                  detail = state.details;
                  var voucherId = detail.id;
                  vouchersOutlet = state.details.outlets ?? <RewardOutlet>[];

                  if (voucherId != null) {
                    return BlocListener<SecurityBloc, SecurityState>(
                      listener:
                          (context, securityState) =>
                              _handleModernSecurityState(
                                context,
                                securityState,
                                detail,
                              ),
                      child: _buildModernOwnedVoucherDetail(context, detail),
                    );
                  }

                  var formatter = DateFormat(appDateFormat);
                  final parsedExpiry = DateTime.tryParse(detail.expired ?? '');
                  var dateFormate =
                      parsedExpiry == null
                          ? '—'
                          : formatter.format(parsedExpiry);

                  if (voucherId != null) {
                    return RefreshIndicator(
                      key: _refreshIndicatorKey,
                      onRefresh: () async {
                        await Future.delayed(Duration(seconds: 1));
                        BlocProvider.of<VoucherBloc>(
                          // ignore: use_build_context_synchronously
                          context,
                        ).add(VoucherOutletCheck());
                      },
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Container(
                              color: colorBackground,
                              // margin: EdgeInsets.fromLTRB(
                              //     marginHorizontal, 0, marginHorizontal, 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.fromLTRB(
                                          marginHorizontal,
                                          0,
                                          marginHorizontal,
                                          26,
                                        ),
                                        // padding: EdgeInsets.only(bottom: 26),
                                        child: AspectRatio(
                                          aspectRatio: 1 / 1,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: colorDisableGrey,
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: colorGreyBox,
                                                  blurRadius: 5.0,
                                                  offset: Offset(0.0, 5.0),
                                                ),
                                              ],
                                            ),
                                            child: CachedImage(
                                              imageUrl: detail.image!,
                                              // colorFilter: ColorFilter.mode(
                                              //   colorWhite.withOpacity(0.35),
                                              //   BlendMode.dstATop,
                                              // ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      detail.isMuslim == true
                                          ? Positioned(
                                            right: 20,
                                            top: 5,
                                            child: HalalWidget(
                                              muslimCategory:
                                                  detail.muslimCategory!,
                                              width: ScreenSize.width * 0.15,
                                            ),
                                          )
                                          : SizedBox(),
                                    ],
                                  ),
                                  Container(
                                    margin: EdgeInsets.fromLTRB(
                                      marginHorizontal,
                                      0,
                                      marginHorizontal,
                                      0,
                                    ),
                                    child: Text(
                                      detail.name!,
                                      style: TextStyle(
                                        fontFamily: fontFamilyMain,
                                        fontSize: AppDesign.titleSize,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: marginHorizontal,
                                      vertical: 20,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        InkWell(
                                          child: Container(
                                            // height: height * 0.07,
                                            width: ScreenSize.width * 0.35,
                                            padding: EdgeInsets.all(3),
                                            // margin: EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              // shape: BoxShape.circle,
                                              color: colorGoldButton,
                                              border: Border.all(
                                                color: colorWhite,
                                                width: 2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: colorGreyBox,
                                                  blurRadius: 4.0,
                                                  spreadRadius: 2,
                                                  offset: Offset(0.0, 1.0),
                                                ),
                                              ],
                                            ),
                                            child: Container(
                                              margin: EdgeInsets.all(
                                                AppDesign.spaceSm,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Image(
                                                    width:
                                                        ScreenSize.width *
                                                        0.035,
                                                    image: AssetImage(
                                                      'assets/icons/empty_brand.webp',
                                                    ),
                                                    color: colorBlackTab,
                                                  ),
                                                  SizedBox(
                                                    width:
                                                        ScreenSize.width * 0.01,
                                                  ),
                                                  Text(
                                                    '${detail.outlets!.length} Outlet(s)',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize:
                                                          AppDesign.bodySize,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: mainColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          onTap: () {
                                            Navigator.of(context).pushNamed(
                                              OderRoutes.locationOutlet,
                                              arguments:
                                                  LocationScreenParameters(
                                                    locationDetails:
                                                        vouchersOutlet,
                                                  ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.fromLTRB(
                                      marginHorizontal,
                                      0,
                                      marginHorizontal,
                                      10,
                                    ),
                                    // alignment: Alignment.topLeft,
                                    color: colorBackground,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: ScreenSize.height * 0.03,
                                          height: ScreenSize.height * 0.03,
                                          margin: EdgeInsets.only(
                                            right: AppDesign.spaceLg,
                                          ),
                                          padding: EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: colorWhite,
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                            border: Border.all(
                                              color: colorRedDark,
                                            ),
                                          ),
                                          child: Image(
                                            image: AssetImage(
                                              'assets/icons/calendar.webp',
                                            ),
                                            color: colorRedDark,
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Valid till',
                                              style: TextStyle(
                                                fontFamily: fontFamilyMain,
                                                fontSize: AppDesign.captionSize,
                                                color: colorGreyBlue,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textScaler: TextScaler.linear(
                                                scaleFactor,
                                              ),
                                            ),
                                            Text(
                                              dateFormate,
                                              style: TextStyle(
                                                fontFamily: fontFamilyMain,
                                                fontSize: AppDesign.smallSize,
                                                color: colorBlack,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textScaler: TextScaler.linear(
                                                scaleFactor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(
                                    color: colorDarkGray,
                                    thickness: 0.4,
                                    indent: marginHorizontal,
                                    endIndent: marginHorizontal,
                                  ),
                                  /* --------------------------------------------------- Description title part */
                                  Container(
                                    margin: EdgeInsets.fromLTRB(
                                      marginHorizontal,
                                      10,
                                      marginHorizontal,
                                      10,
                                    ),
                                    child: Text(
                                      'Description',
                                      style: TextStyle(
                                        fontSize: AppDesign.bodyLargeSize,
                                        color: colorBlack,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      textScaler: TextScaler.linear(
                                        scaleFactor,
                                      ),
                                    ),
                                  ),
                                  /* --------------------------------------------------- Description info part(from API) */
                                  Container(
                                    margin: EdgeInsets.fromLTRB(
                                      marginHorizontal,
                                      0,
                                      marginHorizontal,
                                      20,
                                    ),
                                    padding: EdgeInsets.only(left: 20),
                                    alignment: Alignment.topLeft,
                                    color: colorWhite,
                                    child: Text(
                                      detail.desc!,
                                      style: TextStyle(
                                        fontSize: AppDesign.bodySize,
                                        // color: colorSoftGrey,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      textScaler: TextScaler.linear(
                                        scaleFactor,
                                      ),
                                    ),
                                  ),
                                  Divider(
                                    color: colorDarkGray,
                                    thickness: 0.5,
                                    indent: marginHorizontal,
                                    endIndent: marginHorizontal,
                                  ),
                                  /* --------------------------------------------------- Terms & conditions title part */
                                  Container(
                                    margin: EdgeInsets.fromLTRB(
                                      marginHorizontal,
                                      20,
                                      marginHorizontal,
                                      AppDesign.spaceLg,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Terms & Conditions:',
                                      style: TextStyle(
                                        fontSize: AppDesign.bodyLargeSize,
                                        color: colorBlack,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      textScaler: TextScaler.linear(
                                        scaleFactor,
                                      ),
                                    ),
                                  ),
                                  /* --------------------------------------------------- Terms & conditions info part(from API) */
                                  Container(
                                    color: colorTransparent,
                                    margin: EdgeInsets.fromLTRB(
                                      marginHorizontal,
                                      0,
                                      marginHorizontal,
                                      20,
                                    ),
                                    child: HtmlWidget(
                                      detail.tnc!,
                                      onTapUrl:
                                          (url) => openInAppWebView(
                                            context,
                                            url,
                                            title:
                                                detail.name ??
                                                widget.title ??
                                                'Voucher',
                                          ),
                                      textStyle: TextStyle(
                                        fontSize: AppDesign.bodySize,
                                        color: colorBlackTab,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      // customWidgetBuilder: (element) {
                                      //   if (element.localName == 'span') {
                                      //     return Text(
                                      //       element.text,
                                      //       style: TextStyle(
                                      //         fontFamily: fontFamilyMain,
                                      //         fontSize: 14,
                                      //         color: colorSoftGrey,
                                      //       ),
                                      //     );
                                      //   }
                                      //   return null;
                                      // },
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.fromLTRB(
                                      marginHorizontal,
                                      10,
                                      marginHorizontal,
                                      20,
                                    ),
                                    child: BlocConsumer<
                                      SecurityBloc,
                                      SecurityState
                                    >(
                                      listener: (context, securityState) {
                                        fToast = FToast();
                                        fToast.init(context);

                                        setProcessingStatus(false);

                                        if (securityState
                                            is SecurityCheckVerified) {
                                          if (securityState.verified == false) {
                                            Storage().page = 'voucher_details';
                                            Navigator.of(context)
                                                .pushNamed(
                                                  OderRoutes.securityCreate,
                                                )
                                                .then((value) {
                                                  if (!context.mounted) return;
                                                  BlocProvider.of<VoucherBloc>(
                                                      context,
                                                    )
                                                    ..reloadBack = true
                                                    ..add(
                                                      VoucherDetailsLoad(
                                                        voucherId:
                                                            Storage().voucherId,
                                                      ),
                                                    );

                                                  setProcessingStatus(false);

                                                  Timer(
                                                    Duration(milliseconds: 5),
                                                    () {
                                                      slideController.reset();
                                                    },
                                                  );
                                                });
                                          } else {
                                            Storage().page = 'voucher_details';
                                            redeemMethod == 1
                                                ? Navigator.of(context)
                                                    .pushNamed(
                                                      OderRoutes.passcodeKey,
                                                    )
                                                    .then((value) {
                                                      if (value != null) {
                                                        passcodePin =
                                                            value.toString();

                                                        setState(() {
                                                          BlocProvider.of<
                                                            VoucherBloc
                                                          >(context).add(
                                                            VoucherRedeem(
                                                              voucherId:
                                                                  detail.id
                                                                      .toString(),
                                                              qrCode: '',
                                                              pin:
                                                                  value
                                                                      .toString(),
                                                            ),
                                                          );
                                                        });

                                                        setProcessingStatus(
                                                          false,
                                                        );

                                                        Timer(
                                                          Duration(
                                                            milliseconds: 5,
                                                          ),
                                                          () {
                                                            slideController
                                                                .reset();
                                                          },
                                                        );
                                                      } else {
                                                        if (!context.mounted) {
                                                          return;
                                                        }
                                                        BlocProvider.of<
                                                            VoucherBloc
                                                          >(context)
                                                          ..reloadBack = true
                                                          ..add(
                                                            VoucherDetailsLoad(
                                                              voucherId:
                                                                  Storage()
                                                                      .voucherId,
                                                            ),
                                                          );

                                                        setProcessingStatus(
                                                          false,
                                                        );

                                                        Timer(
                                                          Duration(
                                                            milliseconds: 5,
                                                          ),
                                                          () {
                                                            slideController
                                                                .reset();
                                                          },
                                                        );
                                                      }
                                                    })
                                                : scanBarcodeNormal();
                                          }
                                        }

                                        if (securityState is SecurityOtpSent) {
                                          showSuccessToast(
                                            securityState.data['message'],
                                            context,
                                          );
                                          Navigator.of(context).pushNamed(
                                            OderRoutes.securityOtp,
                                            arguments: SecurityOtpParameters(
                                              otpData: securityState.data,
                                            ),
                                          );
                                        }

                                        if (securityState is SecurityError) {
                                          Navigator.pop(context);
                                          showErrorToast(
                                            securityState.error,
                                            context,
                                          );
                                        }
                                        /* ----------------------------------------------------- Listen to maintenance error, navigate to maintenance page */
                                        if (securityState
                                            is SecurityMaintenanceError) {
                                          Navigator.pushAndRemoveUntil<void>(
                                            context,
                                            MaterialPageRoute<void>(
                                              builder:
                                                  (
                                                    BuildContext context,
                                                  ) => MaintenanceScreen(
                                                    parameters:
                                                        MaintenanceParameters(
                                                          message:
                                                              securityState
                                                                  .message,
                                                        ),
                                                  ),
                                            ),
                                            ModalRoute.withName('/'),
                                          );
                                        }
                                      },
                                      builder: (context, state) {
                                        return Column(
                                          children: [
                                            SlideButton(
                                              textButton: Text(
                                                detail.redeemMethod == 'swipe'
                                                    ? 'SWIPE TO REDEEM'
                                                    : 'SCAN QR TO REDEEM',
                                                style: TextStyle(
                                                  fontFamily: fontFamilyMain,
                                                  letterSpacing: 2,
                                                  fontSize: AppDesign.bodySize,
                                                  fontWeight: FontWeight.w400,
                                                  color: colorWhite,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              textSlide: Text(
                                                'Unlock',
                                                style: TextStyle(
                                                  fontFamily: fontFamilyMain,
                                                  letterSpacing: 2,
                                                  fontSize: AppDesign.bodySize,
                                                  fontWeight: FontWeight.w400,
                                                  color: colorWhite,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              // buttonSize: height / 14,
                                              backgroundColor: colorMulberry,
                                              slideColor: colorRaspberyRed,
                                              icon: Icon(
                                                Icons.arrow_forward,
                                                color: colorWhite,
                                              ),
                                              // buttonColor: colorSlideGreen,
                                              onSlided: () async {
                                                if (detail.redeemMethod ==
                                                    'swipe') {
                                                  redeemMethod = 1;

                                                  BlocProvider.of<SecurityBloc>(
                                                    context,
                                                  ).add(SecurityStart());

                                                  return true;
                                                } else {
                                                  Storage().page =
                                                      'redeemVoucher';
                                                  redeemMethod = 2;

                                                  BlocProvider.of<SecurityBloc>(
                                                    context,
                                                  ).add(SecurityStart());

                                                  return true;
                                                }
                                              },
                                            ),
                                            Container(
                                              // child: Align(
                                              margin: EdgeInsets.only(
                                                top: 20,
                                                bottom: AppDesign.spaceLg,
                                              ),
                                              alignment: Alignment.center,
                                              child: OderButtonText(
                                                detail.redeemMethod == 'swipe'
                                                    ? 'Or click to scan QR'
                                                    : 'Or click to redeem',
                                                color: colorBlack,
                                                fontSize:
                                                    AppDesign.bodyLargeSize,
                                                underline: true,
                                                fontWeight: FontWeight.w600,
                                                // fontStyle: FontStyle.italic,
                                                onClick: () {
                                                  if (detail.redeemMethod ==
                                                      'swipe') {
                                                    Storage().page =
                                                        'redeemVoucher';
                                                    redeemMethod = 2;

                                                    BlocProvider.of<
                                                      SecurityBloc
                                                    >(
                                                      context,
                                                    ).add(SecurityStart());
                                                  } else {
                                                    redeemMethod = 1;

                                                    BlocProvider.of<
                                                      SecurityBloc
                                                    >(
                                                      context,
                                                    ).add(SecurityStart());
                                                  }
                                                  // Storage().page = 'redeemVoucher';
                                                  // redeemMethod = 2;

                                                  // BlocProvider.of<SecurityBloc>(
                                                  //         context)
                                                  //     .add(SecurityStart());
                                                  // // scanBarcodeNormal();
                                                },
                                              ),
                                              // ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Container();
                }

                return LoadingWidget();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernOwnedVoucherDetail(
    BuildContext context,
    VoucherDetails voucher,
  ) {
    final outlets = voucher.outlets ?? const <RewardOutlet>[];
    final expired = _formatVoucherDate(voucher.expired) ?? '—';

    return VoucherDetailBody(
      imageUrl: voucher.image,
      title: voucher.name ?? widget.title ?? 'My voucher',
      label: null,
      isMuslim: voucher.isMuslim ?? false,
      muslimCategory: voucher.muslimCategory,
      onShare: () => _shareOwnedVoucher(voucher),
      facts: [
        VoucherDetailFact(
          label: 'Valid until',
          value: expired,
          icon: Icons.calendar_today_outlined,
        ),
        VoucherDetailFact(
          label: 'Quantity',
          value: quantity == null ? '—' : 'x$quantity',
          icon: Icons.confirmation_number_outlined,
        ),
      ],
      sections: [
        VoucherDetailSection(
          title: 'Description',
          initiallyExpanded: true,
          content: _ownedDetailCopy(voucher.desc),
        ),
        VoucherDetailSection(
          title: 'Terms & Conditions',
          content: HtmlWidget(
            voucher.tnc?.trim().isNotEmpty == true ? voucher.tnc! : '—',
            onTapUrl:
                (url) => openInAppWebView(
                  context,
                  url,
                  title: voucher.name ?? widget.title ?? 'My voucher',
                ),
            textStyle: TextStyle(
              color: AppDesign.voucherDetails.text,
              fontFamily: fontFamilyMain,
              fontSize: AppDesign.bodySize,
              height: 1.4,
            ),
          ),
        ),
        VoucherDetailSection(
          title: 'Applicable outlets',
          content: _ownedOutletsContent(context, outlets),
        ),
      ],
      bottomAction: _buildOwnedVoucherActions(context, voucher),
      palette: AppDesign.voucherDetails,
    );
  }

  Widget _ownedDetailCopy(String? value) {
    final copy = value?.trim() ?? '';
    return Text(
      copy.isEmpty ? 'Description unavailable' : copy,
      style: TextStyle(
        color: AppDesign.voucherDetails.text,
        fontFamily: fontFamilyMain,
        fontSize: AppDesign.bodySize,
        height: 1.4,
      ),
    );
  }

  Widget _ownedOutletsContent(
    BuildContext context,
    List<RewardOutlet> outlets,
  ) {
    if (outlets.isEmpty) {
      return Text(
        'Applicable outlet details are unavailable.',
        style: TextStyle(
          color: AppDesign.voucherDetails.muted,
          fontFamily: fontFamilyMain,
          fontSize: AppDesign.bodySize,
        ),
      );
    }

    final visibleOutlets = outlets.take(5).toList(growable: false);

    return Column(
      children: [
        for (int index = 0; index < visibleOutlets.length; index++) ...[
          _buildOwnedOutletTile(context, visibleOutlets[index]),
          if (index != visibleOutlets.length - 1)
            Divider(height: 1, color: AppDesign.voucherDetails.border),
        ],
        if (outlets.length > visibleOutlets.length) ...[
          const SizedBox(height: AppDesign.spaceSm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  OderRoutes.locationOutlet,
                  arguments: LocationScreenParameters(locationDetails: outlets),
                );
              },
              icon: Icon(
                Icons.list_alt_outlined,
                color: AppDesign.voucherDetails.action,
                size: 18,
              ),
              label: Text(
                'View all outlets',
                style: TextStyle(
                  color: AppDesign.voucherDetails.action,
                  fontFamily: fontFamilyMain,
                  fontSize: AppDesign.bodySize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOwnedOutletTile(BuildContext context, RewardOutlet outlet) {
    final place = outlet.place?.trim() ?? '';
    final address = outlet.address?.trim() ?? '';
    final distance = outlet.distance?.trim() ?? '';
    final subtitleParts = <String>[if (place.isNotEmpty) place];
    if (address.isNotEmpty && address != place) subtitleParts.add(address);
    if (distance.isNotEmpty) subtitleParts.add('$distance km away');
    final outletId = outlet.id?.trim() ?? '';
    final outletName =
        place.isNotEmpty
            ? place
            : (outlet.merchantName?.trim().isNotEmpty == true
                ? outlet.merchantName!.trim()
                : 'Outlet');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 9,
      leading: CircleAvatar(
        backgroundColor: colorBlueDidik.withValues(alpha: 0.1),
        child: Icon(
          Icons.store_outlined,
          color: AppDesign.voucherDetails.action,
        ),
      ),
      title: Text(
        outlet.merchantName?.trim().isNotEmpty == true
            ? outlet.merchantName!.trim()
            : 'Merchant unavailable',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppDesign.voucherDetails.text,
          fontFamily: fontFamilyMain,
          fontSize: AppDesign.bodySize,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitleParts.isEmpty
            ? 'Outlet details unavailable'
            : subtitleParts.join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppDesign.voucherDetails.muted,
          fontFamily: fontFamilyMain,
          fontSize: AppDesign.smallSize,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppDesign.voucherDetails.muted,
      ),
      onTap:
          outletId.isEmpty
              ? null
              : () {
                final parsedDistance = double.tryParse(distance);
                if (parsedDistance != null) {
                  Storage().distance = parsedDistance.toStringAsFixed(2);
                }
                Navigator.of(context).pushNamed(
                  OderRoutes.outletDetails,
                  arguments: OutletDetailsParameters(
                    outletId: outletId,
                    outlet: outletName,
                  ),
                );
              },
    );
  }

  Widget _buildOwnedVoucherActions(
    BuildContext context,
    VoucherDetails voucher,
  ) {
    final canRedeem = !isProcessing;
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: canRedeem ? () => _showRedeemChooser(voucher) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppDesign.voucherDetails.action,
              foregroundColor: AppDesign.voucherDetails.onAction,
              disabledBackgroundColor: AppDesign.setupDisabled,
              elevation: 0,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27),
              ),
            ),
            child: const Text('Redeem'),
          ),
        ),
      ],
    );
  }

  Future<void> _shareOwnedVoucher(VoucherDetails voucher) async {
    final parts = <String>[
      voucher.share?.trim() ?? '',
      voucher.shareLink?.trim() ?? '',
    ]..removeWhere((part) => part.isEmpty);
    if (parts.isEmpty) return;
    await Share.share(parts.join('\n\n'));
  }

  Future<void> _showRedeemChooser(VoucherDetails voucher) async {
    var selectedMethod = voucher.redeemMethod?.toLowerCase() == 'swipe' ? 1 : 2;
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppDesign.voucherPurchase.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDesign.sheetRadius),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  AppDesign.spaceMd,
                  20,
                  20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppDesign.voucherPurchase.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDesign.spaceLg),
                    Text(
                      'Choose how to redeem',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppDesign.voucherPurchase.text,
                        fontFamily: fontFamilyMain,
                        fontSize: AppDesign.headingSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppDesign.spaceSm),
                    Text(
                      'Choose how you want to redeem this voucher.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppDesign.voucherPurchase.muted,
                        fontFamily: fontFamilyMain,
                        fontSize: AppDesign.bodySize,
                      ),
                    ),
                    const SizedBox(height: AppDesign.spaceLg),
                    _RedeemChoice(
                      title: 'Redeem here',
                      subtitle: 'Confirm with the outlet.',
                      selected: selectedMethod == 1,
                      onTap: () => setSheetState(() => selectedMethod = 1),
                    ),
                    const SizedBox(height: AppDesign.spaceMd),
                    _RedeemChoice(
                      title: 'Scan outlet QR',
                      subtitle: 'Scan the QR code at the outlet.',
                      selected: selectedMethod == 2,
                      onTap: () => setSheetState(() => selectedMethod = 2),
                    ),
                    const SizedBox(height: AppDesign.spaceLg),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: TextButton.styleFrom(
                              foregroundColor: AppDesign.voucherPurchase.action,
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: AppDesign.spaceMd),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed:
                                () =>
                                    Navigator.pop(sheetContext, selectedMethod),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppDesign.voucherPurchase.action,
                              foregroundColor:
                                  AppDesign.voucherPurchase.onAction,
                              elevation: 0,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27),
                              ),
                            ),
                            child: const Text('Continue'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || selected == null) return;
    redeemMethod = selected;
    Storage().page = 'voucher_details';
    Storage().voucherId = voucher.id ?? Storage().voucherId;
    Storage().titlePasscodeRoute = voucher.name ?? widget.title;
    setProcessingStatus(true);
    context.read<SecurityBloc>().add(SecurityStart());
  }

  void _handleModernSecurityState(
    BuildContext context,
    SecurityState securityState,
    VoucherDetails voucher,
  ) {
    if (securityState is SecurityCheckVerified) {
      if (!securityState.verified) {
        Storage().page = 'voucher_details';
        Storage().voucherId = voucher.id ?? Storage().voucherId;
        Storage().titlePasscodeRoute = voucher.name ?? widget.title;
        Navigator.of(context).pushNamed(OderRoutes.securityCreate).then((_) {
          if (mounted) setProcessingStatus(false);
        });
      } else if (redeemMethod == 1) {
        final voucherBloc = context.read<VoucherBloc>();
        Navigator.of(context).pushNamed(OderRoutes.passcodeKey).then((value) {
          if (!mounted) return;
          if (value == null) {
            setProcessingStatus(false);
            return;
          }
          voucherBloc.add(
            VoucherRedeem(
              voucherId: voucher.id.toString(),
              qrCode: '',
              pin: value.toString(),
            ),
          );
          setProcessingStatus(false);
        });
      } else {
        scanBarcodeNormal();
      }
      return;
    }

    if (securityState is SecurityError) {
      setProcessingStatus(false);
      showErrorToast(securityState.error, context);
    } else if (securityState is SecurityNetworkError) {
      setProcessingStatus(false);
      showErrorToast(securityState.error, context);
    } else if (securityState is SecurityMaintenanceError) {
      setProcessingStatus(false);
      Navigator.pushAndRemoveUntil<void>(
        context,
        MaterialPageRoute<void>(
          builder:
              (context) => MaintenanceScreen(
                parameters: MaintenanceParameters(
                  message: securityState.message,
                ),
              ),
        ),
        ModalRoute.withName('/'),
      );
    }
  }

  String? _formatVoucherDate(String? value) {
    final raw = value?.trim() ?? '';
    final parsed = DateTime.tryParse(raw);
    return parsed == null ? null : DateFormat(appDateFormat).format(parsed);
  }

  /* --------------------------------------------------------------------------- Scan barcode function */
  FutureOr<void> scanBarcodeNormal() {
    /* Navigate to scan view page */
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (BuildContext context) =>
                AppBarcodeScannerWidget.defaultStyle(tabFor: 'voucher_desc'),
      ),
    ).then((value) {
      // print('QR CODE: $value');
      if (value != null) {
        qrCode = value;

        if (!mounted) return;
        Navigator.of(context).pushNamed(OderRoutes.passcodeKey).then((value) {
          if (value != null) {
            passcodePin = value.toString();

            setState(() {
              BlocProvider.of<VoucherBloc>(context).add(
                VoucherRedeem(
                  voucherId: detail.id.toString(),
                  qrCode: qrCode,
                  pin: passcodePin,
                ),
              );
            });
          } else {
            if (!mounted) return;
            BlocProvider.of<VoucherBloc>(context)
              ..reloadBack = true
              ..add(VoucherDetailsLoad(voucherId: Storage().voucherId));
          }

          setProcessingStatus(false);
          Timer(Duration(milliseconds: 5), () {
            slideController.reset();
          });
        });
      } else {
        if (!mounted) return;
        BlocProvider.of<VoucherBloc>(context)
          ..reloadBack = true
          ..add(VoucherDetailsLoad(voucherId: Storage().voucherId));

        setProcessingStatus(false);
        Timer(Duration(milliseconds: 5), () {
          slideController.reset();
        });
      }
    });
  }
}

class _RedeemChoice extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RedeemChoice({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppDesign.voucherPurchase;
    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $subtitle',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(
            AppDesign.spaceLg,
            AppDesign.spaceLg,
            AppDesign.spaceLg,
            AppDesign.spaceLg,
          ),
          decoration: BoxDecoration(
            color:
                selected
                    ? colorBlueDidik.withValues(alpha: 0.1)
                    : palette.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? palette.action : palette.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? palette.action : palette.muted,
                size: 24,
              ),
              const SizedBox(width: AppDesign.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: palette.text,
                        fontFamily: fontFamilyMain,
                        fontSize: AppDesign.bodySize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: palette.muted,
                        fontFamily: fontFamilyMain,
                        fontSize: AppDesign.smallSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
