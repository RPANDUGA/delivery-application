import 'package:flutter/widgets.dart';

import 'auth.dart';

class AuthScope extends InheritedWidget {
  final AuthRepository auth;

  const AuthScope({
    super.key,
    required this.auth,
    required super.child,
  });

  static AuthRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found in context');
    return scope!.auth;
  }

  @override
  bool updateShouldNotify(AuthScope oldWidget) => auth != oldWidget.auth;
}
