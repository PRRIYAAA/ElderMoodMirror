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
![Figma Link](https://icon-curve-05584395.figma.site)

## 🏗️ System Architecture  

![System Architecture](assets/images/architecture.png)  

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

Copyright (c) 2025 Priyadharshini K

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


