import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';

extension SafeNavExtension on BuildContext {
  /// Safely pops the current route if possible.
  /// If Navigator cannot pop (e.g. root route in web or after direct navigation),
  /// it smoothly replaces the route with DashboardScreen to prevent Flutter's
  /// `_history.isNotEmpty` assertion failure.
  void safePop<T extends Object?>([T? result]) {
    if (Navigator.canPop(this)) {
      Navigator.pop(this, result);
    } else {
      Navigator.pushReplacement(
        this,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }
}

class SafeNav {
  /// Safely pops context if it can pop, otherwise navigates to DashboardScreen.
  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, result);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }
}
