CREATE TABLE "<%= $vno_id %>_rt" (
  id SERIAL PRIMARY KEY NOT NULL,
  carrier varchar(64) DEFAULT NULL
);
DELETE FROM version WHERE table_name ='<%= $vno_id %>_rt';
INSERT INTO version VALUES ('<%= $vno_id %>_rt', (SELECT table_version FROM version WHERE table_name='route_tree')) ;
INSERT INTO "<%= $vno_id %>_rt" VALUES (1,'default');
