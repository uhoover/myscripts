CREATE TABLE IF NOT EXISTS title(
  "title_id" 					INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
  "title_name"					TEXT UNIQUE,
  "title_name_new"				TEXT,
  "title_opus"					TEXT,
  "ref_besetzung_id"			INTEGER,
  "ref_opus_id"					INTEGER,
  "title_info"					TEXT
)
