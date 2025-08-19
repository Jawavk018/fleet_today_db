--enviroment

INSERT INTO config.environment (environment_sno, environment_name) VALUES (1, 'local');
INSERT INTO config.environment (environment_sno, environment_name) VALUES (2, 'development');
INSERT INTO config.environment (environment_sno, environment_name) VALUES (3, 'testing');
INSERT INTO config.environment (environment_sno, environment_name) VALUES (4, 'staging');
INSERT INTO config.environment (environment_sno, environment_name) VALUES (5, 'production');


--config_key

INSERT INTO config.config_key (config_key_sno, config_key_attribute, encrypt_type_cd) VALUES (1, 'db.schema.key', NULL);
INSERT INTO config.config_key (config_key_sno, config_key_attribute, encrypt_type_cd) VALUES (2, 'content.type', NULL);
INSERT INTO config.config_key (config_key_sno, config_key_attribute, encrypt_type_cd) VALUES (3, 'access.control.allow.origin', NULL);
INSERT INTO config.config_key (config_key_sno, config_key_attribute, encrypt_type_cd) VALUES (4, 'server.port', NULL);
INSERT INTO config.config_key (config_key_sno, config_key_attribute, encrypt_type_cd) VALUES (5, 'http.port.no', NULL);
INSERT INTO config.config_key (config_key_sno, config_key_attribute, encrypt_type_cd) VALUES (6, 'master.key.file.name', NULL);
INSERT INTO config.config_key (config_key_sno, config_key_attribute, encrypt_type_cd) VALUES (7, 'keystore.file.name', NULL);
INSERT INTO config.config_key (config_key_sno, config_key_attribute, encrypt_type_cd) VALUES (8, 'keystore.type', NULL);
INSERT INTO config.config_key (config_key_sno, config_key_attribute, encrypt_type_cd) VALUES (9, 'cryptography.algorithm', NULL);
INSERT INTO config.config_key (config_key_sno, config_key_attribute, encrypt_type_cd) VALUES (10, 'file.key.password', NULL);
INSERT INTO config.config_key (config_key_sno, config_key_attribute, encrypt_type_cd) VALUES (11, 'file.key.alias.name', NULL);

INSERT INTO config.config_key (config_key_sno, config_key_attribute, encrypt_type_cd) VALUES (12, 'db.port.no', NULL);
INSERT INTO config.config_key (config_key_sno, config_key_attribute, encrypt_type_cd) VALUES (13, 'db.host', NULL);
INSERT INTO config.config_key (config_key_sno, config_key_attribute, encrypt_type_cd) VALUES (14, 'database.name', NULL);
INSERT INTO config.config_key (config_key_sno, config_key_attribute, encrypt_type_cd) VALUES (15, 'db.user.name', NULL);
INSERT INTO config.config_key (config_key_sno, config_key_attribute, encrypt_type_cd) VALUES (16, 'db.password', NULL);
INSERT INTO config.config_key (config_key_sno, config_key_attribute, encrypt_type_cd) VALUES (17, 'db.conn.pool.size', NULL);

INSERT INTO config.config_key (config_key_sno, config_key_attribute, encrypt_type_cd) VALUES (18, 'push.server.key', NULL);

--module

INSERT INTO config.module (module_sno,environment_sno, module_name) VALUES (1,1, 'bustoday');

--sub_module

INSERT INTO config.sub_module (sub_module_sno, module_sno, sub_module_name) VALUES (1, 1, 'portal');
INSERT INTO config.sub_module (sub_module_sno, module_sno, sub_module_name) VALUES (2, 1, 'operator');
INSERT INTO config.sub_module (sub_module_sno, module_sno, sub_module_name) VALUES (3, 1, 'master');
INSERT INTO config.sub_module (sub_module_sno, module_sno, sub_module_name) VALUES (4, 1, 'driver');
INSERT INTO config.sub_module (sub_module_sno, module_sno, sub_module_name) VALUES (5, 1, 'notification');
INSERT INTO config.sub_module (sub_module_sno, module_sno, sub_module_name) VALUES (6, 1, 'cron');
INSERT INTO config.sub_module (sub_module_sno, module_sno, sub_module_name) VALUES (7, 1, 'rent');
INSERT INTO config.sub_module (sub_module_sno, module_sno, sub_module_name) VALUES (8, 1, 'media');
INSERT INTO config.sub_module (sub_module_sno, module_sno, sub_module_name) VALUES (9, 1, 'tyre');

/*
INSERT INTO config.sub_module (sub_module_sno, module_sno, sub_module_name) VALUES (3, 1, 'sales/e-commerce');
INSERT INTO config.sub_module (sub_module_sno, module_sno, sub_module_name) VALUES (4, 1, 'service providers');
 INSERT INTO config.sub_module (sub_module_sno, module_sno, sub_module_name) VALUES (5, 1, 'timesheet');
INSERT INTO config.sub_module (sub_module_sno, module_sno, sub_module_name) VALUES (6, 1, 'contract'); */

--config

--portal service
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (1, 1, 1, 1, 1, 'portal');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (2, 1, 1, 1, 2, 'application/json;charset=utf-8');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (3, 1, 1, 1, 3, '*');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (4, 1, 1, 1, 4, '8080');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (5, 1, 1, 1, 5, '8052');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (6, 1, 1, 1, 6, './src/main/resources/yInhUOEDMv2PZqJWc2j3id0tZVYD3vBt.key');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (7, 1, 1, 1, 7, 'EzvxzEy7/EGAEgV728ADN2le3hTuNuNSmJdnGlJMztY0pWQNb0C4pg==');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (8, 1, 1, 1, 8, 'JCEKS');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (9, 1, 1, 1, 9, 'AES');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (10, 1, 1, 1, 10, '1maRuaJV8JApV07CyhDnbA1zpy/cQixHs91aClA1pCk0pWQNb0C4pg==');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (11, 1, 1, 1, 11, '3xCsKXY9E/8QI1Db7z8Xrex4IMuHhvJfhfeZ+McwTSY0pWQNb0C4pg==');

--portal db
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (12, 1, 1, 1, 12, '5432');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (13, 1, 1, 1, 13, 'localhost');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (14, 1, 1, 1, 14, 'bus_db');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (15, 1, 1, 1, 15, 'bus_admin');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (16, 1, 1, 1, 16, 'bus123');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (17, 1, 1, 1, 17, '2000');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (18, 1, 1, 1, 18, 'AAAA_vArJw0:APA91bG-EhDsfDdv7m_o3RXI1-2eBegndpW1sI-OdOqULO31k7MkilW_o4DnlDfMOA3sfPMlTBvKz0Ysx6v1-_v_BQmZwQAKCO6T3ZovWVDYPdGu-59WWdHshH2VW3ADdkjnWxKb862C');


--operator management service
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (19, 1, 1, 2, 1, 'operator');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (20, 1, 1, 2, 2, 'application/json;charset=utf-8');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (21, 1, 1, 2, 3, '*');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (22, 1, 1, 2, 4, '8080');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (23, 1, 1, 2, 5, '8053');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (24, 1, 1, 2, 6, './src/main/resources/yInhUOEDMv2PZqJWc2j3id0tZVYD3vBt.key');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (25, 1, 1, 2, 7, 'EzvxzEy7/EGAEgV728ADN2le3hTuNuNSmJdnGlJMztY0pWQNb0C4pg==');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (26, 1, 1, 2, 8, 'JCEKS');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (27, 1, 1, 2, 9, 'AES');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (28, 1, 1, 2, 10, '1maRuaJV8JApV07CyhDnbA1zpy/cQixHs91aClA1pCk0pWQNb0C4pg==');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (29, 1, 1, 2, 11, '3xCsKXY9E/8QI1Db7z8Xrex4IMuHhvJfhfeZ+McwTSY0pWQNb0C4pg==');

--operator management db
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (30, 1, 1, 2, 12, '5432');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (31, 1, 1, 2, 13, 'localhost');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (32, 1, 1, 2, 14, 'bus_db');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (33, 1, 1, 2, 15, 'bus_admin');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (34, 1, 1, 2, 16, 'bus123');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (35, 1, 1, 2, 17, '2000');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (36, 1, 1, 2, 18, 'AAAA_vArJw0:APA91bG-EhDsfDdv7m_o3RXI1-2eBegndpW1sI-OdOqULO31k7MkilW_o4DnlDfMOA3sfPMlTBvKz0Ysx6v1-_v_BQmZwQAKCO6T3ZovWVDYPdGu-59WWdHshH2VW3ADdkjnWxKb862C');



--master service
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (37, 1, 1, 3, 1, 'master');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (38, 1, 1, 3, 2, 'application/json;charset=utf-8');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (39, 1, 1, 3, 3, '*');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (40, 1, 1, 3, 4, '8080');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (41, 1, 1, 3, 5, '8054');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (42, 1, 1, 3, 6, './src/main/resources/yInhUOEDMv2PZqJWc2j3id0tZVYD3vBt.key');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (43, 1, 1, 3, 7, 'EzvxzEy7/EGAEgV728ADN2le3hTuNuNSmJdnGlJMztY0pWQNb0C4pg==');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (44, 1, 1, 3, 8, 'JCEKS');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (45, 1, 1, 3, 9, 'AES');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (46, 1, 1, 3, 10, '1maRuaJV8JApV07CyhDnbA1zpy/cQixHs91aClA1pCk0pWQNb0C4pg==');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (47, 1, 1, 3, 11, '3xCsKXY9E/8QI1Db7z8Xrex4IMuHhvJfhfeZ+McwTSY0pWQNb0C4pg==');

--master db
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (48, 1, 1, 3, 12, '5432');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (49, 1, 1, 3, 13, 'localhost');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (50, 1, 1, 3, 14, 'bus_db');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (51, 1, 1, 3, 15, 'bus_admin');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (52, 1, 1, 3, 16, 'bus123');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (53, 1, 1, 3, 17, '2000');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (54, 1, 1, 3, 18, 'AAAA_vArJw0:APA91bG-EhDsfDdv7m_o3RXI1-2eBegndpW1sI-OdOqULO31k7MkilW_o4DnlDfMOA3sfPMlTBvKz0Ysx6v1-_v_BQmZwQAKCO6T3ZovWVDYPdGu-59WWdHshH2VW3ADdkjnWxKb862C');



--driver service
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (55, 1, 1, 4, 1, 'driver');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (56, 1, 1, 4, 2, 'application/json;charset=utf-8');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (57, 1, 1, 4, 3, '*');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (58, 1, 1, 4, 4, '8080');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (59, 1, 1, 4, 5, '8055');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (60, 1, 1, 4, 6, './src/main/resources/yInhUOEDMv2PZqJWc2j3id0tZVYD3vBt.key');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (61, 1, 1, 4, 7, 'EzvxzEy7/EGAEgV728ADN2le3hTuNuNSmJdnGlJMztY0pWQNb0C4pg==');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (62, 1, 1, 4, 8, 'JCEKS');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (63, 1, 1, 4, 9, 'AES');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (64, 1, 1, 4, 10, '1maRuaJV8JApV07CyhDnbA1zpy/cQixHs91aClA1pCk0pWQNb0C4pg==');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (65, 1, 1, 4, 11, '3xCsKXY9E/8QI1Db7z8Xrex4IMuHhvJfhfeZ+McwTSY0pWQNb0C4pg==');

--driver db
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (66, 1, 1, 4, 12, '5432');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (67, 1, 1, 4, 13, 'localhost');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (68, 1, 1, 4, 14, 'bus_db');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (69, 1, 1, 4, 15, 'bus_admin');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (70, 1, 1, 4, 16, 'bus123');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (71, 1, 1, 4, 17, '2000');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (72, 1, 1, 4, 18, 'AAAA_vArJw0:APA91bG-EhDsfDdv7m_o3RXI1-2eBegndpW1sI-OdOqULO31k7MkilW_o4DnlDfMOA3sfPMlTBvKz0Ysx6v1-_v_BQmZwQAKCO6T3ZovWVDYPdGu-59WWdHshH2VW3ADdkjnWxKb862C');


--notification service
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (73, 1, 1, 5, 1, 'notification');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (74, 1, 1, 5, 2, 'application/json;charset=utf-8');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (75, 1, 1, 5, 3, '*');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (76, 1, 1, 5, 4, '8080');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (77, 1, 1, 5, 5, '8056');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (78, 1, 1, 5, 6, './src/main/resources/yInhUOEDMv2PZqJWc2j3id0tZVYD3vBt.key');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (79, 1, 1, 5, 7, 'EzvxzEy7/EGAEgV728ADN2le3hTuNuNSmJdnGlJMztY0pWQNb0C4pg==');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (80, 1, 1, 5, 8, 'JCEKS');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (81, 1, 1, 5, 9, 'AES');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (82, 1, 1, 5, 10, '1maRuaJV8JApV07CyhDnbA1zpy/cQixHs91aClA1pCk0pWQNb0C4pg==');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (83, 1, 1, 5, 11, '3xCsKXY9E/8QI1Db7z8Xrex4IMuHhvJfhfeZ+McwTSY0pWQNb0C4pg==');

--notification db
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (84, 1, 1, 5, 12, '5432');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (85, 1, 1, 5, 13, 'localhost');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (86, 1, 1, 5, 14, 'bus_db');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (87, 1, 1, 5, 15, 'bus_admin');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (88, 1, 1, 5, 16, 'bus123');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (89, 1, 1, 5, 17, '2000');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (90, 1, 1, 5, 18, 'AAAA_vArJw0:APA91bG-EhDsfDdv7m_o3RXI1-2eBegndpW1sI-OdOqULO31k7MkilW_o4DnlDfMOA3sfPMlTBvKz0Ysx6v1-_v_BQmZwQAKCO6T3ZovWVDYPdGu-59WWdHshH2VW3ADdkjnWxKb862C');


--cron service
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (91, 1, 1, 6, 1, 'cron');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (92, 1, 1, 6, 2, 'application/json;charset=utf-8');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (93, 1, 1, 6, 3, '*');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (94, 1, 1, 6, 4, '8080');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (95, 1, 1, 6, 5, '8057');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (96, 1, 1, 6, 6, './src/main/resources/yInhUOEDMv2PZqJWc2j3id0tZVYD3vBt.key');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (97, 1, 1, 6, 7, 'EzvxzEy7/EGAEgV728ADN2le3hTuNuNSmJdnGlJMztY0pWQNb0C4pg==');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (98, 1, 1, 6, 8, 'JCEKS');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (99, 1, 1, 6, 9, 'AES');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (100, 1, 1, 6, 10, '1maRuaJV8JApV07CyhDnbA1zpy/cQixHs91aClA1pCk0pWQNb0C4pg==');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (101, 1, 1, 6, 11, '3xCsKXY9E/8QI1Db7z8Xrex4IMuHhvJfhfeZ+McwTSY0pWQNb0C4pg==');

--cron db
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (102, 1, 1, 6, 12, '5432');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (103, 1, 1, 6, 13, 'localhost');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (104, 1, 1, 6, 14, 'bus_db');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (105, 1, 1, 6, 15, 'bus_admin');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (106, 1, 1, 6, 16, 'bus123');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (107, 1, 1, 6, 17, '2000');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (108, 1, 1, 6, 18, 'AAAA_vArJw0:APA91bG-EhDsfDdv7m_o3RXI1-2eBegndpW1sI-OdOqULO31k7MkilW_o4DnlDfMOA3sfPMlTBvKz0Ysx6v1-_v_BQmZwQAKCO6T3ZovWVDYPdGu-59WWdHshH2VW3ADdkjnWxKb862C');



--rent service
---------------
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (109, 1, 1, 7, 1, 'rent');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (110, 1, 1, 7, 2, 'application/json;charset=utf-8');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (111, 1, 1, 7, 3, '*');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (112, 1, 1, 7, 4, '8080');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (113, 1, 1, 7, 5, '8058');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (114, 1, 1, 7, 6, './src/main/resources/yInhUOEDMv2PZqJWc2j3id0tZVYD3vBt.key');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (115, 1, 1, 7, 7, 'EzvxzEy7/EGAEgV728ADN2le3hTuNuNSmJdnGlJMztY0pWQNb0C4pg==');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (116, 1, 1, 7, 8, 'JCEKS');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (117, 1, 1, 7, 9, 'AES');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (118, 1, 1, 7, 10, '1maRuaJV8JApV07CyhDnbA1zpy/cQixHs91aClA1pCk0pWQNb0C4pg==');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (119, 1, 1, 7, 11, '3xCsKXY9E/8QI1Db7z8Xrex4IMuHhvJfhfeZ+McwTSY0pWQNb0C4pg==');

--rent db
----------
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (120, 1, 1, 7, 12, '5432');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (121, 1, 1, 7, 13, 'localhost');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (122, 1, 1, 7, 14, 'bus_db');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (123, 1, 1, 7, 15, 'bus_admin');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (124, 1, 1, 7, 16, 'bus123');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (125, 1, 1, 7, 17, '2000');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (126, 1, 1, 7, 18, 'AAAA_vArJw0:APA91bG-EhDsfDdv7m_o3RXI1-2eBegndpW1sI-OdOqULO31k7MkilW_o4DnlDfMOA3sfPMlTBvKz0Ysx6v1-_v_BQmZwQAKCO6T3ZovWVDYPdGu-59WWdHshH2VW3ADdkjnWxKb862C');


-- --media service
-- ---------------
-- INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (127, 1, 1, 8, 1, 'media');
-- INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (128, 1, 1, 8, 2, 'application/json;charset=utf-8');
-- INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (129, 1, 1, 8, 3, '*');
-- INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (130, 1, 1, 8, 4, '8080');
-- INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (131, 1, 1, 8, 5, '8059');
-- INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (132, 1, 1, 8, 6, './src/main/resources/yInhUOEDMv2PZqJWc2j3id0tZVYD3vBt.key');
-- INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (133, 1, 1, 8, 7, 'EzvxzEy7/EGAEgV728ADN2le3hTuNuNSmJdnGlJMztY0pWQNb0C4pg==');
-- INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (134, 1, 1, 8, 8, 'JCEKS');
-- INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (135, 1, 1, 8, 9, 'AES');
-- INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (136, 1, 1, 8, 10, '1maRuaJV8JApV07CyhDnbA1zpy/cQixHs91aClA1pCk0pWQNb0C4pg==');
-- INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (137, 1, 1, 8, 11, '3xCsKXY9E/8QI1Db7z8Xrex4IMuHhvJfhfeZ+McwTSY0pWQNb0C4pg==');

-- --media db
-- ----------
-- INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (138, 1, 1, 8, 12, '5432');
-- INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (139, 1, 1, 8, 13, 'localhost');
-- INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (140, 1, 1, 8, 14, 'bus_db');
-- INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (141, 1, 1, 8, 15, 'bus_admin');
-- INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (142, 1, 1, 8, 16, 'bus123');
-- INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (143, 1, 1, 8, 17, '2000');
-- INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (144, 1, 1, 8, 18, 'AAAA_vArJw0:APA91bG-EhDsfDdv7m_o3RXI1-2eBegndpW1sI-OdOqULO31k7MkilW_o4DnlDfMOA3sfPMlTBvKz0Ysx6v1-_v_BQmZwQAKCO6T3ZovWVDYPdGu-59WWdHshH2VW3ADdkjnWxKb862C');




--media service
---------------
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (127, 1, 1, 8, 1, 'media');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (128, 1, 1, 8, 2, 'application/json;charset=utf-8');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (129, 1, 1, 8, 3, '*');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (130, 1, 1, 8, 4, '8080');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (131, 1, 1, 8, 5, '8059');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (132, 1, 1, 8, 6, './src/main/resources/yInhUOEDMv2PZqJWc2j3id0tZVYD3vBt.key');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (133, 1, 1, 8, 7, 'EzvxzEy7/EGAEgV728ADN2le3hTuNuNSmJdnGlJMztY0pWQNb0C4pg==');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (134, 1, 1, 8, 8, 'JCEKS');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (135, 1, 1, 8, 9, 'AES');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (136, 1, 1, 8, 10, '1maRuaJV8JApV07CyhDnbA1zpy/cQixHs91aClA1pCk0pWQNb0C4pg==');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (137, 1, 1, 8, 11, '3xCsKXY9E/8QI1Db7z8Xrex4IMuHhvJfhfeZ+McwTSY0pWQNb0C4pg==');

--media db
----------
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (138, 1, 1, 8, 12, '5432');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (139, 1, 1, 8, 13, 'localhost');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (140, 1, 1, 8, 14, 'bus_db');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (141, 1, 1, 8, 15, 'bus_admin');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (142, 1, 1, 8, 16, 'bus123');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (143, 1, 1, 8, 17, '2000');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (144, 1, 1, 8, 18, 'AAAA_vArJw0:APA91bG-EhDsfDdv7m_o3RXI1-2eBegndpW1sI-OdOqULO31k7MkilW_o4DnlDfMOA3sfPMlTBvKz0Ysx6v1-_v_BQmZwQAKCO6T3ZovWVDYPdGu-59WWdHshH2VW3ADdkjnWxKb862C');



--tyre service
---------------
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (145, 1, 1, 9, 1, 'tyre');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (146, 1, 1, 9, 2, 'application/json;charset=utf-8');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (147, 1, 1, 9, 3, '*');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (148, 1, 1, 9, 4, '8080');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (149, 1, 1, 9, 5, '8060');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (150, 1, 1, 9, 6, './src/main/resources/yInhUOEDMv2PZqJWc2j3id0tZVYD3vBt.key');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (151, 1, 1, 9, 7, 'EzvxzEy7/EGAEgV728ADN2le3hTuNuNSmJdnGlJMztY0pWQNb0C4pg==');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (152, 1, 1, 9, 8, 'JCEKS');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (153, 1, 1, 9, 9, 'AES');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (154, 1, 1, 9, 10, '1maRuaJV8JApV07CyhDnbA1zpy/cQixHs91aClA1pCk0pWQNb0C4pg==');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (155, 1, 1, 9, 11, '3xCsKXY9E/8QI1Db7z8Xrex4IMuHhvJfhfeZ+McwTSY0pWQNb0C4pg==');


--tyre db
----------
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (156, 1, 1, 9, 12, '5432');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (157, 1, 1, 9, 13, 'localhost');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (158, 1, 1, 9, 14, 'bus_db');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (159, 1, 1, 9, 15, 'bus_admin');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (160, 1, 1, 9, 16, 'bus123');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (161, 1, 1, 9, 17, '2000');
INSERT INTO config.config (config_sno, environment_sno, module_sno,sub_module_sno,config_key_sno,config_value) VALUES (162, 1, 1, 9, 18, 'AAAA_vArJw0:APA91bG-EhDsfDdv7m_o3RXI1-2eBegndpW1sI-OdOqULO31k7MkilW_o4DnlDfMOA3sfPMlTBvKz0Ysx6v1-_v_BQmZwQAKCO6T3ZovWVDYPdGu-59WWdHshH2VW3ADdkjnWxKb862C');
