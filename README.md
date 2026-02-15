# LabSense - Intelligent Health Monitoring

LabSense is a Flutter-based mobile application designed for intelligent health monitoring. It allows users to upload, analyze, and track their lab results, providing AI-powered insights, health predictions, and wellness tips.

## Key Features

* **Lab Report Management**: Upload and manage PDF lab reports.
* **AI-Powered Insights**: Get AI-generated summaries, optimization tips, and health predictions based on your lab results, powered by Google Gemini.
* **Secure Authentication**: Secure login with Supabase authentication and biometric support (fingerprint/face ID).
* **Multi-Profile Support**: Manage health data for multiple family members.
* **Trend Analysis**: Visualize your health data over time with charts and graphs.
* **Medication Tracking**: Keep a record of your medications.
* **Notifications**: Receive reminders and updates.
* **Data Export**: Export your data as a PDF.

## Getting Started

### Prerequisites

* Flutter SDK: Make sure you have the Flutter SDK installed.
* An editor with the Flutter plugin (e.g., VS Code, Android Studio).

### Installation

1. **Clone the repository:**

    ```bash
    git clone <repository-url>
    cd lab_sense_app
    ```

2. **Install dependencies:**

    ```bash
    flutter pub get
    ```

3. **Set up environment variables:**
    Create a `.env` file in the root of the project and add the following environment variables. You can get these from your Supabase and Google AI project settings.

    ```
    GEMINI_API_KEY=your_gemini_api_key
    SUPABASE_URL=your_supabase_url
    SUPABASE_ANON_KEY=your_supabase_anon_key
    LABSENSE_CHAT_API_KEY=your_labsense_chat_api_key
    Note: Do NOT bundle this file in your build. Instead, use these values with `--dart-define` when running/building the app.
    ```

    flutter run \
      --dart-define=GEMINI_API_KEY=your_key \
      --dart-define=SUPABASE_URL=your_url \
      --dart-define=SUPABASE_ANON_KEY=your_key \
      --dart-define=LABSENSE_CHAT_API_KEY=your_key \
      --dart-define=SENTRY_DSN=your_dsn

    ```


4. **Run the application:**

    ```bash
    flutter run
    ```

## Architecture

LabSense is built with a modern Flutter architecture, emphasizing separation of concerns and maintainability.

* **State Management**: The application uses `flutter_riverpod` for state management, with providers organized by feature domains (auth, core, labs, user, etc.).
* **Backend**: [Supabase](https://supabase.io/) is used for the backend, providing authentication, a PostgreSQL database (with pgvector for embeddings), and file storage.
* **AI Integration**: The application leverages the [Google Gemini API](https://ai.google.dev/) for its AI-powered features, including:
  * **Vector Embeddings**: For semantic search and similarity.
  * **Generative Models**: For summaries, insights, and predictions.
* **Local Storage**: [Hive](https://pub.dev/packages/hive) is used for local caching and offline storage.
* **Security**: The app features biometric authentication (`local_auth`), secure storage for sensitive data (`flutter_secure_storage`), and Row Level Security (RLS) in Supabase.
* **Error Reporting**: [Sentry](https://sentry.io/) is used for real-time error monitoring.

## Core Dependencies

* `flutter_riverpod`: For state management.
* `supabase_flutter`: For backend integration with Supabase.
* `google_generative_ai`: For AI features.
* `fl_chart`: for charting and data visualization.
* `hive`: For local storage.
* `sentry_flutter`: For error reporting.
* `local_auth`: For biometric authentication.
* `pdf`: For PDF generation.

## Project Structure

The project follows a feature-driven directory structure:

```
lib/
├── core/         # Core services, models, and providers
├── features/     # Feature-specific widgets and pages
├── widgets/      # Shared widgets
└── main.dart     # Application entry point
```
