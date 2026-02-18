# Apartment Building Manager System 🏢

A smart management system for apartment buildings, digitizing operations and resident management for better efficiency and professionalism.

## 🌟 Overview
**Apartment Building Manager System** is a comprehensive solution designed for both building management boards and residents. The project focuses on optimizing manual processes, centralizing information, and enhancing transparency in building operations.

## 🚀 Key Features
- **Resident Management:** Maintain profiles, contact information, and demographic records.
- **Apartment Management:** Track apartment status (occupied, vacant, under maintenance).
- **Service & Billing:** Automated calculation and tracking of service fees (electricity, water, security, parking).
- **Notification System:** Quickly blast announcements from management to all residents.
- **Authentication Flow:** Secure login, registration with apartment verification, and password recovery.

## 🛠 Technology Stack
- **Backend:** Java 21, Spring Boot 3.4
- **Frontend:** Flutter, Provider (State Management)
- **Database:** MySQL
- **Mailing:** MailDev (Development)
- **Infrastructure:** Docker & Docker Compose

## 📋 Installation & Setup

### 1. Clone the Repository
Open your terminal and run:
```bash
git clone https://github.com/nguyendangviet12022004/apartment-building-manager-system.git
cd apartment-building-manager-system
```

### 2. Environment Setup (Docker)
The project uses Docker to manage infrastructure services. These services are configured to **restart automatically**, so they will stay running once started.

#### Scenario A: Developing the Backend
If you are writing Java code and running the backend locally, you only need the Database and Mail server:
```bash
docker-compose up -d db maildev
```
*   **Database:** Access via `localhost:3000`
*   **MailDev:** Access Dashboard via `http://localhost:1080`

#### Scenario B: Developing the Frontend
If you are focusing on the Flutter app, you should run all services (including the Backend image):
```bash
docker-compose up -d
```
*   **API Endpoint:** `http://localhost:8080`

### 3. Running the Applications

#### Backend (Local Execution)
Ensure you have JDK 21 and Maven installed.
```bash
cd backend
mvn spring-boot:run
```

#### Frontend (Flutter)
Ensure you have Flutter SDK installed.
```bash
cd frontend
flutter pub get
flutter run
```

## ⚙️ Configuration Notes
- **Lombok & Java 21:** The project requires Lombok 1.18.34+ for compatibility with JDK 21. 
- **Database Port:** Note that the MySQL container maps port `3306` to `3000` on your host machine to avoid conflicts with local MySQL installations.

---
*Developed by [Nguyễn Đăng Việt](https://github.com/nguyendangviet12022004)*
