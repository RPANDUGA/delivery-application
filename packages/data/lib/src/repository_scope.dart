import 'package:flutter/widgets.dart';

import 'repositories.dart';

class RepositoryScope extends InheritedWidget {
  final DataRepository repository;

  const RepositoryScope({
    super.key,
    required this.repository,
    required super.child,
  });

  static DataRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RepositoryScope>();
    assert(scope != null, 'RepositoryScope not found in context');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(RepositoryScope oldWidget) =>
      repository != oldWidget.repository;
}
