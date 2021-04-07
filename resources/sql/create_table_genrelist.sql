DROP TABLE IF EXISTS genrelist;
CREATE TABLE genrelist(
  "genrelist_id"       INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL  UNIQUE,
  "genrelist_name" 	   TEXT,
  "genrelist_info" 	   TEXT
);
.import /home/uwe/my_scripts/resources/load_genrelist.csv tmp
insert into genrelist 
select null,genre_name,null from tmp;
DROP TABLE IF EXISTS tmp;
