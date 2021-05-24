DROP TABLE IF EXISTS besetzung;
CREATE TABLE IF NOT EXISTS besetzung(
  "besetzung_id" 				INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
  "besetzung_name"				TEXT UNIQUE,
  "besetzung_short"				TEXT UNIQUE,
  "besetzung_id_ref"			INTEGER,
  "besetzung_info"				TEXT
)
