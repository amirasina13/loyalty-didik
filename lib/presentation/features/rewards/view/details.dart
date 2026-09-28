import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../../data/data.dart';
import '../../../navigation_service.dart';
import '../../../widgets/extensions/location_screen.dart';
import '../../../widgets/widgets.dart';
import '../../authentication/authentication.dart';
import '../../maintenance/maintenance_screen.dart';
import '../../outlet/outlet_details_screen.dart';
import '../../security_pin/security_pin.dart';
import '../../voucher/voucher.dart';
import '../../webview/webviews.dart';
import '../reward.dart';

class DetailsView extends StatefulWidget {
  final Function? changeView;
  final String? title;
  final int? indexPage;

  const DetailsView({super.key, this.changeView, this.title, this.indexPage});

  @override
  State<DetailsView> createState() => _DetailsViewState();
}

class _PaymentMethod {
  final String id;
  final String label;
  final String amount;
  final num? credits;
  final num? points;

  const _PaymentMethod({
    required this.id,
    required this.label,
    required this.amount,
    this.credits,
    this.points,
  });
}

class _PurchaseRequest {
  final String paymentMethod;
  final int quantity;
  final String referral;

  const _PurchaseRequest({
    required this.paymentMethod,
    required this.quantity,
    required this.referral,
  });
}

class _PaymentChoice extends StatelessWidget {
  final _PaymentMethod method;
  final bool selected;
  final PagePalette palette;
  final VoidCallback onTap;

  const _PaymentChoice({
    required this.method,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: '${method.label}: ${method.amount}',
      child: Material(
        color:
            selected
                ? colorBlueDidik.withValues(alpha: 0.1)
                : palette.background,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesign.spaceLg,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: selected ? palette.action : palette.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? palette.action : palette.muted,
                ),
                const SizedBox(width: AppDesign.spaceMd),
                Expanded(
                  child: Text(
                    method.label,
                    style: TextStyle(
                      color: palette.text,
                      fontFamily: fontFamilyMain,
                      fontSize: AppDesign.bodySize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  method.amount,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: palette.text,
                    fontFamily: fontFamilyMain,
                    fontSize: AppDesign.bodySize,
                    fontWeight: FontWeight.w700,
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

class _PaymentUnavailable extends StatelessWidget {
  final PagePalette palette;

  const _PaymentUnavailable({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spaceLg),
      decoration: BoxDecoration(
        color: colorBlueDidik.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'No payment option is available for this voucher.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: palette.muted,
          fontFamily: fontFamilyMain,
          fontSize: AppDesign.bodySize,
        ),
      ),
    );
  }
}

class _PaymentTotal extends StatelessWidget {
  final _PaymentMethod? method;
  final int quantity;
  final PagePalette palette;

  const _PaymentTotal({
    required this.method,
    required this.quantity,
    required this.palette,
  });

  String _format(num value) => value.toStringAsFixed(2);

  String get value {
    final selected = method;
    if (selected == null) return 'Select a payment option';
    if (selected.id == 'free') return 'Free';
    final credits = selected.credits;
    final points = selected.points;
    final parts = <String>[];
    if (credits != null && credits > 0) {
      parts.add('${_format(credits * quantity)} Credits');
    }
    if (points != null && points > 0) {
      parts.add('${_format(points * quantity)} Points');
    }
    return parts.isEmpty ? selected.amount : parts.join(' + ');
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppDesign.spaceLg,
      vertical: 13,
    ),
    decoration: BoxDecoration(
      color: colorBlueDidik.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total',
          style: TextStyle(
            color: palette.text,
            fontFamily: fontFamilyMain,
            fontSize: AppDesign.bodySize,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: AppDesign.spaceLg),
        Expanded(
          child: Align(
            alignment: Alignment.topRight,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.action,
                fontFamily: fontFamilyMain,
                fontSize: AppDesign.bodySize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final int maximum;
  final PagePalette palette;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  const _QuantityControl({
    required this.quantity,
    required this.maximum,
    required this.palette,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spaceMd,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Quantity',
              style: TextStyle(
                color: palette.text,
                fontFamily: fontFamilyMain,
                fontSize: AppDesign.bodySize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Decrease quantity',
            onPressed: onDecrease,
            icon: Icon(Icons.remove_circle_outline, color: palette.action),
          ),
          Text(
            '$quantity',
            style: TextStyle(
              color: palette.text,
              fontFamily: fontFamilyMain,
              fontSize: AppDesign.bodySize,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            tooltip: 'Increase quantity',
            onPressed: onIncrease,
            icon: Icon(Icons.add_circle_outline, color: palette.action),
          ),
          Text(
            'of $maximum',
            style: TextStyle(
              color: palette.muted,
              fontFamily: fontFamilyMain,
              fontSize: AppDesign.captionSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsViewState extends State<DetailsView> with RouteAware {
  bool isProcessing = false;
  String _result = '';
  _PurchaseRequest? _pendingPurchase;
  String? _pendingRewardId;
  bool isFavouriteClick = false;
  bool isFavClick = false;

  final GlobalKey<VideoPlayerAppState> _videoPlayerKey = GlobalKey();
  final GlobalKey<YoutubePlayerCustomState> _youtubePlayerKey = GlobalKey();
  final GlobalKey<RedirectWebViewState> _controller = GlobalKey();

  void setProcessingStatus(bool processing) {
    if (!mounted) return;
    setState(() {
      isProcessing = processing;
    });
  }

  @override
  void initState() {
    super.initState();

    fToast = FToast();
    fToast.init(context);

    initializeDateFormatting();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  /// Called when another page is pushed on top of DetailsView.
  @override
  void didPushNext() {
    _stopAllMedia();
  }

  // Future<void> _stopVideoIfActive() async {
  //   _videoPlayerKey.currentState?.stopVideo();
  // }

  // Future<void> _stopVideoYoutube() async {
  //   _youtubePlayerKey.currentState?.stopVideoYoutube();
  // }

  // Future<void> _stopWebviewDeeplink() async {
  //   _controller.currentState?.clearWebview();
  // }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _stopAllMedia();
    super.dispose();
  }

  Future<void> _stopAllMedia() async {
    _videoPlayerKey.currentState?.stopVideo();
    _youtubePlayerKey.currentState?.stopVideoYoutube();
    _controller.currentState?.clearWebview();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        _stopAllMedia();

        if (didPop) return;
        navigateBack();
      },
      child: BlocConsumer<RewardBloc, RewardState>(
        listener: (context, state) {
          // fToast = FToast();
          // fToast.init(context);

          // if (Storage().globalValue!['vouchers'] == true &&
          //     Storage().globalValue!['subscriptions'] == true) {
          //   selectedTabVoucher = 0;
          // } else if (Storage().globalValue!['vouchers'] == false) {
          //   selectedTabVoucher = 3;
          // } else {
          //   selectedTabVoucher = 0;
          // }

          /* --------------------------------------------------------------------- Listen to maintenance error, navigate to maintenance page */
          if (state is RewardMaintenanceError) {
            Navigator.pushAndRemoveUntil<void>(
              context,
              MaterialPageRoute<void>(
                builder:
                    (BuildContext context) => MaintenanceScreen(
                      parameters: MaintenanceParameters(message: state.message),
                    ),
              ),
              ModalRoute.withName('/'),
            );
          }

          if (state is RewardDownloadSuccess) {
            setProcessingStatus(false);
            showSuccessToast(state.data['message'], context);

            Navigator.of(context).pushNamedAndRemoveUntil(
              OderRoutes.voucher,
              (route) => false,
              arguments: VoucherParameters(
                selectedTab: 1,
                filterBy: 'all',
                filterValue: '1',
              ),
            );
          }

          if (state is RewardPurchaseSuccess) {
            setProcessingStatus(false);
            showSuccessToast(state.data['message'], context);

            Navigator.of(context).pushNamedAndRemoveUntil(
              OderRoutes.voucher,
              (route) => false,
              arguments: VoucherParameters(
                selectedTab: 1,
                filterBy: 'all',
                filterValue: '1',
              ),
            );
          }

          if (state is RewardRedeemFailed) {
            setProcessingStatus(false);
            showErrorToast(state.redeemResponse['message'], context);
            // Navigator.pop(context);
            BlocProvider.of<RewardBloc>(
              context,
            ).add(RewardDetailsLoad(rewardId: Storage().rewardId));
          }

          if (state is RewardSessionError) {
            sessionExpiredLogOut(state.error);
          }
          if (state is RewardError) {
            setProcessingStatus(false);
            showErrorToast(state.error, context);
          }
          if (state is RewardNetworkError) {
            showErrorToast('No internet connection', context);
            Navigator.of(context).pushNamedAndRemoveUntil(
              OderRoutes.home,
              (Route<dynamic> route) => false,
            );
          }

          if (state is RewardDetailsLoaded) {
            isFavClick = false;
          }
        },
        builder: (context, state) {
          if (state is RewardOutletStarted) {
            BlocProvider.of<RewardBloc>(
              context,
            ).add(RewardDetailsLoad(rewardId: Storage().rewardId));
          }

          if (state is RewardDetailsLoaded) {
            var detail = state.details;
            var rewardId = detail.voucher?.id;
            var dateFormateStart =
                _formatDetailDate(detail.voucher?.start) ?? '—';
            var dateFormateEnd = _formatDetailDate(detail.voucher?.end) ?? '—';
            isFavouriteClick = detail.voucher?.isFavourite ?? false;

            if (rewardId != null) {
              return GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.velocity.pixelsPerSecond.dx > 50) {
                    _stopAllMedia();
                    navigateBack();
                  }
                },
                child: BlocListener<SecurityBloc, SecurityState>(
                  listener:
                      (context, securityState) => _handleRewardSecurityState(
                        context,
                        securityState,
                        detail.voucher!,
                      ),
                  child: voucherDetail(
                    detail,
                    rewardId,
                    dateFormateStart,
                    dateFormateEnd,
                  ),
                ),
              );
            }

            return Container();
          }
          // return Container(color: colorBackground);
          return OderScaffold(
            body: LoadingWidget(),
            bottomMenuIndex: widget.indexPage == 0 ? 0 : 3,
          );
        },
      ),
    );
  }

  Widget voucherDetail(
    DetailsData detail,
    String rewardId,
    String dateFormateStart,
    String dateFormateEnd,
  ) {
    final voucher = detail.voucher!;
    final outlets = detail.outlets ?? const <RewardOutlet>[];
    final payment = voucher.purchaseText?.trim();
    final start = _formatDetailDate(voucher.start) ?? dateFormateStart;
    final end = _formatDetailDate(voucher.end) ?? dateFormateEnd;

    return OderScaffold(
      systemUiOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: colorBackground,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: colorTransparent,
      ),
      title: Text(
        voucher.name?.trim().isNotEmpty == true
            ? voucher.name!
            : (widget.title ?? 'Voucher'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: fontFamilyMain,
          color: AppDesign.voucherDetails.text,
          fontWeight: FontWeight.w700,
          fontSize: AppDesign.bodyLargeSize,
        ),
      ),
      leading: IconButton(
        tooltip: 'Back',
        icon: Icon(Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back),
        onPressed: () {
          _stopAllMedia();
          navigateBack();
        },
      ),
      bottomMenuIndex: widget.indexPage == 0 ? 0 : 3,
      body: SafeArea(
        child: VoucherDetailBody(
          imageUrl: voucher.image,
          title: voucher.name ?? widget.title ?? 'Voucher',
          label: null,
          isMuslim: voucher.isMuslim ?? false,
          muslimCategory: voucher.muslimCategory,
          isFavourite: voucher.isFavourite ?? isFavouriteClick,
          favouriteLoading: isFavClick,
          onFavourite: () => _toggleRewardFavourite(voucher),
          onShare: () => _shareReward(voucher),
          paymentSummary: payment,
          paymentSubtext: _rewardBalanceText(detail.member),
          facts: [
            VoucherDetailFact(
              label: 'Valid dates',
              value: '$start – $end',
              icon: Icons.calendar_today_outlined,
            ),
            VoucherDetailFact(
              label: 'Redemption limit',
              value:
                  voucher.redeem == null ? '—' : '${voucher.redeem} voucher(s)',
              icon: Icons.confirmation_number_outlined,
            ),
          ],
          sections: [
            VoucherDetailSection(
              title: 'Description',
              initiallyExpanded: true,
              content: _detailCopy(voucher.desc),
            ),
            VoucherDetailSection(
              title: 'Terms & Conditions',
              content: HtmlWidget(
                voucher.tnc?.trim().isNotEmpty == true ? voucher.tnc! : '—',
                onTapUrl:
                    (url) => openInAppWebView(
                      context,
                      url,
                      title: voucher.name ?? widget.title ?? 'Voucher',
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
              content: _rewardOutletsContent(outlets),
            ),
          ],
          bottomAction: _buildRewardPurchaseButton(detail, rewardId),
        ),
      ),
    );
  }

  void _toggleRewardFavourite(Details voucher) {
    if (isFavClick || voucher.id == null) return;

    setState(() {
      isFavClick = true;
      isFavouriteClick = !(voucher.isFavourite ?? isFavouriteClick);
    });
    Storage().page = 'details_wishlist';
    context.read<RewardBloc>().add(
      RewardAddRemoveFavouriteLoad(
        voucherId: voucher.id!,
        filterBy: 'all',
        filterValue: 'all',
      ),
    );
  }

  Future<void> _shareReward(Details voucher) async {
    final parts = <String>[
      voucher.share?.trim() ?? '',
      voucher.shareLink?.trim() ?? '',
    ]..removeWhere((part) => part.isEmpty);
    if (parts.isEmpty) return;
    await Share.share(parts.join('\n\n'));
  }

  String? _formatDetailDate(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateFormat(appDateFormat).format(parsed);
  }

  String? _rewardBalanceText(Member? member) {
    if (member == null) return null;
    final balances = <String>[];
    final credits = member.credits?.trim() ?? '';
    final points = member.points?.trim() ?? '';
    if (credits.isNotEmpty) balances.add('$credits Credits available');
    if (points.isNotEmpty) balances.add('$points Points available');
    return balances.isEmpty ? null : balances.join('  ·  ');
  }

  Widget _detailCopy(String? value) {
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

  Widget _rewardOutletsContent(List<RewardOutlet> outlets) {
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
          _buildOutletTile(visibleOutlets[index]),
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

  Widget _buildOutletTile(RewardOutlet outlet) {
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

  Widget _buildRewardPurchaseButton(DetailsData detail, String rewardId) {
    final voucher = detail.voucher!;
    final enabled = (voucher.isAbleRedeem ?? false) && !isProcessing;
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed:
            enabled
                ? () {
                  _stopAllMedia();
                  setProcessingStatus(true);
                  showPaybyModal(detail, rewardId);
                }
                : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? secondaryColor : AppDesign.setupDisabled,
          foregroundColor: colorBlackText,
          disabledForegroundColor: AppDesign.voucherDetails.muted,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              voucher.isSoldOut == true ? 'Sold out' : 'Buy Now',
              style: TextStyle(
                color: colorWhite,
                fontFamily: fontFamilyMain,
                fontSize: AppDesign.bodySize,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (voucher.isSoldOut != true) ...[
              const SizedBox(height: 2),
              Text(
                'Choose how to pay',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorWhite,
                  fontFamily: fontFamilyMain,
                  fontSize: AppDesign.captionSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> showPaybyModal(DetailsData detail, String rewardId) async {
    final voucher = detail.voucher!;
    final methods = _paymentMethodsFor(voucher);
    var referralCode = TempData.voucherRefCode;
    final maxQuantity = _quantityLimit(voucher.redeem);
    var quantity = 1;
    var acceptedTerms = false;

    _result = methods.length == 1 ? methods.first.id : '';
    final request = await showModalBottomSheet<_PurchaseRequest>(
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
            final selectedMethod = methods.where(
              (method) => method.id == _result,
            );
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.86,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    AppDesign.spaceMd,
                    20,
                    20,
                  ),
                  child: Column(
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
                        'Choose how to pay',
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
                        'Select payment, quantity and referral details.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppDesign.voucherPurchase.muted,
                          fontFamily: fontFamilyMain,
                          fontSize: AppDesign.bodySize,
                        ),
                      ),
                      const SizedBox(height: AppDesign.spaceLg),
                      if (methods.isEmpty)
                        _PaymentUnavailable(palette: AppDesign.voucherPurchase)
                      else
                        for (final method in methods)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PaymentChoice(
                              method: method,
                              selected: _result == method.id,
                              palette: AppDesign.voucherPurchase,
                              onTap:
                                  () =>
                                      setSheetState(() => _result = method.id),
                            ),
                          ),
                      const SizedBox(height: AppDesign.spaceXs),
                      _QuantityControl(
                        quantity: quantity,
                        maximum: maxQuantity,
                        palette: AppDesign.voucherPurchase,
                        onDecrease:
                            quantity > 1
                                ? () => setSheetState(() => quantity--)
                                : null,
                        onIncrease:
                            quantity < maxQuantity
                                ? () => setSheetState(() => quantity++)
                                : null,
                      ),
                      const SizedBox(height: AppDesign.spaceMd),
                      _PaymentTotal(
                        method:
                            selectedMethod.isEmpty
                                ? null
                                : selectedMethod.first,
                        quantity: quantity,
                        palette: AppDesign.voucherPurchase,
                      ),
                      const SizedBox(height: AppDesign.spaceMd),
                      TextFormField(
                        initialValue: referralCode,
                        onChanged: (value) => referralCode = value,
                        textCapitalization: TextCapitalization.characters,
                        style: TextStyle(
                          color: AppDesign.voucherPurchase.text,
                          fontFamily: fontFamilyMain,
                          fontSize: AppDesign.bodySize,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Referral code (optional)',
                          labelStyle: TextStyle(
                            color: AppDesign.voucherPurchase.muted,
                            fontFamily: fontFamilyMain,
                            fontSize: AppDesign.bodySize,
                          ),
                          filled: true,
                          fillColor: AppDesign.voucherPurchase.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: BorderSide(
                              color: AppDesign.voucherPurchase.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: BorderSide(
                              color: AppDesign.voucherPurchase.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: BorderSide(
                              color: AppDesign.voucherPurchase.action,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDesign.spaceSm),
                      CheckboxListTile(
                        value: acceptedTerms,
                        onChanged:
                            (value) => setSheetState(
                              () => acceptedTerms = value ?? false,
                            ),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppDesign.voucherPurchase.action,
                        title: Text(
                          'I accept the Terms & Conditions and Privacy Policy.',
                          style: TextStyle(
                            color: AppDesign.voucherPurchase.muted,
                            fontFamily: fontFamilyMain,
                            fontSize: AppDesign.smallSize,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDesign.spaceSm),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                _result = '';
                                Navigator.pop(sheetContext);
                              },
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    AppDesign.voucherPurchase.action,
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: AppDesign.spaceMd),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed:
                                  _result.isEmpty ||
                                          methods.isEmpty ||
                                          !acceptedTerms
                                      ? null
                                      : () => Navigator.pop(
                                        sheetContext,
                                        _PurchaseRequest(
                                          paymentMethod: _result,
                                          quantity: quantity,
                                          referral: referralCode.trim(),
                                        ),
                                      ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppDesign.voucherPurchase.action,
                                foregroundColor:
                                    AppDesign.voucherPurchase.onAction,
                                disabledBackgroundColor:
                                    AppDesign.setupDisabled,
                                disabledForegroundColor:
                                    AppDesign.voucherPurchase.muted,
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
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (request == null) {
      setProcessingStatus(false);
      _result = '';
      return;
    }

    TempData.voucherRefCode = request.referral;
    _result = '';
    _pendingPurchase = request;
    _pendingRewardId = rewardId;
    Storage().page = 'reward_details';
    Storage().rewardId = rewardId;
    setProcessingStatus(true);
    context.read<SecurityBloc>().add(SecurityStart());
  }

  List<_PaymentMethod> _paymentMethodsFor(Details voucher) {
    final creditsText = voucher.aftDisCredits ?? voucher.credits;
    final pointsText = voucher.aftDisPoints ?? voucher.points;
    final credits = _paymentAmount(creditsText);
    final points = _paymentAmount(pointsText);
    final method = voucher.purchaseMethod?.trim().toLowerCase();

    if (voucher.voucherType?.trim().toLowerCase() == 'downloadable') {
      return const [
        _PaymentMethod(
          id: 'free',
          label: 'Free',
          amount: 'No payment required',
          credits: 0,
          points: 0,
        ),
      ];
    }

    if (method == 'credits') {
      return _isPositive(credits)
          ? [
            _PaymentMethod(
              id: 'credits',
              label: 'Credits',
              amount: creditsText ?? '—',
              credits: credits,
            ),
          ]
          : const [];
    }
    if (method == 'points') {
      return _isPositive(points)
          ? [
            _PaymentMethod(
              id: 'points',
              label: 'Points',
              amount: pointsText ?? '—',
              points: points,
            ),
          ]
          : const [];
    }
    if (method == 'both') {
      return _isPositive(credits) && _isPositive(points)
          ? [
            _PaymentMethod(
              id: 'both',
              label: 'Credits + Points',
              amount: '${creditsText ?? '—'} + ${pointsText ?? '—'}',
              credits: credits,
              points: points,
            ),
          ]
          : const [];
    }

    return [
      if (_isPositive(credits))
        _PaymentMethod(
          id: 'credits',
          label: 'Credits',
          amount: creditsText ?? '—',
          credits: credits,
        ),
      if (_isPositive(points))
        _PaymentMethod(
          id: 'points',
          label: 'Points',
          amount: pointsText ?? '—',
          points: points,
        ),
    ];
  }

  int _quantityLimit(int? value) {
    return value == null || value < 1 ? 1 : value;
  }

  void _handleRewardSecurityState(
    BuildContext context,
    SecurityState securityState,
    Details voucher,
  ) {
    if (securityState is SecurityCheckVerified) {
      if (!securityState.verified) {
        Storage().page = 'reward_details';
        Navigator.of(context).pushNamed(OderRoutes.securityCreate).then((_) {
          if (mounted) setProcessingStatus(false);
        });
        return;
      }

      final request = _pendingPurchase;
      final rewardId = _pendingRewardId ?? voucher.id;
      if (request == null || rewardId == null) {
        setProcessingStatus(false);
        return;
      }

      final rewardBloc = context.read<RewardBloc>();
      Navigator.of(context).pushNamed(OderRoutes.passcodeKey).then((value) {
        if (!mounted) return;
        if (value == null) {
          setProcessingStatus(false);
          return;
        }

        final pin = value.toString();
        if (voucher.voucherType?.trim().toLowerCase() == 'downloadable') {
          rewardBloc.add(
            RewardDownload(
              voucherId: rewardId,
              pin: pin,
              referral: request.referral,
              quantity: request.quantity.toString(),
            ),
          );
        } else {
          rewardBloc.add(
            RewardPurchaseLoad(
              voucherId: rewardId,
              redeemVia:
                  request.paymentMethod == 'both'
                      ? 'credits'
                      : request.paymentMethod,
              pin: pin,
              points: '0.00',
              referral: request.referral,
              quantity: request.quantity.toString(),
            ),
          );
        }
      });
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

  num? _paymentAmount(String? value) {
    final raw = value?.trim() ?? '';
    return num.tryParse(raw);
  }

  bool _isPositive(num? value) => value != null && value > 0;

  void navigateBack() {
    if (TempData.deeplink.isNotEmpty) {
      TempData.deeplink = '';
      _stopAllMedia();
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      OderRoutes.voucher,
      (Route<dynamic> route) => true,
      arguments: VoucherParameters(
        selectedTab: 0,
        filterBy: 'all',
        filterValue: '1',
      ),
    );
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
