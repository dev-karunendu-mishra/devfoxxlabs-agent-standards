import 'package:flutter/material.dart';

/// Navigation slide direction.
enum SlideDirection { rightToLeft, leftToRight, bottomToTop, topToBottom }

/// A custom page route that transitions screens with a smooth slide effect.
///
/// **Universal Rule**:
/// In every app, screen transitions MUST ALWAYS use a slide effect
/// (Right-to-Left by default).
///
/// Usage:
/// ```dart
/// Navigator.push(context, SlidePageRoute(builder: (_) => NextScreen()));
/// // Or using context extension:
/// context.pushSlide(const NextScreen());
/// ```
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  SlidePageRoute({
    required WidgetBuilder builder,
    super.settings,
    this.direction = SlideDirection.rightToLeft,
    this.curve = Curves.fastOutSlowIn,
    super.transitionDuration = const Duration(milliseconds: 300),
    super.reverseTransitionDuration = const Duration(milliseconds: 250),
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final offset = _getBeginOffset(direction);

           final inAnimation = Tween<Offset>(
             begin: offset,
             end: Offset.zero,
           ).chain(CurveTween(curve: curve)).animate(animation);

           // Subtle parallax slide-out when a subsequent page is pushed on top
           final outAnimation = Tween<Offset>(
             begin: Offset.zero,
             end: Offset(-offset.dx * 0.25, -offset.dy * 0.25),
           ).chain(CurveTween(curve: curve)).animate(secondaryAnimation);

           return SlideTransition(
             position: outAnimation,
             child: SlideTransition(position: inAnimation, child: child),
           );
         },
       );

  final SlideDirection direction;
  final Curve curve;

  static Offset _getBeginOffset(SlideDirection direction) {
    switch (direction) {
      case SlideDirection.rightToLeft:
        return const Offset(1.0, 0.0);
      case SlideDirection.leftToRight:
        return const Offset(-1.0, 0.0);
      case SlideDirection.bottomToTop:
        return const Offset(0.0, 1.0);
      case SlideDirection.topToBottom:
        return const Offset(0.0, -1.0);
    }
  }
}

/// A [PageTransitionsBuilder] that slides pages into view.
///
/// Configured globally in [AppTheme] so that all standard [MaterialPageRoute]
/// navigations automatically use this smooth slide transition.
class SlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const SlidePageTransitionsBuilder({
    this.direction = SlideDirection.rightToLeft,
    this.curve = Curves.fastOutSlowIn,
  });

  final SlideDirection direction;
  final Curve curve;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final offset = SlidePageRoute._getBeginOffset(direction);

    final inAnimation = Tween<Offset>(
      begin: offset,
      end: Offset.zero,
    ).chain(CurveTween(curve: curve)).animate(animation);

    final outAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(-offset.dx * 0.25, -offset.dy * 0.25),
    ).chain(CurveTween(curve: curve)).animate(secondaryAnimation);

    return SlideTransition(
      position: outAnimation,
      child: SlideTransition(position: inAnimation, child: child),
    );
  }
}

/// Convenience extensions for smooth slide transitions.
extension SlideNavigationExtension on BuildContext {
  /// Pushes a new screen using the standard Right-to-Left slide transition.
  Future<T?> pushSlide<T>(Widget page, {RouteSettings? settings}) {
    return Navigator.of(this)
        .push<T>(SlidePageRoute(builder: (_) => page, settings: settings));
  }

  /// Replaces the current screen using the standard Right-to-Left slide transition.
  Future<T?> pushReplacementSlide<T, TO>(
    Widget page, {
    RouteSettings? settings,
    TO? result,
  }) {
    return Navigator.of(this).pushReplacement<T, TO>(
      SlidePageRoute(builder: (_) => page, settings: settings),
      result: result,
    );
  }

  /// Pushes a new screen and removes all previous routes with a slide transition.
  Future<T?> pushAndRemoveUntilSlide<T>(
    Widget page,
    bool Function(Route<dynamic>) predicate, {
    RouteSettings? settings,
  }) {
    return Navigator.of(this).pushAndRemoveUntil<T>(
      SlidePageRoute(builder: (_) => page, settings: settings),
      predicate,
    );
  }
}
