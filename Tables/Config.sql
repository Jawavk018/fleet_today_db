CREATE TABLE config.environment
(
    environment_sno smallserial NOT NULL PRIMARY KEY,
    environment_name text COLLATE pg_catalog."default" NOT NULL
);
 
CREATE TABLE config.module
(
    module_sno smallserial NOT NULL PRIMARY KEY,
    environment_sno smallint NOT NULL,
    module_name text COLLATE pg_catalog."default" NOT NULL,
  FOREIGN KEY(environment_sno) REFERENCES config.environment(environment_sno) 
);

 
CREATE TABLE config.sub_module
(
    sub_module_sno smallserial NOT NULL PRIMARY KEY,
    module_sno smallint NOT NULL,
    sub_module_name text COLLATE pg_catalog."default" NOT NULL,
    FOREIGN KEY(module_sno) REFERENCES config.module(module_sno)
);
 
CREATE TABLE config.config_key
(
    config_key_sno smallserial NOT NULL PRIMARY KEY,
    config_key_attribute text COLLATE pg_catalog."default",
    encrypt_type_cd smallint,
    CONSTRAINT config_key_config_key_attribute_key UNIQUE (config_key_attribute),
    FOREIGN KEY(encrypt_type_cd) REFERENCES portal.codes_dtl(codes_dtl_sno)
);

CREATE TABLE config.config
(
    config_sno smallserial NOT NULL PRIMARY KEY,
    environment_sno smallint NOT NULL,
    module_sno smallint NOT NULL,
    sub_module_sno smallint NOT NULL,
    config_value text COLLATE pg_catalog."default" NOT NULL,
    config_key_sno smallint NOT NULL,
    FOREIGN KEY(environment_sno) REFERENCES config.environment(environment_sno) ,
    FOREIGN KEY(module_sno) REFERENCES config.module(module_sno),
    FOREIGN KEY(sub_module_sno) REFERENCES config.sub_module(sub_module_sno),
    FOREIGN KEY(config_key_sno) REFERENCES config.config_key(config_key_sno)
);




