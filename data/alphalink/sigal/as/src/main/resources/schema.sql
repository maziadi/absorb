drop table if exists exchange_information;
drop table if exists number;
drop table if exists line_information;
drop table if exists mobile_line_information;
drop table if exists emergency_translation;
drop table if exists emergency_holiday;

CREATE TABLE `emergency_holiday` (
  `day` date NOT NULL,
  `creation_date` datetime NOT NULL,
  `update_date` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`day`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `emergency_translation` (
  `insee_code` varchar(5) NOT NULL,
  `number` varchar(6) NOT NULL,
  `day_of_week` int(1) default NULL,
  `begin_hour` time default NULL,
  `end_hour` time default NULL,
  `idx` int(2) NOT NULL,
  `translated_number` varchar(15) NOT NULL,
  `update_date` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `exchange_information` (
  `account_code` varchar(15) NOT NULL default '',
  `creation_date` datetime NOT NULL,
  `update_date` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `max_inbound_calls` int(5) NOT NULL default '1',
  `max_outbound_calls` int(5) NOT NULL default '1',
  `max_calls` int(5) NOT NULL default '1',
  `inbound_numbering_plan` varchar(31) NOT NULL,
  `outbound_numbering_plan` varchar(31) NOT NULL,
  `locked` char(1) NOT NULL,
  `carrier_code` varchar(32) default NULL,
  PRIMARY KEY  (`account_code`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `line_information` (
  `account_code` varchar(15) NOT NULL,
  `subscriber_number` varchar(15) NOT NULL,
  `max_inbound_calls` int(5) NOT NULL default '1',
  `max_outbound_calls` int(5) NOT NULL default '1',
  `max_calls` int(5) NOT NULL default '1',
  `inbound_numbering_plan` varchar(31) NOT NULL,
  `outbound_numbering_plan` varchar(31) NOT NULL,
  `locked` char(1) NOT NULL,
  `carrier_code` varchar(32) default NULL,
  `creation_date` datetime NOT NULL,
  `update_date` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `trunk` char(1) NOT NULL default '0',
  `fixed_cid` char(1) NOT NULL default '0',
  `indication` char(1) NOT NULL default '0',
  `insee_code` varchar(5) NOT NULL default '99999',
  PRIMARY KEY  (`account_code`),
  UNIQUE KEY `subscriber_number` (`subscriber_number`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `mobile_line_information` (
  `account_code` varchar(15) NOT NULL,
  `msisdn` varchar(15) NOT NULL,
  `carrier_code` varchar(32) default NULL,
  `creation_date` datetime NOT NULL,
  `update_date` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`account_code`),
  UNIQUE KEY `msisdn` (`msisdn`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `number` (
  `number` varchar(31) NOT NULL,
  `redirect_to` varchar(31) default NULL,
  `portability_prefix` varchar(31) default NULL,
  `subscriber_number` varchar(31) default NULL,
  `presentation` char(1) default NULL,
  `insee_code` varchar(5) NOT NULL,
  `creation_date` datetime NOT NULL,
  `update_date` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `fax` char(1) NOT NULL,
  `voicemail` int(3) default NULL,
  PRIMARY KEY  (`number`),
  KEY `number_subscriber_number_fk` (`subscriber_number`),
  CONSTRAINT `number_subscriber_number_c` FOREIGN KEY (`subscriber_number`) REFERENCES `line_information` (`subscriber_number`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `vno_information` (
  `reference` varchar(15) NOT NULL default '',
  `creation_date` datetime NOT NULL,
  `update_date` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `max_calls` int(5) NOT NULL default '1'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
