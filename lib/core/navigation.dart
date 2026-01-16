import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NavItem {
  landing,
  dashboard,
  labResults,
  trends,
  conditions,
  prescriptions,
  settings,
  notifications,
  resultDetail,
  shareResults,
  comparison,
  healthOptimization,
  healthCircles,
  resultExpanded,
  healthChat,
  auth,
}

final navigationProvider = StateProvider<NavItem>((ref) => NavItem.landing);
final isSignUpModeProvider = StateProvider<bool>((ref) => false);

