CREATE TABLE IF NOT EXISTS album(
  "album_id" 					INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
  "album_name"					TEXT UNIQUE,
  "album_name_new"				TEXT,
  "album_opus"					TEXT,
  "ref_besetzung_id"			INTEGER,
  "ref_opus_id"					INTEGER,
  "album_info"					TEXT
)
