import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:intl/date_symbol_data_local.dart';

import '../../../app_setting/app_setting.dart';
import '../../../data/data.dart';
import '../../../locator.dart';
import '../../widgets/widgets.dart';
import '../maintenance/maintenance.dart';
import '../profile/profile.dart';
import '../wrapper.dart';
import 'home.dart';

class HomeScreenNew extends StatefulWidget {
  const HomeScreenNew({super.key});

  @override
  State<HomeScreenNew> createState() => _HomeScreenNewState();
}

class _HomeScreenNewState extends State<HomeScreenNew> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      // onWillPop: () => showExitPopup(context, height),
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        showExitPopup(context, ScreenSize.height);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: colorWhite,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileProcessing) {
              return Container(
                height: ScreenSize.height,
                width: ScreenSize.width,
                color: colorWhite,
                child: const LoadingWidget(),
              );
            }
            return OderScaffold(
              showAppbar: false,
              extendBodyBehindAppBar: true,
              body: BlocProvider<HomeBloc>(
                create: (context) {
                  return HomeBloc(
                    userRepository: RepositoryProvider.of<UserRepository>(
                      context,
                    ),
                    rewardRepository: RepositoryProvider.of<RewardRepository>(
                      context,
                    ),
                  )..add(HomeLoad());
                },
                child: HomeWrapperNew(),
              ),
              bottomMenuIndex: 0,
              isShow: true,
              canClick: false,
            );
          },
        ),
      ),
    );
  }

  Future<bool> showExitPopup(context, height) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: marginHorizontal),
          insetPadding: EdgeInsets.symmetric(horizontal: marginHorizontal),
          content: SizedBox(
            height: height * 0.22,
            width: ScreenSize.width * 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: AppDesign.spaceXxl),
                      child: Text(
                        "Exit App",
                        style: TextStyle(
                          fontSize: AppDesign.bodyLargeSize,
                          fontWeight: FontWeight.w500,
                          color: colorRedLight,
                        ),
                      ),
                    ),
                    InkWell(
                      child: Container(
                        margin: EdgeInsets.only(bottom: AppDesign.spaceXxl),
                        child: Icon(Icons.close, color: colorRedLight),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                Text(
                  "Do you want to exit?",
                  style: TextStyle(
                    fontSize: AppDesign.sectionTitleSize,
                    fontWeight: FontWeight.w500,
                    color: colorOutletAddressLabelGrey,
                  ),
                ),
                SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        highlightColor: colorBackground,
                        child: Container(
                          height: height * 0.05,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: mainColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Text(
                            "Yes",
                            style: TextStyle(
                              fontSize: AppDesign.bodyLargeSize,
                              color: colorWhite,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        onTap: () {
                          exit(0);
                        },
                      ),
                    ),
                    SizedBox(width: AppDesign.spaceLg),
                    Expanded(
                      child: InkWell(
                        highlightColor: colorBackground,
                        child: Container(
                          height: height * 0.05,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colorRaspberyRed,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Text(
                            "No",
                            style: TextStyle(
                              fontSize: AppDesign.bodyLargeSize,
                              color: colorWhite,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                        },
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
  }
}

class HomeWrapperNew extends StatefulWidget {
  const HomeWrapperNew({super.key});

  @override
  OderWrapperState<HomeWrapperNew> createState() => _HomeWrapperNewState();
}

class _HomeWrapperNewState extends OderWrapperState<HomeWrapperNew> {
  var now = DateTime.now();
  var format = DateFormat('yyyy-MM-dd');
  late String dateNow = format.format(now);
  // final CarouselController _carouselController =
  //     CarouselController();
  CarouselSliderController carouselController = CarouselSliderController();
  int _current = 0;
  loc.Location? _location;
  final Permission permission = Permission.locationWhenInUse;
  String packageName = '';
  bool _hasShownAnnouncements = false;

  @override
  void initState() {
    super.initState();

    initializeDateFormatting();
    loadPackageInfo();
  }

  void loadPackageInfo() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      packageName = packageInfo.packageName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (context) {
        final homeBloc = HomeBloc(
          userRepository: sl<UserRepository>(),
          rewardRepository: sl<RewardRepository>(),
        );

        // Add multiple events to the BLoC
        homeBloc.add(HomeLoad());
        // homeBloc.add(VoucherBrandLoad());

        return homeBloc;
      },

      child: BlocConsumer<HomeBloc, HomeState>(
        listener: (context, state) async {
          fToast = FToast();
          fToast.init(context);

          if (state is HomeMaintenanceError) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              OderRoutes.maintenanceScreen,
              (Route<dynamic> route) => false,
              arguments: MaintenanceParameters(message: state.message),
            );
          }

          if (state is HomeLoaded) {
            final banners = state.homePage.banners;
            final bannerPaths =
                banners?.path
                    ?.where((item) => item.path?.trim().isNotEmpty == true)
                    .toList() ??
                const <Path>[];

            if (!_hasShownAnnouncements &&
                banners?.isShow == true &&
                bannerPaths.isNotEmpty) {
              _hasShownAnnouncements = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _showAnnouncementDialog(bannerPaths);
                }
              });
            }

            // Instantiate NewVersion manager object (Using GCP Console app as example)
            final newVersion = NewVersionPlus(
              iOSId: packageName, //'com.hdi365.makantrip',
              androidId: packageName, //'com.hdi365.makantrip',
              iOSAppStoreCountry: 'MY',
              androidPlayStoreCountry: 'MY',
            );

            // You can let the plugin handle fetching the status and showing a dialog,
            // or you can fetch the status and display your own dialog, or no dialog.

            basicStatusCheck(newVersion);

            // Check location enable or not
            bool serviceEnabled = await _isLocationServiceEnabled();
            // print('SERVICE ENABLE 1: $serviceEnabled');
            if (!serviceEnabled) {
              if (Storage().lastUpdateLoc.isEmpty &&
                  Storage().lastUpdateLoc != dateNow) {
                Storage().lastUpdateLoc = dateNow;

                locationDialog();
              }
            } else {
              await getCurrentLocation();
            }
          }

          if (state is HomeError) {
            // ignore: use_build_context_synchronously
            showErrorToast(state.error, context);
          }
          if (state is HomeSessionError) {
            sessionExpiredLogOut(state.error);
          }
        },
        builder: (context, state) {
          return getPageView(<Widget>[
            HomeViewNew(
              token: state is HomeLoaded ? state.token : '',
              changeView: changePage,
            ),
            // SearchView(changeView: changePage),
          ]);
        },
      ),
    );
  }

  Future<void> _showAnnouncementDialog(List<Path> bannerPaths) {
    _current = 0;

    return showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        final screenSize = MediaQuery.sizeOf(dialogContext);

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: colorWhite,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: AppDesign.spaceLg,
                vertical: AppDesign.spaceXl,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: screenSize.height * 0.82,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDesign.spaceLg,
                    AppDesign.spaceMd,
                    AppDesign.spaceLg,
                    AppDesign.spaceLg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Announcement',
                              style: TextStyle(
                                color: colorBlack,
                                fontFamily: fontFamilyMain,
                                fontSize: AppDesign.sectionTitleSize,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close_rounded),
                            color: colorRedDark,
                            tooltip: 'Close announcement',
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDesign.spaceXs),
                      CarouselSlider(
                        items:
                            bannerPaths.map((item) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: ColoredBox(
                                  color: colorWhite,
                                  child: CachedImage(
                                    imageUrl: item.path!,
                                    boxFit: BoxFit.contain,
                                  ),
                                ),
                              );
                            }).toList(),
                        carouselController: carouselController,
                        options: CarouselOptions(
                          // Announcement artwork is supplied as square banners.
                          aspectRatio: 1.0,
                          viewportFraction: 1.0,
                          enableInfiniteScroll: bannerPaths.length > 1,
                          autoPlay: bannerPaths.length > 1,
                          autoPlayInterval: const Duration(seconds: 5),
                          onPageChanged: (index, reason) {
                            setState(() => _current = index);
                          },
                        ),
                      ),
                      const SizedBox(height: AppDesign.spaceMd),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            bannerPaths.asMap().entries.map((entry) {
                              return GestureDetector(
                                onTap:
                                    () => carouselController.animateToPage(
                                      entry.key,
                                    ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: _current == entry.key ? 18 : 7,
                                  height: 7,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _current == entry.key
                                            ? colorRedDark
                                            : colorGrey,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }).toList(),
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
  }

  Future<void> basicStatusCheck(NewVersionPlus newVersion) async {
    try {
      final status = await newVersion.getVersionStatus();
      if (status != null) {
        if (Storage().lastUpdateCheck.isEmpty &&
            Storage().lastUpdateCheck != dateNow) {
          Storage().lastUpdateCheck = dateNow;

          if (mounted) {
            newVersion.showAlertIfNecessary(
              context: context,
              launchModeVersion: LaunchModeVersion.external,
            );
          }
        }
      }
    } catch (error) {
      // Staging packages are not published in the public store. A missing
      // listing is expected and must not surface as an unhandled exception.
      debugPrint('Store version check unavailable: ${error.runtimeType}');
    }
  }

  Future<bool> _isLocationServiceEnabled() async {
    _location ??= loc.Location();
    LocationAccuracyStatus? accuracy;

    // region fail-safe
    bool serviceEnabled;

    serviceEnabled = await _location!.serviceEnabled();

    loc.PermissionStatus permissionGranted = await _location!.hasPermission();

    await Geolocator.getLocationAccuracy()
        .then((value) {
          if (value == LocationAccuracyStatus.reduced) {
            accuracy = LocationAccuracyStatus.reduced;
            // return serviceEnabled && value == LocationAccuracyStatus.reduced;
          }
        })
        .catchError((e) {});

    if (permissionGranted == loc.PermissionStatus.denied ||
        permissionGranted == loc.PermissionStatus.deniedForever) {
      if (accuracy == LocationAccuracyStatus.reduced) {
        return (serviceEnabled && accuracy == LocationAccuracyStatus.reduced);
      }
    }

    if (Platform.isIOS &&
        permissionGranted == loc.PermissionStatus.grantedLimited) {
      return (serviceEnabled &&
          permissionGranted == loc.PermissionStatus.grantedLimited);
    }

    return (serviceEnabled &&
        permissionGranted == loc.PermissionStatus.granted);
  }

  getCurrentLocation() async {
    List<geocoding.Placemark> placemarks;

    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 100,
      timeLimit: Duration(seconds: 5),
    );

    Geolocator.getCurrentPosition(locationSettings: locationSettings)
        .then((Position position) async {
          setState(() {
            Storage().latitude = position.latitude.toString();
            Storage().longitude = position.longitude.toString();
          });

          placemarks = await geocoding.placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          geocoding.Placemark place = placemarks[0];

          Storage().address =
              '${place.street}, ${place.thoroughfare}, ${place.subLocality} ${place.locality}, ${place.postalCode}, ${place.country}';
        })
        .catchError((e) async {
          await Geolocator.getLastKnownPosition()
              .then((value) async {
                Storage().latitude = value!.latitude.toString();
                Storage().longitude = value.longitude.toString();

                placemarks = await geocoding.placemarkFromCoordinates(
                  value.latitude,
                  value.longitude,
                );
                geocoding.Placemark place = placemarks[0];

                Storage().address =
                    '${place.street}, ${place.thoroughfare}, ${place.subLocality} ${place.locality}, ${place.postalCode}, ${place.country}';
              })
              .catchError((e) async {
                Storage().latitude = '3.1390';
                Storage().longitude = '101.6869';

                placemarks = await geocoding.placemarkFromCoordinates(
                  3.1390,
                  101.6869,
                );
                geocoding.Placemark place = placemarks[0];

                Storage().address =
                    '${place.street}, ${place.thoroughfare}, ${place.subLocality} ${place.locality}, ${place.postalCode}, ${place.country}';
              });
        });
  }

  locationDialog() {
    YesNoDialog.showYesNoDialog(
      context,
      'Enable Location Service',
      Platform.isAndroid ? androidLocText : iosLocText,
      colorBlack,
      TextAlign.justify,
      OderStyleButton(
        title: 'Continue',
        backgroundColor: mainColor,
        onPressed: () async {
          Navigator.pop(context);

          bool serviceEnabled = await _location!.serviceEnabled();
          if (!serviceEnabled) {
            serviceEnabled = await _location!.requestService();
            if (!serviceEnabled) {
              Storage().locPermission = 'disable';
              getCurrentLocation();
              return;
            }
          }

          loc.PermissionStatus permissionGranted =
              await _location!.hasPermission();
          if (permissionGranted == loc.PermissionStatus.denied) {
            permissionGranted = await _location!.requestPermission();

            if (permissionGranted == loc.PermissionStatus.granted) {
              loc.Location.instance.changeSettings(
                accuracy: (loc.LocationAccuracy.high),
              );

              getCurrentLocation();
            }

            if (permissionGranted != loc.PermissionStatus.granted) {
              getCurrentLocation();
            }
          }
        },
      ),
    );
  }
}
