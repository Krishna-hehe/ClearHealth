# LabSense2 🧬

LabSense2 is an advanced, AI-powered health management platform designed to help users understand their lab results, track health trends, and manage their overall wellness with ease and security.

## 🚀 Features

- **AI-Powered Lab Analysis**: Upload PDF or image lab reports and get instant, easy-to-understand explanations of your results using Gemini AI.
- **Trend Tracking**: Visualize your health data over time with interactive charts to spot trends and improvements.
- **Secure & Private**: Built with HIPAA compliance in mind. Your data is encrypted and secure.
- **Biometric Security**: Optional biometric authentication (Fingerprint/Face ID) for an extra layer of protection.
- **Comprehensive Dashboard**: View key health stats, active conditions, and upcoming tasks at a glance.
- **Cross-Platform**: Built with Flutter for a seamless experience on Web, iOS, and Android.

## 🛠️ Tech Stack

- **Frontend**: [Flutter](https://flutter.dev/)
- **State Management**: [Riverpod](https://riverpod.dev/)
- **Backend / Database**: [Supabase](https://supabase.com/)
- **AI Integration**: [Google Gemini API](https://ai.google.dev/)
- **Authentication**: Supabase Auth
- **UI Components**: FontAwesome, Custom Themed Widgets

## 📦 Project Structure

```
lib/
├── core/            # Core services (Supabase, AI, Auth, Theme)
├── features/        # Feature modules (Auth, Home, Lab Results, Trends, etc.)
├── widgets/         # Shared UI components
└── main.dart        # Application entry point
```

## ⚡ Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Supabase](https://supabase.com/) Account & Project
- [Google Gemini API Key](https://ai.google.dev/)

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/yourusername/labsense2.git
    cd labsense2
    ```

2.  **Install dependencies**
    ```bash
    flutter pub get
    ```

3.  **Environment Setup**
    Create a `.env` file in the root directory and add your keys:
    ```env
    SUPABASE_URL=your_supabase_url
    SUPABASE_ANON_KEY=your_supabase_anon_key
    GEMINI_API_KEY=your_gemini_api_key
    ```

4.  **Run the App**
    ```bash
    flutter run
    ```

## 🤝 Contributing

Contributions are welcome! Please fork the repository and submit a pull request for any enhancements or bug fixes.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
