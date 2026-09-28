import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../../domain/domain.dart';
import '../../../../util/utils.dart';
import '../../../widgets/widgets.dart';
import '../../authentication/authentication.dart';
import '../../maintenance/maintenance_screen.dart';
import '../../photo/photo.dart';
import '../../profile/profile.dart';
import '../../webview/webviews.dart';
import '../setup.dart';

class VProfileView extends StatefulWidget {
  final Function? changeView;
  final Map profile;

  const VProfileView({super.key, this.changeView, required this.profile});

  @override
  State<VProfileView> createState() => _VProfileViewState();
}

class _VProfileViewState extends State<VProfileView> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final GlobalKey<OderInputFieldState> _fullNameKey = GlobalKey();
  final GlobalKey<OderInputFieldState> _firstNameKey = GlobalKey();
  final GlobalKey<OderInputFieldState> _lastNameKey = GlobalKey();
  final GlobalKey<OderInputFieldState> _dobKey = GlobalKey();
  final GlobalKey<OderInputFieldState> _genderKey = GlobalKey();

  String errorfield = '';
  String? path, imageBytes;

  bool isProcessing = false;
  bool error = false;
  bool isMuslim = false;
  String newDate = '';
  String errorFullName = '',
      errorFirstName = '',
      errorLastName = '',
      errorEmail = '',
      errorDob = '',
      errorGender = '',
      errorMuslim = '',
      errorContact = '';
  late FocusNode _fullNameFocus,
      _firstNameFocus,
      _lastNameFocus,
      _dobFocus,
      _genderFocus;
  String selectedCode = '60';
  DateTime? dateSelect;
  List<String> getGender = ["Male", "Female"];
  Image? image;
  String? profileImage;
  late File _image;
  final ImagePicker _picker = ImagePicker();
  var photoBloc = PhotoBloc();

  AppLinks? _appLinks;
  StreamSubscription<Uri>? _sub;

  void setProcessingStatus(bool processing) {
    setState(() {
      isProcessing = processing;
    });
  }

  void _initDeepLinkListener() {
    _appLinks = AppLinks();
    _sub = _appLinks!.uriLinkStream.listen((uri) async {
      TempData.deeplink = uri.toString();
    });
  }

  @override
  void initState() {
    super.initState();

    initializeDateFormatting();

    _setProfileData();

    _fullNameFocus = FocusNode();
    _firstNameFocus = FocusNode();
    _lastNameFocus = FocusNode();
    _dobFocus = FocusNode();
    _genderFocus = FocusNode();

    if (Platform.isIOS) {
      DeepLinkHandler.listenForDeepLinkIOS();
    } else {
      _initDeepLinkListener();
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _genderController.dispose();

    // Clean up the focus node when the Form is disposed.
    _fullNameFocus.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _dobFocus.dispose();
    _genderFocus.dispose();

    _sub?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: colorWhite,
        statusBarColor: colorWhite,
      ),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          fToast = FToast();
          fToast.init(context);
          /* --------------------------------------------------------------------- Listen to maintenance error, navigate to maintenance page */
          if (state is ProfileMaintenanceError) {
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
          /* --------------------------------------------------------------------- IF Profile got error, show error message */
          if (state is ProfileError) {
            setProcessingStatus(false);
            // ignore: unnecessary_null_comparison
            state.error != null ? error = true : error = false;
            showErrorToast(state.error, context);
            // ErrorDialog.showErrorDialog(context, state.error);
          }

          if (state is ProfilePhotoError) {
            setProcessingStatus(false);
            showErrorToast(state.error, context);
          }

          // if (state is ProfileLoaded) {
          if (state is ProfileUpdated) {
            setProcessingStatus(false);

            if (isMuslimFriendly == true &&
                widget.profile['vMuslim'] == false) {
              Storage().setupDone = false;
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  OderRoutes.setupVMuslim,
                  (Route<dynamic> route) => false,
                  arguments: VMuslimParameters(profile: widget.profile),
                );
              }
            } else if (TempData.deeplink.isNotEmpty) {
              Storage().setupDone = true;
              // Navigate to webview to intercept the url - convert from short url to long url
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => RedirectWebView(
                        parameters: DeeplinkParameters(
                          initialUrl: TempData.deeplink,
                        ),
                      ),
                ),
              );
            } else {
              if (mounted) {
                Storage().setupDone = true;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  OderRoutes.home,
                  (Route<dynamic> route) => false,
                );
              }
            }
          }

          if (state is ProfilePhotoUpdated) {
            setProcessingStatus(false);
            BlocProvider.of<ProfileBloc>(context).add(ProfileLoad());
            showSuccessToast('Profile photo updated.', context);
          }
        },
        builder: (context, state) {
          if (state is ProfileLoaded) {
            _setProfileDataImage(state);
          }

          return Theme(
            data: ThemeData(
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: errorfield == '' ? colorDarkGray : colorRed,
                selectionHandleColor: AppDesign.setup.action,
              ),
            ),
            child: SafeArea(
              child: Container(
                // color: colorBabyBlue,
                margin: EdgeInsets.fromLTRB(
                  marginHorizontal,
                  20,
                  marginHorizontal,
                  0,
                ),
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      backgroundColor: AppDesign.setup.background,
                      title: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: ScreenSize.width * 0.11,
                                height: ScreenSize.height * 0.007,
                                margin: EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: AppDesign.setup.border,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              Container(
                                width: ScreenSize.width * 0.11,
                                height: ScreenSize.height * 0.007,
                                margin: EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: AppDesign.setup.action,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              Container(
                                width: ScreenSize.width * 0.11,
                                height: ScreenSize.height * 0.007,
                                decoration: BoxDecoration(
                                  color: AppDesign.setup.border,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 10),
                            child: Text(
                              'Step 2',
                              style: TextStyle(
                                fontFamily: fontFamilyMain,
                                fontSize: AppDesign.captionSize,
                                fontWeight: FontWeight.w500,
                                color: AppDesign.setup.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BlocProvider<PhotoBloc>.value(
                            value: photoBloc,
                            child: BlocConsumer<PhotoBloc, PhotoState>(
                              listener: (context, photoState) {
                                if (photoState is PhotoSet) {
                                  _showPhotoConfirmDialog(
                                    context,
                                    photoState.photo,
                                  );
                                }
                              },
                              builder: (context, photoState) {
                                Image? image;

                                if (profileImage != null) {
                                  // image = profileImage!;
                                  image = Image.network(
                                    profileImage!,
                                    fit: BoxFit.fill,
                                  );
                                } else {
                                  image = Image.asset(
                                    'assets/icons/no_photo.png',
                                  );
                                }

                                return Center(
                                  child: Stack(
                                    children: [
                                      Container(
                                        height: ScreenSize.height / 5.8,
                                        margin: EdgeInsets.only(top: 10),
                                        color: AppDesign.setup.background,
                                        child: AspectRatio(
                                          aspectRatio: 1 / 1,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              // color: colorBabyBlue,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                width: ScreenSize.width * 0.008,
                                                color: colorBorderGray,
                                              ),
                                            ),
                                            child: ClipOval(child: image),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 6,
                                        bottom: 0.0,
                                        child: InkWell(
                                          onTap:
                                              () =>
                                                  _showSelectionDialog(context),
                                          child: Container(
                                            height: ScreenSize.height * 0.05,
                                            width: ScreenSize.height * 0.05,
                                            decoration: BoxDecoration(
                                              color: colorWhite,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                width: ScreenSize.width * 0.008,
                                                color: colorBorderGray,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.camera_alt_outlined,
                                              color: AppDesign.setup.action,
                                              size: 25.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          // SizedBox(height: sizeBetween * 0.5),
                          /* ------------------------------------------------------- Nickname input field */
                          const SizedBox(height: AppDesign.formFieldGap),
                          OderInputField(
                            palette: AppDesign.setup,
                            label: 'Display Name',
                            key: _fullNameKey,
                            controller: _fullNameController,
                            // hint: 'Example: 123456789',
                            validator: Validator.valueExists,
                            keyboard: TextInputType.emailAddress,
                            border: InputBorder.none,
                            focusNode: _fullNameFocus,
                            textCapitalization: TextCapitalization.words,
                            onValueChanged: (value) {
                              if (value != '') {
                                setState(() {
                                  errorfield = '';
                                });
                              }
                            },
                          ),
                          errorfield == 'error' || errorfield == 'errornick'
                              ? Container(
                                margin: EdgeInsets.only(top: 5),
                                child: Text(
                                  errorFullName,
                                  style: TextStyle(
                                    fontSize: AppDesign.captionSize,
                                    fontWeight: FontWeight.w400,
                                    color:
                                        error
                                            ? colorRed
                                            : errorfield == 'error' ||
                                                errorfield == 'errornick'
                                            ? colorRed
                                            : AppDesign.setup.border,
                                  ),
                                ),
                              )
                              : SizedBox(),
                          /* ----------------------------------------------------------- Firstname/Forename input field */
                          const SizedBox(height: AppDesign.formFieldGap),
                          OderInputField(
                            palette: AppDesign.setup,
                            label: 'First Name',
                            key: _firstNameKey,
                            controller: _firstNameController,
                            // hint: 'Example: 123456789',
                            validator: Validator.valueExists,
                            keyboard: TextInputType.emailAddress,
                            border: InputBorder.none,
                            focusNode: _firstNameFocus,
                            textCapitalization: TextCapitalization.words,
                            onValueChanged: (value) {
                              if (state is ProfileEditLoaded && value != '') {
                                errorfield = '';
                                BlocProvider.of<ProfileBloc>(
                                  context,
                                ).add(ProfileEditLoad(errorField: errorfield));
                              }
                            },
                          ),
                          errorfield == 'error' || errorfield == 'errorfirst'
                              ? Container(
                                margin: EdgeInsets.only(top: 5),
                                child: Text(
                                  errorFirstName,
                                  style: TextStyle(
                                    fontSize: AppDesign.captionSize,
                                    fontWeight: FontWeight.w400,
                                    color:
                                        error
                                            ? colorRed
                                            : errorfield == 'error' ||
                                                errorfield == 'errorfirst'
                                            ? colorRed
                                            : AppDesign.setup.border,
                                  ),
                                ),
                              )
                              : SizedBox(),
                          /* ----------------------------------------------------------- Last Name/ Surname input field */
                          const SizedBox(height: AppDesign.formFieldGap),
                          OderInputField(
                            palette: AppDesign.setup,
                            label: 'Last Name',
                            key: _lastNameKey,
                            controller: _lastNameController,
                            // hint: 'Example: 123456789',
                            validator: Validator.valueExists,
                            keyboard: TextInputType.emailAddress,
                            border: InputBorder.none,
                            focusNode: _lastNameFocus,
                            textCapitalization: TextCapitalization.words,
                            onValueChanged: (value) {
                              if (state is ProfileEditLoaded && value != '') {
                                errorfield = '';
                                BlocProvider.of<ProfileBloc>(
                                  context,
                                ).add(ProfileEditLoad(errorField: errorfield));
                              }
                            },
                          ),
                          errorfield == 'error' || errorfield == 'errorlast'
                              ? Container(
                                margin: EdgeInsets.only(top: 5),
                                child: Text(
                                  errorLastName,
                                  style: TextStyle(
                                    fontSize: AppDesign.captionSize,
                                    fontWeight: FontWeight.w400,
                                    color:
                                        error
                                            ? colorRed
                                            : errorfield == 'error' ||
                                                errorfield == 'errorlast'
                                            ? colorRed
                                            : AppDesign.setup.border,
                                  ),
                                ),
                              )
                              : SizedBox(),
                          /* ----------------------------------------------------------- Gender field */
                          Padding(
                            padding: const EdgeInsets.only(
                              top: AppDesign.formFieldGap,
                            ),
                            child: AccountGenderField(
                              key: _genderKey,
                              palette: AppDesign.setup,
                              options: getGender,
                              value:
                                  _genderController.text.isEmpty
                                      ? ''
                                      : _genderController.text == 'male'
                                      ? 'Male'
                                      : 'Female',
                              onChanged: (newValue) {
                                setState(() {
                                  _genderController.text =
                                      newValue.toLowerCase();
                                  errorfield = '';
                                });
                                if (state is ProfileEditLoaded) {
                                  BlocProvider.of<ProfileBloc>(
                                    context,
                                  ).add(ProfileEditLoad(errorField: ''));
                                }
                              },
                            ),
                          ),
                          errorfield == 'error' || errorfield == 'errorgender'
                              ? Container(
                                margin: EdgeInsets.only(top: 5),
                                child: Text(
                                  errorGender,
                                  style: TextStyle(
                                    fontSize: AppDesign.captionSize,
                                    fontWeight: FontWeight.w400,
                                    color:
                                        error
                                            ? colorRed
                                            : errorfield == 'error' ||
                                                errorfield == 'errorgender'
                                            ? colorRed
                                            : AppDesign.setup.border,
                                  ),
                                ),
                              )
                              : SizedBox(),
                          /* ----------------------------------------------------------- Date of Birth input field */
                          const SizedBox(height: AppDesign.formFieldGap),
                          OderInputField(
                            palette: AppDesign.setup,
                            label: 'Date of Birth *',
                            readOnly: true,
                            endIcon: Icon(
                              Icons.calendar_today_outlined,
                              color: AppDesign.setup.muted,
                              size: 20,
                            ),
                            key: _dobKey,
                            controller: _dobController,
                            // hint: 'Example: 123456789',
                            validator: Validator.valueExists,
                            keyboard: TextInputType.text,
                            border: InputBorder.none,
                            focusNode: _dobFocus,
                            onValueChanged: (value) {
                              setState(() {
                                errorfield = '';
                              });
                            },
                            onTap: () {
                              var date = DateTime.now();
                              DateTime newDateInitial;

                              if (_dobController.text.isNotEmpty) {
                                newDateInitial = DateFormat(
                                  appDateFormat,
                                ).parse(_dobController.text);
                              } else {
                                newDateInitial = DateTime(
                                  date.year - minAgeDOB,
                                  date.month,
                                  date.day,
                                );
                              }

                              FocusScope.of(context).unfocus();
                              showBirthdaySheet(
                                context,
                                firstDate: DateTime(1900),
                                lastDate: DateTime(
                                  date.year - minAgeDOB,
                                  12,
                                  31,
                                ),
                                initialDate: newDateInitial,
                              ).then((selectedDate) {
                                if (!mounted) return;
                                if (selectedDate != null) {
                                  _dobController.text = DateFormat(
                                    appDateFormat,
                                  ).format(selectedDate);

                                  dateSelect = selectedDate;

                                  if (state is ProfileEditLoaded) {
                                    errorfield = '';

                                    if (!context.mounted) return;
                                    BlocProvider.of<ProfileBloc>(context).add(
                                      ProfileEditLoad(errorField: errorfield),
                                    );
                                  }
                                }
                              });
                            },
                          ),
                          errorfield == 'error' || errorfield == 'errordob'
                              ? Container(
                                margin: EdgeInsets.only(top: 5),
                                child: Text(
                                  errorDob,
                                  style: TextStyle(
                                    fontSize: AppDesign.captionSize,
                                    fontWeight: FontWeight.w400,
                                    color:
                                        error
                                            ? colorRed
                                            : errorfield == 'error' ||
                                                errorfield == 'errordob'
                                            ? colorRed
                                            : AppDesign.setup.border,
                                  ),
                                ),
                              )
                              : SizedBox(),
                          Container(
                            margin: EdgeInsets.only(top: 17),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                AccountPrimaryButton(
                                  palette: AppDesign.setup,
                                  label: isProcessing ? 'Processing…' : 'Save',
                                  onPressed:
                                      isProcessing
                                          ? null
                                          : () {
                                            _validateAndUpdatePersonal();
                                            FocusScope.of(context).unfocus();
                                          },
                                ),
                                const SizedBox(height: AppDesign.spaceLg),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppDesign.setup.action,
                                    padding: const EdgeInsets.all(
                                      AppDesign.spaceLg,
                                    ),
                                  ),
                                  onPressed: () {
                                    BlocProvider.of<AuthenticationBloc>(
                                      context,
                                    ).add(AuthenticationLoggedOut());
                                    Storage().token = '';
                                    Navigator.of(
                                      context,
                                    ).pushNamedAndRemoveUntil(
                                      OderRoutes.login,
                                      (route) => false,
                                    );
                                  },
                                  child: const Text('Log Out'),
                                ),
                              ],
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
        },
      ),
    );
  }

  // List<String> _getCodes(List<Country> countries) {
  //   List<String> codes = [];
  //   for (var value in countries) {
  //     codes.add(value.callCode ?? '');
  //   }

  //   return codes;
  // }

  void _validateAndUpdatePersonal() {
    if (!mounted) return;
    setState(() {
      fToast = FToast();
      fToast.init(context);
    });

    if (_fullNameController.text.isEmpty) {
      errorfield = 'errornick';
      _fullNameFocus.requestFocus();
      errorFullName = 'Nickname is required!';
      // showErrorToast('Please enter nickname!', context);

      BlocProvider.of<ProfileBloc>(
        context,
      ).add(ProfileEditLoad(errorField: errorfield));
    } else if (_firstNameController.text.isEmpty) {
      errorfield = 'errorfirst';
      _firstNameFocus.requestFocus();
      errorFirstName = 'First Name is required!';
      // showErrorToast('Please enter first name/ forename!', context);

      BlocProvider.of<ProfileBloc>(
        context,
      ).add(ProfileEditLoad(errorField: errorfield));
    } else if (_lastNameController.text.isEmpty) {
      errorfield = 'errorlast';
      _lastNameFocus.requestFocus();
      errorLastName = 'Last Name is required!';
      // showErrorToast('Please enter last name/ surname!', context);

      BlocProvider.of<ProfileBloc>(
        context,
      ).add(ProfileEditLoad(errorField: errorfield));
      // } else if (_contactController.text.isEmpty) {
      //   errorfield = 'errorcontact';
      //   _contactFocus.requestFocus();
      //   errorContact = 'Mobile No. is required!';
      //   // showErrorToast('Please enter last name/ surname!', context);

      //   BlocProvider.of<ProfileBloc>(context)
      //       .add(ProfileEditLoad(errorField: errorfield));
    } else if (_genderController.text.isEmpty) {
      errorfield = 'errorgender';
      _genderFocus.requestFocus();
      errorGender = 'Gender is required!';
      // showErrorToast('Please choose gender!', context);

      BlocProvider.of<ProfileBloc>(
        context,
      ).add(ProfileEditLoad(errorField: errorfield));
      // } else if (_muslimController.text.isEmpty) {
      //   errorfield = 'errormuslim';
      //   _muslimFocus.requestFocus();
      //   errorMuslim = 'Halal or Non Halal content option is required!';
      //   // showErrorToast('Please choose Muslim friendly!', context);

      //   BlocProvider.of<ProfileBloc>(context)
      //       .add(ProfileEditLoad(errorField: errorfield));
    } else if (_dobController.text.isEmpty) {
      errorfield = 'errordob';
      _dobFocus.requestFocus();
      errorDob = 'DOB is required!';
      // showErrorToast('Please enter date of birth!', context);

      BlocProvider.of<ProfileBloc>(
        context,
      ).add(ProfileEditLoad(errorField: errorfield));
    } else {
      // showConfirmationDialog(context);
      updateProfile();
    }
  }

  void _setProfileData() {
    var profile = widget.profile['profile'];
    var formatter = DateFormat(appDateFormat);
    var dateNow = DateTime.now();

    _fullNameController.text = profile['name'] ?? '';
    _firstNameController.text = profile['forename'] ?? '';
    _lastNameController.text = profile['surname'] ?? '';
    _dobController.text =
        profile['dob'].toString() != '' && profile['dob'].toString().isNotEmpty
            ? formatter.format(DateTime.parse(profile['dob']))
            : formatter.format(
              DateTime(dateNow.year - minAgeDOB, dateNow.month, dateNow.day),
            );
    // _emailController.text = profile['email'] ?? '';
    // _contactController.text =
    //     profile['contact'].substring(profile['contact'].indexOf("-") + 1) ?? '';
    _genderController.text = profile['gender'] ?? '';
    // _muslimController.text = profile['isMuslim'] == null
    //     ? ''
    //     : profile['isMuslim'] == true
    //         ? 'Muslim-Friendly Content Only'
    //         : 'Include Non-Halal Content';

    // selectedCode = profile['contact'] != ''
    //     ? profile['contact'].substring(0, profile['contact'].indexOf("-"))
    //     : '60';
  }

  void _setProfileDataImage(ProfileState state) {
    var profile = (state as ProfileLoaded).userProfile.profile;

    // ignore: unnecessary_null_comparison
    if (profile != null) {
      profileImage = profile.image;

      if (profileImage != null) {
        // image = profileImage!;
        image = Image.network(profileImage!, fit: BoxFit.fill);
      } else {
        image = Image.asset('assets/icons/no_photo.png');
      }
    }
  }

  Future _showSelectionDialog(BuildContext context) async {
    if (isProcessing) return;
    final source = await showProfilePhotoSource(context);
    if (!mounted || source == null) return;
    await _pickImage(source);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        // Keep original detail for zooming; resize only after cropping.
      );

      if (pickedFile != null) {
        if (!mounted) return;
        await _cropImage(File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        showErrorToast(
          "Unable to open or crop the photo. Please check photo/camera permissions and try again.",
          context,
        );
      }
    }
  }

  Future<void> _cropImage(File imageFile) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      maxWidth: 1024,
      maxHeight: 1024,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 95,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Adjust profile photo',
          toolbarColor: AppDesign.photo.background,
          backgroundColor: AppDesign.photo.background,
          hideBottomControls: true,
          toolbarWidgetColor: AppDesign.photo.text,
          activeControlsWidgetColor: AppDesign.photo.action,
          // showCropGrid: false,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          dimmedLayerColor: AppDesign.photo.text.withValues(alpha: 0.55),
        ),
        IOSUiSettings(
          title: 'Adjust profile photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          doneButtonTitle: 'Use crop',
          cancelButtonTitle: 'Cancel',
        ),
      ],
    );

    if (mounted && croppedFile != null) {
      setState(() {
        _image = File(croppedFile.path);
        photoBloc.add(GetPhoto(photo: _image));
      });
    }
  }

  Future _showPhotoConfirmDialog(BuildContext context, File photo) async {
    final bytes = await photo.readAsBytes();
    if (!context.mounted) return;
    imageBytes = base64Encode(bytes);
    final confirmed = await showProfilePhotoPreview(context, photo);
    if (!mounted || confirmed != true) return;
    _confirmUpdatePhoto();
  }

  void _confirmUpdatePhoto() {
    setProcessingStatus(true);
    BlocProvider.of<ProfileBloc>(
      context,
    ).add(ProfilePhotoUpdate(image: imageBytes!));
  }

  showConfirmationDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.all(10.0),
          backgroundColor: AppDesign.setup.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          content: Container(
            color: AppDesign.setup.background,
            alignment: Alignment.center,
            height: ScreenSize.height * 0.35,
            padding: EdgeInsets.symmetric(
              vertical: 20,
              horizontal: AppDesign.spaceLg,
            ),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  // mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: ScreenSize.width * 0.2,
                        width: ScreenSize.width * 0.2,
                        color: colorTransparent,
                        child: Image(
                          image: AssetImage('assets/icons/reminder.webp'),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        // color: colorLightBlue,
                        alignment: Alignment.center,
                        // padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Please make sure all the data entered is correct.',
                          style: TextStyle(
                            fontSize: AppDesign.smallSize,
                            fontWeight: FontWeight.w500,
                            color: AppDesign.setup.text,
                          ),
                          textAlign: TextAlign.center,
                          textScaler: TextScaler.linear(scaleFactor),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            alignment: Alignment.bottomCenter,
                            child: OderStyleButton(
                              backgroundColor: AppDesign.setup.action,
                              height: ScreenSize.height / 16,
                              width: ScreenSize.width,
                              title: 'Confirm',
                              onPressed: () {
                                Navigator.pop(context);
                                FocusScope.of(context).unfocus();

                                setProcessingStatus(true);

                                setState(() {
                                  Storage().page = 'profileReg';
                                  updateProfile();
                                });
                              },
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              FocusScope.of(context).unfocus();
                            },
                            child: Container(
                              margin: EdgeInsets.only(top: 10, bottom: 5),
                              padding: EdgeInsets.symmetric(vertical: 5),
                              // color: colorBabyBlue,
                              alignment: Alignment.center,
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: AppDesign.bodyLargeSize,
                                  color: AppDesign.setup.text,
                                  fontWeight: FontWeight.w400,
                                  decoration: TextDecoration.underline,
                                ),
                                textScaler: TextScaler.linear(scaleFactor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void updateProfile() {
    BlocProvider.of<ProfileBloc>(context).add(
      ProfileUpdate(
        surname: _lastNameController.text.trim(),
        forename: _firstNameController.text.trim(),
        name: _fullNameController.text.trim(),
        // contact: '$selectedCode-${_contactController.text.trim()}',
        gender: _genderController.text.trim(),
        dob: _dobController.text.trim(),
        // isMuslim: isMuslim,
        // vMuslim: widget.profile['vMuslim'],
        // vExtra: widget.profile['vExtra'],
        // vProfile: widget.profile['vProfile'],
      ),
    );
  }
}
