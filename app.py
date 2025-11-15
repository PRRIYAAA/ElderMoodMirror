from flask import Flask, request, jsonify
import os, smtplib, json
import pandas as pd
import matplotlib.pyplot as plt
from collections import Counter
from sklearn.preprocessing import LabelEncoder
from sklearn.cluster import KMeans
import seaborn as sns
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication
from openai import OpenAI
from typing import Dict, List, Any

app = Flask(__name__)

# --- SECURE CONFIGURATION: Load sensitive data from Environment Variables ONLY ---
# Before deploying, ensure these environment variables are set in your server environment 
# (e.g., shell export, .env file, or hosting platform settings).
EMAIL_SENDER = os.environ.get("EMAIL_SENDER")
EMAIL_PASSWORD = os.environ.get("EMAIL_PASSWORD")
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY")

# Conditional initialization of the OpenAI client
client = OpenAI(api_key=OPENAI_API_KEY) if OPENAI_API_KEY else None


def send_email(to_email: str, subject: str, html_body: str, attachments: List[str]):
    # Check if email credentials are available
    if not EMAIL_SENDER or not EMAIL_PASSWORD:
        print("SECURITY ALERT: Email credentials not found in environment variables. Email sending skipped.")
        return

    msg = MIMEMultipart()
    msg["From"] = EMAIL_SENDER
    msg["To"] = to_email
    msg["Subject"] = subject
    msg.attach(MIMEText(html_body, "html"))
    for file_path in attachments:
        with open(file_path, "rb") as f:
            part = MIMEApplication(f.read(), Name=os.path.basename(file_path))
            part["Content-Disposition"] = f'attachment; filename="{os.path.basename(file_path)}"'
            msg.attach(part)
    with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
        server.login(EMAIL_SENDER, EMAIL_PASSWORD)
        server.send_message(msg)

def generate_summary_with_ai(username: str, mood_counts: Dict[str, int], dominant_mood: str, suggestions: List[str]) -> str:
    """Generate a summarized, empathetic mood report using Generative AI."""
    try:
        if not client:
            return "AI summary generation skipped because the OpenAI API key is missing from environment variables."
        
        prompt = f"""
        You are a compassionate AI health assistant summarizing mood data for an elder care report.

        Elder's Name: {username}
        Mood distribution: {json.dumps(mood_counts, indent=2)}
        Dominant mood: {dominant_mood}
        Observations and suggestions: {json.dumps(suggestions, indent=2)}

        Please write a warm, concise summary (in about 100-150 words) that:
        - Summarizes how the elder has been feeling.
        - Highlights the dominant mood.
        - Gives 2–3 actionable recommendations for their caregiver based on the observations.
        - Keeps the tone supportive and easy to understand.
        """
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "You are an empathetic elder-care assistant."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=250,
            temperature=0.8
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        return f"AI summary unavailable: {str(e)}"

@app.route("/analyze", methods=["POST"])
def analyze():
    try:
        data = request.get_json()
        if not data:
            return jsonify({"status": "error", "message": "No JSON body"}), 400

        survey_logs = data.get("daily_logs", [])
        camera_logs = data.get("camera_moods", [])
        all_logs = survey_logs + camera_logs
        if not all_logs:
            return jsonify({"status": "error", "message": "No mood data"}), 400

        email = data.get("guardian_email", "")
        clinic_email = data.get("clinic_email", "")
        username = data.get("user_name", "Your loved one")

        df_all = pd.DataFrame(all_logs)
        if "mood" not in df_all.columns:
            return jsonify({"status": "error", "message": "Missing mood column"}), 400

        # Mood statistics (all logs)
        mood_counts = Counter(df_all["mood"])
        total_moods = sum(mood_counts.values())
        percentages = {m: (c / total_moods) * 100 for m, c in mood_counts.items()}
        dominant_mood = max(mood_counts, key=mood_counts.get)
        
        # Mood-specific coloring for the UI
        mood_color = {
            'Happy': '#4CAF50',  
            'Calm': '#2196F3',   
            'Anxious': '#FF9800',
            'Neutral': '#9E9E9E',
            'Sad': '#F44336'     
        }.get(dominant_mood, '#607D8B') 


        # Prepare survey-only dataframe for clustering (assumed to work based on your prior implementation)
        feature_cols = ["sleep", "water", "exercise", "pain", "energy", "mood"]
        df_survey = pd.DataFrame(survey_logs)
        do_cluster = all(col in df_survey.columns for col in feature_cols)

        suggestions = []
        if do_cluster and not df_survey.empty:
            encoders = {}
            for col in df_survey.columns:
                le = LabelEncoder()
                df_survey[col] = le.fit_transform(df_survey[col].astype(str))
                encoders[col] = le

            df_feat = df_survey.drop(columns=["mood"])
            df_survey["cluster"] = KMeans(n_clusters=2, random_state=42, n_init=10).fit_predict(df_feat)
            df_survey["mood_lbl"] = df_survey["mood"]
            cluster_mean = df_survey.groupby("cluster").mean()
            bad, good = sorted(cluster_mean.index, key=lambda i: cluster_mean.loc[i]["mood_lbl"])

            for col in df_feat.columns:
                bad_v = cluster_mean.loc[bad].get(col)
                good_v = cluster_mean.loc[good].get(col)
                if bad_v is not None and good_v is not None and abs(good_v - bad_v) >= 0.5:
                    from_v = encoders[col].inverse_transform([int(round(bad_v))])[0]
                    to_v = encoders[col].inverse_transform([int(round(good_v))])[0]
                    msg_map = {
                        "sleep": f"They feel better on **{to_v.lower()}** sleep days. Focus on sleep consistency.",
                        "water": "Staying hydrated correlates with emotional balance. Encourage consistent water intake.",
                        "exercise": "Regular exercise improves mood. Schedule a short, gentle activity daily.",
                        "pain": "Less pain correlates with brighter mood. Ensure pain is effectively managed.",
                        "energy": "Higher energy accompanies positive mood. Identify sources of energy dips.",
                    }
                    suggestions.append(msg_map.get(col, f"Improving **{col}** may help."))
        if not suggestions:
            suggestions.append("No immediate correlation factors detected this week. Continue with current supportive routines.")

        # --- Chart Generation ---
        os.makedirs("output", exist_ok=True)
        fig, ax = plt.subplots(figsize=(9, 5))
        colors = sns.color_palette("viridis", len(mood_counts))
        bars = ax.bar(mood_counts.keys(), mood_counts.values(), color=colors, edgecolor="black")
        
        dominant_idx = list(mood_counts.keys()).index(dominant_mood)
        bars[dominant_idx].set_color(mood_color)

        for idx, bar in enumerate(bars):
            ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 0.3,
                    f"{percentages[list(mood_counts.keys())[idx]]:.1f}%",
                    ha="center", va="bottom", fontsize=11, fontweight="bold")
        ax.set_title("🧠 Mood Trend", fontsize=18, color="teal")
        ax.set_ylabel("Count")
        ax.set_ylim(0, max(mood_counts.values()) + 2)
        sns.despine()
        ax.grid(axis="y", linestyle="--", alpha=0.3)
        chart_path = "output/mood_chart.png"
        plt.tight_layout()
        plt.savefig(chart_path, dpi=300)
        plt.close()
        
        # --- AI Summary Generation ---
        ai_summary = generate_summary_with_ai(username, mood_counts, dominant_mood, suggestions)


        # -----------------------------------------------------
        # --- ENHANCED AI REPORT HTML BODY GENERATION ---
        # -----------------------------------------------------

        # 1. Generate the Mood Breakdown List (List with colors)
        summary_html = ""
        for m in sorted(mood_counts.keys(), key=lambda k: percentages[k], reverse=True):
            p = percentages[m]
            c = mood_counts[m]
            item_color_style = mood_color if m == dominant_mood else '#000000'
            
            summary_html += f"""
            <li style="color: {item_color_style}; font-weight: {('bold' if m == dominant_mood else 'normal')}; padding: 3px 0;">
                <span style="display: inline-block; width: 100px;">{m}:</span> 
                {c} times 
                <span style="float: right; font-weight: bold;">({p:.1f}%)</span>
            </li>
            """

        # 2. Generate the Actionable Suggestions (Card/Box Style)
        sug_html = ""
        for s in suggestions:
            s_html = s.replace("**", "<b>").replace("**", "</b>")
            sug_html += f"""
            <div style="
                background-color: #F0F8FF; 
                border-left: 5px solid #00796b; 
                padding: 12px;
                margin-bottom: 10px;
                border-radius: 8px;
                box-shadow: 0 1px 3px rgba(0,0,0,0.1);
                font-size: 15px;
                line-height: 1.4;
            ">
                <span style="font-weight: bold; color: #00796b;">&#9889; Data Insight:</span><br>
                {s_html}
            </div>
            """

        email_body = f"""
        <html><body style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; padding: 20px;">
            <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.15);">
                
                <div style="background-color: #00796b; padding: 20px; color: white;">
                    <h2 style="margin: 0; font-size: 24px;">📊 Weekly Mood Report for {username}</h2>
                </div>

                <div style="padding: 20px;">
                    
                    <h3 style="color: #00796b; border-bottom: 2px solid #e0f2f1; padding-bottom: 5px; margin-top: 0;">🤖 AI Report Summary</h3>
                    <div style="
                        background-color: #e0f2f1; 
                        padding: 15px;
                        border-radius: 8px;
                        margin-bottom: 20px;
                        font-size: 16px;
                        color: #004d40; 
                    ">
                        {ai_summary}
                    </div>

                    <div style="background-color: {mood_color}; color: white; padding: 15px; border-radius: 8px; text-align: center; margin-bottom: 20px;">
                        <span style="font-size: 14px; display: block;">🌟 Dominant Mood Detected</span>
                        <b style="font-size: 28px; display: block;">{dominant_mood}</b>
                        <span style="font-size: 14px;">(Accounted for {percentages.get(dominant_mood, 0.0):.1f}% of all entries)</span>
                    </div>

                    <h3 style="color: #00796b; border-bottom: 2px solid #e0f2f1; padding-bottom: 5px;">🧠 Mood Distribution</h3>
                    <ul style="list-style: none; padding: 0; margin: 0;">{summary_html}</ul>

                    <h3 style="color: #00796b; border-bottom: 2px solid #e0f2f1; padding: 20px 0 5px 0;">💡 Correlated Insights & Recommendations</h3>
                    {sug_html}
                    
                    <p style="text-align: center; margin-top: 30px; font-style: italic; color: #666;">
                        See attached chart for a visual summary of the distribution.
                    </p>
                </div>

                <div style="background-color: #f0f0f0; padding: 15px; text-align: center; font-size: 12px; color: #777; border-top: 1px solid #e0e0e0;">
                    &mdash; Elder Mood Mirror &mdash;
                </div>
            </div>
        </body></html>
        """

        if email:
            send_email(email, f"AI-Driven Well-being Report for {username} 📊", email_body, [chart_path])
        if clinic_email and "@" in clinic_email:
            send_email(clinic_email, f"[Clinic] AI Report – {username}", email_body, [chart_path])

        return jsonify({"status": "success", "dominant_mood": dominant_mood,
                        "suggestions": suggestions,"ai_summary":ai_summary,"mood_chart": "/output/mood_chart.png"}), 200

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
