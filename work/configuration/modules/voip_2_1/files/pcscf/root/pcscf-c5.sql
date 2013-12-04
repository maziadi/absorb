DELETE FROM domain;
DELETE FROM subscriber;
DELETE FROM address;
DELETE FROM dr_carriers;
DELETE FROM dr_gateways;
DELETE FROM dr_groups;
DELETE FROM dr_rules;
DELETE FROM account;

INSERT INTO dr_carriers (carrierid, gwlist, flags, description, update_date) VALUES ('1', '1=50,2=50', 1, 'carrier 1', now());

INSERT INTO dr_gateways (gwid, type, address, probe_mode, description) VALUES ('1', 1, '37.122.202.234:5060', 2, 'Asterisk Server in MRF-2-MAQUETTE');
INSERT INTO dr_gateways (gwid, type, address, probe_mode, description) VALUES ('2', 1, '37.122.202.235:5060', 2, 'Asterisk Server in MRF-3-MAQUETTE');
INSERT INTO dr_gateways (gwid, type, address, probe_mode, description) VALUES ('3', 2, '37.122.202.237:5060', 0, 'C5 : 0990000999001');

INSERT INTO dr_groups VALUES (1, '.*', '.*', 1, 'Everyone');
INSERT INTO dr_groups VALUES (2, '.*', '.*', 2, 'Everyone');

INSERT INTO dr_rules (groupid, prefix, gwlist, description) VALUES ('1', '', '#1', 'Default Route');
INSERT INTO dr_rules (groupid, prefix, gwlist, description) VALUES ('2', '0990000999001', '3', 'C5 : 0990000999001');

INSERT INTO domain (domain, last_modified) VALUES ('sip.openvno.net',now());
INSERT INTO domain (domain, last_modified) VALUES ('37.122.202.232',now());

INSERT INTO subscriber (username, domain, password, ha1, ha1b, group_id) VALUES ('0990000999001','sip.openvno.net','','d09164e46f5fe58f3627e0c0a42d0836','54651552e8bf0a303feabbe225c0cec8',1);
INSERT INTO subscriber (username, domain, password, ha1, ha1b, group_id) VALUES ('0990000999002','sip.openvno.net','ZFj8YW0mxg','d71cb90d34c9d2abdd3063949e3bb07e','07674ffe1b5b5e584b85534f29449eef',1);
INSERT INTO subscriber (username, domain, password, ha1, ha1b, group_id) VALUES ('0990000001008','sip.openvno.net','6x7Exx6QZ6','c82617e69e89a7663e3f8833874a32d9','fd3d8401781565bd1384d1b13765db48',1);

INSERT INTO address (ip, proto, context_info) VALUES ('37.122.202.234','udp','MRFC5');
INSERT INTO address (ip, proto, context_info) VALUES ('37.122.202.235','udp','MRFC5');
INSERT INTO address (ip, proto, context_info) VALUES ('217.15.80.195','udp','0990000999001');
INSERT INTO address (ip, proto, context_info) VALUES ('217.15.80.79','udp','REG_0990000001008');
INSERT INTO address (ip, proto, context_info) VALUES ('83.167.154.34','udp','REG_0990000999002');

INSERT INTO account (account_code, update_date) VALUES ('0990000999001', now());
INSERT INTO account (account_code, update_date) VALUES ('0990000001008', now());
INSERT INTO account (account_code, update_date) VALUES ('0990000999002', now());
