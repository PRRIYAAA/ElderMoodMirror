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

app = Flask(__name__)

EMAIL_SENDER = "abishaeunice123@gmail.com"
EMAIL_PASSWORD = "wcoe ldgk bwam ykem"  # App password

def send_email(to_email, subject, html_body, attachments):
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

        # Prepare survey-only dataframe for clustering (requires full features)
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
                bad_v = cluster_mean.loc[bad][col]
                good_v = cluster_mean.loc[good][col]
                if abs(good_v - bad_v) >= 0.5:
                    from_v = encoders[col].inverse_transform([int(round(bad_v))])[0]
                    to_v = encoders[col].inverse_transform([int(round(good_v))])[0]
                    msg_map = {
                        "sleep": f"• They feel better on <b>{to_v.lower()}</b> sleep days.",
                        "water": "• Staying hydrated helps emotional balance.",
                        "exercise": "• Regular exercise improves mood.",
                        "pain": "• Less pain correlates with brighter mood.",
                        "energy": "• Higher energy accompanies positive mood."
                    }
                    suggestions.append(msg_map.get(col, f"• Improving <b>{col}</b> may help."))
        if not suggestions:
            suggestions.append("• They are maintaining good habits! Keep encouraging them.")

        # Mood chart
        os.makedirs("output", exist_ok=True)
        fig, ax = plt.subplots(figsize=(9, 5))
        colors = sns.color_palette("viridis", len(mood_counts))
        bars = ax.bar(mood_counts.keys(), mood_counts.values(), color=colors, edgecolor="black")
        bars[list(mood_counts.keys()).index(dominant_mood)].set_color("#ff8c42")
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

        # Email body
        summary_html = "".join(f"<li>{m}: {mood_counts[m]} ({percentages[m]:.1f}%)</li>" for m in mood_counts)
        sug_html = "".join(f"<li>{s}</li>" for s in suggestions)
        email_body = f"""
        <html><body style="font-family: Arial;">
            <h2 style="color: teal;">🧓 Weekly Mood Report for {username}</h2>
            <p>Here's how your loved one felt recently:</p>
            <h3>🧠 Mood Breakdown:</h3><ul>{summary_html}</ul>
            <p><b>🌟 Dominant Mood:</b> {dominant_mood}</p>
            <h3>💡 Suggestions:</h3><ul>{sug_html}</ul>
            <p>See attached chart for a visual summary.</p>
            <p><i>— Elder Mood Mirror</i></p>
        </body></html>
        """

        if email:
            send_email(email, f"Mood Report for {username} 📊", email_body, [chart_path])
        if clinic_email and "@" in clinic_email:
            send_email(clinic_email, f"[Clinic] Mood Report – {username}", email_body, [chart_path])

        return jsonify({"status": "success", "dominant_mood": dominant_mood,
                        "suggestions": suggestions, "mood_chart": "/output/mood_chart.png"}), 200

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
