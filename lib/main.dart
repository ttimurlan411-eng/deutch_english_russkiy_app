import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_state.dart';
import 'l10n/app_localizations.dart';
import 'screens/app_root.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const DictionaryApp());
}

/// Root widget. Owns the [AppState] and exposes it to the screens.
class DictionaryApp extends StatefulWidget {
  const DictionaryApp({super.key, this.state, this.locale});

  /// Optional injection point used by tests.
  final AppState? state;

  /// Overrides the active locale. Defaults to the language chosen in the
  /// settings screen (Kyrgyz when nothing is stored yet).
  final Locale? locale;

  @override
  State<DictionaryApp> createState() => _DictionaryAppState();
}

class _DictionaryAppState extends State<DictionaryApp> {
  AppState? _ownedState;
  AppState? _activeState;

  AppState get _state => widget.state ?? (_ownedState ??= AppState());

  @override
  void initState() {
    super.initState();
    _activeState = _state;
    _activeState!.initialize();
  }

  @override
  void didUpdateWidget(covariant DictionaryApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newState = _state;
    if (!identical(newState, _activeState)) {
      _activeState = newState;
      newState.initialize();
    }
  }

  @override
  void dispose() {
    if (widget.state == null) {
      _ownedState?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;

    // The settings controller notifies when the interface language changes.
    return ListenableBuilder(
      listenable: state.settings,
      builder: (context, _) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          locale: widget.locale ?? state.settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: AppRoot(state: state),
        );
      },
    );
  }
}
