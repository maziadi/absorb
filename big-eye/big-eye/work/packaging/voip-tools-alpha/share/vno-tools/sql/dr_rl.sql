CREATE TABLE "<%= $vno_id %>_dr_rl" (
  ruleid SERIAL PRIMARY KEY NOT NULL,
  groupid VARCHAR(255) NOT NULL,
  prefix VARCHAR(64) NOT NULL,
  timerec VARCHAR(255) NOT NULL DEFAULT '',
  priority INTEGER DEFAULT 0 NOT NULL,
  routeid VARCHAR(255) DEFAULT NULL,
  gwlist VARCHAR(255) NOT NULL,
  attrs VARCHAR(255) DEFAULT NULL,
  description VARCHAR(128) DEFAULT '' NOT NULL
);
DELETE FROM version WHERE table_name ='<%= $vno_id %>_dr_rl';
INSERT INTO version VALUES ('<%= $vno_id %>_dr_rl', (SELECT table_version FROM version WHERE table_name='dr_rules')) ;
