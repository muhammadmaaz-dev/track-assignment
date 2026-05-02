# 📚 Assignment Tracker — Your Academic Workflow Manager

**Assignment Tracker** is a sleek, dark-themed, and highly responsive task management application built with Flutter. It is designed specifically to help students organize their academic workflow, track deadlines, and maintain a high success rate across all subjects.

Built with a strong focus on **performance**, **precision scheduling**, and **productivity**, Assignment Tracker ensures you never miss a deadline again.

---

## ✨ Features

### 📝 Smart Categorization
- Classify tasks easily into **Assignments, Quizzes, and Projects**.
- Add comprehensive notes and attach relevant files directly to your tasks.

### ⏰ Precision Reminders
- Scheduled local notifications that trigger exactly on time.
- Custom reminder intervals (e.g., 5 mins or 10 mins before the deadline).
- Configured to handle exact background scheduling and bypass battery optimizations.

### 📊 Performance Tracking
- Dedicated **History Screen** to calculate your real-time "Success Rate".
- Automatically archives overdue and completed tasks for easy review.

### 🌗 Theming & UI
- Consistent, modern **Dark Theme** tailored for late-night study sessions.
- Premium readability using the `Nunito` font family.
- Highly responsive layout adapting strictly to all screen sizes and pixel densities.

---

## 📱 Screenshots

<div align="center" style="white-space:nowrap; overflow-x:auto;">
<!-- Akhtar ki tip: Yahan apne asli GitHub image links daal dena jo tune pehle dikhaye the -->
<img src="https://github.com/user-attachments/assets/77e5a4f8-b213-4391-93c9-73b5479828ed" width="180"/>
<img src="https://github.com/user-attachments/assets/97c09b3e-2dfb-499c-b1b7-03be9459bd32" width="180"/>
<img src="https://github.com/user-attachments/assets/ea4856c2-96c1-4065-a5dc-48ee56b73662" width="180"/>
<img src="https://github.com/user-attachments/assets/35ea5181-b73d-4c30-a093-8cc6d0b8c34d" width="180"/>
<img src="https://github.com/user-attachments/assets/cba3b1a2-c45c-4f55-9d48-0a2d471ad163" width="180"/>
<img src="https://github.com/user-attachments/assets/c1d64a09-a940-4ba3-ac69-b224d1de7235" width="180"/>
</div>

---

## 🛠️ Tech Stack

### Core
- **Framework:** Flutter (Dart)
- **State Management:** Provider (`home_tasks_provider`)

### Storage & Notifications
- `sqflite` (Robust offline database for task storage)
- `flutter_local_notifications` (Exact alarm scheduling)
- `timezone` (Accurate time-based triggers)

### UI / UX
- `flutter_screenutil` (For strict, consistent responsive sizing)
- `cupertino_icons`

> The codebase is fully functional and optimized for maximum responsiveness across Android and iOS devices.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Android Studio or VS Code
- Android device or emulator (Ensure `SCHEDULE_EXACT_ALARM` permission is granted)

### Installation
```bash
git clone [https://github.com/muhammadmaaz-dev/track-assignment.git](https://github.com/muhammadmaaz-dev/track-assignment.git)
cd track-assignment
flutter pub get
flutter run
