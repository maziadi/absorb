CREATE TABLE "test_dr_cr" (
  id SERIAL PRIMARY KEY NOT NULL,
  carrierid VARCHAR(64) NOT NULL,
  gwlist VARCHAR(255) NOT NULL,
  flags INTEGER DEFAULT 0 NOT NULL,
  attrs VARCHAR(255) DEFAULT '',
  description VARCHAR(128) DEFAULT '' NOT NULL,
  update_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "test_dr_carriers_dr_carrier_idx" UNIQUE (carrierid)
);
DELETE FROM version WHERE table_name ='test_dr_cr';
INSERT INTO version VALUES ('test_dr_cr', (SELECT table_version FROM version WHERE table_name='dr_carriers')) ;
