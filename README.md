# MtaaSuite 🏘️

**MtaaSuite – A unified community and local government service app built with Flutter.**

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white)](https://firebase.google.com/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)

## 📋 Overview

MtaaSuite is a comprehensive mobile application designed to bridge the gap between citizens and local government services in Tanzania. The app provides a unified platform for community engagement, service requests, and local governance interactions.

## ✨ Features

### 🔐 Authentication & Security
- **Phone Number Authentication** with OTP verification
- **Firebase App Check** for enhanced security
- **Multi-language Support** (English & Swahili)
- **Secure Data Storage** with encryption

### 👥 User Management
- **Citizen Registration** with location-based services
- **Ward Official Management** with verification
- **Profile Management** with avatar support
- **Role-based Access Control**

### 🏛️ Government Services
- **Service Request System** for local government services
- **Complaint Filing** and tracking
- **Document Submission** and verification
- **Payment Integration** for services

### 📍 Location Services
- **GPS-based Location** detection
- **Administrative Divisions** (Regions, Districts, Wards)
- **Offline Location Data** with fallback support
- **Address Validation** and geocoding

### 📊 Dashboard & Analytics
- **Interactive Charts** using Syncfusion
- **Service Statistics** and reporting
- **Performance Metrics** for officials
- **Data Visualization** with multiple chart types

### 🔔 Notifications & Communication
- **Push Notifications** via Firebase
- **SMS Integration** for critical alerts
- **In-app Messaging** system
- **Announcement Broadcasting**

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: `^3.8.1`
- **Dart SDK**: `^3.8.1`
- **Android Studio** or **VS Code** with Flutter extensions
- **Firebase Account** for backend services

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/ErickWDaniel/mtaasuite.git
   cd mtaasuite
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication, Realtime Database, Storage, and Functions
   - Add your Android app with package name: `tz.co.mtaasuite.mtaasuite`
   - Download `google-services.json` and place it in `android/app/`

4. **Configure Environment**
   - Copy `.env.example` to `.env`
   - Fill in your Firebase configuration and API keys

5. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Configuration

#### App Check Setup (Development)
1. Go to Firebase Console → App Check
2. Register your Android app
3. Use Debug provider for development
4. Register the debug token shown in app logs

#### Authentication Setup
1. Enable Phone Authentication in Firebase Console
2. Configure SMS verification settings
3. Set up reCAPTCHA for web verification

## 📱 Screenshots

*Screenshots will be added here*

## 🏗️ Architecture

### Tech Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Authentication, Database, Storage, Functions)
- **State Management**: Provider + Riverpod
- **UI Framework**: Material Design 3
- **Charts**: Syncfusion Flutter Charts

### Project Structure
```
lib/
├── auth/                    # Authentication modules
│   ├── auth_core/          # Core authentication logic
│   ├── auth_gui/           # Authentication UI components
│   └── model/              # Authentication data models
├── services/               # Business logic services
├── dashboards/             # User dashboards
├── screens/                # App screens
├── utils/                  # Utility functions
└── widgets/                # Reusable UI components
```

## 🔧 Development

### Code Style
- Follow Flutter's [official style guide](https://flutter.dev/docs/development/tools/formatting)
- Use `flutter analyze` for code analysis
- Run `flutter test` for unit tests

### Building for Production

#### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

### Environment Variables
Create a `.env` file with:
```
FIREBASE_API_KEY=your_api_key
FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_project.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
```

## 📚 API Documentation

### Authentication Endpoints
- `POST /auth/login` - User login
- `POST /auth/register` - User registration
- `POST /auth/verify-otp` - OTP verification

### Service Endpoints
- `GET /services` - List available services
- `POST /services/request` - Submit service request
- `GET /services/{id}/status` - Check request status

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Write clear, concise commit messages
- Add tests for new features
- Update documentation as needed
- Follow the existing code style

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Erick W. Daniel** - *Initial work* - [GitHub](https://github.com/ErickWDaniel)

## 🙏 Acknowledgments

- Flutter Team for the amazing framework
- Firebase for backend services
- Tanzanian Government for inspiration
- Open source community for tools and libraries

## 📞 Support

For support, email erickwdaniel@example.com or join our Discord community.

---

**Made with ❤️ in Tanzania** 🇹🇿
