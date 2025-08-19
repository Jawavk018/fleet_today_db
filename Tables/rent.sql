--rent_bus
------------
create table if not exists rent.rent_bus(
	rent_bus_sno bigserial PRIMARY KEY, 
	customer_sno bigint,
	trip_starting_date date,
	trip_end_date date,
	trip_source json,
	trip_destination json,
	trip_via json,
	is_same_route boolean,
	return_type_cd smallint,
	return_rent_bus_sno bigint,
	total_km double precision,
	FOREIGN KEY(return_type_cd) REFERENCES portal.codes_dtl(codes_dtl_sno)		
);

--booking
-----------
CREATE TABLE IF NOT EXISTS rent.booking(
booking_sno bigserial primary key,
vehicle_sno bigint not null,
start_date timestamp,
end_date timestamp,	
customer_name text,
customer_address text,
contact_number text,
active_flag boolean default true,
no_of_days_booked bigint,
total_booking_amount double precision,
advance_paid double precision,
balance_amount_to_paid double precision,
toll_parking_includes boolean,
driver_wages_includes boolean,
driver_wages double precision,
description text,
booking_id text unique,
trip_plan text,
created_on timestamp,
FOREIGN KEY(vehicle_sno) REFERENCES operator.vehicle(vehicle_sno)
);