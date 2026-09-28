import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../app_setting/app_setting.dart';
import '../../../locator.dart';
import '../../navigation_service.dart';

// Kept for existing callers which initialise FToast; display is owned below.
late FToast fToast;

void showSuccess(String msg) {
  final context =
      sl<NavigationService>().navigatorKey.currentState?.overlay?.context;
  if (context != null) showSuccessToast(msg, context);
}

void cancelToast() => dismissErrorToast();
void showErrorToast(String msg, BuildContext context) =>
    _showToast(msg, context);
void showSuccessToast(String msg, BuildContext context) =>
    _showToast(msg, context, success: true);
void showPaginationToast(String msg, BuildContext context) =>
    _showToast(msg, context, info: true);
void showErrorScannerToast(String msg, BuildContext context) =>
    _showToast(msg, context);

OverlayEntry? _errorEntry;
Timer? _errorTimer;

void dismissErrorToast() {
  _errorTimer?.cancel();
  _errorTimer = null;
  _errorEntry?.remove();
  _errorEntry = null;
}

void _showToast(
  String msg,
  BuildContext context, {
  bool success = false,
  bool info = false,
}) {
  if (!context.mounted) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  dismissErrorToast();
  final background =
      success
          ? AppDesign.toastSuccessBackground
          : info
          ? colorBlueDidik.withValues(alpha: 0.1)
          : AppDesign.errorBackground;
  final foreground =
      success
          ? AppDesign.toastSuccessText
          : info
          ? AppDesign.profile.text
          : AppDesign.errorText;
  final border =
      success
          ? AppDesign.toastSuccessBorder
          : info
          ? AppDesign.profile.border
          : AppDesign.errorBorder;
  final entry = OverlayEntry(
    builder: (overlayContext) {
      final media = MediaQuery.of(overlayContext);
      return Positioned(
        left: 16,
        right: 16,
        top: media.padding.top + AppDesign.toastTopGap,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 440,
              maxHeight: (media.size.height - media.viewInsets.bottom) * .45,
            ),
            child: Material(
              color: background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesign.toastRadius),
                side: BorderSide(color: border),
              ),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDesign.spaceLg,
                  AppDesign.spaceSm,
                  AppDesign.spaceXs,
                  AppDesign.spaceSm,
                ),
                child: Row(
                  children: [
                    Icon(
                      success
                          ? Icons.check_circle_outline
                          : info
                          ? Icons.info_outline
                          : Icons.error_outline,
                      color: foreground,
                    ),
                    const SizedBox(width: AppDesign.spaceMd),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            msg,
                            style: TextStyle(
                              color: foreground,
                              fontSize: AppDesign.bodySize,
                              fontFamily: fontFamilyMain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Dismiss notification',
                      onPressed: dismissErrorToast,
                      icon: Icon(Icons.close, color: foreground),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  _errorEntry = entry;
  overlay.insert(entry);
  _errorTimer = Timer(AppDesign.toastDuration, () {
    if (identical(_errorEntry, entry)) dismissErrorToast();
  });
}

/// Error messages belong to the route where they occurred.
class ErrorToastObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      dismissErrorToast();
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      dismissErrorToast();
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      dismissErrorToast();
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      dismissErrorToast();
}
