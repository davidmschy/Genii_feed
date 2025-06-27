# Genii Feed

Genii Feed is an AI-powered real estate operations platform. This Flutter application provides a dynamic, post-based interface for managing property listings, agent interactions, financial events, tasks, and more.

## 🚀 Quick Start (Development Setup)

Follow these steps to get the Genii Feed application running locally on your machine for development.

### 1. Prerequisites

*   **Flutter SDK**: Ensure you have Flutter installed. If not, follow the [official Flutter installation guide](https://flutter.dev/docs/get-started/install).
*   **Firebase Account**: You will need a Firebase project to connect the application to backend services (Authentication, Realtime Database, etc.).
*   **Firebase CLI**: Install the Firebase CLI: `npm install -g firebase-tools` (or other methods from [Firebase CLI setup](https://firebase.google.com/docs/cli#setup_the_cli)). Log in with `firebase login`.
*   **FlutterFire CLI**: Install the FlutterFire CLI: `dart pub global activate flutterfire_cli`.
*   **API Keys**: You will need API keys for external services:
    *   ScraperAPI (for Zillow/Redfin scraping)
    *   Repliers.io API

### 2. Clone the Repository

```bash
git clone <YOUR_REPOSITORY_URL_HERE>
# Example: git clone https://github.com/your-username/genii-feed-flutter.git
cd genii-feed-flutter # Or your repository's directory name
```

### 3. Configure Firebase

*   If this is a fresh clone and Firebase hasn't been configured for your environment:
    ```bash
    flutterfire configure
    ```
    Follow the prompts to connect this Flutter project to your Firebase project. This will generate `lib/firebase_options.dart` and automatically add necessary platform-specific configuration files (like `google-services.json` for Android and `GoogleService-Info.plist` for iOS).
*   **Ensure Firebase Services are Enabled**: In your Firebase project console, make sure you have enabled:
    *   Firebase Authentication (e.g., Email/Password, Anonymous sign-in for testing).
    *   Firebase Realtime Database.
    *   (Optional, if used later) Cloud Firestore, Firebase Storage.

### 4. Set Up Environment Variables (API Keys)

The application uses external APIs that require API keys. These are managed via an environment file that is *not* committed to version control.

*   Copy the example environment file:
    ```bash
    cp lib/env/env.example.dart lib/env/env.dart
    ```
*   Open `lib/env/env.dart` in your editor.
*   Replace the placeholder values with your actual API keys:
    ```dart
    // lib/env/env.dart
    class Env {
      static const String scraperApiKey = "YOUR_ACTUAL_SCRAPER_API_KEY"; // Replace this
      static const String repliersApiKey = "YOUR_ACTUAL_REPLIERS_API_KEY";   // Replace this
    }
    ```
    **Important**: `lib/env/env.dart` is (and should be) listed in your `.gitignore` file to prevent accidentally committing your secret keys. Ensure `/lib/env/env.dart` is in your project's `.gitignore` file.

### 5. Get Flutter Dependencies

```bash
flutter pub get
```

### 6. Run the Application

*   **Select a Device**: Ensure you have an emulator running or a physical device connected. You can see available devices with `flutter devices`.
*   **Run the App**:
    ```bash
    flutter run
    ```
    To run on a specific device: `flutter run -d <deviceId>`

### Development Toggles

The application includes configuration toggles for development convenience:

*   **Test Mode (`lib/config/app_config.dart`)**:
    *   `const bool kAppTestMode = true;`
    *   If set to `true` and no Firebase user is logged in, the app will use a mock "Genii Tester" user, bypassing the need for actual login during UI development and testing. Set to `false` for production or when testing real authentication flows.
*   **Development Firebase Collections (`lib/config/firebase_config.dart`)**:
    *   `const bool kUseDevCollections = true;`
    *   If set to `true`, the app will use Firebase Realtime Database paths suffixed with `_dev` (e.g., `geniiPosts_dev`, `profile_dev`). This is useful for keeping development data separate from production data. Set to `false` to use production collection names.

### Initial Data Seeding (Optional)

The application includes a mock data seeder to populate the database with sample users, properties, agents, and posts (excluding property listings which are fetched live or via fallback). This is useful for testing features.

*   Once the app is running and you are (mock or real) logged in:
    1.  Open the sidebar menu.
    2.  Tap on "Seed Mock Data". This will populate your configured Firebase Realtime Database with sample data.
    3.  Use "Fetch Listings (My ZIP)" or "Update ZIP & Fetch" in the sidebar to test listing ingestion.

You should now have Genii Feed running locally!

---
*(Rest of README would go here, e.g., Project Structure, Features, Deployment, etc.)*
