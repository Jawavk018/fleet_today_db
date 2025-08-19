-- drop table if exist tyre.tyre;
CREATE TABLE IF NOT EXISTS tyre.tyre(
    tyre_sno bigserial PRIMARY KEY,
    org_sno bigint,
    tyre_serial_number citext unique not null,
    tyre_type_sno bigint,
    tyre_size_sno bigint,
    tyre_price double precision,
    agency_name varchar(60),
    invoice_date timestamp,
    incoming_date timestamp,
    invoice_media bigint,
    payment_mode_cd smallint,
    is_new boolean,
    is_tread boolean,
    km_drive text,
    no_of_tread smallint,
    stock boolean default true,
    efficiency_value smallint,
    is_running boolean default false,
    active_flag boolean default true,
    is_bursted boolean default false,
    tyre_company_sno bigint,
    tyre_model text,
    FOREIGN KEY(org_sno) REFERENCES operator.org(org_sno),
    FOREIGN KEY(tyre_type_sno) REFERENCES master_data.tyre_type(tyre_type_sno),
    FOREIGN KEY(tyre_size_sno) REFERENCES master_data.tyre_size(tyre_size_sno),
    FOREIGN KEY(tyre_company_sno) REFERENCES master_data.tyre_company(tyre_company_sno),
    FOREIGN KEY(invoice_media) REFERENCES media.media(media_sno),
    FOREIGN KEY(payment_mode_cd) REFERENCES portal.codes_dtl(codes_dtl_sno)
);

CREATE TABLE IF NOT EXISTS tyre.tyre_activity(
    tyre_activity_sno bigserial PRIMARY KEY,
    tyre_sno bigint,
    vehicle_sno bigint,
    wheel_position text,
    description text,
    tyre_activity_type_cd smallint,
    odo_meter numeric,
    activity_date timestamp,
    is_running boolean default true,
    FOREIGN KEY(tyre_sno) REFERENCES tyre.tyre(tyre_sno),
    FOREIGN KEY(vehicle_sno) REFERENCES operator.vehicle(vehicle_sno),
    FOREIGN KEY(tyre_activity_type_cd) REFERENCES portal.codes_dtl(codes_dtl_sno)
);

CREATE TABLE IF NOT EXISTS tyre.tyre_activity_total_km(
    tyre_activity_total_km_sno bigserial PRIMARY KEY,
    tyre_sno bigint,
    tyre_activity_type_cd smallint,
    running_km numeric,
    running_life text,
    activity_start_date timestamp,
    activity_end_date timestamp,
    tyre_activity_sno bigint,
    FOREIGN KEY(tyre_activity_type_cd) REFERENCES portal.codes_dtl(codes_dtl_sno),
    FOREIGN KEY(tyre_activity_sno) REFERENCES tyre.tyre_activity(tyre_activity_sno)
);

CREATE TABLE IF NOT EXISTS tyre.tyre_invoice(
    tyre_invoice_sno bigserial PRIMARY KEY,
    tyre_sno bigint not null,
    tyre_activity_type_cd smallint not null,
    description text,
    invoice_date timestamp not null,
    agency_name text not null,
    amount numeric not null,
    FOREIGN KEY(tyre_sno) REFERENCES tyre.tyre(tyre_sno),
    FOREIGN KEY(tyre_activity_type_cd) REFERENCES portal.codes_dtl(codes_dtl_sno)
);