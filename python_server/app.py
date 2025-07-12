from flask import Flask, request, jsonify
import json, os, smtplib
import pandas as pd
import matplotlib.pyplot as plt
from collections import Counter
from sklearn.preprocessing import LabelEncoder
from sklearn.cluster import KMeans
import seaborn as sns
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication

app = Flask(__name__)

EMAIL_SENDER = "abishaeunice123@gmail.com"
EMAIL_PASSWORD = "wcoe ldgk bwam ykem"  # App Password

def send_email(to_email, subject, html_body, attachments):
    msg = MIMEMultipart()
    msg['From'] = EMAIL_SENDER
    msg['To'] = to_email
    msg['Subject'] = subject
    msg.attach(MIMEText(html_body, 'html'))

    for file_path in attachments:
        with open(file_path, "rb") as f:
            part = MIMEApplication(f.read(), Name=os.path.basename(file_path))
            part['Content-Disposition'] = f'attachment; filename="{os.path.basename(file_path)}"'
            msg.attach(part)

    with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
        server.login(EMAIL_SENDER, EMAIL_PASSWORD)
        server.send_message(msg)

@app.route('/analyze', methods=['POST'])
def analyze():
    try:
        data = request.get_json()
        if not data or 'daily_logs' not in data:
            return jsonify({"status": "error", "message": "No daily_logs found"}), 400

        survey_logs = data['daily_logs']
        camera_logs = data.get('camera_moods', [])
        all_logs = survey_logs + camera_logs

        email = data.get('guardian_email', None)
        clinic_email = data.get('clinic_email', None)
        username = data.get('user_name', 'Your loved one')

        if not all_logs:
            return jsonify({"status": "error", "message": "No mood data received"}), 400

        df = pd.DataFrame(all_logs)
        features = ["sleep", "water", "exercise", "pain", "energy", "mood"]
        if not all(col in df.columns for col in features):
            return jsonify({"status": "error", "message": "Missing features in some entries"}), 400

        encoders = {}
        for col in df.columns:
            le = LabelEncoder()
            df[col] = le.fit_transform(df[col].astype(str))
            encoders[col] = le

        mood_labels = encoders["mood"].inverse_transform(df["mood"])
        mood_counts = Counter(mood_labels)
        total_days = len(mood_labels)
        percentages = {m: (c / total_days) * 100 for m, c in mood_counts.items()}
        dominant_mood = max(mood_counts, key=mood_counts.get)

        # KMeans clustering
        df_features = df.drop(columns=["mood"])
        df["cluster"] = KMeans(n_clusters=2, random_state=42, n_init=10).fit_predict(df_features)
        df["mood_label"] = df["mood"]
        cluster_summary = df.groupby("cluster").mean()

        bad_cluster, good_cluster = sorted(
            cluster_summary.index, key=lambda i: cluster_summary.loc[i]["mood_label"]
        )

        # Bar chart
        mood_names = list(mood_counts.keys())
        counts = list(mood_counts.values())
        colors = sns.color_palette("viridis", len(mood_counts))
        dominant_index = mood_names.index(dominant_mood)

        fig, ax = plt.subplots(figsize=(9, 5))
        bars = ax.bar(mood_names, counts, color=colors, edgecolor="black", linewidth=1.2)
        bars[dominant_index].set_color("#ff8c42")

        for i, bar in enumerate(bars):
            yval = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2, yval + 0.3,
                    f"{percentages[mood_names[i]]:.1f}%",
                    ha='center', va='bottom', fontsize=11, fontweight='bold')

        ax.set_title("🧠 Mood Trend (Survey + Camera)", fontsize=18, color='teal')
        ax.set_ylabel("Mood Count")
        ax.set_ylim(0, max(counts) + 2)
        sns.despine()
        ax.grid(axis='y', linestyle='--', alpha=0.3)

        os.makedirs("output", exist_ok=True)
        mood_chart_path = "output/mood_chart.png"
        plt.tight_layout()
        plt.savefig(mood_chart_path, dpi=300)
        plt.close()

        # AI Suggestions
        suggestions = []
        for col in df_features.columns:
            bad_val = cluster_summary.loc[bad_cluster][col]
            good_val = cluster_summary.loc[good_cluster][col]
            if abs(good_val - bad_val) >= 0.5:
                from_val = encoders[col].inverse_transform([int(round(bad_val))])[0]
                to_val = encoders[col].inverse_transform([int(round(good_val))])[0]
                suggestions.append({
                                       "sleep": f"• They feel better on days with <b>{to_val.lower()}</b> sleep.",
                                       "water": "• Staying hydrated supports emotional stability.",
                                       "exercise": "• Physical activity lifts their mood noticeably.",
                                       "pain": "• Less pain is linked to brighter mood patterns.",
                                       "energy": "• High energy days often coincide with positive moods."
                                   }.get(col, f"• Improvement in <b>{col}</b> may help."))

        if not suggestions:
            suggestions.append("• They are maintaining good habits! Keep encouraging them.")

        # Mood summary HTML
        mood_summary_lines = ''.join(
            f"<li>{m}: {mood_counts[m]} times ({percentages[m]:.1f}%)</li>"
            for m in mood_counts
        )
        insights_html = ''.join(f"<li>{s}</li>" for s in suggestions)

        email_body = f"""
        <html><body style="font-family: Arial;">
            <h2 style="color: teal;">🧓 Weekly Mood Report for {username}</h2>
            <p>Here’s how your loved one felt recently:</p>
            <h3>🧠 Mood Breakdown:</h3><ul>{mood_summary_lines}</ul>
            <p><b>🌟 Dominant Mood:</b> {dominant_mood}</p>
            <h3>💡 Suggestions:</h3><ul>{insights_html}</ul>
            <p>See attached chart for a visual summary.</p>
            <p><i>— Elder Mood Mirror</i></p>
        </body></html>
        """

        if email:
            send_email(email, f"Mood Report for {username} 📊", email_body, [mood_chart_path])

        if clinic_email and '@' in clinic_email:
            send_email(clinic_email, f"[Clinic] Mood Report – {username}", email_body, [mood_chart_path])

        return jsonify({
            "status": "success",
            "dominant_mood": dominant_mood,
            "suggestions": suggestions,
            "mood_chart": "/output/mood_chart.png"
        })

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
