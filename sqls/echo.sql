-- MySQL dump 10.11
--
-- Host: localhost    Database: echo
-- ------------------------------------------------------
-- Server version	5.0.67-community-nt

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `concernments`
--

DROP TABLE IF EXISTS `concernments`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `concernments` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) default NULL,
  `tag_id` int(11) default NULL,
  `sort` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_concernments_on_user_id_and_sort` (`user_id`,`sort`),
  KEY `index_concernments_on_sort` (`sort`)
) ENGINE=InnoDB AUTO_INCREMENT=1305500939 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `concernments`
--

LOCK TABLES `concernments` WRITE;
/*!40000 ALTER TABLE `concernments` DISABLE KEYS */;
INSERT INTO `concernments` VALUES (373525301,110237153,387021202,0,'2010-03-04 15:16:22','2010-03-04 15:16:22'),(1070110500,1706849627,2066945243,0,'2010-03-04 15:16:22','2010-03-04 15:16:22'),(1305500938,1706849627,387021202,1,'2010-03-04 15:16:22','2010-03-04 15:16:22');
/*!40000 ALTER TABLE `concernments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `echo_details`
--

DROP TABLE IF EXISTS `echo_details`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `echo_details` (
  `id` int(11) NOT NULL auto_increment,
  `echo_id` int(11) default NULL,
  `user_id` int(11) default NULL,
  `visited` tinyint(1) default '0',
  `supported` tinyint(1) default '0',
  PRIMARY KEY  (`id`),
  KEY `index_echo_details_on_echo_id` (`echo_id`),
  KEY `index_echo_details_on_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `echo_details`
--

LOCK TABLES `echo_details` WRITE;
/*!40000 ALTER TABLE `echo_details` DISABLE KEYS */;
INSERT INTO `echo_details` VALUES (1,1,227792458,1,0);
/*!40000 ALTER TABLE `echo_details` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `echos`
--

DROP TABLE IF EXISTS `echos`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `echos` (
  `id` int(11) NOT NULL auto_increment,
  `visitor_count` int(11) default '0',
  `supporter_count` int(11) default '0',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `echos`
--

LOCK TABLES `echos` WRITE;
/*!40000 ALTER TABLE `echos` DISABLE KEYS */;
INSERT INTO `echos` VALUES (1,1,0),(2,0,0),(3,0,0),(4,0,0),(5,0,0),(6,0,0),(7,0,0),(8,0,0);
/*!40000 ALTER TABLE `echos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `feedbacks`
--

DROP TABLE IF EXISTS `feedbacks`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `feedbacks` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `email` varchar(255) default NULL,
  `message` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `feedbacks`
--

LOCK TABLES `feedbacks` WRITE;
/*!40000 ALTER TABLE `feedbacks` DISABLE KEYS */;
/*!40000 ALTER TABLE `feedbacks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `locales`
--

DROP TABLE IF EXISTS `locales`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `locales` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(255) default NULL,
  `name` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_locales_on_code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=2106599820 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `locales`
--

LOCK TABLES `locales` WRITE;
/*!40000 ALTER TABLE `locales` DISABLE KEYS */;
INSERT INTO `locales` VALUES (1935262019,'en','en'),(2106599819,'de','de');
/*!40000 ALTER TABLE `locales` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `memberships`
--

DROP TABLE IF EXISTS `memberships`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `memberships` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) default NULL,
  `organisation` varchar(255) default NULL,
  `position` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=742894933 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `memberships`
--

LOCK TABLES `memberships` WRITE;
/*!40000 ALTER TABLE `memberships` DISABLE KEYS */;
INSERT INTO `memberships` VALUES (742894932,1706849627,'Greenpeace','Member','2010-03-04 15:16:23','2010-03-04 15:16:23');
/*!40000 ALTER TABLE `memberships` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `profiles`
--

DROP TABLE IF EXISTS `profiles`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `profiles` (
  `id` int(11) NOT NULL auto_increment,
  `first_name` varchar(255) default NULL,
  `last_name` varchar(255) default NULL,
  `female` tinyint(1) default NULL,
  `city` varchar(255) default NULL,
  `country` varchar(255) default NULL,
  `about_me` text,
  `motivation` text,
  `birthday` date default NULL,
  `user_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `avatar_file_name` varchar(255) default NULL,
  `avatar_content_type` varchar(255) default NULL,
  `avatar_file_size` int(11) default NULL,
  `avatar_updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2144956510 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `profiles`
--

LOCK TABLES `profiles` WRITE;
/*!40000 ALTER TABLE `profiles` DISABLE KEYS */;
INSERT INTO `profiles` VALUES (34307863,'Edi','Tor',NULL,NULL,NULL,NULL,NULL,NULL,1290924475,'2010-03-04 15:16:23','2010-03-04 15:16:23',NULL,NULL,NULL,NULL),(1164650630,'Admin','Test',NULL,NULL,NULL,NULL,NULL,NULL,135138679,'2010-03-04 15:16:23','2010-03-04 15:16:23',NULL,NULL,NULL,NULL),(1349361420,'Ben','Test',NULL,NULL,NULL,NULL,NULL,NULL,110237153,'2010-03-04 15:16:23','2010-03-04 15:16:23',NULL,NULL,NULL,NULL),(1499116550,'User','Test',NULL,NULL,NULL,NULL,NULL,NULL,227792458,'2010-03-04 15:16:23','2010-03-04 15:16:23',NULL,NULL,NULL,NULL),(2144956509,'Joe','Test',0,'Berlin','Germany','Pantha Rei.','I am idealist.','2009-10-30',1706849627,'2010-03-04 15:16:23','2010-03-04 15:16:23',NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `profiles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `reports`
--

DROP TABLE IF EXISTS `reports`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `reports` (
  `id` int(11) NOT NULL auto_increment,
  `reporter_id` int(11) default NULL,
  `suspect_id` int(11) default NULL,
  `reason` text,
  `done` tinyint(1) default '0',
  `decision` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1808400198 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `reports`
--

LOCK TABLES `reports` WRITE;
/*!40000 ALTER TABLE `reports` DISABLE KEYS */;
INSERT INTO `reports` VALUES (430157098,227792458,1706849627,'Over and over again!',1,'But we are all friends.','2010-03-04 15:16:23','2010-03-04 15:16:23'),(1808400197,227792458,1706849627,'Joe should really be reported.',0,' ','2010-03-04 15:16:23','2010-03-04 15:16:23');
/*!40000 ALTER TABLE `reports` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `roles` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(40) default NULL,
  `authorizable_type` varchar(40) default NULL,
  `authorizable_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2144527706 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES (343340186,'censor',NULL,NULL,'2010-03-04 15:16:23','2010-03-04 15:16:23'),(1742147595,'editor',NULL,NULL,'2010-03-04 15:16:23','2010-03-04 15:16:23'),(2144527705,'admin',NULL,NULL,'2010-03-04 15:16:23','2010-03-04 15:16:23');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `roles_users`
--

DROP TABLE IF EXISTS `roles_users`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `roles_users` (
  `user_id` int(11) default NULL,
  `role_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `roles_users`
--

LOCK TABLES `roles_users` WRITE;
/*!40000 ALTER TABLE `roles_users` DISABLE KEYS */;
INSERT INTO `roles_users` VALUES (1290924475,1742147595,NULL,NULL),(135138679,2144527705,NULL,NULL);
/*!40000 ALTER TABLE `roles_users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `schema_migrations`
--

DROP TABLE IF EXISTS `schema_migrations`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `schema_migrations` (
  `version` varchar(255) NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `schema_migrations`
--

LOCK TABLES `schema_migrations` WRITE;
/*!40000 ALTER TABLE `schema_migrations` DISABLE KEYS */;
INSERT INTO `schema_migrations` VALUES ('20090825095800'),('20090825170636'),('20090827052026'),('20090827071723'),('20090827072846'),('20090827160621'),('20090829092843'),('20090912071928'),('20090915070848'),('20090915133056'),('20090924125806'),('20090930145231'),('20090930184501'),('20091008104532'),('20091027084559'),('20091027160730'),('20091030172204'),('20091030183251'),('20091031113224'),('20091031124730'),('20091102155547'),('20091114161154'),('20091114182343'),('20091117175250'),('20091120151337'),('20091120192909'),('20091124134642'),('20091128180020'),('20091202050840'),('20091202191941'),('20091203141234'),('20091207054420');
/*!40000 ALTER TABLE `schema_migrations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `sessions` (
  `id` int(11) NOT NULL auto_increment,
  `session_id` varchar(255) NOT NULL,
  `data` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_sessions_on_session_id` (`session_id`),
  KEY `index_sessions_on_updated_at` (`updated_at`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `sessions`
--

LOCK TABLES `sessions` WRITE;
/*!40000 ALTER TABLE `sessions` DISABLE KEYS */;
INSERT INTO `sessions` VALUES (1,'feed426fea606f52537c6627daf89866','BAh7CyIYdXNlcl9jcmVkZW50aWFsc19pZGkEStaTDSIVdXNlcl9jcmVkZW50\naWFscyIBgDZjZGUwNjc0NjU3YThhMzEzY2U5NTJkZjk3OWRlMjgzMDMwOWFh\nNGMxMWNhNjU4MDVkZDAwYmZkYzY1ZGJjYzJmNWUzNjcxODY2MGExZDJlNjhj\nMWEwOGMyNzZkOTk2NzYzOTg1ZDJmMDZmZDNkMDc2ZWI3YmM0ZDk3YjFlMzE3\nOhBfY3NyZl90b2tlbiIxU1NobkRlWStOSzFPbU5nSWkzRi9RSDJ4akRSaTJO\nMHJJSDZYdTFuZmZtbz06DnJldHVybl90byIQL2VuL2Nvbm5lY3QiCmZsYXNo\nSUM6J0FjdGlvbkNvbnRyb2xsZXI6OkZsYXNoOjpGbGFzaEhhc2h7BzoKZXJy\nb3IwOgtub3RpY2UwBjoKQHVzZWR7BzsIRjsJRjoVY3VycmVudF9wcm9wb3Nh\nbFsNaQTPMkYnbCsHRCCkUmwrByieK0ZsKwd7TahVaQTke0gUbCsHAIQnSWwr\nBx3vH05pBDf1syU=\n','2010-03-04 15:16:40','2010-03-05 13:41:47');
/*!40000 ALTER TABLE `sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `statement_documents`
--

DROP TABLE IF EXISTS `statement_documents`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `statement_documents` (
  `id` int(11) NOT NULL auto_increment,
  `title` varchar(255) default NULL,
  `text` text,
  `author_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1910015855 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `statement_documents`
--

LOCK TABLES `statement_documents` WRITE;
/*!40000 ALTER TABLE `statement_documents` DISABLE KEYS */;
INSERT INTO `statement_documents` VALUES (15998671,'Fourth Proposal','I think we should have a fourth proposal as well!',1290924475),(21847541,'Test Question?','The Question is: is this a question?',1290924475),(65737242,'Fifth Proposal','I think we should have a fifth proposal as well!',1290924475),(253224912,'Sixth Proposal','I think we should have a sixth proposal as well!',1290924475),(702532647,'Third Proposal','I think we should have a third proposal as well!',227792458),(1110494196,'A better first proposal','I think, a better first proposal would be a better one!',110237153),(1342428310,'This proposal should not be seen...','unless you are an editor',1290924475),(1723581017,'A first proposal!','I think, a good proposal would be a first one!',1290924475),(1764314166,'Second Proposal','I think we should have a second proposal as well!',227792458),(1910015854,'Inbetween Proposal','I think we should have a proposal inbetween as well!',1290924475);
/*!40000 ALTER TABLE `statement_documents` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `statements`
--

DROP TABLE IF EXISTS `statements`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `statements` (
  `id` int(11) NOT NULL auto_increment,
  `type` varchar(255) default NULL,
  `parent_id` int(11) default NULL,
  `root_id` int(11) default NULL,
  `document_id` int(11) default NULL,
  `creator_id` int(11) default NULL,
  `work_package_id` int(11) default NULL,
  `echo_id` int(11) default NULL,
  `category_id` int(11) default NULL,
  `state` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2109843789 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `statements`
--

LOCK TABLES `statements` WRITE;
/*!40000 ALTER TABLE `statements` DISABLE KEYS */;
INSERT INTO `statements` VALUES (340294628,'Proposal',2109843788,2109843788,702532647,227792458,NULL,3,1664239895,1,'2010-03-04 15:16:23','2010-03-04 15:19:10'),(632550711,'Proposal',2109843788,2109843788,1342428310,1290924475,NULL,NULL,1664239895,0,'2010-03-04 15:16:23','2010-03-04 15:16:23'),(658911951,'Proposal',2109843788,2109843788,15998671,1290924475,NULL,5,1664239895,1,'2010-03-04 15:16:23','2010-03-04 15:19:10'),(1177263656,'Proposal',2109843788,2109843788,1910015854,1290924475,NULL,7,1664239895,1,'2010-03-04 15:16:23','2010-03-04 15:19:27'),(1227326464,'Proposal',2109843788,2109843788,253224912,1290924475,NULL,2,1664239895,1,'2010-03-04 15:16:23','2010-03-04 15:19:10'),(1310715677,'Proposal',2109843788,2109843788,65737242,1290924475,NULL,4,1664239895,1,'2010-03-04 15:16:23','2010-03-04 15:19:10'),(1386487876,'Proposal',2109843788,2109843788,1764314166,227792458,NULL,6,1664239895,1,'2010-03-04 15:16:23','2010-03-04 15:19:10'),(1437093243,'Proposal',2109843788,2109843788,1723581017,1290924475,NULL,8,1664239895,1,'2010-03-04 15:16:23','2010-03-04 15:19:27'),(1979119882,'ImprovementProposal',1437093243,2109843788,1110494196,110237153,NULL,NULL,1664239895,1,'2010-03-04 15:16:23','2010-03-04 15:16:23'),(2109843788,'Question',NULL,NULL,21847541,1290924475,NULL,1,1664239895,1,'2010-03-04 15:16:23','2010-03-04 15:19:10');
/*!40000 ALTER TABLE `statements` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tags`
--

DROP TABLE IF EXISTS `tags`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `tags` (
  `id` int(11) NOT NULL auto_increment,
  `value` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2066945245 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `tags`
--

LOCK TABLES `tags` WRITE;
/*!40000 ALTER TABLE `tags` DISABLE KEYS */;
INSERT INTO `tags` VALUES (387021202,'Energy','2010-03-04 15:16:23','2010-03-04 15:16:23'),(1591410034,'echocracy','2010-03-04 15:16:23','2010-03-04 15:16:23'),(1664239895,'echonomyJAM','2010-03-04 15:16:23','2010-03-04 15:16:23'),(2066945243,'Water','2010-03-04 15:16:23','2010-03-04 15:16:23'),(2066945244,'echo','2010-03-04 15:17:23','2010-03-04 15:17:23');
/*!40000 ALTER TABLE `tags` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `translations`
--

DROP TABLE IF EXISTS `translations`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `translations` (
  `id` int(11) NOT NULL auto_increment,
  `key` varchar(255) default NULL,
  `raw_key` varchar(255) default NULL,
  `value` text,
  `pluralization_index` int(11) default '1',
  `locale_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_translations_on_locale_id_and_key_and_pluralization_index` (`locale_id`,`key`,`pluralization_index`),
  KEY `index_translations_on_locale_id_and_raw_key` (`locale_id`,`raw_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `translations`
--

LOCK TABLES `translations` WRITE;
/*!40000 ALTER TABLE `translations` DISABLE KEYS */;
/*!40000 ALTER TABLE `translations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `users` (
  `id` int(11) NOT NULL auto_increment,
  `email` varchar(255) NOT NULL,
  `crypted_password` varchar(255) default NULL,
  `password_salt` varchar(255) default NULL,
  `persistence_token` varchar(255) NOT NULL,
  `perishable_token` varchar(255) NOT NULL,
  `login_count` int(11) NOT NULL default '0',
  `failed_login_count` int(11) NOT NULL default '0',
  `last_request_at` datetime default NULL,
  `current_login_at` datetime default NULL,
  `last_login_at` datetime default NULL,
  `current_login_ip` varchar(255) default NULL,
  `last_login_ip` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `active` tinyint(1) NOT NULL default '0',
  `openid_identifier` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1706849628 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (110237153,'ben@echologic.org','902fcb59b634aaffc39766e27c90e81e4f8c3ea9ef9e6401c0d7b608a256e0b0ddbe50958f1bb519f943c7f8372f44aeb5b6651236350c9baeb34b304f2f8bf4','2a770639b06c5c2cec3032533f513f17fb3b02a183eba411da5f9878ba010bcf0b51c737d556c6348a71e696b6365fadbc1d6dac3ca6e710f92aa9c197172fa3','6cde0674657a8a313ce952df979de2830309aa4c11ca65805dd00bfdc65dbcc2f5e36718660a1d2e68c1a08c276d996763985d2f06fd3d076eb7bc4d97b1e317','LIMwSPN6OzmHgz23mx5Q',0,0,NULL,NULL,NULL,NULL,NULL,'2010-03-04 15:16:24','2010-03-04 15:16:24',1,NULL),(135138679,'admin@echologic.org','6d0154396238fce4cd06b9d8336887beb5202ddd890cdcd8fdb1a72988f798ef29c973b60b0a17d3a75b7376e164fbb8edce0bea3c7da9684b8d4646d396e9df','d2b9c107db6c83cb1608d5e7a8433445d70d7f8575efd165ae18f85904af49888874f0c07747a154a256d8685b2212b649255cb7107cc60083ce1673128e7c5e','6cde0674657a8a313ce952df979de2830309aa4c11ca65805dd00bfdc65dbcc2f5e36718660a1d2e68c1a08c276d996763985d2f06fd3d076eb7bc4d97b1e317','bQsRK81kauetg9hStNOA',0,0,'2010-03-04 15:18:17',NULL,NULL,NULL,NULL,'2010-03-04 15:16:24','2010-03-04 15:18:17',1,NULL),(227792458,'user@echologic.org','f3b2cf17a3b3af1dc8b975874a0af640e364b395808aa06a46950a8f04ef6042da34930081bec18e9ab766e2854491495c577d1ea1f0167ede80774d2e87dffe','f8266b969df033785ffb609b4c21d56c67ad502ef83c69274fc390fb06affefc6960674e75e8cad162b60a9ddaf6c9d57ea587da2f6ce7c7a3dcf8da5861f880','6cde0674657a8a313ce952df979de2830309aa4c11ca65805dd00bfdc65dbcc2f5e36718660a1d2e68c1a08c276d996763985d2f06fd3d076eb7bc4d97b1e317','Oh3i_4pRcuZQjeshx92S',3,0,'2010-03-05 13:41:46','2010-03-04 16:24:50','2010-03-04 15:32:55','127.0.0.1','127.0.0.1','2010-03-04 15:16:24','2010-03-05 13:41:46',1,NULL),(1290924475,'editor@echologic.org','cf393cd04fc9dc896697ce0b53a5b2cecbf5167dfa7499c2d055c1c6d8b6896f3e8d9f72d39587fa4e0143dfd7b63e3329402e3da26b9e0cb01e3c5bf69740da','78f615073c8c37a0e4c46435ea835258c4a61349577ffdce266e37fc83b8cce8b6266a1acd1b4eeca1fb65267955ff5d2710d59c58d20616482f5c25c865ddfc','6cde0674657a8a313ce952df979de2830309aa4c11ca65805dd00bfdc65dbcc2f5e36718660a1d2e68c1a08c276d996763985d2f06fd3d076eb7bc4d97b1e317','WT9VZP_4n7AxQDxVW8VK',0,0,NULL,NULL,NULL,NULL,NULL,'2010-03-04 15:16:24','2010-03-04 15:16:24',1,NULL),(1706849627,'joe@echologic.org','e501b2bc5814d5cab991b9c04fa1189bdc65178466f77a161dac046ba7de352255bab28bb872e68f3c4d161b84ace012c1f0146355c73ebd4240631954f1e7cd','Av-EvhZ9VR4U2QkMCeXZ','31c4df467032bed4798f00e1866fd4965d30afc4a7b9c5073f61aa92f34ed8ab81e57a40e4bd0acd332dcac16df95bc7983cf0f2545462d048fdcd15062c4d52','kSNhE15rM3F2LxvG_e5N',0,0,NULL,NULL,NULL,NULL,NULL,'2010-03-04 15:16:24','2010-03-04 15:16:24',1,NULL);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `web_profiles`
--

DROP TABLE IF EXISTS `web_profiles`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `web_profiles` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) default NULL,
  `location` varchar(255) default NULL,
  `sort` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_web_profiles_on_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1759814118 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `web_profiles`
--

LOCK TABLES `web_profiles` WRITE;
/*!40000 ALTER TABLE `web_profiles` DISABLE KEYS */;
INSERT INTO `web_profiles` VALUES (982785419,227792458,'http://blog.com/user',0,'2010-03-04 15:16:24','2010-03-04 15:16:24'),(1315399100,227792458,'http://twitter.com/user',0,'2010-03-04 15:16:24','2010-03-04 15:16:24'),(1759814117,1706849627,'http://twitter.com/joe',0,'2010-03-04 15:16:24','2010-03-04 15:16:24');
/*!40000 ALTER TABLE `web_profiles` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2010-03-05 18:25:11
