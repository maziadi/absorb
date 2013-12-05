CREATE TABLE "<%= $vno_id %>_dom" (
  id SERIAL PRIMARY KEY NOT NULL,
  domain VARCHAR(64) DEFAULT '' NOT NULL,
  last_modified TIMESTAMP WITHOUT TIME ZONE DEFAULT '1900-01-01 00:00:01' NOT NULL,
  CONSTRAINT "<%= $vno_id %>_domain_domain_idx" UNIQUE (domain)
);
INSERT INTO "<%= $vno_id %>_dom" VALUES (1,'<%= $opensips_service_addr %>',now());
DELETE FROM version WHERE table_name ='<%= $vno_id %>_dom';
INSERT INTO version VALUES ('<%= $vno_id %>_dom', (SELECT table_version FROM version WHERE table_name='domain')) ;
