# AIDA - AI Donation Assistant

A Flutter prototype app for an AI-powered donation platform focused on matching donors and recipients (NGOs & Individuals in need) in India. The app demonstrates functional integration with Gemini APIs for AI-powered image analysis, tagging, and matching.

## 🌟 Features

### Core Features - AI at the Center

- **AI-Powered Image Analysis**: Upload/take photos of donation items and get AI-generated descriptions and tags using Gemini API
- **Need-Based Matching Engine**: Smart matching algorithm that prioritizes urgency, proximity, and relevance
- **Smart Notifications**: Real-time notifications when matches are found (simulated)

### Donor Features

- **Effortless Donation Upload**: In-app camera functionality with AI-powered item analysis
- **My Donations Dashboard**: Track donation status (Pending, Matched, Ready for Pickup, Completed)
- **Match Management**: View matched recipients and manage donation status
- **In-app Chat**: Direct communication with recipients (UI ready, backend integration pending)

### Recipient Features (NGOs and Individuals)

- **Verified Profile Creation**: Separate registration flows for NGOs and individuals
- **Needs Management System**: Post specific needs with urgency levels and detailed descriptions
- **Inbound Match Feed**: View all donations matching their needs
- **Match Acceptance**: Accept or reject donation matches

## 🏗️ Architecture

### Data Models
- **User**: Base user model with common fields
- **NGO**: Extended user model for organizations with registration details
- **Individual**: Extended user model for individuals with need explanations
- **Donation**: Item donation with AI-generated tags and matching status
- **Need**: Recipient requirements with urgency and location data
- **Match**: AI-powered matching between donations and needs
- **ChatMessage**: Real-time messaging between users

### Services
- **GeminiService**: AI image analysis and tagging using Google's Gemini API
- **MatchingService**: Smart matching algorithm based on tags, location, and urgency
- **SampleDataService**: Hardcoded sample data for demonstration

### State Management
- **AppState**: Provider-based state management for user data, donations, needs, and matches

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.9.0 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Supabase account for backend services
- Google AI Studio account for Gemini API

### Configuration Setup

⚠️ **Important**: This repository contains placeholder configurations for security. You must set up your own credentials to run the app.

#### 1. Supabase Backend Setup

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Run the database migration from `profile_system_migration.sql`
3. Update `lib/config/supabase_config.dart`:
   ```dart
   static const String url = 'YOUR_ACTUAL_SUPABASE_URL';
   static const String anonKey = 'YOUR_ACTUAL_SUPABASE_ANON_KEY';
   ```

#### 2. Gemini AI API Setup

1. Get your API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Update `lib/config/api_config.dart`:
   ```dart
   static const String geminiApiKey = 'YOUR_ACTUAL_GEMINI_API_KEY';
   ```

#### 3. Alternative: Environment Variables (Recommended)

1. Create a `.env` file in the project root:
   ```env
   SUPABASE_URL=your_supabase_url_here
   SUPABASE_ANON_KEY=your_supabase_anon_key_here
   GEMINI_API_KEY=your_gemini_api_key_here
   ```

2. Add flutter_dotenv to your pubspec.yaml and update your config files to read from environment variables

### Installation
- Google Gemini API key (optional - app works with mock data)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd aida2
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API Keys**
   - Copy `.env.example` to `.env`
   - Get your Gemini API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Update `lib/config/api_config.dart` with your API key:
     ```dart
     static const String geminiApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
     ```
   - For Supabase integration, update your Supabase URL and keys in the same file

4. **Generate JSON serialization code**
   ```bash
   flutter packages pub run build_runner build
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## ⚙️ API Configuration

### Gemini AI Setup
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a new API key
3. Update `lib/config/api_config.dart`:
   ```dart
   static const String geminiApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
   ```

### Supabase Setup (Optional)
1. Create a project at [Supabase](https://app.supabase.com)
2. Get your project URL and anon key
3. Update the configuration in your app

**Note**: Without API keys, the app will work with mock data for demonstration.

## 📱 App Flow

### For Donors
1. **Registration**: Choose "I want to Donate" and complete registration
2. **Upload Items**: Use camera or gallery to upload donation items
3. **AI Analysis**: Get automatic item description and tags
4. **Match Discovery**: View matched recipients for your donations
5. **Communication**: Chat with recipients to coordinate donation

### For Recipients
1. **Registration**: Choose "I need Help" and select NGO or Individual
2. **Post Needs**: Create detailed need posts with urgency levels
3. **Browse Matches**: View donations that match your needs
4. **Accept Matches**: Accept suitable donations and coordinate pickup

## 🎯 Sample Data

The app includes hardcoded sample data for demonstration:

### Sample NGOs
- Akshaya Patra Foundation (Mumbai)
- Smile Foundation (Delhi)
- Goonj NGO (Chennai)

### Sample Individuals
- Priya Sharma (Mumbai) - Single mother needing winter clothing
- Rajesh Kumar (Delhi) - Elderly person needing food and medicines
- Sunita Devi (Chennai) - Widow needing children's items

### Sample Needs
- Winter blankets for children (Urgent)
- Educational toys for learning center (Medium)
- Winter coats for children (High)
- Food supplies and medicines (Urgent)
- School supplies for rural children (Medium)

## 🔧 Technical Implementation

### AI Integration
- **Gemini API**: Computer vision for image analysis
- **Smart Tagging**: Automatic generation of relevant tags
- **Matching Algorithm**: Multi-factor scoring based on:
  - Location proximity (30% weight)
  - Tag similarity (40% weight)
  - Urgency level (20% weight)
  - Quantity matching (10% weight)

### UI/UX Features
- **Material Design 3**: Modern, accessible interface
- **Responsive Layout**: Works on phones and tablets
- **Intuitive Navigation**: Clear user flows for different user types
- **Visual Feedback**: Status indicators, progress bars, and animations

### State Management
- **Provider Pattern**: Efficient state management across screens
- **Reactive UI**: Automatic updates when data changes
- **Persistent State**: User sessions and data persistence

## 🚧 Future Enhancements

### Planned Features
- **Firebase Integration**: Real-time chat and push notifications
- **Cloud Storage**: Image upload to Firebase Storage
- **Advanced Matching**: Machine learning-based recommendation engine
- **Payment Integration**: Donation tracking and verification
- **Social Features**: User reviews and feedback system
- **Admin Dashboard**: Management interface for NGOs

### Technical Improvements
- **Offline Support**: Local data caching and sync
- **Performance Optimization**: Image compression and lazy loading
- **Security**: User authentication and data encryption
- **Analytics**: User behavior tracking and insights

## 📋 Project Structure

```
lib/
├── models/                 # Data models
│   ├── user.dart
│   ├── donation.dart
│   ├── need.dart
│   ├── match.dart
│   └── chat_message.dart
├── services/               # Business logic
│   ├── gemini_service.dart
│   ├── matching_service.dart
│   └── sample_data_service.dart
├── providers/              # State management
│   └── app_state.dart
├── screens/                # UI screens
│   ├── welcome_screen.dart
│   ├── auth/               # Authentication screens
│   ├── donor/              # Donor-specific screens
│   └── recipient/          # Recipient-specific screens
└── main.dart              # App entry point
```

## 🤝 Contributing

This is a prototype project for demonstration purposes. For production use, consider:

1. **Security**: Implement proper authentication and authorization
2. **Scalability**: Use cloud databases and microservices architecture
3. **Testing**: Add comprehensive unit and integration tests
4. **Documentation**: Expand API documentation and user guides
5. **Accessibility**: Ensure WCAG compliance for all users

## 📄 License

This project is created for educational and demonstration purposes. Please ensure you have proper licenses for any third-party services used in production.

## 🙏 Acknowledgments

- **Google Gemini API** for AI-powered image analysis
- **Flutter Team** for the excellent framework
- **Material Design** for UI components and guidelines
- **Indian NGOs** for inspiration and real-world use cases

---

**Note**: This is a prototype application. For production deployment, additional security, scalability, and compliance measures would be required.