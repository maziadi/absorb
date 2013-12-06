CREATE TABLE "test_dr_gr" (
  id SERIAL PRIMARY KEY NOT NULL,
  username VARCHAR(64) NOT NULL,
  domain VARCHAR(128) DEFAULT '' NOT NULL,
  groupid INTEGER DEFAULT 0 NOT NULL,
  description VARCHAR(128) DEFAULT '' NOT NULL
);
DELETE FROM version WHERE table_name ='test_dr_gr';
INSERT INTO version VALUES ('test_dr_gr', (SELECT table_version FROM version WHERE table_name='dr_groups')) ;
