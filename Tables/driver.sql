-- create exte
--driver
---------
CREATE TABLE IF NOT EXISTS driver.driver(
    driver_sno bigserial PRIMARY KEY,
    driver_name text not null,
    driver_mobile_number text not null,
    driver_whatsapp_number text,
    dob timestamp not null,
    father_name text,
    address text,
    current_address text,
    current_district text,
    blood_group_cd smallint,
    media_sno bigint,
    certificate_sno bigint,
    certificate_description text,
    licence_number citext not null unique,
    licence_expiry_date timestamp,
    transport_licence_expiry_date timestamp,
    driving_licence_type int [],
    active_flag boolean NOT NULL default true,
    kyc_status smallint,
    reject_reason text,
    licence_front_sno bigint,
    licence_back_sno bigint,
    foreign key(kyc_status) REFERENCES portal.codes_dtl(codes_dtl_sno),
    FOREIGN KEY(blood_group_cd) REFERENCES portal.codes_dtl(codes_dtl_sno)
);

--driver_user
--------------
CREATE TABLE IF NOT EXISTS driver.driver_user(
    driver_user_sno bigserial PRIMARY KEY,
    driver_sno bigint not null,
    app_user_sno bigint not null,
    active_flag boolean NOT NULL default true,
    FOREIGN KEY(driver_sno) REFERENCES driver.driver(driver_sno),
    FOREIGN KEY(app_user_sno) REFERENCES portal.app_user(app_user_sno)
);

--driver_attendance
--------------------
CREATE TABLE IF NOT EXISTS driver.driver_attendance(
    driver_attendance_sno bigserial PRIMARY KEY,
    driver_sno bigint not null,
    vehicle_sno bigint not null,
    start_lat_long text,
    end_lat_long text,
    start_media json,
    end_media json,
    start_time timestamp,
    end_time timestamp,
    start_value text,
    end_value text,
    attendance_status_cd smallint,
    active_flag boolean default true,
    accept_status boolean default false,
    is_calculated boolean default false,
    report_id bigint,
    FOREIGN KEY(driver_sno) REFERENCES driver.driver(driver_sno),
    FOREIGN KEY(vehicle_sno) REFERENCES operator.vehicle(vehicle_sno),
    FOREIGN KEY(attendance_status_cd) REFERENCES portal.codes_dtl(codes_dtl_sno)
);

CREATE TABLE IF NOT EXISTS operator.fuel(
    fuel_sno bigserial PRIMARY KEY,
    vehicle_sno bigint,
    driver_sno bigint,
    driver_attendance_sno bigint,
    bunk_sno bigint,
    lat_long text,
    fuel_media json,
    odo_meter_media json,
    fuel_quantity double precision not null,
    fuel_amount double precision not null,
    odo_meter_value bigint not null,
    filled_date timestamp not null,
    price_per_ltr double precision not null,
    accept_status boolean default false,
    active_flag boolean default true,
    is_filled boolean NOT NULL,
    fuel_fill_type_cd smallint,
    tank_media json,
    is_calculated boolean,
    report_id bigint,
    FOREIGN KEY(vehicle_sno) REFERENCES operator.vehicle(vehicle_sno),
    FOREIGN KEY(driver_sno) REFERENCES driver.driver(driver_sno),
    FOREIGN KEY(driver_attendance_sno) REFERENCES driver.driver_attendance(driver_attendance_sno),
    FOREIGN KEY(bunk_sno) REFERENCES operator.bunk(bunk_sno),
    FOREIGN KEY(fuel_fill_type_cd) REFERENCES portal.codes_dtl(codes_dtl_sno)

);

CREATE TABLE IF NOT EXISTS operator.operator_driver(
    operator_driver_sno bigserial PRIMARY KEY,
    org_sno bigint not null,
    driver_sno bigint not null,
    accept_status_cd smallint,
    active_flag boolean NOT NULL default true,
    FOREIGN KEY(org_sno) REFERENCES operator.org(org_sno),
    FOREIGN KEY(driver_sno) REFERENCES driver.driver(driver_sno)
);

CREATE TABLE IF NOT EXISTS driver.driver_mileage(
    driver_mileage_sno bigserial PRIMARY KEY,
    driver_sno bigint,
    driving_type_cd bigint,
    mileage text,
    kms text,
    fuel double precision,
    vehicle_sno bigint,
    active_flag boolean,
    FOREIGN KEY(driver_sno) REFERENCES driver.driver(driver_sno),
    FOREIGN KEY(vehicle_sno) REFERENCES operator.vehicle(vehicle_sno)
);

--bus_report
-------------    
CREATE TABLE IF NOT EXISTS operator.bus_report(
    bus_report_sno bigserial PRIMARY KEY,
    org_sno bigint,
    vehicle_sno bigint,
    driver_sno bigint,
    driver_attendance_sno bigint,
    driving_type_cd smallint,
    start_km bigint,
    end_km bigint,
    drived_km numeric,
    start_date timestamp,
    end_date timestamp,
    fuel_consumed double precision,
    mileage double precision,
    created_on timestamp,
    FOREIGN KEY(driver_sno) REFERENCES driver.driver(driver_sno),
    FOREIGN KEY(org_sno) REFERENCES operator.org(org_sno),
    FOREIGN KEY(vehicle_sno) REFERENCES operator.vehicle(vehicle_sno),
    FOREIGN KEY(driver_attendance_sno) REFERENCES driver.driver_attendance(driver_attendance_sno),
    FOREIGN KEY(driving_type_cd) REFERENCES portal.codes_dtl(codes_dtl_sno)
);

--vehicle_driver
----------------
CREATE TABLE IF NOT EXISTS operator.vehicle_driver(
    vehicle_driver_sno bigserial PRIMARY KEY,
    driver_sno bigint,
    vehicle_sno bigint,
    created_on timestamp,
    FOREIGN KEY(driver_sno) REFERENCES driver.driver(driver_sno),
    FOREIGN KEY(vehicle_sno) REFERENCES operator.vehicle(vehicle_sno)
);




--job_post
----------

CREATE TABLE IF NOT EXISTS driver.job_post(
    job_post_sno bigserial PRIMARY KEY,
    role_cd smallint NOT NULL,
    org_sno bigint,
    driver_sno bigint,
    user_lat_long json,
    start_date timestamp,
    end_date timestamp,
    posted_on timestamp,
    contact_name text,
    contact_number text,
    drive_type_cd smallint[],
    job_type_cd smallint[],
    fuel_type_cd smallint[],
    transmission_type_cd smallint[],
    auth_type_cd smallint,
    lat text,
    lng text,
    description text,
    active_flag boolean,
    FOREIGN KEY(role_cd) REFERENCES portal.codes_dtl(codes_dtl_sno),
    FOREIGN KEY(org_sno) REFERENCES operator.org(org_sno),
    FOREIGN KEY(driver_sno) REFERENCES driver.driver(driver_sno)
); 
