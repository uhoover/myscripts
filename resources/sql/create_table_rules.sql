DROP TABLE IF EXISTS rules;
CREATE TABLE IF NOT EXISTS rules(
  "rules_id" 					INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
  "rules_name"					TEXT UNIQUE,
  "rules_type"					TEXT,
  "rules_db"					TEXT,
  "rules_tb"					TEXT,
  "rules_field"					TEXT,
  "rules_db_ref"				TEXT,
  "rules_tb_ref"				TEXT,
  "rules_action"				TEXT,
  "rules_col_list"				TEXT,
  "rules_info"					TEXT
)
