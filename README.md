# Clear Health

![Build Status](https://img.shields.io/badge/build-passing-brightgreen) ![License](https://img.shields.io/badge/license-MIT-blue) ![Flutter](https://img.shields.io/badge/Flutter-3.10.4-02569B?logo=flutter)

**Clear Health** (formerly LabSense) is an intelligent health monitoring application built with Flutter. It empowers users to upload lab reports, receive AI-powered insights, tracking health trends monitoring, and manage family health profiles securely.

## Features

- **📄 Lab Report Management**: Upload PDF lab reports and extract data automatically.
- **t 🤖 AI-Powered Insights**: Get personalized health summaries, optimization tips, and predictions using Google Gemini.
- **🔒 Secure Authentication**: Biometric login (Fingerprint/Face ID) and Supabase authentication.
- **👨‍👩‍👧‍👦 Multi-Profile Support**: Manage health records for the entire family.
- **📈 Trend Analysis**: Visualize health metrics over time with interactive charts.
- **💊 Medication Tracking**: Keep track of prescriptions and schedules.
- **🔔 Smart Notifications**: Reminders for medication and appointments.
- **📤 Data Export**: Generate comprehensive PDF health reports.

## Tech Stack

- **Frontend**: [Flutter](https://flutter.dev/)
- **Backend**: [Supabase](https://supabase.io/) (Auth, Database, Storage, Edge Functions)
- **AI**: [Google Gemini API](https://ai.google.dev/)
- **State Management**: [Riverpod](https://riverpod.dev/)
- **Local Storage**: [Hive](https://docs.hivedb.dev/)
- **Charts**: [fl_chart](https://pub.dev/packages/fl_chart)

## Quick Start

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- Detailed setup guide available in [docs/setup.md](./docs/setup.md) (create this if needed).

### Installation

1. **Clone the repository:**

    ```bash
    git clone https://github.com/your-username/clear_health.git
    cd clear_health
    ```

2. **Install dependencies:**

    ```bash
    flutter pub get
    ```

3. **Configure Environment:**
    Create a `.env` file in the root directory (see `.env.example` for reference):

    ```env
    GEMINI_API_KEY=your_key
    SUPABASE_URL=your_url
    SUPABASE_ANON_KEY=your_key
    ```

4. **Run the app:**

    ```bash
    flutter run
    ```

## Documentation

- **[Features Guide](./docs/FEATURES.md)**: Detailed breakdown of what Clear Health can do.
- **[Technical Architecture](./docs/ARCHITECTURE.md)**: Overview of the tech stack and system design.
- **[Development Guide](./docs/DEVELOPMENT_GUIDE.md)**: Setup instructions and development workflows.
- **[User Manual](./docs/USER_MANUAL.md)**: Step-by-step documentation for end users.
- **[Contributing Guidelines](CONTRIBUTING.md)**: How to help improve Clear Health.
- **[Changelog](CHANGELOG.md)**: Version history and updates.
- **[License](LICENSE)**: MIT License details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
