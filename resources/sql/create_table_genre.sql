DROP TABLE IF EXISTS genre;
CREATE TABLE IF NOT EXISTS genre(
  "genre_id" 					INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
  "genre_name"					TEXT UNIQUE,
  "ref_genrelist_id"	    	INTEGER,
  "genre_info"					TEXT
)
