# 🍳 DishDash - Your Intelligent AI Sous-Chef

DishDash is a modern, feature-rich Flutter application designed to revolutionize the way you cook. It combines the power of **Google Gemini AI** and **Groq Llama 3** to provide a seamless cooking experience, from scanning your pantry to step-by-step voice-guided instructions.

## ✨ Features

- **📸 AI Pantry Scanner**: Snap a photo of your ingredients, and Google Gemini AI will identify them instantly.
- **🤖 AI Chef Chat**: Get creative recipe ideas based on what you have in your kitchen using Groq's high-speed Llama 3 models.
- **🎙️ Voice-Guided Cooking**: A hands-free experience! The AI reads instructions out loud and listens for your voice commands ("Next", "Repeat", "Previous").
- **🍎 Nutrition Logging**: Automatically logs your meals and updates your inventory after cooking.
- **🌍 Multilingual Support**: Fully localized in 15+ languages including English, Hindi, Gujarati, Spanish, French, Korean, and more.
- **🌓 Dynamic Theming**: Beautiful Dark and Light modes.
- **📱 Multi-Platform**: Built for Android, iOS, Web, and Windows.

## 🚀 Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **Backend**: Firebase (Auth, Firestore, Storage, Realtime Database)
- **AI Models**: 
  - Google Gemini 1.5 Flash (Computer Vision)
  - Groq Llama 3.3 70B (Natural Language Processing)
- **State Management**: Provider
- **Local Secrets**: Flutter Dotenv

---

## 🛠️ Setup Instructions

To protect sensitive data, API keys and Firebase configurations are excluded from this repository. Follow these steps to get the project running locally:

### 1. Prerequisites
- Flutter SDK installed
- Firebase CLI installed
- A Groq API Key ([Get it here](https://console.groq.com/))
- A Google AI (Gemini) API Key ([Get it here](https://aistudio.google.com/))

### 2. Clone the Repository
```bash
git clone https://github.com/AZRIEL2004/dishdash.git
cd dishdash
```

### 3. Environment Variables
Create a `.env` file in the root directory and add your API keys:
```env
GEMINI_API_KEY=your_gemini_key_here
GROQ_API_KEY=your_groq_key_here
```

### 4. Firebase Configuration
Initialize Firebase for your own project:
```bash
flutterfire configure
```
This will generate the required `lib/firebase_options.dart` file.

### 5. Install Dependencies & Run
```bash
flutter pub get
flutter run
```

---

## 📂 Project Structure

- `lib/screens/`: All UI screens (Home, AI Chef, Recipe Details, etc.)
- `lib/models/`: Data models for Recipes and Users.
- `lib/theme.dart`: Centralized theme configuration.
- `lib/l10n/`: Localization files for internationalization.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---
Developed with ❤️ by [AZRIEL2004](https://github.com/AZRIEL2004)
