# Elder Mood Mirror 

An AI-powered mental wellness companion designed for elderly individuals.  
The app monitors mood through surveys, facial expressions, and voice analysis, then provides personalized recommendations and well-being summaries.

---

## 🎥 Demo Video

![Demo Preview](demo.gif)  
▶️ [Watch full demo video](ElderMoodMirror.mp4)

---

## 🚀 Features
- 📊 Daily & Weekly Mood Reports  
- 😊 Mood detection via camera and surveys  
- 💊 Tablet/medicine intake tracking  
- 🛡️ Emergency alert suggestions  
- 🗣️ Voice-assisted interaction for elderly accessibility  
- 🌐 Multilingual support  

---

## 🛠️ Tech Stack
- **Frontend**: Flutter  
- **Backend**: Shared Preferences  
- **Database**: SQLite / Firebase (Real time) 
- **AI Integration**: OpenAI API for mood summarization & recommendations  

---

## 📥 Installation
1. Clone the repository  
   ```bash
   git clone https://github.com/yourusername/elder-mood-mirror.git
   cd elder-mood-mirror
2. Install Flutter dependencies
   ```
   flutter pub get
3. Run the app on an emulator or connected device
   ```
   flutter run

## 📊 System Architecture
Diagram (Conceptual)

```
                ┌──────────────────────┐
                │        User          │
                │ (Elderly / Caregiver)│
                └─────────┬────────────┘
                          │
                          ▼
              ┌──────────────────────────┐
              │    Flutter Mobile App    │
              │ (Survey UI, Camera, Voice│
              │   Inputs, Notifications) │
              └─────────┬────────────────┘
                        │
        ┌───────────────┼────────────────┐
        │                               │
        ▼                               ▼
┌───────────────────┐          ┌─────────────────────┐
│ Local Database    │          │ Cloud Database       │
│                   │          │ (Firebase / Firestore│
│ Stores user data  │          │ Remote sync, reports │
└───────────────────┘          └─────────────────────┘
                        │
                        ▼
             ┌─────────────────────┐
             │     Backend/API     │
             │ (Node.js / Flask)   │
             │ Data aggregation,   │
             │ caregiver dashboard │
             └─────────┬──────────┘
                       │
                       ▼
           ┌─────────────────────────┐
           │   AI Services (OpenAI)  │
           │ - Mood summarization    │
           │ - Recommendation engine │
           └─────────────────────────┘

