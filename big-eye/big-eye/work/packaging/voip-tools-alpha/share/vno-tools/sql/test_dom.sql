CREATE TABLE "test_dom" (
  id SERIAL PRIMARY KEY NOT NULL,
  domain VARCHAR(64) DEFAULT '' NOT NULL,
  last_modified TIMESTAMP WITHOUT TIME ZONE DEFAULT '1900-01-01 00:00:01' NOT NULL,
  CONSTRAINT "test_domain_domain_idx" UNIQUE (domain)
);
INSERT INTO "test_dom" VALUES (1,'1.1.1.1',now());
DELETE FROM version WHERE table_name ='test_dom';
INSERT INTO version VALUES ('test_dom', (SELECT table_version FROM version WHERE table_name='domain')) ;
