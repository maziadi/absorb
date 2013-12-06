-- DELETE FROM d200911200002_dom;
DELETE FROM d200911200001_sub;
DELETE FROM d200911200001_adr;
DELETE FROM d200911200001_dr_cr;
DELETE FROM d200911200001_dr_gw;
DELETE FROM d200911200001_dr_gr;
DELETE FROM d200911200001_dr_rl;
DELETE FROM d200911200001_act;

INSERT INTO d200911200001_dr_cr (carrierid, gwlist, flags, description, update_date) VALUES ('1', '1=50,2=50', 1, 'carrier 1', now());

INSERT INTO d200911200001_dr_gw (gwid, type, address, probe_mode, description) VALUES ('1', 1, '37.122.202.234:5060', 2, 'Asterisk Server in MRF-2-MAQUETTE');
INSERT INTO d200911200001_dr_gw (gwid, type, address, probe_mode, description) VALUES ('2', 1, '37.122.202.235:5060', 2, 'Asterisk Server in MRF-3-MAQUETTE');
INSERT INTO d200911200001_dr_gw (gwid, type, address, probe_mode, description) VALUES ('3', 3, '217.15.80.163:5060', 0, 'Opensips Proxy in PCSCF-1-CBV1');
INSERT INTO d200911200001_dr_gw (gwid, type, address, probe_mode, description) VALUES ('4', 4, '217.15.80.79:5060', 0, 'C4 : 0990000001009');

INSERT INTO d200911200001_dr_gr VALUES (1, '.*', '.*', 1, 'Everyone');
INSERT INTO d200911200001_dr_gr VALUES (2, '.*', '.*', 2, 'Everyone');

INSERT INTO d200911200001_dr_rl (groupid, prefix, gwlist, description) VALUES ('1', '', '#1', 'Default Route');
INSERT INTO d200911200001_dr_rl (groupid, prefix, gwlist, description) VALUES ('2', '0990000999004', '3', 'INTERCO : 0990000999004');
INSERT INTO d200911200001_dr_rl (groupid, prefix, gwlist, description) VALUES ('3', '0990000001009', '4', '');

-- Inserted when table is created
-- INSERT INTO d200911200001_dom (domain, last_modified) VALUES ('37.122.202.233',now());

INSERT INTO d200911200001_sub (username, domain, password, ha1, ha1b, group_id) VALUES ('0990000999004','sip.openvno.net','','','',1);
INSERT INTO d200911200001_sub (username, domain, password, ha1, ha1b, group_id) VALUES ('0990000001009','sip.openvno.net','','','',1);

INSERT INTO d200911200001_adr (ip, proto, context_info) VALUES ('37.122.202.234','udp','MRFC4');
INSERT INTO d200911200001_adr (ip, proto, context_info) VALUES ('37.122.202.235','udp','MRFC4');
INSERT INTO d200911200001_adr (ip, proto, context_info) VALUES ('217.15.80.163','udp','0990000999004');
INSERT INTO d200911200001_adr (ip, proto, context_info) VALUES ('217.15.80.79','udp','0990000001009');

INSERT INTO d200911200001_act (account_code, update_date) VALUES ('0990000999004', now());
INSERT INTO d200911200001_act (account_code, update_date) VALUES ('0990000001009', now());
