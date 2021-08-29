DROP TABLE IF EXISTS album;
CREATE TABLE IF NOT EXISTS album(
  "album_id" 					INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
  "album_name"					TEXT UNIQUE,
  "ref_track_album"				INTEGER,
  "album_opus"					TEXT,
  "ref_besetzung_id"			INTEGER,
  "ref_opus_catalog"			TEXT,
  "album_info"					TEXT
)
