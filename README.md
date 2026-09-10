# BandUp IELTS PrepPro

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/NestJS-E0234E?style=for-the-badge&logo=nestjs&logoColor=white" alt="NestJS" />
  <img src="https://img.shields.io/badge/Next.js-000000?style=for-the-badge&logo=nextdotjs&logoColor=white" alt="Next.js" />
  <img src="https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL" />
  <img src="https://img.shields.io/badge/Prisma-2D3748?style=for-the-badge&logo=prisma&logoColor=white" alt="Prisma" />
  <img src="https://img.shields.io/badge/Groq_Cloud-F55036?style=for-the-badge&logo=fastapi&logoColor=white" alt="Groq" />
  <img src="https://img.shields.io/badge/Google_Gemini-8E75C2?style=for-the-badge&logo=google&logoColor=white" alt="Gemini" />
</p>

BandUp IELTS is a production-ready, premium IELTS preparation platform helping students prepare for both **IELTS Academic** and **IELTS General Training** exams. It features automated AI grading across all 4 skills (Speaking, Reading, Writing, Listening), timed mock exams, study streak trackers, personalized tutor feedback overrides, and subscription plans.

---

## 🏗️ Technical Architecture

```mermaid
flowchart TD
    subgraph Clients["Frontend Clients"]
        A["Flutter Mobile App (iOS / Android)"]
        B["Next.js Web (Student Portal)"]
        C["Next.js Web (Admin & Tutor Panel)"]
    end

    subgraph Core["Backend API & Services"]
        D["NestJS API Gateway & Controller"]
        E["Prisma ORM & Business Logic"]
        D --> E
    end

    subgraph Ecosystem["Data & AI Ecosystem"]
        F[("PostgreSQL Database")]
        G["AI Providers (Groq / Gemini / OpenAI)"]
    end

    Clients -->|"HTTPS / REST API"| D
    E -->|"Prisma ORM Queries"| F
    E -->|"Multi-Key LLM Router"| G
```

---

## 📁 Project Structure

*   `/backend`: NestJS Server with Prisma and PostgreSQL.
*   `/admin`: Next.js Admin & Tutor dashboard.
*   `/website`: Next.js Marketing Landing page & Student dashboard.
*   `/mobile_app`: Flutter native application (Android & iOS).
*   `/docs`: Architecture diagrams and database schemas.

---

## 🚀 Getting Started

### 1. Database Setup
1. Ensure a local PostgreSQL server is running.
2. Edit `/backend/.env` to configure your connection string:
   ```env
   DATABASE_URL="postgresql://postgres:password@localhost:5432/bandup_ielts?schema=public"
   ```
3. Run migrations and seed database:
   ```bash
   cd backend
   npx prisma migrate dev --name init
   npm run seed
   ```

### 2. Run API Server (NestJS)
```bash
cd backend
npm install
npm run start:dev
```
The server will start at `http://localhost:5000/api`.

### 3. Run Web Dashboard (Next.js Student / Landing)
```bash
cd website
npm install
npm run dev
```
Open `http://localhost:3000` to view the landing website.

### 4. Run Admin & Tutor Panel (Next.js)
```bash
cd admin
npm install
npm run dev
```
Open `http://localhost:3001` to view the administration panel.

### 5. Run Mobile Application (Flutter)
Ensure you have the Flutter SDK installed and emulator running:
```bash
cd mobile_app
flutter pub get
flutter run
```

---

## 🔑 Default Test Accounts (Seeded)

*   **Super Admin**: `admin@bandup.com` / `admin123`
*   **Tutor / Examiner**: `tutor@bandup.com` / `tutor123`
*   **Student**: `student@bandup.com` / `student123`

---

## 🌟 Key Platform Features & Updates

*   **🇳🇬 Naira Currency Transition**: 100% localization from USD ($) to Nigerian Naira (₦) across landing pages, backend database models, payment records, and referral calculations.
*   **⚡ Groq Cloud Integration (`console.groq.com`)**: Integrated Groq API using the ultra-fast Llama 3.3 70B Versatile model for speaking and writing evaluations.
*   **📅 Daily Question Auto-Scheduler**: Background task that automatically seeds 20 questions daily (balanced across Listening, Reading, Writing, and Speaking) up to a maximum database limit of 1,000 questions.
*   **📊 Student Limits & Usage Tracker**: Dynamic progress bars on the student dashboard displaying daily question usage and remaining mock tests.
*   **💳 Admin Subscription Upgrader**: Interactive plan selectors directly within the Admin Users list to grant, modify, or revoke student subscription privileges in one click.
*   **🎨 Custom App Icon & release APK**: Re-branded native app icons with the custom gold logo and built the final release APK.

---

## 🧠 Smart AI Routing, Fallbacks & Multi-Key Support

To keep the platform's running costs at **₦0** while maintaining 100% online availability, the backend is equipped with a custom **LLM Fallback Router** and **Multi-Key Support**:

*   **Fallback Routing Chain**: The backend can cascade between Google Gemini, Groq Cloud, OpenRouter, and OpenAI. If the active provider fails (e.g., due to free-tier rate limits or key depletion), it automatically retries with the next configured provider.
*   **Multi-Key Loop (Same Provider)**: You can combine multiple API keys from the same provider (created across different Google/Groq accounts) by separating them with commas (e.g., `key_1, key_2, key_3`). The router will loop through each key individually before escalating to the next provider.

```mermaid
flowchart TD
    A["Student Submits Practice Response"] --> B["Load AI Provider Settings & Keys"]
    B --> C["Build Prioritized Candidate Queue"]
    C --> D{"Keys Available in Queue?"}

    D -->|"Yes"| E["Execute Request with Next API Key"]
    D -->|"All Keys Exhausted"| H["Engage Dynamic Local Evaluator"]

    E --> F{"API Response Status"}
    F -->|"200 OK"| G["Return Formatted Evaluation"]
    F -->|"Rate Limit / Error"| K["Log Warning & Advance Queue"]
    K --> D

    H --> G
```

---

## 🔍 Validation Commands

To verify that all components are syntax-error free and build correctly:

*   **Backend**: `cd backend && npx nest build`
*   **Website**: `cd website && npm run build`
*   **Admin**: `cd admin && npm run build`
*   **Mobile App**: `cd mobile_app && flutter analyze --no-pub`

