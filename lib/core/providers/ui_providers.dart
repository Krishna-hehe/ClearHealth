import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';

// UI State Providers
final showOnboardingProvider = StateProvider<bool>((ref) => false);

final selectedComparisonReportsProvider = StateProvider<List<LabReport>>((ref) => []);

final isComparisonModeProvider = StateProvider<bool>((ref) => false);

final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

// Temporary: Selected Result Provider
final selectedReportProvider = StateProvider<LabReport?>((ref) => null); 
final selectedTestProvider = StateProvider<TestResult?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');
