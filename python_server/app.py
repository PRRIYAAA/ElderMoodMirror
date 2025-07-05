from flask import Flask, request, jsonify
import json
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from collections import Counter
from sklearn.preprocessing import LabelEncoder
from sklearn.cluster import KMeans
import seaborn as sns
import os

app = Flask(__name__)

@app.route('/analyze', methods=['POST'])
def analyze():
    try:
        # Save posted JSON to file
        data = request.get_json()
        if not data or 'daily_logs' not in data:
            return jsonify({"status": "error", "message": "No daily_logs found"}), 400

        logs = data['daily_logs']
        if not logs:
            return jsonify({"status": "error", "message": "Empty daily_logs"}), 400

        # Save JSON file (optional)
        with open("active_inputs.json", "w", encoding='utf-8') as f:
            json.dump(data, f, indent=2)

        # -------------------------------------
        # Start analysis (same as your script)
        # -------------------------------------
        df = pd.DataFrame(logs)
        features = ["sleep", "water", "exercise", "pain", "energy", "mood"]
        df = df[features]

        encoders = {}
        for col in df.columns:
            le = LabelEncoder()
            df[col] = le.fit_transform(df[col])
            encoders[col] = le

        mood_labels = encoders["mood"].inverse_transform(df["mood"])
        mood_counts = Counter(mood_labels)
        total_days = len(mood_labels)
        percentages = {m: (c / total_days) * 100 for m, c in mood_counts.items()}
        dominant_mood = max(mood_counts, key=mood_counts.get)

        df_features = df.drop(columns=["mood"])
        df["cluster"] = KMeans(n_clusters=2, random_state=42).fit_predict(df_features)
        df["mood_label"] = df["mood"]
        cluster_summary = df.groupby("cluster").mean()

        if cluster_summary.loc[0]["mood_label"] < cluster_summary.loc[1]["mood_label"]:
            bad_cluster, good_cluster = 0, 1
        else:
            bad_cluster, good_cluster = 1, 0

        # ---------------- Mood Bar Chart ----------------
        mood_names = list(mood_counts.keys())
        counts = list(mood_counts.values())
        colors = sns.color_palette("viridis", len(mood_counts))

        dominant_index = mood_names.index(dominant_mood)

        fig, ax = plt.subplots(figsize=(9, 5))
        bars = ax.bar(mood_names, counts, color=colors, edgecolor="black", linewidth=1.2)
        bars[dominant_index].set_color("#ff8c42")
        bars[dominant_index].set_edgecolor("black")
        bars[dominant_index].set_linewidth(2)

        for i, bar in enumerate(bars):
            yval = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2, yval + 0.3,
                    f"{percentages[mood_names[i]]:.1f}%",
                    ha='center', va='bottom', fontsize=11, fontweight='bold', color="black")

        ax.set_title("🧠 Mood Trend Over the Week", fontsize=18, color='teal', pad=20)
        ax.set_ylabel("Number of Days", fontsize=12)
        ax.set_ylim(0, max(counts) + 2)
        ax.set_facecolor("white")
        sns.despine()
        ax.grid(axis='y', linestyle='--', alpha=0.3)

        os.makedirs("output", exist_ok=True)
        plt.tight_layout()
        plt.savefig("output/mood_chart.png", dpi=300)
        plt.close()

        # ---------------- Text Summary ----------------
        suggestions = []
        for col in df_features.columns:
            bad_val = cluster_summary.loc[bad_cluster][col]
            good_val = cluster_summary.loc[good_cluster][col]
            if abs(good_val - bad_val) >= 0.5:
                from_val = encoders[col].inverse_transform([int(round(bad_val))])[0]
                to_val = encoders[col].inverse_transform([int(round(good_val))])[0]

                if col == "sleep":
                    suggestions.append(f"• You are more likely to feel better on days you get {to_val.lower()} sleep.")
                elif col == "water":
                    suggestions.append(f"• Drinking water regularly seems to help maintain a better mood.")
                elif col == "exercise":
                    suggestions.append(f"• Physical activity appears to have a positive impact on your mood.")
                elif col == "pain":
                    suggestions.append(f"• Less pain is associated with more stable or improved mood.")
                elif col == "energy":
                    suggestions.append(f"• You tend to feel more positive on days with higher energy levels.")
                else:
                    suggestions.append(f"• Improving '{col}' from '{from_val}' to '{to_val}' may help.")

        if not suggestions:
            suggestions.append("• You're maintaining consistent mood-supporting habits. Keep it up!")

        summary_path = "output/mood_summary_and_ai.txt"
        with open(summary_path, "w", encoding='utf-8') as f:
            f.write("🧠 Mood Summary for the Week\n")
            f.write("===========================\n")
            for mood in mood_counts:
                f.write(f"- {mood}: {mood_counts[mood]} days ({percentages[mood]:.1f}%)\n")
            f.write(f"\n🌟 Dominant Mood: {dominant_mood}\n\n")
            f.write("💡 AI-Based Mood Insights\n")
            f.write("===========================\n")
            for line in suggestions:
                f.write(line + "\n")

        return jsonify({
            "status": "success",
            "dominant_mood": dominant_mood,
            "suggestions": suggestions,
            "mood_chart": "/output/mood_chart.png",
            "summary_text": "/output/mood_summary_and_ai.txt"
        })

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)