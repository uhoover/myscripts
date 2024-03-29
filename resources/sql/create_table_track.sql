DROP TABLE IF EXISTS track;
CREATE TABLE IF NOT EXISTS track(
  "track_id" 					INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
  "track_status"				INTEGER default 0,
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
  "fls_track_filename"			TEXT,
  "track_nb_streams"			TEXT,
  "track_nb_program"			TEXT,
  "track_start_time"			TEXT,
  "track_bit_rate"				TEXT,
  "track_probe_score"			TEXT,
  "track_timestamp"				TEXT,
  "track_info"					TEXT default 'batch'
);
CREATE INDEX ix_track_album_id ON track (ref_album_id);
CREATE INDEX ix_track_title_id ON track (ref_title_id);
CREATE INDEX ix_track_composer_id ON track (ref_composer_id);
CREATE INDEX ix_track_artist_id ON track (ref_artist_id);
