class TestResult {
  final String name;
  final String loinc;
  final String result;
  final String unit;
  final String reference;
  final String status;

  TestResult({
    required this.name,
    required this.loinc,
    required this.result,
    required this.unit,
    required this.reference,
    required this.status,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      name: json['test_name'] ?? json['name'] ?? '',
      loinc: json['loinc'] ?? '',
      result: json['result_value']?.toString() ?? json['result']?.toString() ?? '',
      unit: json['unit'] ?? '',
      reference: json['reference_range'] ?? json['reference'] ?? '',
      status: json['status'] ?? 'Normal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'test_name': name,
      'loinc': loinc,
      'result_value': result,
      'unit': unit,
      'reference_range': reference,
      'status': status,
    };
  }
}

class LabReport {
  final String id;
  final DateTime date;
  final String labName;
  final int testCount;
  final int abnormalCount;
  final String status;
  final bool isSelected;
  final List<TestResult>? testResults;

  LabReport({
    required this.id,
    required this.date,
    required this.labName,
    required this.testCount,
    this.abnormalCount = 0,
    required this.status,
    this.isSelected = false,
    this.testResults,
  });

  factory LabReport.fromJson(Map<String, dynamic> json) {
    return LabReport(
      id: json['id']?.toString() ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      labName: json['lab_name'] ?? 'Unknown Lab',
      testCount: json['tests'] is int ? json['tests'] : (json['test_results'] as List?)?.length ?? 0,
      abnormalCount: json['abnormal_count'] ?? 0,
      status: json['status'] ?? 'Normal',
      testResults: (json['test_results'] as List?)?.map((t) => TestResult.fromJson(t)).toList(),
    );
  }
}

