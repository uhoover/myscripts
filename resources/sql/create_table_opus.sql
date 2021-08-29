CREATE TABLE IF NOT EXISTS opus(
  "opus_id" 				INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
  "opus_name"				TEXT UNIQUE,
  "opus_short"				TEXT UNIQUE,
  "opus_info"				TEXT
)
