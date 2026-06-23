# 🌊 Tide — AI Powered Task Manager

Tide is a smart productivity app built using Flutter that helps users manage daily tasks efficiently with the help of AI. It automatically categorizes tasks, supports smart search, and provides a clean, modern task management experience.

---

## 🚀 Features

### 🧠 AI Task Categorization
- Automatically categorizes tasks into:
  - Work
  - Personal
  - Study
  - Health
  - Finance
- Uses Google Gemini API for intelligent classification

---

### 🔍 Smart Task Search
- Search tasks using keyword filtering
- AI-powered search support (semantic understanding via Gemini API integration)
- Helps quickly find relevant tasks even with vague input

---

### 📝 Task Management
- Add new tasks with title, priority, and category
- Mark tasks as completed
- Delete unwanted tasks
- Persistent storage using SharedPreferences

---

### 🎨 Modern UI
- Clean dark-themed UI
- Color-coded categories
- Priority indicators (High / Medium / Low)
- Smooth task cards with visual hierarchy

---

### 🔐 Authentication
- Firebase Authentication integrated
- Secure login/logout system

---

## 🛠️ Tech Stack

- Flutter (UI framework)
- Dart (Programming language)
- Firebase Authentication
- Google Gemini API (AI features)
- SharedPreferences (Local storage)

---

## 🧠 AI Features

Tide uses Google Gemini API to:
- Categorize tasks automatically
- Enhance task search results
- Provide intelligent task understanding

Example prompt:
> "Categorize this task into Work, Personal, Study, Health, Finance"

---

## 📂 Project Structure

lib/
├── main.dart
├── auth_screen.dart
├── gemini_service.dart
├── firebase_options.dart



🔮 Future Improvements
AI Chat Assistant for tasks
Weekly productivity summary
Smart reminders & notifications
Cloud sync with Firebase Firestore
Voice input for tasks
👨‍💻 Author

Built as a learning project to explore:

Flutter development
Firebase integration
AI API integration using Google Gemini
