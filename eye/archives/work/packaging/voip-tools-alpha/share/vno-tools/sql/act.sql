CREATE TABLE "<%= $vno_id %>_act" (
  account_code varchar(15) PRIMARY KEY NOT NULL,
  update_date timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);
