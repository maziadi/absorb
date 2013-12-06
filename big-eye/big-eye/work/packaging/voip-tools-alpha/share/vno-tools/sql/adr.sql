CREATE TABLE "<%= $vno_id %>_adr" (
  id SERIAL PRIMARY KEY NOT NULL,
  grp SMALLINT DEFAULT 0 NOT NULL,
  ip VARCHAR(50) NOT NULL,
  mask SMALLINT DEFAULT 32 NOT NULL,  
  port SMALLINT DEFAULT 0 NOT NULL,
  proto VARCHAR(4) DEFAULT 'any' NOT NULL,
  pattern VARCHAR(64) DEFAULT NULL,
  context_info VARCHAR(32) DEFAULT NULL
);
DELETE FROM version WHERE table_name ='<%= $vno_id %>_adr';
INSERT INTO version VALUES ('<%= $vno_id %>_adr', (SELECT table_version FROM version WHERE table_name='address')) ;
