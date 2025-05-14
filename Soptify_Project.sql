/*
--------------------------------------------------------------
Title      : Spotify Streaming History Analysis
Author     : Dheeraj Kandpal
Date       : 2025-05-14
Database   : PostgreSQL
Table Used : spotify_tracks
Purpose    : To analyze user listening behavior, artist popularity,
             skip patterns, platform preferences, and time trends.
--------------------------------------------------------------
*/

-- Drop the table if it already exists to avoid duplication
DROP TABLE IF EXISTS spotify_tracks;

-- Create the cleaned table structure
CREATE TABLE spotify_tracks (
    spotify_track_uri TEXT,
    ts TEXT,  -- original timestamp as text
    platform TEXT,
    ms_played TEXT,
    len TEXT,
    track_name TEXT,
    artist_name TEXT,
    album_name TEXT,
    reason_start TEXT,
    reason_end TEXT,
    shuffle TEXT,
    skipped TEXT
);

-- Import data from CSV file
COPY spotify_tracks
FROM '/Users/dheerajkandpal/Downloads/Spotify+Streaming+History/spotify_history.csv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ','
);

-- Preview conversion for timestamp to validate format
SELECT 
    ts,
    TO_TIMESTAMP(ts, 'DD/MM/YY HH24:MI') AS formatted_ts
FROM spotify_tracks
LIMIT 5;

-- Add new column for cleaned timestamp
ALTER TABLE spotify_tracks 
ADD COLUMN ts_cleaned TIMESTAMP;

-- Clean and populate timestamp only for well-formatted entries
UPDATE spotify_tracks
SET ts_cleaned = TO_TIMESTAMP(ts, 'DD/MM/YY HH24:MI')
WHERE ts ~ '^\d{2}/\d{2}/\d{2} \d{1,2}:\d{2}$';


--Basic Level Questions


/*------------------------------------------------------------
Question 1 : Total Number of Tracks in Dataset
Purpose   : Understand overall dataset size
Insight   : Gives scale of data available for analysis
------------------------------------------------------------*/
SELECT COUNT(*) AS total_tracks
FROM spotify_tracks;

/*------------------------------------------------------------
Question 2 : Unique Songs Played
Purpose   : Count distinct track IDs
Insight   : Helps identify diversity in listening habits
------------------------------------------------------------*/
SELECT COUNT(DISTINCT spotify_track_uri) AS unique_songs
FROM spotify_tracks;

/*------------------------------------------------------------
Question 3 : Unique Artists
Purpose   : Identify how many different artists were heard
Insight   : Reflects variety in user taste
------------------------------------------------------------*/
SELECT COUNT(DISTINCT artist_name) AS unique_artists
FROM spotify_tracks;

/*------------------------------------------------------------
Question 4 : Most Played Track by Frequency
Purpose   : Identify top favorite track by count
Insight   : Shows repeat behavior
------------------------------------------------------------*/
SELECT track_name, COUNT(*) AS play_count
FROM spotify_tracks
GROUP BY track_name
ORDER BY play_count DESC
LIMIT 1;

/*------------------------------------------------------------
Question 5 : Most Played Artist by Frequency
Purpose   : Identify most heard artist by count
Insight   : Captures user's top musical preference
------------------------------------------------------------*/
SELECT artist_name, COUNT(*) AS play_count
FROM spotify_tracks
GROUP BY artist_name
ORDER BY play_count DESC
LIMIT 1;

/*------------------------------------------------------------
Question 6 : Total Play Time in Milliseconds
Purpose   : Calculate overall listening time
Insight   : Indicates total engagement
------------------------------------------------------------*/
SELECT SUM(ms_played::INTEGER) AS total_ms_played
FROM spotify_tracks;

/*------------------------------------------------------------
Question 7 : Shuffle Mode Usage Count
Purpose   : Understand how often shuffle was used
Insight   : Detects listening patterns
------------------------------------------------------------*/
SELECT COUNT(*) AS shuffle_plays
FROM spotify_tracks
WHERE shuffle = 'TRUE';

/*------------------------------------------------------------
Question 8 : Number of Skipped Tracks
Purpose   : Quantify skipped songs
Insight   : Evaluates engagement vs disinterest
------------------------------------------------------------*/
SELECT COUNT(*) AS skipped_tracks
FROM spotify_tracks
WHERE skipped = 'TRUE';

/*------------------------------------------------------------
Question 9 : Platforms Used to Listen
Purpose   : Identify listening platforms
Insight   : Device/platform usage trends
------------------------------------------------------------*/
SELECT platform, COUNT(*) AS play_count
FROM spotify_tracks
GROUP BY platform
ORDER BY play_count DESC;

/*------------------------------------------------------------
Question 10 : Average Play Duration per Song
Purpose   : Measure user engagement per play
Insight   : Detect if songs are played in full
------------------------------------------------------------*/
SELECT ROUND(AVG(ms_played::INTEGER), 2) AS avg_play_duration_ms
FROM spotify_tracks;


--Intermediate Level Questions


/*------------------------------------------------------------
Question 11 : Track with Highest Total Playtime
Purpose   : Find most heavily engaged track
Insight   : Indicates deep user connection
------------------------------------------------------------*/
SELECT track_name, SUM(ms_played::INTEGER) AS total_play_time
FROM spotify_tracks
GROUP BY track_name
ORDER BY total_play_time DESC
LIMIT 1;

/*------------------------------------------------------------
Question 12 : Artist with Highest Cumulative Listening Time
Purpose   : Identify artist with max total listen time
Insight   : Measures artist loyalty
------------------------------------------------------------*/
SELECT artist_name, SUM(ms_played::INTEGER) AS total_ms
FROM spotify_tracks
GROUP BY artist_name
ORDER BY total_ms DESC
LIMIT 1;

/*------------------------------------------------------------
Question 13 : Most Common Reason Songs Started
Purpose   : Know why songs began
Insight   : Measures autoplay, manual selection etc.
------------------------------------------------------------*/
SELECT reason_start, COUNT(*) AS count
FROM spotify_tracks
GROUP BY reason_start
ORDER BY count DESC
LIMIT 1;

/*------------------------------------------------------------
Question 14 : Most Common Reason Songs Ended
Purpose   : Know what ended the song
Insight   : Detects skips, manual stop, or song end
------------------------------------------------------------*/
SELECT reason_end, COUNT(*) AS count
FROM spotify_tracks
GROUP BY reason_end
ORDER BY count DESC
LIMIT 1;

/*------------------------------------------------------------
Question 15 : Peak Listening Hours
Purpose   : Identify hours with highest user engagement
Insight   : Optimize content release timing
------------------------------------------------------------*/
SELECT 
    EXTRACT(HOUR FROM ts_cleaned) AS hour,
    COUNT(*) AS plays,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_contribution
FROM spotify_tracks
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3;

/*------------------------------------------------------------
Question 16 : Top 5 Albums by Total Play Time
Purpose   : Find albums with most listening time
Insight   : Highlights top album preferences
------------------------------------------------------------*/
SELECT album_name, SUM(ms_played::INTEGER) AS total_playtime
FROM spotify_tracks
GROUP BY album_name
ORDER BY total_playtime DESC
LIMIT 5;

/*------------------------------------------------------------
Question 17 : Songs Played More Than 10 Times
Purpose   : Identify most repeated songs
Insight   : Reveals personal favorites
------------------------------------------------------------*/
SELECT track_name, COUNT(*) AS play_count
FROM spotify_tracks
GROUP BY track_name
HAVING COUNT(*) > 10
ORDER BY play_count DESC;

/*------------------------------------------------------------
Question 18 : Percentage of Songs Skipped
Purpose   : Understand user disinterest
Insight   : Skipping rate metric
------------------------------------------------------------*/
SELECT 
    ROUND(100.0 * SUM(CASE WHEN skipped = 'TRUE' THEN 1 ELSE 0 END) / COUNT(*), 2) AS skip_percentage
FROM spotify_tracks;

/*------------------------------------------------------------
Question 19 : Average Playtime per Platform
Purpose   : Analyze device-based engagement
Insight   : Understand where deeper listening happens
------------------------------------------------------------*/
SELECT platform, ROUND(AVG(ms_played::INTEGER), 2) AS avg_ms_played
FROM spotify_tracks
GROUP BY platform
ORDER BY avg_ms_played DESC;

/*------------------------------------------------------------
Question 20 : Day with Maximum Songs Played
Purpose   : Detect peak listening days
Insight   : Reveals behavioral patterns
------------------------------------------------------------*/
SELECT DATE(ts_cleaned) AS play_day, COUNT(*) AS plays
FROM spotify_tracks
GROUP BY play_day
ORDER BY plays DESC
LIMIT 1;


--Advanced Level Questions


/*------------------------------------------------------------
Question 21 : Retention Rate of Songs (Not Skipped vs Skipped)
Purpose   : Understand content stickiness
Insight   : Measures user satisfaction
------------------------------------------------------------*/
SELECT 
    SUM(CASE WHEN skipped = 'FALSE' THEN 1 ELSE 0 END) AS not_skipped,
    SUM(CASE WHEN skipped = 'TRUE' THEN 1 ELSE 0 END) AS skipped,
    ROUND(100.0 * SUM(CASE WHEN skipped = 'FALSE' THEN 1 ELSE 0 END) / COUNT(*), 2) AS retention_rate
FROM spotify_tracks;

/*------------------------------------------------------------
Question 22 : Artist with Highest Avg Playtime per Track
Purpose   : Find artist that engages longest
Insight   : Signals deeper user interest
------------------------------------------------------------*/
SELECT artist_name, ROUND(AVG(ms_played::INTEGER), 2) AS avg_playtime
FROM spotify_tracks
GROUP BY artist_name
ORDER BY avg_playtime DESC
LIMIT 1;

/*------------------------------------------------------------
Question 23 : Play Count Over Time (Daily)
Purpose   : Build time series of usage
Insight   : Detects trends in usage behavior
------------------------------------------------------------*/
SELECT DATE(ts_cleaned) AS date_played, COUNT(*) AS daily_plays
FROM spotify_tracks
GROUP BY date_played
ORDER BY date_played;

/*------------------------------------------------------------
Question 24 : Top Song in Shuffle Mode
Purpose   : Find most played track when shuffle was ON
Insight   : Preferences during randomized play
------------------------------------------------------------*/
SELECT track_name, COUNT(*) AS play_count
FROM spotify_tracks
WHERE shuffle = 'TRUE'
GROUP BY track_name
ORDER BY play_count DESC
LIMIT 1;

/*------------------------------------------------------------
Question 25 : Autoplay + Short Duration Anomalies
Purpose   : Detect potential disinterest in autoplayed songs
Insight   : User skipped autoplay content
------------------------------------------------------------*/
SELECT track_name, ms_played
FROM spotify_tracks
WHERE reason_start = 'autoplay' AND ms_played::INTEGER < 10000
ORDER BY ms_played ASC;

/*------------------------------------------------------------
Question 26 : Top Songs Never Skipped
Purpose   : Highest listening commitment
Insight   : Pure favorites
------------------------------------------------------------*/
SELECT track_name, SUM(ms_played::INTEGER) AS total_time
FROM spotify_tracks
WHERE skipped = 'FALSE'
GROUP BY track_name
ORDER BY total_time DESC
LIMIT 5;

/*------------------------------------------------------------
Question 27 : Artist Ranking by Avg Listening Time
Purpose   : Find who holds user's attention most
Insight   : Deep listening indicators
------------------------------------------------------------*/
SELECT artist_name, ROUND(AVG(ms_played::INTEGER), 2) AS avg_ms_played
FROM spotify_tracks
GROUP BY artist_name
ORDER BY avg_ms_played DESC
LIMIT 5;

/*------------------------------------------------------------
Question 28 : Skip Rate by Platform
Purpose   : Compare user behavior across platforms
Insight   : Skipping trends by device
------------------------------------------------------------*/
SELECT platform, 
    ROUND(100.0 * SUM(CASE WHEN skipped = 'TRUE' THEN 1 ELSE 0 END) / COUNT(*), 2) AS skip_rate_pct
FROM spotify_tracks
GROUP BY platform
ORDER BY skip_rate_pct DESC;

/*------------------------------------------------------------
Question 29 : Songs Played Under 30% of Length
Purpose   : Detect tracks abandoned early
Insight   : Track-level engagement issues
------------------------------------------------------------*/
SELECT track_name, ms_played, len,
       ROUND(100.0 * ms_played::INTEGER / NULLIF(len::INTEGER * 1000, 0), 2) AS percent_played
FROM spotify_tracks
WHERE (ms_played::INTEGER / NULLIF(len::INTEGER * 1000, 0)) < 0.3
ORDER BY percent_played ASC;

/*------------------------------------------------------------
Question 30 : Shuffle Influence on Skip Rate
Purpose   : Measure effect of shuffle on skipping
Insight   : Behavioral pattern under random play
------------------------------------------------------------*/
SELECT shuffle, 
    ROUND(100.0 * SUM(CASE WHEN skipped = 'TRUE' THEN 1 ELSE 0 END) / COUNT(*), 2) AS skip_rate_pct
FROM spotify_tracks
GROUP BY shuffle;


--Additional Advanced level Questions 

/*------------------------------------------------------------
Question 1 : Peak Listening Hours
Purpose   : Identify hours with highest user engagement
Insight   : Optimize content release timing
------------------------------------------------------------*/
SELECT 
    EXTRACT(HOUR FROM ts_cleaned) AS hour,
    COUNT(*) AS plays,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_contribution
FROM spotify_tracks
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3;

/*------------------------------------------------------------
Question 2 : Top 10 Most Played Tracks
Purpose   : Identify tracks with the highest engagement
Insight   : Determine which songs resonate the most
------------------------------------------------------------*/
SELECT 
    track_name, 
    artist_name,
    COUNT(*) AS play_count,
    SUM(ms_played::INTEGER)/60000.0 AS total_minutes_played
FROM spotify_tracks
GROUP BY track_name, artist_name
ORDER BY play_count DESC
LIMIT 10;

/*------------------------------------------------------------
Question 3 : Most Streamed Artists
Purpose   : Rank artists by play frequency
Insight   : Artist performance over time
------------------------------------------------------------*/
SELECT 
    artist_name,
    COUNT(*) AS total_plays,
    SUM(ms_played::INTEGER)/60000.0 AS total_minutes
FROM spotify_tracks
GROUP BY artist_name
ORDER BY total_plays DESC
LIMIT 10;

/*------------------------------------------------------------
Question 4 : Listening Behavior by Platform
Purpose   : Analyze engagement across platforms
Insight   : Optimize platform-specific strategies
------------------------------------------------------------*/
SELECT 
    platform, 
    COUNT(*) AS plays,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_usage
FROM spotify_tracks
GROUP BY platform
ORDER BY plays DESC;

/*------------------------------------------------------------
Question 5 : Tracks with High Skip Rate
Purpose   : Detect tracks frequently skipped
Insight   : Improve user satisfaction and curation
------------------------------------------------------------*/
SELECT 
    track_name, 
    artist_name,
    COUNT(*) FILTER (WHERE skipped = 'TRUE') AS skip_count,
    COUNT(*) AS total_plays,
    ROUND(100.0 * COUNT(*) FILTER (WHERE skipped = 'TRUE') / COUNT(*), 1) AS skip_rate_pct
FROM spotify_tracks
GROUP BY track_name, artist_name
HAVING COUNT(*) > 10
ORDER BY skip_rate_pct DESC
LIMIT 10;

/*------------------------------------------------------------
Question 6 : Autoplay vs Manual Play Distribution
Purpose   : Evaluate content discovery modes
Insight   : Understand organic vs algorithm-driven plays
------------------------------------------------------------*/
SELECT 
    reason_start, 
    COUNT(*) AS plays,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_reason
FROM spotify_tracks
GROUP BY reason_start
ORDER BY plays DESC;

/*------------------------------------------------------------
Question 7 : Most Popular Albums
Purpose   : Identify albums with high engagement
Insight   : Support campaign planning for albums
------------------------------------------------------------*/
SELECT 
    album_name, 
    COUNT(*) AS total_plays,
    SUM(ms_played::INTEGER)/60000.0 AS total_minutes
FROM spotify_tracks
GROUP BY album_name
ORDER BY total_plays DESC
LIMIT 10;

/*------------------------------------------------------------
Question 8 : Yearly Listening Trends
Purpose   : Identify engagement over the years
Insight   : Track growth and seasonality in usage
------------------------------------------------------------*/
SELECT 
    EXTRACT(YEAR FROM ts_cleaned) AS year,
    COUNT(*) AS plays,
    SUM(ms_played::INTEGER)/60000.0 AS total_minutes
FROM spotify_tracks
GROUP BY year
ORDER BY year;

/*------------------------------------------------------------
Question 9 : Monthly Listening Behavior
Purpose   : Breakdown of listening patterns per month
Insight   : Identify seasonal trends
------------------------------------------------------------*/
SELECT 
    TO_CHAR(ts_cleaned, 'YYYY-MM') AS year_month,
    COUNT(*) AS total_plays,
    SUM(ms_played::INTEGER)/60000.0 AS minutes_played
FROM spotify_tracks
GROUP BY year_month
ORDER BY year_month;

/*------------------------------------------------------------
Question 10 : Shuffle Play Analysis
Purpose   : Determine how often shuffle mode is used
Insight   : Understand user's playlist behavior
------------------------------------------------------------*/
SELECT 
    shuffle,
    COUNT(*) AS plays,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_shuffle
FROM spotify_tracks
GROUP BY shuffle;

/*------------------------------------------------------------
Question 11 : Longest Played Tracks
Purpose   : Find tracks with longest individual sessions
Insight   : Potentially immersive or high-value content
------------------------------------------------------------*/
SELECT 
    track_name, 
    artist_name,
    MAX(ms_played::INTEGER)/60000.0 AS max_minutes
FROM spotify_tracks
GROUP BY track_name, artist_name
ORDER BY max_minutes DESC
LIMIT 10;

/*------------------------------------------------------------
Question 12 : Most Played Tracks at Night (10 PM - 4 AM)
Purpose   : Explore nocturnal listening habits
Insight   : Plan for late-night audience engagement
------------------------------------------------------------*/
SELECT 
    track_name,
    artist_name,
    COUNT(*) AS play_count
FROM spotify_tracks
WHERE EXTRACT(HOUR FROM ts_cleaned) IN (22, 23, 0, 1, 2, 3, 4)
GROUP BY track_name, artist_name
ORDER BY play_count DESC
LIMIT 10;

/*
------------------------------------------------------------
Final Summary: Total Plays, Minutes, Unique Tracks by Year
------------------------------------------------------------
*/
SELECT 
    EXTRACT(YEAR FROM ts_cleaned) AS year,
    COUNT(*) AS total_plays,
    SUM(ms_played::INTEGER)/60000.0 AS total_minutes_played,
    COUNT(DISTINCT spotify_track_uri) AS unique_tracks
FROM spotify_tracks
WHERE ts_cleaned IS NOT NULL
GROUP BY year
ORDER BY year;

-- ----------------------------------------------------------
/*
----------------------
End of Analysis Script
Author: Dheeraj Kandpal
----------------------
*/

