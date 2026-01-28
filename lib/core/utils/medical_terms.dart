class NormalizedTest {
  final String standardizedName;
  final String loincCode;
  final String category;

  const NormalizedTest({
    required this.standardizedName,
    required this.loincCode,
    this.category = 'General',
  });
}

class MedicalTermsNormalizer {
  static const Map<String, NormalizedTest> _mapping = {
    // Diabetes
    'hba1c': NormalizedTest(
      standardizedName: 'Hemoglobin A1c',
      loincCode: '4548-4',
      category: 'Diabetes',
    ),
    'a1c': NormalizedTest(
      standardizedName: 'Hemoglobin A1c',
      loincCode: '4548-4',
      category: 'Diabetes',
    ),
    'glycated hemoglobin': NormalizedTest(
      standardizedName: 'Hemoglobin A1c',
      loincCode: '4548-4',
      category: 'Diabetes',
    ),
    'glucose': NormalizedTest(
      standardizedName: 'Glucose',
      loincCode: '2345-7',
      category: 'Diabetes',
    ),
    'blood sugar': NormalizedTest(
      standardizedName: 'Glucose',
      loincCode: '2345-7',
      category: 'Diabetes',
    ),
    'fasting glucose': NormalizedTest(
      standardizedName: 'Glucose',
      loincCode: '2345-7',
      category: 'Diabetes',
    ),

    // Lipids
    'cholesterol': NormalizedTest(
      standardizedName: 'Cholesterol, Total',
      loincCode: '2093-3',
      category: 'Lipids',
    ),
    'total cholesterol': NormalizedTest(
      standardizedName: 'Cholesterol, Total',
      loincCode: '2093-3',
      category: 'Lipids',
    ),
    'chol': NormalizedTest(
      standardizedName: 'Cholesterol, Total',
      loincCode: '2093-3',
      category: 'Lipids',
    ),
    'hdl': NormalizedTest(
      standardizedName: 'HDL Cholesterol',
      loincCode: '2085-9',
      category: 'Lipids',
    ),
    'hdl cholesterol': NormalizedTest(
      standardizedName: 'HDL Cholesterol',
      loincCode: '2085-9',
      category: 'Lipids',
    ),
    'ldl': NormalizedTest(
      standardizedName: 'LDL Cholesterol',
      loincCode: '2089-1',
      category: 'Lipids',
    ),
    'ldl cholesterol': NormalizedTest(
      standardizedName: 'LDL Cholesterol',
      loincCode: '2089-1',
      category: 'Lipids',
    ),
    'triglycerides': NormalizedTest(
      standardizedName: 'Triglycerides',
      loincCode: '2571-8',
      category: 'Lipids',
    ),
    'trig': NormalizedTest(
      standardizedName: 'Triglycerides',
      loincCode: '2571-8',
      category: 'Lipids',
    ),

    // Thyroid
    'tsh': NormalizedTest(
      standardizedName: 'Thyroid Stimulating Hormone',
      loincCode: '11579-0',
      category: 'Thyroid',
    ),
    'thyroid stimulating hormone': NormalizedTest(
      standardizedName: 'Thyroid Stimulating Hormone',
      loincCode: '11579-0',
      category: 'Thyroid',
    ),
    'free t4': NormalizedTest(
      standardizedName: 'Thyroxine (T4), Free',
      loincCode: '4225-7',
      category: 'Thyroid',
    ),
    'ft4': NormalizedTest(
      standardizedName: 'Thyroxine (T4), Free',
      loincCode: '4225-7',
      category: 'Thyroid',
    ),

    // Vitamins & Minerals
    'vitamin d': NormalizedTest(
      standardizedName: 'Vitamin D, 25-Hydroxy',
      loincCode: '62292-8',
      category: 'Vitamins',
    ),
    '25-oh vitamin d': NormalizedTest(
      standardizedName: 'Vitamin D, 25-Hydroxy',
      loincCode: '62292-8',
      category: 'Vitamins',
    ),
    'vitamin b12': NormalizedTest(
      standardizedName: 'Vitamin B12',
      loincCode: '2132-9',
      category: 'Vitamins',
    ),
    'b12': NormalizedTest(
      standardizedName: 'Vitamin B12',
      loincCode: '2132-9',
      category: 'Vitamins',
    ),
    'iron': NormalizedTest(
      standardizedName: 'Iron',
      loincCode: '2498-4',
      category: 'Minerals',
    ),
    'serum iron': NormalizedTest(
      standardizedName: 'Iron',
      loincCode: '2498-4',
      category: 'Minerals',
    ),
    'ferritin': NormalizedTest(
      standardizedName: 'Ferritin',
      loincCode: '2276-4',
      category: 'Minerals',
    ),

    // CBC
    'hemoglobin': NormalizedTest(
      standardizedName: 'Hemoglobin',
      loincCode: '718-7',
      category: 'CBC',
    ),
    'hgb': NormalizedTest(
      standardizedName: 'Hemoglobin',
      loincCode: '718-7',
      category: 'CBC',
    ),
    'hematocrit': NormalizedTest(
      standardizedName: 'Hematocrit',
      loincCode: '4544-3',
      category: 'CBC',
    ),
    'hct': NormalizedTest(
      standardizedName: 'Hematocrit',
      loincCode: '4544-3',
      category: 'CBC',
    ),
    'platelets': NormalizedTest(
      standardizedName: 'Platelet Count',
      loincCode: '777-3',
      category: 'CBC',
    ),
    'plt': NormalizedTest(
      standardizedName: 'Platelet Count',
      loincCode: '777-3',
      category: 'CBC',
    ),
    'wbc': NormalizedTest(
      standardizedName: 'WBC Count',
      loincCode: '6690-2',
      category: 'CBC',
    ),
    'rbc': NormalizedTest(
      standardizedName: 'RBC Count',
      loincCode: '789-8',
      category: 'CBC',
    ),
  };

  /// Normalizes a raw test name from a lab report into a standardized name and LOINC code.
  static NormalizedTest normalize(String rawName) {
    final cleanName = rawName.toLowerCase().trim();

    // Exact match
    if (_mapping.containsKey(cleanName)) {
      return _mapping[cleanName]!;
    }

    // Fuzzy match (partial)
    for (var entry in _mapping.entries) {
      if (cleanName.contains(entry.key) || entry.key.contains(cleanName)) {
        return entry.value;
      }
    }

    // Fallback
    return NormalizedTest(
      standardizedName: rawName,
      loincCode: '',
      category: 'Uncategorized',
    );
  }
}
