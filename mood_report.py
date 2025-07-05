import json
import pandas as pd
import matplotlib.pyplot as plt
from collections import Counter
from sklearn.preprocessing import LabelEncoder
from sklearn.cluster import KMeans
import seaborn as sns

# Load JSON
with open("active_inputs.json", "r") as f:
    data = json.load(f)

daily_logs = data.get("daily_logs", [])
camera_moods = data.get("camera_moods", [])

# Normalize mood values
def normalize(mood):
    return mood.strip().capitalize()

survey_moods = [normalize(entry["mood"]) for entry in daily_logs]
camera_moods_list = [normalize(entry["mood"]) for entry in camera_moods]

# Frequency & % calculations
survey_counts = Counter(survey_moods)
camera_counts = Counter(camera_moods_list)
survey_total = sum(survey_counts.values())
camera_total = sum(camera_counts.values())

survey_percentages = {m: (c / survey_total) * 100 for m, c in survey_counts.items()}
camera_percentages = {m: (c / camera_total) * 100 for m, c in camera_counts.items()}

# Combine % (averaged)
all_moods = set(survey_percentages) | set(camera_percentages)
combined_percentages = {
    mood: round((survey_percentages.get(mood, 0) + camera_percentages.get(mood, 0)) / 2, 2)
    for mood in all_moods
}

# ----------------------------
# Professional Bar Chart
# ----------------------------
sns.set(style="whitegrid")
plt.figure(figsize=(10, 6))
sorted_data = sorted(combined_percentages.items(), key=lambda x: -x[1])
moods, percentages = zip(*sorted_data)
colors = sns.color_palette("viridis", len(moods))

bars = sns.barplot(x=list(moods), y=list(percentages), palette=colors)
plt.title("🌈 Weekly Mood Report (Survey + Camera)", fontsize=18, color="darkblue")
plt.ylabel("Mood Percentage (%)")
plt.xlabel("Mood Type")
plt.ylim(0, 100)

for bar in bars.patches:
    height = bar.get_height()
    plt.text(
        bar.get_x() + bar.get_width() / 2,
        height + 1,
        f"{height:.1f}%",
        ha="center",
        va="bottom",
        fontsize=10,
        fontweight="bold"
    )

plt.tight_layout()
plt.savefig("mood_bar_chart_weekly.png", dpi=300)
plt.close()

# ----------------------------
# AI Suggestions using KMeans
# ----------------------------
df = pd.DataFrame(daily_logs)
relevant_features = ["sleep", "water", "exercise", "pain", "energy", "mood"]
df = df[relevant_features]
encoders = {}

for col in df.columns:
    le = LabelEncoder()
    df[col] = le.fit_transform(df[col])
    encoders[col] = le

df_features = df.drop(columns=["mood"])
kmeans = KMeans(n_clusters=2, random_state=42, n_init=10)
df["cluster"] = kmeans.fit_predict(df_features)
df["mood_label"] = df["mood"]

cluster_summary = df.groupby("cluster").mean()

if cluster_summary.loc[0]["mood_label"] < cluster_summary.loc[1]["mood_label"]:
    bad_cluster, good_cluster = 0, 1
else:
    bad_cluster, good_cluster = 1, 0

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

# ----------------------------
# Save Summary Report
# ----------------------------
with open("mood_summary_and_ai.txt", "w", encoding="utf-8") as f:
    f.write("🧠 Mood Summary (Survey)\n")
    f.write("============================\n")
    for mood, pct in survey_percentages.items():
        f.write(f"{mood}: {pct:.1f}%\n")

    f.write("\n📷 Mood Summary (Camera)\n")
    f.write("============================\n")
    for mood, pct in camera_percentages.items():
        f.write(f"{mood}: {pct:.1f}%\n")

    f.write("\n💡 AI Suggestions\n")
    f.write("============================\n")
    for s in suggestions:
        f.write(s + "\n")

print("✅ Done! Generated:")
print("- mood_bar_chart_weekly.png")
print("- mood_summary_and_ai.txt")