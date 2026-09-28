import 'package:flutter/services.dart';
// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../../util/utils.dart';
import '../../../widgets/widgets.dart';
import '../../authentication/authentication.dart';
import '../../maintenance/maintenance.dart';
import '../../profile/profile.dart';
import '../../security_pin/security_pin.dart';
import '../../settings/setting.dart';
import '../../voucher/voucher.dart';
import '../wallet.dart';

class WalletView extends StatefulWidget {
  final Function changeView;

  const WalletView({super.key, required this.changeView});

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  String passcodePin = '';
  String? versionNum, buildNum;
  bool isProcessing = false;
  bool? clickPasscode = false;
  int? totalMyVoucher = 0;
  var profileData, height, width;

  void setProcessingStatus(bool processing) {
    setState(() {
      isProcessing = processing;
    });
  }

  @override
  initState() {
    super.initState();

    fToast = FToast();
    fToast.init(context);

    getAppVersion();
  }

  Future<void> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String version = packageInfo.version; // e.g. "1.0.0"
    String buildNumber = packageInfo.buildNumber; // e.g. "1"

    if (!mounted) return;
    setState(() {
      versionNum = version;
      buildNum = buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    double statusbarHeight = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: mainColor,
        statusBarIconBrightness: Brightness.light,
        // iOS: Dark content mode (which translates to white text/icons on iOS)
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: colorWhite,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          Navigator.of(context).pushNamedAndRemoveUntil(
            OderRoutes.home,
            (Route<dynamic> route) => false,
          );
        },
        child: OderScaffold(
          background: AppDesign.profile.background,
          bottomMenuIndex: 3,
          isShow: true,
          showAppbar: false,
          extendBodyBehindAppBar: true,
          canClick: false,
          isCenterTitle: false,
          body: BlocConsumer<WalletBloc, WalletState>(
            listener: (context, state) {},
            builder: (context, state) {
              if (state is WalletLoaded) {
                profileData = state.userQrcode;

                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 50),
                    child: Column(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            gradient: AppDesign.profileHeader,
                          ),
                          child: Column(
                            children: [
                              _topBody(statusbarHeight),
                              _creditPointsBalanceBody(),
                            ],
                          ),
                        ),
                        _topupBody(),
                        _settingBody(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: marginHorizontal,
                          ),
                          child: Container(
                            padding: const EdgeInsets.only(
                              top: AppDesign.spaceXxl,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Version: ",
                                  style: TextStyle(
                                    color: colorSoftGrey,
                                    fontFamily: fontFamilyMain,
                                    fontWeight: FontWeight.w300,
                                    fontSize: AppDesign.bodySize,
                                  ),
                                ),
                                Text(
                                  "$versionNum ($buildNum)",
                                  style: TextStyle(
                                    color: colorSoftGrey,
                                    fontFamily: fontFamilyMain,
                                    fontWeight: FontWeight.w300,
                                    fontSize: AppDesign.bodySize,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return LoadingWidget();
            },
          ),
        ),
      ),
    );
  }

  Widget _topBody(double statusbarHeight) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDesign.spaceXl,
        statusbarHeight + AppDesign.spaceXl,
        AppDesign.spaceXl,
        AppDesign.spaceXl,
      ),
      child: Column(
        children: [
          const SizedBox(height: AppDesign.spaceSm),
          Row(
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: ClipOval(
                  child: CachedImage(imageUrl: profileData.profile.image ?? ''),
                ),
              ),
              const SizedBox(width: AppDesign.spaceLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profileData.profile.name ?? '',
                      style: const TextStyle(
                        fontSize: AppDesign.sectionTitleSize,
                        fontWeight: FontWeight.w700,
                        color: AppDesign.profileHeaderText,
                      ),
                    ),
                    const SizedBox(height: AppDesign.spaceSm),
                    Text(
                      profileData.profile.code ?? '',
                      style: const TextStyle(
                        fontSize: AppDesign.bodySize,
                        color: AppDesign.profileHeaderSecondary,
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppDesign.profileHeaderText,
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                      onPressed:
                          () => Navigator.of(
                            context,
                          ).pushNamed(OderRoutes.profile),
                      child: const Text(
                        'View Profile',
                        style: TextStyle(color: colorSoftGrey),
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

  Widget _balanceRow(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDesign.spaceLg),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: const TextStyle(
                  color: AppDesign.profileHeaderSecondary,
                  fontSize: AppDesign.bodySize,
                ),
              ),
            ),
            const SizedBox(width: AppDesign.spaceLg),
            Expanded(
              flex: 3,
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: AppDesign.profileHeaderText,
                  fontSize: AppDesign.titleSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppDesign.spaceSm),
            const Icon(
              Icons.chevron_right,
              color: AppDesign.profileHeaderSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _openHistory(int tab) {
    Navigator.of(context)
        .pushNamed(
          OderRoutes.history,
          arguments: HistoryParameters(selectedTab: tab),
        )
        .then((_) {
          if (mounted) BlocProvider.of<WalletBloc>(context).add(WalletLoad());
        });
  }

  Widget _creditPointsBalanceBody() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDesign.spaceXl,
        0,
        AppDesign.spaceXl,
        AppDesign.spaceXl,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spaceLg,
        vertical: AppDesign.spaceXs,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppDesign.profileHeaderSecondary.withValues(alpha: .35),
        ),
        borderRadius: BorderRadius.circular(AppDesign.cardRadius),
      ),
      child: Column(
        children: [
          BlocBuilder<VoucherBloc, VoucherState>(
            builder: (context, state) {
              if (state is VoucherCountLoaded) {
                totalMyVoucher = state.vouchersLength;
              }
              return _balanceRow('My Voucher', totalMyVoucher.toString(), () {
                Storage().rewardReload = '';
                Navigator.of(context).pushNamedAndRemoveUntil(
                  OderRoutes.voucher,
                  (route) => false,
                  arguments: VoucherParameters(
                    selectedTab: 1,
                    filterBy: 'all',
                    filterValue: '1',
                  ),
                );
              });
            },
          ),
          _balanceRow(
            '$creditLabelTitle ($creditLabelText)',
            profileData.profile.credits ?? '',
            () => _openHistory(0),
          ),
          _balanceRow(
            pointLabelTitle,
            profileData.profile.points ?? '',
            () => _openHistory(1),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(String title, IconData icon, VoidCallback onTap) {
    final palette = AppDesign.profile;
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.action,
          padding: const EdgeInsets.symmetric(vertical: AppDesign.spaceXl),
          side: BorderSide(color: palette.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesign.cardRadius),
          ),
        ),
        onPressed: onTap,
        child: Column(
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: AppDesign.spaceMd),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _topupBody() {
    return Padding(
      padding: const EdgeInsets.all(AppDesign.spaceXl),
      child: Row(
        children: [
          _quickAction('Top-up', Icons.add_circle_outline, _topupCredit),
          const SizedBox(width: AppDesign.spaceLg),
          _quickAction(
            'History',
            Icons.receipt_long_outlined,
            () => _openHistory(0),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(
      top: AppDesign.spaceXl,
      bottom: AppDesign.spaceMd,
    ),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: AppDesign.profile.text,
          fontSize: AppDesign.sectionTitleSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );

  Widget _settingBody() {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: marginHorizontal),
          decoration: BoxDecoration(
            color: AppDesign.profile.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'My Account',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppDesign.profile.text,
                    ),
                  ),
                ),
                OderMenuLine(
                  palette: AppDesign.profile,
                  title: 'My Account',
                  icon: Image(
                    image: AssetImage(
                      'assets/icons/settings/account-circle-line.webp',
                    ),
                  ),
                  onTap: (() {
                    // Storage().page = 'card';
                    Navigator.of(context).pushNamed(OderRoutes.profile).then((
                      value,
                    ) {
                      // if (!mounted) return;
                      // BlocProvider.of<WalletBloc>(context).add(WalletLoad());
                    });
                  }),
                ),
                SizedBox(height: height * 0.01),
                OderMenuLine(
                  palette: AppDesign.profile,
                  title: 'Refer Friends',
                  icon: Image(
                    image: AssetImage(
                      'assets/icons/settings/hand-heart-line.webp',
                    ),
                  ),
                  onTap: (() async {
                    // var currentBrightness = await ScreenBrightness().current;
                    // var newBrightness = 1 - currentBrightness;

                    // BrightnessCheck()
                    //     .setBrightness(currentBrightness + newBrightness);

                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pushNamed(OderRoutes.refer).then((
                      value,
                    ) {
                      // BrightnessCheck().resetBrightness();
                      if (!mounted) return;
                      BlocProvider.of<ProfileBloc>(context).add(ProfileLoad());
                    });
                  }),
                ),
                SizedBox(height: height * 0.01),
                _sectionTitle('Favourites'),
                OderMenuLine(
                  palette: AppDesign.profile,
                  title: 'Following Merchant',
                  icon: Image(
                    image: AssetImage('assets/icons/settings/user_add.webp'),
                  ),
                  onTap: (() {
                    Storage().page = '';
                    Navigator.of(context).pushNamed(OderRoutes.favMerchant);
                  }),
                ),
                SizedBox(height: height * 0.01),
                OderMenuLine(
                  palette: AppDesign.profile,
                  title: 'Favourite Brands\' Outlets',
                  icon: Image(
                    image: AssetImage('assets/icons/settings/fav_brand.webp'),
                  ),
                  onTap: (() {
                    Storage().page = '';
                    Navigator.of(context).pushNamed(OderRoutes.favOutlet);
                  }),
                ),
                SizedBox(height: height * 0.01),
                OderMenuLine(
                  palette: AppDesign.profile,
                  title: 'Favourite Deals',
                  icon: Image(
                    image: AssetImage('assets/icons/settings/fav-deal.webp'),
                  ),
                  onTap: (() {
                    Storage().page = '';
                    Navigator.of(context).pushNamed(OderRoutes.favDeal);
                  }),
                ),
                SizedBox(height: height * 0.01),
                _sectionTitle('Security'),
                BlocConsumer<SecurityBloc, SecurityState>(
                  listener: (context, securityState) {
                    fToast = FToast();
                    fToast.init(context);

                    if (securityState is SecurityError) {
                      setState(() => clickPasscode = false);
                      showErrorToast(securityState.error, context);
                    }
                    if (securityState is SecurityMaintenanceError) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        OderRoutes.maintenanceScreen,
                        (route) => false,
                        arguments: MaintenanceParameters(
                          message: securityState.message,
                        ),
                      );
                    }
                    if (securityState is SecurityCheckVerified) {
                      if (securityState.verified == false) {
                        Storage().set = 'create';
                        Storage().page = 'wallet';
                        // Storage().email = email!;

                        // BlocProvider.of<SecurityBloc>(context)
                        //     .add(SecurityOtpSend());

                        Navigator.of(
                          context,
                        ).pushNamed(OderRoutes.securityCreate).then((value) {
                          setState(() {
                            clickPasscode = false;
                          });
                        });
                      } else {
                        Storage().set = 'reset';
                        Storage().page = 'wallet';
                        Navigator.of(
                          context,
                        ).pushNamed(OderRoutes.securityChange).then((value) {
                          setState(() {
                            clickPasscode = false;
                          });
                        });
                      }
                    }
                    if (securityState is SecurityOtpSent) {
                      showSuccessToast(securityState.data['message'], context);
                      Navigator.of(context)
                          .pushNamed(
                            OderRoutes.securityOtp,
                            arguments: SecurityOtpParameters(
                              otpData: securityState.data,
                            ),
                          )
                          .then((value) {
                            setState(() {
                              clickPasscode = false;
                            });
                          });
                    }
                  },
                  builder: (context, securityState) {
                    return OderMenuLine(
                      palette: AppDesign.profile,
                      title: 'Passcode',
                      icon: Image(
                        image: AssetImage(
                          'assets/icons/settings/lock-password-line.webp',
                        ),
                      ),
                      onTap:
                          clickPasscode == false
                              ? (() {
                                setState(() {
                                  clickPasscode = true;
                                });
                                // print('ALREADY CLICK !!!!!!');
                                BlocProvider.of<SecurityBloc>(
                                  context,
                                ).add(SecurityStart());
                              })
                              : () {},
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: ScreenSize.height * 0.02),
        Container(
          margin: EdgeInsets.symmetric(horizontal: marginHorizontal),
          decoration: BoxDecoration(
            color: AppDesign.profile.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Support',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppDesign.profile.text,
                    ),
                  ),
                ),
                urlAboutUs != ''
                    ? OderMenuLine(
                      palette: AppDesign.profile,
                      title: 'About Us',
                      icon: Image(
                        image: AssetImage(
                          'assets/icons/settings/team-line.webp',
                        ),
                      ),
                      onTap:
                          (() => {
                            Navigator.push(
                              context,
                              NoAnimationPageRoute(
                                builder: (context) {
                                  // Directly return WidgetWebView, as it contains its own Scaffold and AppBar
                                  return WidgetWebView(
                                    widgetUrl: urlAboutUs,
                                    title: 'About Us',
                                  );
                                },
                              ),
                            ),
                          }),
                    )
                    : SizedBox(),
                urlFAQ != ''
                    ? OderMenuLine(
                      palette: AppDesign.profile,
                      title: 'Help Center',
                      icon: Image(
                        image: AssetImage(
                          'assets/icons/settings/customer-service-line.webp',
                        ),
                      ),
                      onTap:
                          (() => {
                            Navigator.push(
                              context,
                              NoAnimationPageRoute(
                                builder: (context) {
                                  // Directly return WidgetWebView, as it contains its own Scaffold and AppBar
                                  return WidgetWebView(
                                    widgetUrl: urlFAQ,
                                    title: 'FAQ',
                                  );
                                },
                              ),
                            ),
                          }),
                    )
                    : SizedBox(),
                urlTerm != ''
                    ? OderMenuLine(
                      palette: AppDesign.profile,
                      title: 'Terms of Use',
                      icon: Image(
                        image: AssetImage(
                          'assets/icons/settings/file-list-2-line.webp',
                        ),
                      ),
                      onTap:
                          (() => {
                            Navigator.push(
                              context,
                              NoAnimationPageRoute(
                                builder: (context) {
                                  // Directly return WidgetWebView, as it contains its own Scaffold and AppBar
                                  return WidgetWebView(
                                    widgetUrl: urlTerm,
                                    title: 'Terms of Use',
                                  );
                                },
                              ),
                            ),
                          }),
                    )
                    : SizedBox(),
                urlPolicy != ''
                    ? OderMenuLine(
                      palette: AppDesign.profile,
                      title: 'Privacy Policy',
                      icon: Image(
                        image: AssetImage(
                          'assets/icons/settings/shield-keyhole-line.webp',
                        ),
                      ),
                      onTap:
                          (() => {
                            Navigator.push(
                              context,
                              NoAnimationPageRoute(
                                builder: (context) {
                                  // Directly return WidgetWebView, as it contains its own Scaffold and AppBar
                                  return WidgetWebView(
                                    widgetUrl: urlPolicy,
                                    title: 'Privacy Policy',
                                  );
                                },
                              ),
                            ),
                          }),
                    )
                    : SizedBox(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDesign.spaceXl,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppDesign.profile.action,
                        minimumSize: const Size.fromHeight(52),
                        side: BorderSide(color: AppDesign.profile.border),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {
                        BlocProvider.of<AuthenticationBloc>(
                          context,
                        ).add(AuthenticationLoggedOut());
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          OderRoutes.login,
                          (route) => false,
                        );
                      },
                      child: const Text('Log Out'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _topupCredit() {
    Navigator.of(context).pushNamed(OderRoutes.creditOnline).then((value) {
      if (!mounted) return;
      BlocProvider.of<WalletBloc>(context).add(WalletLoad());
    });
  }
}
