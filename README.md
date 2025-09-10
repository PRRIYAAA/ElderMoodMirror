# Elder Mood Mirror (EMM)  

Elder Mood Mirror (EMM) is an AI-powered elder-care mobile application designed to monitor, analyze, and improve the emotional well-being of elderly individuals.  
The app integrates **daily surveys, facial mood detection, motivational quotes, and AI-generated insights** to provide emotional support and timely interventions.  

---

## 🚀 Features  
- 👤 **Elder Profile Setup** – Collects user details (name, age, gender, medical conditions).  
- 📋 **Daily Mood Survey** – Personalized questions based on user profile.  
- 📷 **Facial Expression Analysis** – Auto-detects mood using camera.  
- 💬 **Motivational Quotes** – Provides positive reinforcement.  
- 🤖 **AI-Powered Insights (Planned)** – Weekly/monthly reports, recommendations, and caregiver alerts.  
- 🔔 **Reminders & Alerts (Planned)** – Daily medication reminders, mood alerts.  

---

## 📱 App Demo  

### 🎥 Video Walkthrough  
![App Demo](demo.gif)  
*(Replace `demo.gif` with your converted GIF from local video)*  

---

## 🖼️ Screenshots  

| User Info Screen | Daily Survey | 
|------------------|--------------|
| ![User Info](Screenshot%202025-09-09%20235644.png) | ![Survey](Screenshot%202025-09-10%20000058.png) |

---

## Figma 
https://icon-curve-05584395.figma.site

## 🏗️ System Architecture  

![System Architecture](WhatsApp%20Image%202025-09-10%20at%2020.54.41_2b8d6c60.jpg)  

**Workflow:**  
1. Elder interacts with mobile app (Flutter).  
2. Survey & mood inputs sent to backend (Flask API).  
3. AI model analyzes inputs and generates mood insights.  
4. Insights & recommendations returned to the app.  
5. Notifications/reminders handled via Firebase (planned).  

---

## ⚙️ Tech Stack  

### Frontend  
- **Framework:** Flutter  
- **Language:** Dart  

### Backend  
- **Framework:** Flask (Python)  
- **Database:** JSON (current), SQLite / NoSQL (planned)  
- **AI Models:** OpenCV + Pretrained Models + OpenAI API (planned)  

### Notifications (Planned)  
- Firebase Cloud Messaging (FCM)  

---

## 🛠️ Installation  

### Clone Repository  
```bash
git clone https://github.com/<yourusername>/ElderMoodMirror.git
cd ElderMoodMirror

1. Flutter (Frontend) Setup
cd frontend
flutter pub get
flutter run

```

## 📊 Future Enhancements

- AI-driven personalized recommendations.
- Caregiver monitoring dashboard.
- Voice-based interactions for accessibility.
- IoT/wearable integration for vitals.


## MIT License

This project is licensed under the [MIT License](LICENSE).


