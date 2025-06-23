# CityFix - Municipal Issue Reporting App

A Flutter-based mobile application that allows citizens to report municipal issues (potholes, street lights, garbage, etc.) to their local authorities. The app provides real-time communication between citizens and municipal staff through an integrated chat system.

## Features

### For Citizens
- **Issue Reporting**: Report various municipal issues with photos and location
- **Real-time Chat**: Communicate directly with municipal staff about your reports
- **Status Tracking**: Monitor the progress of your reported issues
- **Push Notifications**: Receive updates when your report status changes or when staff sends messages
- **Location-based**: Automatically detects your municipal authority based on postcode
- **Anonymous Reporting**: Option to report issues anonymously

### For Municipal Staff
- **Issue Management**: View and manage reported issues
- **Chat System**: Respond to citizen inquiries through the integrated chat
- **Status Updates**: Update issue status and communicate with reporters
- **Photo Support**: View photos submitted with reports

## Technical Features

- **Firebase Integration**: Authentication, Firestore database, Cloud Functions, and FCM
- **Real-time Notifications**: Push notifications for status changes and new messages
- **Image Upload**: Photo capture and upload to Firebase Storage
- **Location Services**: GPS integration for precise issue location
- **Offline Support**: Basic offline functionality with local caching
- **Cross-platform**: Works on both Android and iOS

## Tech Stack

- **Frontend**: Flutter
- **Backend**: Firebase
  - Authentication (Email/Password, Google Sign-in)
  - Firestore (Database)
  - Cloud Functions (Backend logic)
  - Firebase Cloud Messaging (Push notifications)
  - Firebase Storage (Image storage)
- **State Management**: Flutter's built-in state management
- **UI**: Material Design with custom theming

## Setup Instructions

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio / VS Code
- Firebase project
- Google Cloud account

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/city_fix.git
   cd city_fix
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Enable Authentication (Email/Password, Google Sign-in)
   - Create a Firestore database
   - Set up Cloud Functions for notifications
   - Download and add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

4. **Configure Firebase**
   - Update Firebase configuration in your project
   - Set up Firestore security rules
   - Configure Cloud Functions for push notifications

5. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── incident_type_screen.dart
│   ├── incident_details_screen.dart
│   ├── incident_chat_screen.dart
│   └── ...
├── utils/                    # Utility classes
│   ├── auth_service.dart
│   ├── location_service.dart
│   └── permissions.dart
└── theme/                    # App theming
    └── app_theme.dart
```

## Firebase Collections

- **reports**: Municipal issue reports
- **reporter**: User profiles and FCM tokens
- **users**: Admin/staff user management
- **municipals**: Municipal authority data
- **incidentTypes**: Available issue types with icons

## Push Notifications

The app supports push notifications for:
- Report status changes
- New messages from municipal staff
- System updates

Notifications can open either the incident details screen or the chat screen based on the notification type.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, email support@cityfix.com or create an issue in this repository.

## Acknowledgments

- Flutter team for the amazing framework
- Firebase for the backend services
- Material Design for the UI guidelines
