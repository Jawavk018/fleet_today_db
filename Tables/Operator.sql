
CREATE TABLE IF NOT EXISTS operator.address(
	address_sno  bigserial primary key,
	address_line1 text not null,
	address_line2 text,
    	pincode int not null,
	city_name text,
	state_name text,
    	district_name text,
    	country_name text,
	country_code smallint,
	latitude text,
	longitude text
);


CREATE TABLE IF NOT EXISTS operator.org(
    org_sno bigserial PRIMARY KEY,
    org_name text not null,
	owner_name text not null,
	vehicle_number text not null,
    org_status_cd smallint not null,
    active_flag boolean NOT NULL default true,
    FOREIGN KEY(org_status_cd) REFERENCES portal.codes_dtl(codes_dtl_sno)
);

CREATE TABLE IF NOT EXISTS operator.org_owner(
    org_owner_sno bigserial PRIMARY KEY,
    org_sno bigint,
    app_user_sno bigint,
    FOREIGN KEY(org_sno) REFERENCES operator.org(org_sno),
    FOREIGN KEY(app_user_sno) REFERENCES portal.app_user(app_user_sno)
);

CREATE TABLE IF NOT EXISTS operator.org_user(
    org_user_sno bigserial PRIMARY KEY,
    operator_user_sno bigint,
    role_user_sno bigint,
    FOREIGN KEY(operator_user_sno) REFERENCES portal.app_user(app_user_sno),
    FOREIGN KEY(operator_user_sno) REFERENCES portal.app_user(app_user_sno)
);

CREATE TABLE IF NOT EXISTS operator.org_detail(
    org_detail_sno bigserial PRIMARY KEY,
    org_sno bigint not null,
    org_logo json,
    org_banner json,
    address_sno bigint not null,
    org_website text,
    FOREIGN KEY(address_sno) REFERENCES operator.address(address_sno),
    FOREIGN KEY(org_sno) REFERENCES operator.org(org_sno)
);



CREATE TABLE IF NOT EXISTS operator.org_contact(
    org_contact_sno bigserial PRIMARY KEY,
    org_sno bigint,
    contact_sno bigint,
    active_flag boolean NOT NULL default true,
    FOREIGN KEY(org_sno) REFERENCES operator.org(org_sno),
    FOREIGN KEY(contact_sno) REFERENCES portal.contact(contact_sno)
);

CREATE TABLE IF NOT EXISTS operator.org_social_link(
    org_social_link_sno bigserial PRIMARY KEY,
    org_sno bigint,
    social_link_sno bigint,
    active_flag boolean NOT NULL default true,
    FOREIGN KEY(org_sno) REFERENCES operator.org(org_sno),
    FOREIGN KEY(social_link_sno) REFERENCES portal.social_link(social_link_sno)
);


-- CREATE TABLE IF NOT EXISTS operator.branch(
--     branch_sno bigserial PRIMARY KEY,
--     branch_name text,
--     org_sno  bigint not null,
--     address_sno bigint not null,
--     contact_numbers json, -- name,phone no,role --??
--     active_flag boolean NOT NULL default true,
--     FOREIGN KEY(org_sno) REFERENCES operator.org(org_sno)
-- );


CREATE TABLE IF NOT EXISTS operator.vehicle(
    vehicle_sno bigserial PRIMARY KEY,
    vehicle_reg_number text not null,
    vehicle_name text not null,
    vehicle_banner_name text not null,
    chase_number text not null,
	engine_number text,
    media_sno bigint,
    vehicle_type_cd smallint not null,
	tyre_type_cd smallint[] not null,
	tyre_size_cd smallint[] not null,
    active_flag boolean NOT NULL default true,
	kyc_status smallint,
	reject_reason text,
    tyre_count_cd smallint,
    FOREIGN KEY(vehicle_type_cd) REFERENCES portal.codes_dtl(codes_dtl_sno),
    FOREIGN KEY(media_sno) REFERENCES media.media(media_sno),
	FOREIGN KEY(kyc_status) REFERENCES portal.codes_dtl(codes_dtl_sno),
    FOREIGN KEY(tyre_count_cd) REFERENCES portal.codes_dtl(codes_dtl_sno)
);



CREATE TABLE IF NOT EXISTS operator.org_vehicle(
    org_vehicle_sno bigserial PRIMARY KEY,
    org_sno bigint not null,
    vehicle_sno bigint not null,
    FOREIGN KEY(org_sno) REFERENCES operator.org(org_sno),
    FOREIGN KEY(vehicle_sno) REFERENCES operator.vehicle(vehicle_sno)
);



CREATE TABLE IF NOT EXISTS operator.vehicle_detail(
			vehicle_detail_sno bigserial PRIMARY KEY,
			vehicle_sno bigint,
			vehicle_logo json,
       		vehicle_reg_date timestamp,
			fc_expiry_date timestamp,
			insurance_expiry_date timestamp,
			pollution_expiry_date timestamp,
			tax_expiry_date timestamp,
			permit_expiry_date timestamp,
			state_sno bigint,
			district_sno bigint,
			odo_meter_value bigint,
			fuel_capacity int,
			fuel_type_cd smallint,
			video_types_cd int[],
			seat_Type_cd smallint,
			Audio_types_cd int[],
			Cool_type_cd smallint,
			suspension_type smallint,
			driving_type_cd smallint,
			wheelbase_type_cd smallint,
	  		vehicle_make_cd smallint,
			vehicle_model text,
			wheels_cd smallint,
	  		stepny_cd smallint,
			fuel_norms_cd smallint,
	    	seat_capacity_cd smallint,
			price_perday bigint,
	   		otherslist json,
		    seat_capacity smallint,
		    luckage_count smallint,
		    top_luckage_carrier boolean,
			public_addressing_system_cd int[],
			lighting_system_cd int[],
            image_sno bigint,
            fc_expiry_amount double precision,
            insurance_expiry_amount double precision,
            tax_expiry_amount double precision,
			FOREIGN KEY(vehicle_sno) REFERENCES operator.vehicle(vehicle_sno)
			);
			
			


/* CREATE TABLE IF NOT EXISTS operator.vehicle_owner(
    vehicle_owner_sno bigserial PRIMARY KEY,
    vehicle_sno bigint,
    owner_name text,
    owner_number int,
    current_owner boolean,
    purchase_date timestamp,
    active_flag boolean NOT NULL default true,
    user_profile_sno bigint
); */


CREATE TABLE IF NOT EXISTS operator.vehicle_owner(
    vehicle_owner_sno bigserial PRIMARY KEY,
    vehicle_sno bigint,
    owner_name text,
    owner_number text,
    current_owner boolean,
    purchase_date timestamp,
    active_flag boolean NOT NULL default true,
    app_user_sno bigint,
    FOREIGN KEY(app_user_sno) REFERENCES portal.app_user(app_user_sno),
    FOREIGN KEY(vehicle_sno) REFERENCES operator.vehicle(vehicle_sno)
);



CREATE TABLE IF NOT EXISTS  operator.operator_route(
 operator_route_sno   bigserial PRIMARY KEY, 
 route_sno 	bigint,
 operator_sno bigint,
 active_flag boolean default true,
 FOREIGN KEY(route_sno) REFERENCES master_data.route(route_sno),
 FOREIGN KEY(operator_sno) REFERENCES operator.org(org_sno)		
 );


CREATE TABLE IF NOT EXISTS  operator.single_route(
 single_route_sno   bigserial PRIMARY KEY, 
 route_sno 	bigint not null,
 org_sno bigint not null,
 vehicle_sno bigint not null,
 starting_time timestamp not null,
 running_time bigint not null,	
 active_flag boolean default true,
 FOREIGN KEY(route_sno) REFERENCES master_data.route(route_sno),
 FOREIGN KEY(org_sno) REFERENCES operator.org(org_sno),
 FOREIGN KEY(vehicle_sno) REFERENCES operator.vehicle(vehicle_sno)		

 );

CREATE TABLE IF NOT EXISTS operator.bunk(
    bunk_sno bigserial PRIMARY KEY,
    bunk_name text not null,
    address text,
	operator_sno smallint,
    FOREIGN KEY(operator_sno) REFERENCES operator.org(org_sno)
);



CREATE TABLE IF NOT EXISTS operator.trip(
    trip_sno bigserial PRIMARY KEY,
    source_name text not null,
    destination text,
    start_date timestamp,
    end_date timestamp,
    district_sno bigint not null,
    active_flag boolean default true,
    FOREIGN KEY(district_sno) REFERENCES master_data.district(district_sno)
);



CREATE TABLE IF NOT EXISTS operator.trip_route(
    trip_route_sno bigserial PRIMARY KEY,
    trip_sno bigint not null,
    via_name text,
    latitude text,
    longitude text,
    active_flag boolean default true,
    FOREIGN KEY(trip_sno) REFERENCES operator.trip(trip_sno)
);


CREATE TABLE IF NOT EXISTS operator.via(
  via_sno serial primary key,
  operator_route_sno bigint,
  city_sno bigint,
  active_flag boolean default true,
  FOREIGN KEY(city_sno) REFERENCES  master_data.city (city_sno),
  FOREIGN KEY(operator_route_sno) REFERENCES  operator.operator_route (operator_route_sno)
  );
  
  CREATE TABLE IF NOT EXISTS operator.vehicle_route(
    vehicle_route_sno bigserial PRIMARY KEY,
    operator_route_sno bigint,
    vehicle_sno bigint,
    active_flag boolean NOT NULL default true,
    FOREIGN KEY(operator_route_sno) REFERENCES operator.operator_route(operator_route_sno),
    FOREIGN KEY(vehicle_sno) REFERENCES operator.vehicle(vehicle_sno)
);

CREATE TABLE IF NOT EXISTS operator.reject_reason(
    reject_reason_sno bigserial PRIMARY KEY,
    org_sno bigint,
    reason text,
    FOREIGN KEY(org_sno) REFERENCES operator.org(org_sno)
);

CREATE TABLE IF NOT EXISTS operator.bank_account_detail(
			bank_account_detail_sno bigserial PRIMARY KEY,
			org_sno bigint,
			bank_account_name text,
			FOREIGN KEY(org_sno) REFERENCES operator.org(org_sno)

);


CREATE TABLE IF NOT EXISTS operator.vehicle_due_fixed_pay(
			vehicle_due_sno bigserial PRIMARY KEY,
			vehicle_sno bigint,
			org_sno bigint,
            bank_account_detail_sno bigint,
			due_type_cd smallint,
			due_close_date date,
	        remainder_type_cd integer[],
			due_amount double precision,
			active_flag boolean default true,
			bank_name text,
			bank_account_number text,
	        discription text,
			FOREIGN KEY(org_sno) REFERENCES operator.org(org_sno),
            FOREIGN KEY(bank_account_detail_sno) REFERENCES operator.bank_account_detail(bank_account_detail_sno),
			FOREIGN KEY(vehicle_sno) REFERENCES operator.vehicle(vehicle_sno)
);


CREATE TABLE IF NOT EXISTS operator.vehicle_due_variable_pay(
			vehicle_due_variable_pay_sno bigserial PRIMARY KEY,
			vehicle_due_sno bigint,
			due_pay_date date,
			due_amount double precision,
			active_flag boolean default true,
            is_pass_paid boolean  DEFAULT false,
			FOREIGN KEY(vehicle_due_sno) REFERENCES operator.vehicle_due_fixed_pay(vehicle_due_sno)
);

CREATE TABLE IF NOT EXISTS operator.toll_pass_detail(
			toll_pass_detail_sno bigserial PRIMARY KEY,
			vehicle_sno bigint,
			org_sno bigint,
			toll_id text,
			toll_name text,
			-- remainder_type_cd integer[],
			toll_amount double precision,
       		pass_start_date date,
			pass_end_date date,
            active_flag boolean,
            is_paid boolean default false,
			FOREIGN KEY(org_sno) REFERENCES operator.org(org_sno),
			FOREIGN KEY(vehicle_sno) REFERENCES operator.vehicle(vehicle_sno)
);




