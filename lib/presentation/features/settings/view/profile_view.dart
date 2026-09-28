import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../../../app_setting/app_setting.dart';
import '../../../../domain/domain.dart';
import '../../../widgets/widgets.dart';
import '../../maintenance/maintenance_screen.dart';
import '../../photo/photo.dart';
import '../../profile/profile.dart';

class ProfileView extends StatefulWidget {
  final Function? changeView;

  const ProfileView({super.key, this.changeView});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  // with AutomaticKeepAliveClientMixin {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _muslimController = TextEditingController();
  final GlobalKey<OderInputFieldState> _fullNameKey = GlobalKey();
  final GlobalKey<OderInputFieldState> _firstNameKey = GlobalKey();
  final GlobalKey<OderInputFieldState> _lastNameKey = GlobalKey();
  final GlobalKey<OderInputFieldState> _dobKey = GlobalKey();
  final GlobalKey<OderInputFieldState> _emailKey = GlobalKey();
  final GlobalKey<OderSelectValueState> _contactKey = GlobalKey();

  String selectedCode = '60';
  String errorfield = '';
  String? path, imageBytes;
  String errorFullName = '', errorFirstName = '', errorLastName = '';
  late FocusNode nickFocus, firstFocus, lastFocus, emailFocus;
  String? profileImage;
  bool isProcessing = false;
  bool error = false;
  // ignore: prefer_typing_uninitialized_variables
  bool profileEvalid = false;
  Image? image;
  // ignore: unused_field
  late File _image;
  var photoBloc = PhotoBloc();
  List<String> getGender = ["Male", "Female"];
  List<String> getMuslim = [
    "Muslim-Friendly Content Only",
    "Include Non-Halal Content",
  ];
  String dropdownValue = 'One';
  final ImagePicker _picker = ImagePicker();
  // Track whether initial hydration has occurred
  bool _isInitialHydration = true;

  void setProcessingStatus(bool processing) {
    setState(() {
      isProcessing = processing;
    });
  }

  @override
  void initState() {
    super.initState();

    initializeDateFormatting();
    nickFocus = FocusNode();
    firstFocus = FocusNode();
    lastFocus = FocusNode();
    emailFocus = FocusNode();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _genderController.dispose();
    _muslimController.dispose();

    // Clean up the focus node when the Form is disposed.
    nickFocus.dispose();
    firstFocus.dispose();
    lastFocus.dispose();
    emailFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // super.build(context);

    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded) {
          // _setProfileData(state);
          // Only hydrate controllers if it's the initial load or user explicitly discarded changes
          if (_isInitialHydration) {
            _setProfileData(state);
            _isInitialHydration = false;
          } else {
            // Optionally update only non-input state (e.g. read-only fields or image URL)
            setState(() {
              profileImage = state.userProfile.profile?.image;
            });
          }
        }

        if (state is ProfileMaintenanceError) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            OderRoutes.maintenanceScreen,
            (Route<dynamic> route) => false,
            arguments: MaintenanceParameters(message: state.message),
          );
        }
        if (state is ProfileError) {
          setProcessingStatus(false);
          // ignore: unnecessary_null_comparison
          state.error != null ? error = true : error = false;
          showErrorToast(state.error, context);
        }

        if (state is ProfileNetworkError) {
          setProcessingStatus(false);
          showErrorToast(state.error, context);
        }

        if (state is ProfilePhotoError) {
          setProcessingStatus(false);
          showErrorToast(state.error, context);
        }

        if (state is ProfileEditLoaded) {
          errorfield = state.errorField;
        }
        if (state is ProfileUpdated) {
          setProcessingStatus(false);
          // FocusScope.of(context).unfocus();

          BlocProvider.of<ProfileBloc>(context).add(ProfileLoad());
          showSuccessToast('Update was successful.', context);
        }
        if (state is ProfilePhotoUpdated) {
          setProcessingStatus(false);
          BlocProvider.of<ProfileBloc>(context).add(ProfileLoad());
          showSuccessToast('Profile photo updated.', context);
        }
      },
      builder: (context, state) {
        return SafeArea(
          child: Theme(
            data: ThemeData(
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: errorfield == '' ? colorDarkGray : colorRed,
              ),
            ),

            child: SingleChildScrollView(
              child: Container(
                color: colorWhite,
                margin: const EdgeInsets.symmetric(
                  horizontal: AppDesign.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    BlocProvider<PhotoBloc>.value(
                      value: photoBloc,
                      child: BlocConsumer<PhotoBloc, PhotoState>(
                        listener: (context, photoState) {
                          if (photoState is PhotoSet) {
                            _showPhotoConfirmDialog(context, photoState.photo);
                          }
                        },
                        builder: (context, photoState) {
                          Image? image;
                          // print('PHOTO BUILDER: $state');

                          // if (state is ProfileLoaded) {
                          //   BlocProvider.of<ProfileBloc>(context)
                          //       .add(ProfileLoad());
                          // }

                          if (profileImage != null) {
                            // image = profileImage!;
                            image = Image.network(
                              profileImage!,
                              fit: BoxFit.fitWidth,
                            );
                          } else {
                            image = Image.asset('assets/icons/no_photo.png');
                          }

                          return Center(
                            child: Stack(
                              children: [
                                Container(
                                  height: ScreenSize.height / 5.8,
                                  color: AppDesign.editProfile.background,
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
                                    onTap: () => _showSelectionDialog(context),
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
                                        color: AppDesign.editProfile.action,
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
                    /* ----------------------------------------------------------- Nickname input field */
                    const SizedBox(height: AppDesign.formFieldGap),
                    OderRoundField(
                      palette: AppDesign.editProfile,
                      label: 'Display Name',
                      horizontalPadding: 0,
                      focusBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color:
                              error
                                  ? colorRed
                                  : errorfield == 'error' ||
                                      errorfield == 'errornick'
                                  ? colorRed
                                  : AppDesign.editProfile.border,
                        ),
                        // borderRadius: BorderRadius.circular(25.0),
                      ),
                      key: _fullNameKey,
                      controller: _fullNameController,
                      labelStyle: TextStyle(
                        color:
                            error
                                ? colorRed
                                : errorfield == 'error' ||
                                    errorfield == 'errornick'
                                ? colorRed
                                : AppDesign.editProfile.border,
                        fontSize: AppDesign.bodySize,
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: Validator.valueExists,
                      keyboard: TextInputType.text,
                      border: InputBorder.none,
                      focusNode: nickFocus,
                      onValueChanged: (value) {
                        if (state is ProfileEditLoaded && value != '') {
                          errorfield = '';
                          BlocProvider.of<ProfileBloc>(
                            context,
                          ).add(ProfileEditLoad(errorField: errorfield));
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
                                      : colorGreyBox,
                            ),
                          ),
                        )
                        : SizedBox(),
                    /* ----------------------------------------------------------- Firstname/Forename input field */
                    const SizedBox(height: AppDesign.formFieldGap),
                    Container(
                      margin: EdgeInsets.zero,
                      child: OderRoundField(
                        palette: AppDesign.editProfile,
                        label: 'First Name',
                        focusBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                error
                                    ? colorRed
                                    : errorfield == 'error' ||
                                        errorfield == 'errorfirst'
                                    ? colorRed
                                    : AppDesign.editProfile.border,
                          ),
                          // borderRadius: BorderRadius.circular(25.0),
                        ),
                        key: _firstNameKey,
                        controller: _firstNameController,
                        labelStyle: TextStyle(
                          color:
                              error
                                  ? colorRed
                                  : errorfield == 'error' ||
                                      errorfield == 'errorfirst'
                                  ? colorRed
                                  : AppDesign.editProfile.border,
                          fontSize: AppDesign.bodySize,
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: Validator.valueExists,
                        keyboard: TextInputType.text,
                        border: InputBorder.none,
                        focusNode: firstFocus,
                        onValueChanged: (value) {
                          if (state is ProfileEditLoaded && value != '') {
                            errorfield = '';
                            BlocProvider.of<ProfileBloc>(
                              context,
                            ).add(ProfileEditLoad(errorField: errorfield));
                          }
                        },
                      ),
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
                                      : colorGreyBox,
                            ),
                          ),
                        )
                        : SizedBox(),
                    /* ----------------------------------------------------------- Last Name/ Surname input field */
                    const SizedBox(height: AppDesign.formFieldGap),
                    Container(
                      margin: EdgeInsets.zero,
                      child: OderRoundField(
                        palette: AppDesign.editProfile,
                        label: 'Last Name',
                        focusBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                error
                                    ? colorRed
                                    : errorfield == 'error' ||
                                        errorfield == 'errorlast'
                                    ? colorRed
                                    : AppDesign.editProfile.border,
                          ),
                          // borderRadius: BorderRadius.circular(25.0),
                        ),
                        key: _lastNameKey,
                        controller: _lastNameController,
                        labelStyle: TextStyle(
                          color:
                              error
                                  ? colorRed
                                  : errorfield == 'error' ||
                                      errorfield == 'errorlast'
                                  ? colorRed
                                  : AppDesign.editProfile.border,
                          fontSize: AppDesign.bodySize,
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: Validator.valueExists,
                        keyboard: TextInputType.text,
                        border: InputBorder.none,
                        focusNode: lastFocus,
                        onValueChanged: (value) {
                          if (state is ProfileEditLoaded && value != '') {
                            errorfield = '';
                            BlocProvider.of<ProfileBloc>(
                              context,
                            ).add(ProfileEditLoad(errorField: errorfield));
                          }
                        },
                      ),
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
                                      : colorGreyBox,
                            ),
                          ),
                        )
                        : SizedBox(),
                    /* ----------------------------------------------------------- Email input field */
                    const SizedBox(height: AppDesign.formFieldGap),
                    _buildVerifiedEmail(state),
                    /* ----------------------------------------------------------- Content preference input field */
                    if (isMuslimFriendly)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppDesign.formFieldGap,
                        ),
                        child: _readOnlyValue(
                          'Content Preference',
                          _muslimController,
                        ),
                      ),
                    const SizedBox(height: AppDesign.formFieldGap),
                    Container(
                      margin: EdgeInsets.zero,
                      child: OderRoundField(
                        palette: AppDesign.editProfile,
                        label: 'Mobile Number',
                        focusBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppDesign.editProfile.border,
                          ),
                          // borderRadius: BorderRadius.circular(25.0),
                        ),
                        key: _contactKey,
                        controller: _contactController,
                        labelStyle: TextStyle(
                          color: AppDesign.editProfile.border,
                          fontSize: AppDesign.bodySize,
                        ),
                        validator: Validator.valueExists,
                        keyboard: TextInputType.text,
                        border: InputBorder.none,
                        readOnly: true,
                        textAlignVertical: TextAlignVertical.center,
                      ),
                    ),
                    /* ----------------------------------------------------------- Gender input field */
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppDesign.formFieldGap,
                      ),
                      child: _readOnlyValue('Gender', _genderController),
                    ),
                    /* ----------------------------------------------------------- Date of Birth input field */
                    Container(
                      margin: const EdgeInsets.only(
                        top: AppDesign.formFieldGap,
                      ),
                      child: OderRoundField(
                        palette: AppDesign.editProfile,
                        label: 'Date of Birth',
                        focusBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppDesign.editProfile.border,
                          ),
                          // borderRadius: BorderRadius.circular(25.0),
                        ),
                        key: _dobKey,
                        controller: _dobController,
                        labelStyle: TextStyle(
                          color: AppDesign.editProfile.border,
                          fontSize: AppDesign.bodySize,
                        ),
                        validator: Validator.valueExists,
                        keyboard: TextInputType.text,
                        border: InputBorder.none,
                        readOnly: true,
                        textAlignVertical: TextAlignVertical.center,
                      ),
                    ),
                    /* ----------------------------------------------------------- Save changes button */
                    Container(
                      alignment: Alignment.bottomCenter,
                      margin: const EdgeInsets.only(
                        top: AppDesign.formFieldGap,
                      ),
                      child: AccountPrimaryButton(
                        palette: AppDesign.editProfile,
                        label: isProcessing ? 'Processing…' : 'Save',
                        onPressed:
                            isProcessing ? null : _validateAndUpdatePersonal,
                      ),
                    ),
                    /* ----------------------------------------------------------- Acc Deletion button */
                    InkWell(
                      child: Container(
                        alignment: Alignment.center,
                        margin: EdgeInsets.symmetric(
                          vertical: AppDesign.spaceXxl,
                        ),
                        child: AccountUnderlinedLabel(
                          'Delete My Account',
                          style: TextStyle(
                            fontFamily: fontFamilyMain,
                            fontSize: AppDesign.smallSize,
                            fontWeight: FontWeight.w700,
                            color: colorRedLight,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.of(
                          context,
                        ).pushNamed(OderRoutes.deleteAccount).then((value) {
                          if (!context.mounted) return;
                          BlocProvider.of<ProfileBloc>(
                            context,
                          ).add(ProfileLoad());
                        });
                      },
                    ),
                    SizedBox(height: ScreenSize.height * 0.05),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _readOnlyValue(String label, TextEditingController controller) =>
      OderRoundField(
        palette: AppDesign.editProfile,
        label: label,
        controller: controller,
        readOnly: true,
        textAlignVertical: TextAlignVertical.center,
      );

  Widget _buildVerifiedEmail(ProfileState profileState) {
    return Container(
      margin: EdgeInsets.zero,
      child: OderRoundField(
        palette: AppDesign.editProfile,
        label: 'Email Address',
        focusBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color:
                error
                    ? colorRed
                    : errorfield == 'error' || errorfield == 'erroremail'
                    ? colorRed
                    : AppDesign.editProfile.border,
          ),
          // borderRadius: BorderRadius.circular(25.0),
        ),
        key: _emailKey,
        controller: _emailController,
        labelStyle: TextStyle(
          color:
              error
                  ? colorRed
                  : errorfield == 'error' || errorfield == 'erroremail'
                  ? colorRed
                  : AppDesign.editProfile.border,
          fontSize: AppDesign.bodySize,
        ),
        validator: Validator.valueExists,
        keyboard: TextInputType.text,
        border: InputBorder.none,
        // suffixIcon: Container(
        //     margin: EdgeInsets.only(right: 10),
        //     child: _buildVerifyEmail(context, profileState)),
        readOnly: profileEvalid ? true : false,
        textAlignVertical: TextAlignVertical.center,
        focusNode: emailFocus,
        onValueChanged: (value) {
          if (profileState is ProfileEditLoaded && value != '') {
            errorfield = '';
            BlocProvider.of<ProfileBloc>(
              context,
            ).add(ProfileEditLoad(errorField: errorfield));
          }
        },
      ),
    );
  }

  // Widget _buildVerifyEmail(BuildContext context, ProfileState profileState) {
  //   if (!profileEvalid) {
  //     return Container(
  //       // color: AppDesign.editProfile.background,
  //       width: MediaQuery.of(context).size.width * 0.16,
  //       alignment: Alignment.centerRight,
  //       child: OderTextButton(
  //         'Verify Email',
  //         fontSize: 10,
  //         color: colorLightBlue,
  //         padding: EdgeInsets.zero,
  //         onClick: () {
  //           Navigator.of(context).pushNamed( OderRoutes.verifyEmail,
  //               arguments: VerifyEmailParameters(email: Storage().verifyEmail));
  //         },
  //       ),
  //     );
  //   } else {
  //     return Container(
  //       // color: colorLightBlue,
  //       width: MediaQuery.of(context).size.width * 0.16,
  //       alignment: Alignment.centerRight,
  //       child: Text(
  //         'Verified',
  //         style: TextStyle(
  //           fontSize: 10,
  //           color: secondaryColor,
  //         ),
  //         textScaler: TextScaler.linear(scaleFactor),
  //       ),
  //     );
  //   }
  // }

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

      // Guard against screen unmount while user is picking an image
      if (!mounted || pickedFile == null) return;

      // Await cropping before updating state
      await _cropImage(File(pickedFile.path));
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

    // Guard against screen unmount during crop step
    if (!mounted || croppedFile == null) return;

    final File cropped = File(croppedFile.path);

    setState(() {
      _image = cropped;
      // photoBloc.add(GetPhoto(photo: _image));
    });

    photoBloc.add(GetPhoto(photo: cropped));
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

  void _validateAndUpdatePersonal() {
    if (!mounted || isProcessing) return;
    setState(() {
      fToast = FToast();
      fToast.init(context);
    });

    if (_fullNameController.text.isEmpty) {
      errorfield = 'errornick';
      nickFocus.requestFocus();
      errorFullName = 'Nickname is required!';
      // showErrorToast('Nickname cannot be empty', context);

      BlocProvider.of<ProfileBloc>(
        context,
      ).add(ProfileEditLoad(errorField: errorfield));
    } else if (_firstNameController.text.isEmpty) {
      errorfield = 'errorfirst';
      firstFocus.requestFocus();
      errorFirstName = 'First Name is required!';
      // showErrorToast('First Name/ Forname cannot be empty', context);

      BlocProvider.of<ProfileBloc>(
        context,
      ).add(ProfileEditLoad(errorField: errorfield));
    } else if (_lastNameController.text.isEmpty) {
      errorfield = 'errorlast';
      lastFocus.requestFocus();
      errorLastName = 'Last Name is required!';
      // showErrorToast('Last Name/ Surname cannot be empty', context);
      // ErrorDialog.showErrorDialog(
      //     context, 'Last Name/ Surname cannot be empty');

      BlocProvider.of<ProfileBloc>(
        context,
      ).add(ProfileEditLoad(errorField: errorfield));
    } else if (_emailController.text.isEmpty) {
      errorfield = 'erroremail';
      emailFocus.requestFocus();
      showErrorToast('Email cannot be empty', context);
      // ErrorDialog.showErrorDialog(context, 'Email cannot be empty');

      BlocProvider.of<ProfileBloc>(
        context,
      ).add(ProfileEditLoad(errorField: errorfield));
    } else {
      setProcessingStatus(true);
      BlocProvider.of<ProfileBloc>(context).add(
        ProfileUpdate(
          surname: _lastNameController.text.trim(),
          forename: _firstNameController.text.trim(),
          name: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          dob:
              _dobController.text.trim().isEmpty
                  ? ''
                  : _dobController.text.trim(),
          gender: _genderController.text.trim().toLowerCase(),
        ),
      );
    }
  }

  void _setProfileData(ProfileState state) {
    var profile = (state as ProfileLoaded).userProfile.profile;
    if (profile == null) return;

    String formattedDob = '';

    // // ignore: prefer_typing_uninitialized_variables
    // var dateFormate;

    if (profile.dob?.isNotEmpty == true) {
      try {
        final parsedDate = DateTime.parse(profile.dob!);
        formattedDob = DateFormat(appDateFormat).format(parsedDate);
      } catch (_) {
        formattedDob = profile.dob!; // Fallback to raw string if parsing fails
      }

      // late var formatter = DateFormat(appDateFormat);
      // dateFormate = formatter.format(DateTime.parse(profile.dob!));
    }
    // else {
    //   var dateNow = DateTime.now();
    //   late var formatter = DateFormat(appDateFormat);
    //   dateFormate = formatter.format(
    //     DateTime(dateNow.year - minAgeDOB, dateNow.month, dateNow.day),
    //   );
    // }

    // // ignore: unnecessary_null_comparison
    // if (profile != null) {
    _fullNameController.text = profile.name ?? '';
    _firstNameController.text = profile.forename ?? '';
    _lastNameController.text = profile.surname ?? '';
    _dobController.text = formattedDob;
    _emailController.text = profile.email ?? '';
    _contactController.text = profile.contact ?? '';
    final gender = profile.gender?.trim().toLowerCase() ?? '';
    _genderController.text =
        gender == 'male'
            ? 'Male'
            : gender == 'female'
            ? 'Female'
            : (profile.gender ?? '');
    profileEvalid = profile.eValid ?? false;
    // Storage().verifyEmail = profile.email!;
    profileImage = profile.image;

    if (profileImage != null) {
      // image = profileImage!;
      image = Image.network(profileImage!, fit: BoxFit.fitWidth);
    } else {
      image = Image.asset('assets/icons/no_photo.png');
    }

    _muslimController.text =
        profile.isMuslim == null
            ? 'Include Non-Halal Content'
            // ignore: unrelated_type_equality_checks
            : profile.isMuslim == true || profile.isMuslim == '1'
            ? 'Muslim-Friendly Content Only'
            : 'Include Non-Halal Content';
    // }
  }

  // @override
  // bool get wantKeepAlive => true;
}
