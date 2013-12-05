CREATE TABLE "test_rt" (
  id SERIAL PRIMARY KEY NOT NULL,
  carrier varchar(64) DEFAULT NULL
);
DELETE FROM version WHERE table_name ='test_rt';
INSERT INTO version VALUES ('test_rt', (SELECT table_version FROM version WHERE table_name='route_tree')) ;
INSERT INTO "test_rt" VALUES (1,'default');
