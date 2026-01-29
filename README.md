# LabSense2 🧬

LabSense2 is an advanced, AI-powered health management platform designed to help users understand their lab results, track health trends, manage medications, and maintain their overall wellness with enterprise-grade security.

## ✨ Key Features

### 🔬 Lab Results Management

- **AI-Powered Analysis**: Upload PDF or image lab reports and get instant, easy-to-understand explanations using Gemini AI
- **OCR Technology**: Automatic text extraction from lab reports with intelligent parsing
- **Trend Visualization**: Interactive charts showing health metrics over time
- **Comparison Tools**: Compare results across different time periods
- **Abnormal Value Detection**: Automatic highlighting of out-of-range values

### 💊 Medication Management

- **Prescription Tracking**: Manage all your medications in one place
- **Smart Reminders**: Get notified when it's time to take your medication
- **Dosage History**: Track medication adherence over time
- **Refill Alerts**: Never run out of important medications

### 👥 Family Health Profiles

- **Multi-Profile Support**: Manage health records for your entire family
- **Secure Sharing**: Share lab results with doctors via secure, time-limited links
- **Doctor View Mode**: Special read-only mode for healthcare providers
- **Care Circles**: Collaborate with family members on health management

### 🤖 AI Health Assistant

- **Contextual Chat**: Ask health questions with full context of your lab results
- **Personalized Insights**: AI analyzes your health trends and provides recommendations
- **Medical Term Explanations**: Understand complex medical terminology easily

### 🔐 Enterprise-Grade Security

#### Active Security Features

- **Row Level Security (RLS) Verification**: Automatic verification of database security policies on every login
- **Biometric Authentication**: Fingerprint/Face ID support for quick, secure access
- **Session Management**: Automatic timeout and secure session handling
- **Encrypted Storage**: All sensitive data encrypted at rest and in transit
- **Audit Logging**: Comprehensive security event tracking

#### Security Services (Ready for Integration)

- **Input Validation**: SQL injection and XSS protection on all user inputs
- **Rate Limiting**: Brute-force attack prevention on login and API endpoints
- **Content Security Policy**: Strict CSP headers to prevent XSS attacks

**Security Score**: 65/100 (Target: 85/100 after full integration)

See [Security Documentation](docs/SECURITY_INTEGRATION_GUIDE.md) for details.

### 📊 Analytics & Insights

- **Health Dashboard**: Comprehensive overview of your health status
- **Trend Analysis**: AI-powered insights into your health patterns
- **Risk Assessment**: Early warning system for potential health issues
- **Progress Tracking**: Monitor improvements in key health metrics

## 🛠️ Tech Stack

- **Frontend**: [Flutter](https://flutter.dev/) 3.x
- **State Management**: [Riverpod](https://riverpod.dev/) 2.x
- **Backend**: [Supabase](https://supabase.com/) (PostgreSQL + Realtime)
- **AI**: [Google Gemini API](https://ai.google.dev/) (Gemini 2.0 Flash)
- **Authentication**: Supabase Auth (Email, Google, Apple)
- **Storage**: Supabase Storage (Encrypted file storage)
- **OCR**: Google Cloud Vision API
- **Security**: RLS, Input Validation, Rate Limiting
- **Monitoring**: Sentry (Error tracking)

## 📦 Project Structure

```text
lib/
├── core/
│   ├── services/          # Core services (Supabase, AI, Security)

│   │   ├── rls_verification_service.dart  # RLS security verification

│   │   ├── rate_limiter.dart              # Rate limiting service

│   │   └── ...
│   ├── utils/             # Utilities (Input validation, etc.)

│   ├── providers/         # Riverpod state providers

│   ├── repositories/      # Data access layer

│   └── models.dart        # Data models

├── features/              # Feature modules

│   ├── auth/             # Authentication

│   ├── home/             # Dashboard

│   ├── lab_results/      # Lab result management

│   ├── trends/           # Health trends

│   ├── medications/      # Medication tracking

│   ├── chat/             # AI health assistant

│   ├── settings/         # User settings & family profiles

│   └── share/            # Secure sharing features

├── widgets/              # Shared UI components

└── main.dart             # Application entry point

docs/
├── SECURITY_INTEGRATION_GUIDE.md      # Security implementation guide

├── SECURITY_AUDIT_REPORT.md           # Security audit findings

├── PLAN-security-integration.md       # Security roadmap

└── SECURITY_INTEGRATION_HANDOFF.md    # Development handoff doc

```text

## ⚡ Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.0 or higher)
- [Supabase](https://supabase.com/) Account & Project
- [Google Gemini API Key](https://ai.google.dev/)
- [Sentry DSN](https://sentry.io/) (Optional, for error tracking)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/labsense2.git
   cd labsense2
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Environment Setup**

   Create a `.env` file in the root directory:

   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   GEMINI_API_KEY=your_gemini_api_key
   SENTRY_DSN=your_sentry_dsn  # Optional

   ```

4. **Database Setup**
   - Run the SQL migrations in `supabase/migrations/`
   - Enable Row Level Security (RLS) on all tables
   - See [Database Schema](docs/DATABASE_SCHEMA.md) for details

5. **Run the App**

   ```bash
   # Web

   flutter run -d chrome
   
   # iOS

   flutter run -d ios
   
   # Android

   flutter run -d android
   ```

## 🔒 Security Features

### Active Security Measures

1. **RLS Verification** ✅
   - Automatic verification on user login
   - Tests 3 critical tables: `lab_results`, `profiles`, `prescriptions`
   - Logs security status to console
   - See logs: "🔐 User authenticated - verifying RLS policies..."

2. **Biometric Authentication** ✅
   - Fingerprint/Face ID support
   - Secure local authentication
   - Fallback to PIN/Password

3. **Session Security** ✅
   - Automatic timeout after inactivity
   - Secure token management
   - Session hijacking prevention

### Pending Integration (Phase 2-3)

1. **Input Validation** ⏳
   - SQL injection prevention
   - XSS attack prevention
   - Comprehensive sanitization

2. **Rate Limiting** ⏳
   - Login: 5 attempts / 15 minutes
   - File uploads: 10 / 5 minutes
   - AI queries: 20 / 5 minutes

See [Security Integration Progress](docs/SECURITY_INTEGRATION_PROGRESS.md) for status.

## 📱 Platform Support

- ✅ **Web**: Chrome, Firefox, Safari, Edge
- ✅ **iOS**: 12.0+
- ✅ **Android**: API 21+ (Android 5.0+)

## 🧪 Testing

```bash

# Run all tests

flutter test

# Run specific test

flutter test test/widget/dashboard_page_test.dart

# Run with coverage

flutter test --coverage
```text

## 📚 Documentation

- [Security Integration Guide](docs/SECURITY_INTEGRATION_GUIDE.md)
- [Security Audit Report](docs/SECURITY_AUDIT_REPORT.md)
- [API Documentation](docs/API_DOCUMENTATION.md)
- [Development Handoff](docs/SECURITY_INTEGRATION_HANDOFF.md)

## 🗺️ Roadmap

### ✅ Completed

- [x] Core lab result management
- [x] AI-powered analysis
- [x] Medication tracking with reminders
- [x] Family health profiles
- [x] Secure doctor sharing
- [x] RLS verification system
- [x] Biometric authentication
- [x] Health chat assistant

### 🚧 In Progress (Phase 2-3)

- [ ] Input validation integration
- [ ] Rate limiting integration
- [ ] Security monitoring dashboard

### 📋 Planned

- [ ] Wearable device integration
- [ ] Appointment scheduling
- [ ] Telemedicine integration
- [ ] Health insurance integration
- [ ] Multi-language support

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure:

- Code passes `flutter analyze` with no errors
- All tests pass
- Security features are not compromised
- Documentation is updated

## 🐛 Bug Reports

Found a bug? Please open an issue with:

- Description of the bug
- Steps to reproduce
- Expected vs actual behavior
- Screenshots (if applicable)
- Device/platform information

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Google Gemini AI for intelligent health insights
- Supabase for secure backend infrastructure
- Flutter team for the amazing framework
- Open source community for various packages

