import sqlite3
import pandas as pd

conn = sqlite3.connect("traces.db")
df = pd.read_sql("SELECT * FROM spans", conn)
df["duration_ms"] = (df["end_time"] - df["start_time"]) / 1e6

# --- Q4: which span names appear? ---
print("Span names:", df["name"].unique())

# --- Q5: total duration per span type, excluding rag ---
totals = (
    df[df["name"] != "rag"]
    .groupby("name")["duration_ms"]
    .sum()
)
print("\nTotal duration by span (ms):")
print(totals)

# --- Q6: input token stability across llm spans ---
llm_df = df[df["name"] == "llm"]
print("\nInput tokens per llm call:")
print(llm_df["input_tokens"].tolist())

mean_tokens = llm_df["input_tokens"].mean()
spread = (llm_df["input_tokens"].max() - llm_df["input_tokens"].min()) / mean_tokens * 100
print(f"\nVariation across runs: {spread:.1f}%")