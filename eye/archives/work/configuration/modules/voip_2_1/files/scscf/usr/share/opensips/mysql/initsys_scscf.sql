--
-- Table structure for table `acc`
--

CREATE TABLE `acc` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `method` char(16) NOT NULL default '',
  `from_tag` char(64) NOT NULL default '',
  `to_tag` char(64) NOT NULL default '',
  `callid` char(64) NOT NULL default '',
  `sip_code` char(3) NOT NULL default '',
  `sip_reason` char(32) NOT NULL default '',
  `time` datetime NOT NULL,
  `from_uri` varchar(64) NOT NULL,
  `to_uri` varchar(64) NOT NULL,
  `account_code` varchar(16) NOT NULL,
  `carrier_code` varchar(64) NOT NULL,
  `evaluated` int(1) default NULL,
  PRIMARY KEY  (`id`),
  KEY `callid_idx` (`callid`),
  KEY `evaluated` (`evaluated`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `address`
--

CREATE TABLE `address` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `grp` smallint(5) unsigned NOT NULL default '0',
  `ip_addr` char(15) NOT NULL,
  `mask` tinyint(4) NOT NULL default '32',
  `port` smallint(5) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `carrierfailureroute`
--

CREATE TABLE `carrierfailureroute` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `carrier` int(10) unsigned NOT NULL default '0',
  `domain` char(64) NOT NULL default '',
  `scan_prefix` char(64) NOT NULL default '',
  `host_name` char(128) NOT NULL default '',
  `reply_code` char(3) NOT NULL default '',
  `flags` int(11) unsigned NOT NULL default '0',
  `mask` int(11) unsigned NOT NULL default '0',
  `next_domain` char(64) NOT NULL default '',
  `description` char(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `carrierroute`
--

CREATE TABLE `carrierroute` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `carrier` int(10) unsigned NOT NULL default '0',
  `domain` char(64) NOT NULL default '',
  `scan_prefix` char(64) NOT NULL default '',
  `flags` int(11) unsigned NOT NULL default '0',
  `mask` int(11) unsigned NOT NULL default '0',
  `prob` float NOT NULL default '0',
  `strip` int(11) unsigned NOT NULL default '0',
  `rewrite_host` char(128) NOT NULL default '',
  `rewrite_prefix` char(64) NOT NULL default '',
  `rewrite_suffix` char(64) NOT NULL default '',
  `description` char(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `domain`
--

CREATE TABLE `domain` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `domain` char(64) NOT NULL default '',
  `last_modified` datetime NOT NULL default '1900-01-01 00:00:01',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `domain_idx` (`domain`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `missed_calls`
--

CREATE TABLE `missed_calls` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `method` char(16) NOT NULL default '',
  `from_tag` char(64) NOT NULL default '',
  `to_tag` char(64) NOT NULL default '',
  `callid` char(64) NOT NULL default '',
  `sip_code` char(3) NOT NULL default '',
  `sip_reason` char(32) NOT NULL default '',
  `time` datetime NOT NULL,
  `from_uri` varchar(64) NOT NULL,
  `to_uri` varchar(64) NOT NULL,
  `account_code` varchar(16) NOT NULL,
  `carrier_code` varchar(64) NOT NULL,
  `evaluated` int(1) default NULL,
  PRIMARY KEY  (`id`),
  KEY `callid_idx` (`callid`),
  KEY `evaluated` (`evaluated`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

--
-- Table structure for table `route_tree`
--

CREATE TABLE `route_tree` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `carrier` char(64) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `trusted`
--

CREATE TABLE `trusted` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `src_ip` char(50) NOT NULL,
  `proto` char(4) NOT NULL,
  `from_pattern` char(64) default NULL,
  `tag` char(32) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `version`
--

CREATE TABLE `version` (
  `table_name` varchar(32) NOT NULL,
  `table_version` int(10) unsigned NOT NULL default '0',
  UNIQUE KEY `t_name_idx` (`table_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `version`
--

INSERT INTO `version` VALUES ('acc',5);
INSERT INTO `version` VALUES ('address',4);
INSERT INTO `version` VALUES ('carrierroute',3);
INSERT INTO `version` VALUES ('carrierfailureroute',2);
INSERT INTO `version` VALUES ('domain',2);
INSERT INTO `version` VALUES ('missed_calls',4);
INSERT INTO `version` VALUES ('route_tree',2);
INSERT INTO `version` VALUES ('trusted',5);
