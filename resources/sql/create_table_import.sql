DROP TABLE IF EXISTS IMPORT;
CREATE TABLE import(
  "ID" 					INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
  "filename" 			TEXT,
  "nb_streams" 			TEXT,
  "nb_programs" 		TEXT,
  "format_name" 		TEXT,
  "format_long_name" 	TEXT,
  "start_time" 			TEXT,
  "duration" 			TEXT,
  "size" 				TEXT,
  "bit_rate" 			TEXT,
  "probe_score" 		TEXT,
  "tags_title" 			TEXT,
  "tags_artist" 		TEXT,
  "tags_album" 			TEXT,
  "tags_track" 			TEXT,
  "tags_genre" 			TEXT,
  "tags_composer" 		TEXT,
  "tags_date" 			TEXT
);
