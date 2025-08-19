
CREATE TABLE IF NOT EXISTS stage_carriage.permit_route(
    permit_route_sno  bigserial PRIMARY KEY,
    source_city_sno bigint not null,
    destination_city_sno bigint not null,
    vehicle_sno bigint not null,
    active_flag boolean default true,
    FOREIGN KEY(source_city_sno) REFERENCES master_data.city(city_sno),
    FOREIGN KEY(destination_city_sno) REFERENCES master_data.city(city_sno),
    FOREIGN KEY(vehicle_sno) REFERENCES operator.vehicle(vehicle_sno)
);

CREATE TABLE IF NOT EXISTS stage_carriage.single(
    single_sno  bigserial PRIMARY KEY,
    route_sno bigint not null,
    start_time timestamp not null,
    vehicle_sno bigint not null,
    running_mints int not null,
    active_flag boolean default true,
    FOREIGN KEY(vehicle_sno) REFERENCES operator.vehicle(vehicle_sno),
    FOREIGN KEY(route_sno) REFERENCES master_data.route(route_sno)
);


CREATE TABLE IF NOT EXISTS stage_carriage.via(
    via_sno  bigserial PRIMARY KEY,
    single_sno bigint not null,
    via_city_sno  bigint,
    active_flag boolean default true,
    FOREIGN KEY(single_sno) REFERENCES stage_carriage.single(single_sno),
    FOREIGN KEY(via_city_sno) REFERENCES master_data.city(city_sno)
);
