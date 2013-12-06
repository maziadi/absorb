CREATE TABLE "test_sub" (
  id SERIAL PRIMARY KEY NOT NULL,
  username VARCHAR(64) DEFAULT '' NOT NULL,
  domain VARCHAR(64) DEFAULT '' NOT NULL,
  password VARCHAR(25) DEFAULT '' NOT NULL,
  email_address VARCHAR(64) DEFAULT '' NOT NULL,
  ha1 VARCHAR(64) DEFAULT '' NOT NULL,
  ha1b VARCHAR(64) DEFAULT '' NOT NULL,
  rpid VARCHAR(64) DEFAULT NULL,
  group_id INTEGER NOT NULL default '1',
  CONSTRAINT "test_subscriber_account_idx" UNIQUE (username, domain)
);
CREATE INDEX "test_username_idx" ON "test_sub" (username);
DELETE FROM version WHERE table_name ='test_sub';
INSERT INTO version VALUES ('test_sub', (SELECT table_version FROM version WHERE table_name='subscriber')) ;
