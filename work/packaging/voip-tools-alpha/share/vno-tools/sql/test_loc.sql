CREATE TABLE "test_loc" (
  id SERIAL PRIMARY KEY NOT NULL,
  username VARCHAR(64) DEFAULT '' NOT NULL,
  domain VARCHAR(64) DEFAULT '' NOT NULL,
  contact VARCHAR(255) DEFAULT '' NOT NULL,
  received VARCHAR(128) DEFAULT NULL,
  path VARCHAR(128) DEFAULT NULL,
  expires TIMESTAMP WITHOUT TIME ZONE DEFAULT '2020-05-28 21:32:15' NOT NULL,
  q REAL DEFAULT 1.0 NOT NULL,
  callid VARCHAR(255) DEFAULT 'Default-Call-ID' NOT NULL,
  cseq INTEGER DEFAULT 13 NOT NULL,
  last_modified TIMESTAMP WITHOUT TIME ZONE DEFAULT '1900-01-01 00:00:01' NOT NULL,
  flags INTEGER DEFAULT 0 NOT NULL,
  cflags INTEGER DEFAULT 0 NOT NULL,
  user_agent VARCHAR(255) DEFAULT '' NOT NULL,
  socket VARCHAR(64) DEFAULT NULL,
  methods INTEGER DEFAULT NULL,
  sip_instance VARCHAR(255) DEFAULT NULL,
  CONSTRAINT "test_account_contact_idx" UNIQUE (username, domain, contact, callid)
);
DELETE FROM version WHERE table_name ='test_loc';
INSERT INTO version VALUES ('test_loc', (SELECT table_version FROM version WHERE table_name='location')) ;
