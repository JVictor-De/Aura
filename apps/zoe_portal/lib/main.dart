/// Ponto de entrada do Dashboard Zoe Portal (lojistas).
///
/// Referência: ARCHITECTURE.md §Estrutura de Pastas: zoe_portal/
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/injection/portal_injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configurePortalDependencies();
  runApp(const ZoePortalApp());
}
