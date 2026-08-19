/// Ponto de entrada do app Zoe (cliente).
///
/// Referências:
/// - ARCHITECTURE.md §Estrutura de Pastas: main.dart → app.dart
/// - prompt.md §3.1: HydratedBloc storage init antes de runApp
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // HydratedBloc storage para persistência OOM do carrinho
  // Web usa IndexedDB via HydratedStorage.webStorageDirectory
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : await getApplicationDocumentsDirectory(),
  );

  // Service locator
  await configureDependencies();

  runApp(const ZoeApp());
}
