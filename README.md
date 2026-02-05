# CampusX 🎓  
*A centralized platform for college clubs and student communities*

---

## 📌 Project Overview

CampusConnect is a Flutter + Firebase based application that centralizes **college club events, registrations, announcements, and attendance** into one platform.

The goal of this project is to solve the problem of **scattered communication and manual event management** across WhatsApp groups, Google Forms, and spreadsheets.

This project is being built as part of **Kalvium Work Integration** with a long-term vision to scale it into a **real SaaS product** for colleges and student communities.

---

## 🚀 Problem Statement

College clubs and student communities manage events and communication across scattered channels, making coordination frustrating.

**How might we centralize event registrations, announcements, and attendance in one place?**

---

## 💡 Solution

CampusConnect provides:
- A single platform for all club events
- Centralized announcements
- Easy event registration
- Attendance tracking
- Role-based access for students, club admins, and college admins

---

## 🧑‍💻 User Roles

- **Student**
  - View events
  - Register for events
  - Mark attendance
  - Receive announcements

- **Club Admin**
  - Create and manage events
  - Post announcements
  - Track registrations and attendance

- **College Admin (Future Scope)**
  - Monitor all clubs
  - View analytics
  - Manage subscriptions

---

## 🛠️ Tech Stack

### Frontend
- **Flutter** (Android + Web)
- **Dart**

### State Management
- Provider / Riverpod

### Backend & Cloud
- **Firebase Authentication**
- **Cloud Firestore**
- **Firebase Storage**
- **Cloud Functions**

### DevOps
- Git & GitHub
- GitHub Actions (CI/CD – future)
- Firebase Hosting (Web deployment)

---

## 📂 Project Structure (High Level)

```text
campus_connect/
│── lib/              # Flutter application code
│── android/          # Android configuration
│── web/              # Web configuration
│── pubspec.yaml      # Dependencies and assets
│── README.md         # Project documentation
