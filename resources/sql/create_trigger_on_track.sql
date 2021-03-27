DROP TRIGGER IF EXISTS track_after_insert;
CREATE TRIGGER IF NOT EXISTS track_after_insert 
   AFTER INSERT ON track
BEGIN
	INSERT OR IGNORE INTO album (album_name,album_name_new) VALUES (new.track_album,new.track_album);
    UPDATE track set ref_album_id = (select album_id from album where album_name = new.track_album);
	INSERT OR IGNORE INTO title (title_name,title_name_new) VALUES (new.track_title,new.track_title);
    UPDATE track set ref_title_id = (select title_id from title where title_name = new.track_title);
	INSERT OR IGNORE INTO composer (composer_name,composer_name_last) VALUES (new.track_composer,new.track_composer);
    UPDATE track set ref_composer_id = (select composer_id from composer where composer_name = new.track_composer);
	INSERT OR IGNORE INTO artist (artist_name,artist_name_last) VALUES (new.track_artist,new.track_artist);
    UPDATE track set ref_artist_id = (select artist_id from artist where artist_name = new.track_artist);
	INSERT OR IGNORE INTO genre (genre_name) VALUES (new.track_genre);
    UPDATE track set ref_genre_id = (select genre_id from genre where genre_name = new.track_genre);
END;
