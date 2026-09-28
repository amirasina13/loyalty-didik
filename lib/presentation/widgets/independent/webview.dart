import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../app_setting/app_setting.dart';
import '../../../util/custom_page_route.dart';

/// Opens an HTTP(S) link in the shared in-app WebView.
///
/// Returning `false` for other schemes lets the HTML renderer keep its normal
/// handling for anchors, mail links, and phone links.
Future<bool> openInAppWebView(
  BuildContext context,
  String rawUrl, {
  String title = 'Web page',
}) async {
  final uri = Uri.tryParse(rawUrl.trim());
  final scheme = uri?.scheme.toLowerCase();
  if (uri == null || (scheme != 'http' && scheme != 'https')) {
    return false;
  }

  if (!context.mounted) return true;
  await Navigator.of(context).push(
    NoAnimationPageRoute(
      builder:
          (_) => WidgetWebView(
            widgetUrl: uri.toString(),
            title: title.trim().isEmpty ? 'Web page' : title.trim(),
          ),
    ),
  );
  return true;
}

class WidgetWebView extends StatefulWidget {
  final Function? changeView;
  final String? widgetUrl;
  final String title;

  const WidgetWebView({
    super.key,
    this.changeView,
    this.widgetUrl,
    required this.title,
  });

  @override
  State<WidgetWebView> createState() => _WidgetWebViewState();
}

class _WidgetWebViewState extends State<WidgetWebView> {
  static const _allowedSchemes = {'http', 'https'};

  final GlobalKey webViewKey = GlobalKey();
  final InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: kDebugMode,
    javaScriptEnabled: true,
    useShouldOverrideUrlLoading: true,
    mediaPlaybackRequiresUserGesture: true,
    allowsInlineMediaPlayback: true,
    supportMultipleWindows: false,
  );

  InAppWebViewController? webViewController;
  PullToRefreshController? pullToRefreshController;
  Uri? _initialUri;
  double _progress = 0;
  bool _isLoading = true;
  String? _errorMessage;
  DateTime? currentBackPressTime;

  PagePalette get _palette => AppDesign.profile;

  String get _pageTitle {
    final value = widget.title.trim();
    return value.isEmpty ? 'Web page' : value;
  }

  @override
  void initState() {
    super.initState();
    _initialUri = _parseHttpUri(widget.widgetUrl);
    pullToRefreshController = _createPullToRefreshController();
  }

  Uri? _parseHttpUri(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    if (uri == null || !_allowedSchemes.contains(uri.scheme.toLowerCase())) {
      return null;
    }
    return uri;
  }

  PullToRefreshController? _createPullToRefreshController() {
    if (kIsWeb ||
        ![
          TargetPlatform.iOS,
          TargetPlatform.android,
        ].contains(defaultTargetPlatform)) {
      return null;
    }

    return PullToRefreshController(
      settings: PullToRefreshSettings(
        color: _palette.action,
        backgroundColor: _palette.background,
      ),
      onRefresh: () async {
        if (defaultTargetPlatform == TargetPlatform.android) {
          await webViewController?.reload();
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final currentUrl = await webViewController?.getUrl();
          if (currentUrl != null) {
            await webViewController?.loadUrl(
              urlRequest: URLRequest(url: currentUrl),
            );
          }
        }
      },
    );
  }

  @override
  void dispose() {
    pullToRefreshController?.endRefreshing();
    super.dispose();
  }

  Future<void> _handleBack() async {
    final controller = webViewController;

    if (controller != null) {
      try {
        final currentWebUri = await controller.getUrl();
        final currentUrl = currentWebUri?.toString() ?? '';

        // Normalize URLs for comparison (ignoring trailing slashes)
        final normCurrent = currentUrl.replaceAll(RegExp(r'/$'), '');
        final normInitial = (_initialUri?.toString() ?? '').replaceAll(
          RegExp(r'/$'),
          '',
        );

        // If we are back at the original URL or an authorization route, exit screen immediately
        if (normCurrent == normInitial || currentUrl.contains('token=')) {
          if (mounted) Navigator.of(context).pop();
          return;
        }

        // Check if we can go back in history with a safety timeout
        final canBack = await controller.canGoBack().timeout(
          const Duration(milliseconds: 300),
          onTimeout: () => false,
        );

        if (canBack) {
          await controller.goBack();
          return;
        }
      } catch (e) {
        debugPrint('Error handling back: $e');
      }
    }

    // Fallback: Exit Flutter screen
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _reload() async {
    final controller = webViewController;
    if (controller == null || _initialUri == null) return;

    setState(() {
      _isLoading = true;
      _progress = 0;
      _errorMessage = null;
    });
    await controller.reload();
  }

  void _setMainFrameLoading({required bool loading}) {
    if (!mounted) return;
    setState(() {
      _isLoading = loading;
      if (loading) {
        _progress = 0;
        _errorMessage = null;
      }
    });
  }

  Future<NavigationActionPolicy?> _handleNavigationRequest(
    InAppWebViewController controller,
    NavigationAction navigationAction,
  ) async {
    final uri = navigationAction.request.url;
    final scheme = uri?.scheme.toLowerCase();
    if (uri == null || !_allowedSchemes.contains(scheme)) {
      debugPrint('Blocked WebView navigation: ${uri?.toString()}');
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
  }

  Widget _buildErrorState() {
    final message = _errorMessage ?? 'This page could not be loaded.';
    return ColoredBox(
      color: _palette.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDesign.pagePadding),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDesign.spaceXl),
            decoration: BoxDecoration(
              color: colorBlueDidik.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDesign.cardRadius),
              border: Border.all(color: _palette.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.public_off_outlined,
                  color: _palette.action,
                  size: 40,
                ),
                const SizedBox(height: AppDesign.spaceMd),
                Text(
                  'Unable to load page',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _palette.text,
                    fontFamily: fontFamilyMain,
                    fontSize: AppDesign.sectionTitleSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDesign.spaceSm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _palette.muted,
                    fontFamily: fontFamilyMain,
                    fontSize: AppDesign.bodySize,
                    height: 1.4,
                  ),
                ),
                if (_initialUri != null) ...[
                  const SizedBox(height: AppDesign.spaceLg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return ColoredBox(
      color: _palette.background.withValues(alpha: 0.96),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _palette.action, strokeWidth: 2.5),
            const SizedBox(height: AppDesign.spaceMd),
            Text(
              'Loading page…',
              style: TextStyle(
                color: _palette.muted,
                fontFamily: fontFamilyMain,
                fontSize: AppDesign.bodySize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final systemUiStyle = SystemUiOverlayStyle(
      statusBarColor: _palette.background,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: _palette.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: _palette.background,
        appBar: AppBar(
          backgroundColor: _palette.background,
          foregroundColor: _palette.text,
          surfaceTintColor: colorTransparent,
          elevation: 0,
          centerTitle: true,
          titleSpacing: 0,
          systemOverlayStyle: systemUiStyle,
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: _handleBack,
          ),
          title: Text(
            _pageTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _palette.text,
              fontFamily: fontFamilyMain,
              fontSize: AppDesign.appBarTitleSize,
              fontWeight: FontWeight.w700,
            ),
            textScaler: TextScaler.linear(scaleFactor),
          ),
          actions: [
            IconButton(
              tooltip: 'Reload page',
              onPressed: _isLoading ? null : _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              if (_initialUri == null)
                _buildErrorState()
              else
                InAppWebView(
                  key: webViewKey,
                  initialUrlRequest: URLRequest(
                    url: WebUri(_initialUri.toString()),
                  ),
                  initialSettings: settings,
                  pullToRefreshController: pullToRefreshController,
                  onWebViewCreated: (controller) {
                    webViewController = controller;
                  },
                  onLoadStart: (controller, url) {
                    _setMainFrameLoading(loading: true);
                  },
                  onPermissionRequest: (controller, request) async {
                    return PermissionResponse(
                      resources: request.resources,
                      action: PermissionResponseAction.DENY,
                    );
                  },
                  shouldOverrideUrlLoading: _handleNavigationRequest,
                  onLoadStop: (controller, url) {
                    pullToRefreshController?.endRefreshing();
                    if (!mounted) return;
                    setState(() {
                      _progress = 1;
                      _isLoading = false;
                      _errorMessage = null;
                    });
                  },
                  onReceivedError: (controller, request, error) {
                    if (request.isForMainFrame == false || !mounted) return;
                    pullToRefreshController?.endRefreshing();
                    setState(() {
                      _isLoading = false;
                      _errorMessage =
                          'Please check your connection and try again.';
                    });
                    debugPrint('WebView load error: ${error.description}');
                  },
                  onProgressChanged: (controller, progress) {
                    if (!mounted) return;
                    setState(() => _progress = progress / 100);
                    if (progress == 100) {
                      pullToRefreshController?.endRefreshing();
                    }
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    if (kDebugMode) debugPrint(consoleMessage.message);
                  },
                ),
              if (_initialUri != null && _isLoading && _errorMessage == null)
                Positioned.fill(child: _buildLoadingOverlay()),
              if (_initialUri != null && _isLoading && _errorMessage == null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      value: _isLoading && _progress > 0 ? _progress : 0,
                      backgroundColor: colorBlueDidik.withValues(alpha: 0.1),
                      color: _palette.action,
                    ),
                  ),
                ),
              if (_initialUri != null && _errorMessage != null)
                Positioned.fill(child: _buildErrorState()),
            ],
          ),
        ),
      ),
    );
  }
}
