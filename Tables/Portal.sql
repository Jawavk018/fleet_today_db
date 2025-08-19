
--portal schema tables

CREATE TABLE IF NOT EXISTS portal.codes_hdr(
    codes_hdr_sno smallserial PRIMARY KEY,
    code_type text NOT NULL,
    active_flag boolean NOT NULL default true
);

CREATE TABLE IF NOT EXISTS portal.codes_dtl(
    codes_dtl_sno smallserial PRIMARY KEY,
    codes_hdr_sno smallint NOT NULL,
    cd_value TEXT NOT NULL,
    seqno INT,
    filter_1 TEXT,
    filter_2 TEXT,
    active_flag boolean NOT NULL default true,
    FOREIGN KEY(codes_hdr_sno) REFERENCES portal.codes_hdr(codes_hdr_sno)
);

CREATE TABLE IF NOT EXISTS portal.app_user(
    app_user_sno bigserial PRIMARY KEY,
    mobile_no text NOT NULL UNIQUE,
    password text ,
	confirm_password text ,
    user_status_cd smallint NOT NULL,
    FOREIGN KEY(user_status_cd) REFERENCES portal.codes_dtl(codes_dtl_sno)
);

CREATE TABLE IF NOT EXISTS portal.otp(
    otp_sno bigserial PRIMARY KEY,
    app_user_sno BIGINT NOT NULL,
    sim_otp varchar(6) not null,
    --email_otp varchar(6) not null,
    api_otp varchar(10) NOT NULL,
    push_otp varchar(10) NOT NULL,
    device_id text NOT NULL,
    expire_time TIMESTAMP NOT NULL,
    active_flag boolean NOT NULL default true,
    FOREIGN KEY(app_user_sno) REFERENCES portal.app_user(app_user_sno)
);

CREATE TABLE IF NOT EXISTS portal.signin_config(
    signin_config_sno bigserial PRIMARY KEY,
    app_user_sno bigint NOT NULL,
    push_token_id text,
    --log_in_time TIMESTAMP NOT NULL,
    --log_out_time TIMESTAMP,
    device_type_cd smallint NOT NULL ,
    device_id text NOT NULL,
    active_flag boolean default true,
    FOREIGN KEY(app_user_sno) REFERENCES portal.app_user(app_user_sno),
    FOREIGN KEY(device_type_cd) REFERENCES portal.codes_dtl(codes_dtl_sno)
);

CREATE TABLE IF NOT EXISTS portal.app_menu
(   app_menu_sno smallserial PRIMARY KEY, 
    title text not null,
    href text,
    icon text, 
    has_sub_menu boolean,
    parent_menu_sno integer,
    router_link text
);

CREATE TABLE IF NOT EXISTS portal.app_menu_role
(
    app_menu_role_sno smallserial PRIMARY KEY,
    app_menu_sno integer NOT NULL,
    role_cd integer NOT NULL,
    FOREIGN KEY(app_menu_sno) REFERENCES portal.app_menu(app_menu_sno)
);


CREATE TABLE IF NOT EXISTS portal.app_menu_user (
    app_menu_user_sno smallserial PRIMARY KEY,
    app_menu_sno integer NOT NULL,
    app_user_sno bigint NOT NULL,
    is_admin boolean,
    FOREIGN KEY(app_menu_sno) REFERENCES portal.app_menu(app_menu_sno),
    FOREIGN KEY(app_user_sno) REFERENCES portal.app_user(app_user_sno)
);

CREATE TABLE IF NOT EXISTS portal.app_user_role(
    app_user_role_sno bigserial PRIMARY KEY,
    app_user_sno bigint NOT NULL,
    role_cd smallint NOT NULL,
    FOREIGN KEY(app_user_sno) REFERENCES portal.app_user(app_user_sno),
    FOREIGN KEY(role_cd) REFERENCES portal.codes_dtl(codes_dtl_sno)
);


CREATE TABLE IF NOT EXISTS portal.user_profile(
    user_profile_sno bigserial PRIMARY KEY,
    app_user_sno bigint,
    first_name text not null,
    last_name text not null,
	mobile text not null,
    gender_cd int,
    photo text,
	dob timestamp,
    FOREIGN KEY(app_user_sno) REFERENCES portal.app_user(app_user_sno),
    FOREIGN KEY(gender_cd) REFERENCES portal.codes_dtl(codes_dtl_sno)
);

CREATE TABLE IF NOT EXISTS portal.contact(
    contact_sno bigserial PRIMARY KEY,
    app_user_sno bigint,
	name text,
	contact_role_cd smallint,
    mobile_number text,
    email text,
	is_show boolean,
    active_flag boolean NOT NULL default true,
	FOREIGN KEY(contact_role_cd) REFERENCES portal.codes_dtl(codes_dtl_sno),
	FOREIGN KEY(app_user_sno) REFERENCES portal.app_user(app_user_sno)
);

CREATE TABLE IF NOT EXISTS portal.social_link(
    social_link_sno bigserial PRIMARY KEY,
    social_url text,
    social_link_type_cd int,
    active_flag boolean NOT NULL default true,
    FOREIGN KEY(social_link_type_cd) REFERENCES portal.codes_dtl(codes_dtl_sno)
);


CREATE TABLE IF NOT EXISTS portal.app_user_contact(
    app_user_contact_sno bigserial PRIMARY KEY,
    app_user_sno bigint NOT NULL,
    user_name text,
    mobile_no text NOT NULL UNIQUE,
    alternative_mobile_no text,
    email text,
    user_status_cd smallint NOT NULL,
    FOREIGN KEY(app_user_sno) REFERENCES portal.app_user(app_user_sno),
    FOREIGN KEY(user_status_cd) REFERENCES portal.codes_dtl(codes_dtl_sno)
);



