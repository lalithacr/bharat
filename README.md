# 🇮🇳 Bharat Problem Solver AI

An AI-powered civic issue reporting platform that empowers citizens to report, track, and resolve local infrastructure problems — built with Flutter, FastAPI, and YOLO-based computer vision.

---

## 🚀 Features

- 📸 **AI Image Analysis** — YOLO-powered auto-detection of civic issues (potholes, garbage, flooding, broken lights, etc.)
- 🗺️ **Geo-tagged Reports** — GPS-based issue reporting with nearby issue discovery
- 🎫 **Ticket System** — Auto-generated ticket numbers (BPS-XXXXXXXX) for every report
- 🏆 **Reward Points** — Citizens earn points for reporting and resolved issues
- 📊 **Dashboard** — Real-time stats: Total, Resolved, and Pending reports
- 🌐 **Multilingual** — Indian language support
- 👮 **Authority Panel** — Status updates by verified authorities
- 📱 **Cross-platform** — Flutter Web + Android + iOS

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Web + Mobile) |
| Backend | FastAPI (Python) |
| AI/ML | YOLO (object detection), Claude AI |
| Database | PostgreSQL + SQLAlchemy (async) |
| Auth | JWT Token-based |
| Storage | S3-compatible image storage |

---

## 📁 Project Structure

```
bharat_backend2/
├── backend/
│   ├── app/
│   │   ├── core/          # Database, security, config
│   │   ├── models/        # SQLAlchemy models (User, Report)
│   │   ├── routers/       # API endpoints (auth, reports, analytics)
│   │   ├── schemas/       # Pydantic schemas
│   │   └── services/      # AI service, storage, notifications
│   ├── main.py
│   └── requirements.txt
└── frontend/
    └── lib/
        ├── screens/       # Dashboard, Login
        ├── map/           # Nearby issues map
        ├── report/        # Report submission
        ├── profile/       # Leaderboard, user profile
        ├── core/          # API service
        └── data/models/   # Report, User models
```

---

## ⚙️ Setup & Installation

### Backend

```bash
cd backend
python -m venv venv
venv\Scripts\activate        # Windows
# source venv/bin/activate   # Mac/Linux

pip install -r requirements.txt

# Create .env file with your config
cp .env.example .env

uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend

```bash
cd frontend
flutter pub get
flutter run -d edge          # Web (Microsoft Edge)
# flutter run                # Android/iOS
```

---

## 🔌 API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/v1/auth/login` | User login |
| POST | `/api/v1/reports` | Submit a report |
| GET | `/api/v1/reports/my` | Get my reports |
| GET | `/api/v1/reports/nearby` | Get nearby reports |
| POST | `/api/v1/reports/analyze-image` | AI image analysis |
| GET | `/api/v1/analytics/summary` | Dashboard stats |
| GET | `/api/v1/analytics/leaderboard` | Top reporters |

---

## 🤖 AI Pipeline

When a citizen uploads a photo with a report:

1. **YOLO Detection** — Identifies the issue type in the image
2. **Auto Classification** — Sets `issue_type` and `severity` automatically
3. **Confidence Scoring** — Rates detection confidence (0–1)
4. **AI Summary** — Generates a human-readable description
5. **Reward Points** — Awarded on submission and resolution

---

## 📸 Screenshots

> Dashboard · Report Issue · Nearby Map · Profile & Leaderboard

---

## 👥 Team

Built for **Smart India Hackathon / Civic Tech Track**

---

## 📄 License

MIT License — feel free to use and build on this project.
