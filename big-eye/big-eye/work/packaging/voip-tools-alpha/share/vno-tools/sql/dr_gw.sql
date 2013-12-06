CREATE TABLE "<%= $vno_id %>_dr_gw" (
  id SERIAL PRIMARY KEY NOT NULL,
  gwid VARCHAR(64) NOT NULL,
  type INTEGER DEFAULT 0 NOT NULL,
  address VARCHAR(128) NOT NULL,
  strip INTEGER DEFAULT 0 NOT NULL,
  pri_prefix VARCHAR(16) DEFAULT NULL,
  attrs VARCHAR(255) DEFAULT NULL,
  probe_mode INTEGER DEFAULT 0 NOT NULL,
  description VARCHAR(128) DEFAULT '' NOT NULL,
  CONSTRAINT "<%= $vno_id %>_dr_gateways_dr_gw_idx" UNIQUE (gwid)
);
DELETE FROM version WHERE table_name ='<%= $vno_id %>_dr_gw';
INSERT INTO version VALUES ('<%= $vno_id %>_dr_gw', (SELECT table_version FROM version WHERE table_name='dr_gateways')) ;
