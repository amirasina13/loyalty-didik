import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app_setting/app_setting.dart';

class AccountPrimaryButton extends StatelessWidget {
  const AccountPrimaryButton({
    super.key,
    required this.label,
    required this.palette,
    this.onPressed,
  });
  final String label;
  final PagePalette palette;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.action,
        foregroundColor: palette.onAction,
        disabledBackgroundColor: AppDesign.setupDisabled,
        disabledForegroundColor: palette.onAction,
        elevation: 0,
        minimumSize: const Size.fromHeight(AppDesign.setupButtonHeight),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: fontFamilyMain,
          fontSize: AppDesign.bodySize,
          fontWeight: FontWeight.w700,
        ),
      ),
      onPressed: onPressed,
      child: Text(label),
    ),
  );
}

Future<T?> showAccountSheet<T>(
  BuildContext context,
  PagePalette palette,
  Widget child,
) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: palette.background,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(AppDesign.sheetRadius),
    ),
  ),
  builder:
      (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppDesign.spaceXl),
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
);

Widget sheetTitle(String text, PagePalette palette) => Text(
  text,
  textAlign: TextAlign.center,
  style: TextStyle(
    fontFamily: fontFamilyMain,
    fontSize: AppDesign.titleSize,
    fontWeight: FontWeight.w700,
    color: palette.text,
  ),
);

Future<ImageSource?> showProfilePhotoSource(BuildContext context) {
  const p = AppDesign.photo;
  return showAccountSheet<ImageSource>(
    context,
    p,
    Builder(
      builder:
          (context) => Column(
            children: [
              sheetTitle('Profile photo', p),
              const SizedBox(height: AppDesign.spaceSm),
              Text(
                'How would you like to add your photo?',
                style: TextStyle(color: p.muted),
              ),
              const SizedBox(height: AppDesign.spaceXl),
              for (final option in [
                (
                  ImageSource.camera,
                  Icons.camera_alt_outlined,
                  'Take a photo',
                  'Use your camera',
                ),
                (
                  ImageSource.gallery,
                  Icons.photo_library_outlined,
                  'Choose from gallery',
                  'Select an existing photo',
                ),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDesign.spaceMd),
                  child: Material(
                    color: colorBlueDidik.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDesign.cardRadius),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDesign.cardRadius,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppDesign.spaceLg,
                        vertical: AppDesign.spaceSm,
                      ),
                      leading: Icon(option.$2, color: p.action),
                      title: Text(
                        option.$3,
                        style: TextStyle(
                          color: p.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        option.$4,
                        style: TextStyle(color: p.muted),
                      ),
                      trailing: Icon(Icons.chevron_right, color: p.muted),
                      onTap: () => Navigator.pop(context, option.$1),
                    ),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: p.action),
                child: const Text('Cancel'),
              ),
            ],
          ),
    ),
  );
}

Future<bool?> showProfilePhotoPreview(BuildContext context, File photo) {
  const p = AppDesign.photo;
  return showAccountSheet<bool>(
    context,
    p,
    Builder(
      builder:
          (context) => Column(
            children: [
              sheetTitle('Your new profile photo', p),
              const SizedBox(height: AppDesign.spaceSm),
              Text(
                'This is how you’ll appear on your profile.',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.muted),
              ),
              const SizedBox(height: AppDesign.spaceXl),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorBlueDidik.withValues(alpha: 0.1),
                ),
                child: ClipOval(
                  child: Image.file(
                    photo,
                    width: 168,
                    height: 168,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: AppDesign.spaceXl),
              AccountPrimaryButton(
                label: 'Use this photo',
                palette: p,
                onPressed: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: AppDesign.spaceSm),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(foregroundColor: p.action),
                child: const Text('Cancel'),
              ),
            ],
          ),
    ),
  );
}

Future<DateTime?> showBirthdaySheet(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  const p = AppDesign.calendar;
  var selected =
      initialDate.isBefore(firstDate)
          ? firstDate
          : initialDate.isAfter(lastDate)
          ? lastDate
          : initialDate;
  return showAccountSheet<DateTime>(
    context,
    p,
    StatefulBuilder(
      builder:
          (context, setState) => Column(
            children: [
              sheetTitle('Date of Birth', p),
              const SizedBox(height: AppDesign.spaceSm),
              Text(
                'Choose your birth year, then month and day.',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.muted),
              ),
              const SizedBox(height: AppDesign.spaceMd),
              Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: p.action,
                    onPrimary: p.onAction,
                    surface: p.background,
                    onSurface: p.text,
                  ),
                ),
                child: CalendarDatePicker(
                  initialDate:
                      initialDate.isBefore(firstDate)
                          ? firstDate
                          : initialDate.isAfter(lastDate)
                          ? lastDate
                          : initialDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  initialCalendarMode: DatePickerMode.year,
                  onDateChanged: (date) => setState(() => selected = date),
                ),
              ),
              const SizedBox(height: AppDesign.spaceMd),
              AccountPrimaryButton(
                label: 'Confirm birthday',
                palette: p,
                onPressed: () => Navigator.pop(context, selected),
              ),
              const SizedBox(height: AppDesign.spaceSm),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: p.action),
                child: const Text('Cancel'),
              ),
            ],
          ),
    ),
  );
}

class AccountGenderField extends StatelessWidget {
  const AccountGenderField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.options,
    required this.palette,
  });
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final PagePalette palette;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Gender',
    value: value,
    child: Material(
      color: palette.background,
      borderRadius: BorderRadius.circular(AppDesign.fieldRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDesign.fieldRadius),
        onTap: () async {
          FocusScope.of(context).unfocus();
          final selected = await showAccountSheet<String>(
            context,
            palette,
            Builder(
              builder:
                  (sheetContext) => Column(
                    children: [
                      sheetTitle('Select gender', palette),
                      const SizedBox(height: AppDesign.spaceXl),
                      for (final option in options)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppDesign.spaceMd,
                          ),
                          child: Material(
                            color: palette.background,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDesign.cardRadius,
                              ),
                              side: BorderSide(
                                color:
                                    value == option
                                        ? palette.action
                                        : palette.border,
                              ),
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppDesign.cardRadius,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 6,
                              ),
                              title: Text(
                                option,
                                style: TextStyle(
                                  color: palette.text,
                                  fontSize: AppDesign.bodyLargeSize,
                                ),
                              ),
                              trailing: Icon(
                                value == option
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color:
                                    value == option
                                        ? palette.action
                                        : palette.border,
                              ),
                              onTap: () => Navigator.pop(sheetContext, option),
                            ),
                          ),
                        ),
                      TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: TextButton.styleFrom(
                          foregroundColor: palette.action,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
            ),
          );
          if (!context.mounted || selected == null) return;
          onChanged(selected);
        },
        child: InputDecorator(
          decoration: outlinedAccountField(
            const InputDecoration(labelText: 'Gender *'),
            palette,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value.isEmpty ? 'Select gender' : value,
                  style: TextStyle(
                    fontFamily: fontFamilyMain,
                    fontSize: AppDesign.bodyLargeSize,
                    color: value.isEmpty ? palette.muted : palette.text,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: palette.muted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
