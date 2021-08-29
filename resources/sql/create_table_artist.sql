DROP TABLE IF EXISTS artist;
CREATE TABLE IF NOT EXISTS artist(
  "artist_id" 					INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
  "artist_name"					TEXT UNIQUE,
  "ref_group_id"				INTEGER,
  "artist_name_first"			TEXT,
  "artist_name_last"			TEXT,
  "artist_name_short"			TEXT,
  "artist_from"					TEXT,
  "artist_to"					TEXT,
  "artist_info"					TEXT
)
