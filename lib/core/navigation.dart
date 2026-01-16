import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';

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
final selectedTestProvider = StateProvider<TestResult?>((ref) => null);
final selectedReportProvider = StateProvider<LabReport?>((ref) => null);
