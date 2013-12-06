CREATE TABLE "<%= $vno_id %>_dr_gr" (
  id SERIAL PRIMARY KEY NOT NULL,
  username VARCHAR(64) NOT NULL,
  domain VARCHAR(128) DEFAULT '' NOT NULL,
  groupid INTEGER DEFAULT 0 NOT NULL,
  description VARCHAR(128) DEFAULT '' NOT NULL
);
DELETE FROM version WHERE table_name ='<%= $vno_id %>_dr_gr';
INSERT INTO version VALUES ('<%= $vno_id %>_dr_gr', (SELECT table_version FROM version WHERE table_name='dr_groups')) ;
