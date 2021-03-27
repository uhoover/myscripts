CREATE TABLE IF NOT EXISTS track(
  "track_id" 					INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
  "track_status"				INTEGER,
  "track_album"					TEXT,
  "ref_album_id"				INTEGER,
  "track_title"					TEXT,
  "ref_title_id"				INTEGER,
  "track_composer"				TEXT,
  "ref_composer_id"				INTEGER,
  "track_artist"				TEXT,
  "ref_artist_id"				INTEGER,
  "track_genre"					TEXT,
  "ref_genre_id"				INTEGER,
  "track_date"					TEXT,
  "track_duration"				TEXT,
  "track_size"					TEXT,
  "track_format_name"			TEXT,
  "track_format_long_name"		TEXT,
  "track_filename"				TEXT,
  "track_nb_streams"			TEXT,
  "track_nb_program"			TEXT,
  "track_start_time"			TEXT,
  "track_bit_rate"				TEXT,
  "track_probe_score"			TEXT,
  "track_timestamp"				TEXT,
  "track_info"					TEXT
);
CREATE TRIGGER IF NOT EXISTS track_after_insert 
   AFTER INSERT ON track
BEGIN
	INSERT OR IGNORE INTO album(album_name) VALUES (new.track_album);
    UPDATE track set ref_album_id = (select album_id from album where album_name = new.track_album);
END;
