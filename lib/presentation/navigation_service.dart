import 'package:flutter/material.dart';

import '../app_setting/routes.dart';
import 'features/ordering/ordering_screen.dart';

/// Global observer used by RouteAware widgets.
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

/// Tracks only live routes; disposed routes must not be retained as history.
class NavigationService extends NavigatorObserver {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final List<Route<dynamic>> _routes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute == null) return;
    final index = _routes.indexOf(oldRoute);
    if (index != -1) {
      if (newRoute == null) {
        _routes.removeAt(index);
      } else {
        _routes[index] = newRoute;
      }
    }
  }

  bool _isDefaultDirectory(Route<dynamic> route) {
    final arguments = route.settings.arguments;
    return route.settings.name == OderRoutes.orderingMerchant &&
        arguments is OrderingScreenParameters &&
        arguments.selectedTab == 0 &&
        arguments.categoryId == null;
  }

  void openMainSection(String routeName, {Object? arguments}) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    if (routeName == OderRoutes.wallet &&
        _routes.isNotEmpty &&
        _routes.last.settings.name == routeName) {
      return;
    }

    // Directory contains browsing state. Reuse it while it is still in this
    // session's stack, but never reuse a category/deep-link entry as the root.
    if (routeName == OderRoutes.orderingMerchant) {
      for (final route in _routes.reversed) {
        if (_isDefaultDirectory(route)) {
          navigator.popUntil((candidate) => identical(candidate, route));
          return;
        }
      }
    }

    // Keep Home and, when present, the default Directory beneath the new
    // section. Recreate Deals/Profile so vouchers and balances stay fresh.
    navigator.pushNamedAndRemoveUntil(
      routeName,
      (route) =>
          route.settings.name == OderRoutes.home ||
          (routeName != OderRoutes.orderingMerchant &&
              _isDefaultDirectory(route)),
      arguments: arguments,
    );
  }

  Future<dynamic>? navigateTo(String routeName) {
    if (_routes.isEmpty || _routes.last.settings.name != routeName) {
      return navigatorKey.currentState?.pushNamedAndRemoveUntil(
        routeName,
        (Route<dynamic> route) => false,
      );
    }
    return null;
  }
}
