# 🎧 Spotify Streaming Data Analysis (SQL Project)

<p align="center">
  <img src="https://img.shields.io/badge/Language-SQL-blue.svg" />
  <img src="https://img.shields.io/badge/Tool-PostgreSQL-blueviolet" />
  <img src="https://img.shields.io/badge/Focus-Data%20Analysis-brightgreen" />
</p>

## 📌 Project Overview

This project dives deep into **Spotify streaming history** using **PostgreSQL**, exploring user listening habits, content performance, and behavioral trends. It uses over **30 data-driven questions and KPIs** to uncover insights from raw streaming logs.

> 🔍 **Goal**: Convert raw listening logs into actionable insights for business and product decisions in the music streaming domain.

---

## 📂 Dataset Description

- **Table Used**: `spotify_tracks`
- **Source**: Exported CSV file from [Spotify’s Streaming History](https://www.spotify.com/us/account/privacy/)
- **Imported using**: `COPY` command in PostgreSQL
- **Preprocessing**:
  - Parsed timestamp into a clean `TIMESTAMP` format
  - Casted fields like `ms_played` into appropriate types for aggregation

---

## 🔍 Analysis Highlights

Here’s a breakdown of key analytical queries and insights:

| No. | Topic                                      | Insight Extracted                                       |
|-----|--------------------------------------------|----------------------------------------------------------|
| 01  | 🎯 Peak Listening Hours                   | Identify most engaged hours of the day                  |
| 02  | 🔥 Top Tracks & Artists                   | Rank by frequency and total playtime                    |
| 03  | 💽 Popular Albums                        | Measure engagement at album level                       |
| 04  | 📱 Platform-Based Behavior               | Compare engagement by device or app                     |
| 05  | ⏭️ High Skip Rate Tracks                | Pinpoint tracks users frequently skip                   |
| 06  | 🔄 Autoplay vs Manual                    | Discover user discovery vs algorithm-driven plays       |
| 07  | 🔄 Shuffle Mode Usage                    | Detect playlist randomness and preference               |
| 08  | 📆 Yearly & Monthly Trends               | Analyze seasonality and long-term growth                |
| 09  | 🌙 Night Listening Trends                | Study user behavior from 10 PM to 4 AM                  |
| 10  | 🧠 Longest Played Tracks                 | Highlight immersive or highly engaging songs            |

---

## 🛠 Tech Stack

- **SQL Flavor**: PostgreSQL
- **Platform**: macOS (locally via pgAdmin & Beekeeper Studio)
- **Tools Used**: pgAdmin, SQL Formatter, Excel (for EDA planning)

---

## 📊 Sample SQL Query

```sql
-- Top 10 Most Played Tracks
SELECT 
    track_name, 
    artist_name,
    COUNT(*) AS play_count,
    SUM(ms_played::INTEGER)/60000.0 AS total_minutes_played
FROM spotify_tracks
GROUP BY track_name, artist_name
ORDER BY play_count DESC
LIMIT 10;
