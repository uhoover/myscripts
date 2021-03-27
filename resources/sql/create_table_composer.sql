CREATE TABLE IF NOT EXISTS composer(
  "composer_id" 					INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
  "composer_name"					TEXT UNIQUE,
  "composer_name_first"				TEXT,
  "composer_name_last"				TEXT,
  "composer_name_short"				TEXT,
  "composer_from"					TEXT,
  "composer_to"						TEXT,
  "composer_info"					TEXT
)
