CREATE TABLE IF NOT EXISTS master_data.state(
    state_sno bigserial PRIMARY KEY,
    state_name text, 
    active_flag boolean default true
);

CREATE TABLE IF NOT EXISTS master_data.district(
    district_sno bigserial PRIMARY KEY,
    district_name text, 
    state_sno bigint,
    active_flag boolean default true,
    FOREIGN KEY(state_sno) REFERENCES master_data.state(state_sno)
);


CREATE TABLE IF NOT EXISTS master_data.city(
    city_sno bigserial PRIMARY KEY,
    city_name text, 
    district_sno bigint,
    active_flag boolean default true,
    FOREIGN KEY(district_sno) REFERENCES master_data.district(district_sno)
);

CREATE TABLE IF NOT EXISTS master_data.route(
    route_sno bigserial PRIMARY KEY,
    source_city_sno bigint not null,
    destination_city_sno bigint not null,
    active_flag boolean default true,
    FOREIGN KEY(source_city_sno) REFERENCES master_data.city(city_sno),
    FOREIGN KEY(destination_city_sno) REFERENCES master_data.city(city_sno)
);

CREATE TABLE IF NOT EXISTS master_data.tyre_type(
    tyre_type_sno bigserial PRIMARY KEY,
    tyre_type text not null,
    active_flag boolean default true
);

CREATE TABLE IF NOT EXISTS master_data.tyre_size(
    tyre_size_sno bigserial PRIMARY KEY,
    tyre_type_sno bigint,
    tyre_size text not null,
    active_flag boolean default true,
    FOREIGN KEY(tyre_type_sno) REFERENCES master_data.tyre_type(tyre_type_sno)
);

CREATE TABLE IF NOT EXISTS master_data.tyre_company(
    tyre_company_sno bigserial PRIMARY KEY,
    tyre_company text,
    active_flag boolean default true
);