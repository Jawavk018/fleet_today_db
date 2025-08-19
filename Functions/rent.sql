
--insert_rent_bus
-----------------

CREATE OR REPLACE FUNCTION rent.insert_rent_bus(p_data json)
RETURNS json
AS $BODY$
declare 
rentBusSno bigint;
v_doc json;
i int:=0;
begin
SET datestyle = GERMAN, DMY;

for v_doc in SELECT * FROM json_array_elements((p_data->>'data')::json) loop
i=i+1;
raise notice'%value i',i;
	insert into rent.rent_bus(customer_sno,
							  trip_starting_date,
							  trip_end_date,
							  trip_source,
							  trip_destination,
							  trip_via,
							  is_same_route,
							  return_type_cd,
							 return_rent_bus_sno,
							 total_km) 
     values ((v_doc->>'customerSno')::bigint,
			 (v_doc->>'tripStartingDate')::date,
			 (v_doc->>'tripEndDate')::date,
			 (v_doc->>'tripSource')::json,
			 (v_doc->>'tripDestination')::json,
			 (v_doc->>'tripVia')::json,
			 (v_doc->>'isSameRoute')::boolean,
			 (v_doc->>'returnTypeCd')::smallint,
			(select case when (i=2) then  rentBusSno::bigint else null end),
			 (v_doc->>'totalKm')::double precision
            ) returning rent_bus_sno  INTO rentBusSno;
end loop;

  return (select json_build_object('data',json_build_object('rentBusSno',rentBusSno)));
end;
$BODY$
LANGUAGE plpgsql;



--get_rent_bus
--------------

CREATE OR REPLACE FUNCTION rent.get_rent_bus(p_data json)
    RETURNS json
AS $BODY$
declare 
begin
return (select json_build_object('data',(
	select json_agg(json_build_object(
		'rentBusSno',rent_bus_sno,
		'customerSno',customer_sno,
		'tripStartingDate',trip_starting_date,
		'tripEndDate',trip_end_date,
		'tripSource',trip_source,
		'tripDestination',trip_destination,
		'tripVia',trip_via,
		'isSameRoute',is_same_route::boolean,
		'returnTypeCd',return_type_cd
		))))from rent.rent_bus);
end;
$BODY$
LANGUAGE plpgsql;



--create_booking
------------------

CREATE OR REPLACE FUNCTION rent.create_booking(
	p_data json)
    RETURNS json
AS $BODY$
declare 
_booking_sno bigint;
isAlready bigint;
begin
raise notice '%',p_data;

select count(*) into isAlready from rent.booking b where vehicle_sno = (p_data->>'vehicleSno')::bigint and active_flag = true and
(((b.start_date between (p_data->>'startDate')::timestamp and (p_data->>'endDate')::timestamp) or
(b.end_date between (p_data->>'startDate')::timestamp and (p_data->>'endDate')::timestamp)) or
(((p_data->>'startDate')::timestamp between b.start_date and b.end_date) or 
((p_data->>'endDate')::timestamp between b.start_date and b.end_date)));

raise notice '%count',isAlready;

if isAlready = 0 then
  
insert into rent.booking(vehicle_sno,start_date,end_date,customer_name,customer_address,contact_number,active_flag,
no_of_days_booked,total_booking_amount,advance_paid,balance_amount_to_paid,toll_parking_includes,driver_wages_includes,
						 driver_wages,description,booking_id,trip_plan,created_on) 
   values ((p_data->>'vehicleSno')::bigint,(p_data->>'startDate')::timestamp,
		   (p_data->>'endDate')::timestamp,(p_data->>'customerName'),(p_data->>'customerAddress'),
		   (p_data->>'contactNumber'),true,(p_data->>'noOfDaysBooked')::bigint,(p_data->>'totalBookingAmount')::double precision,(p_data->>'advancePaid')::double precision,
		   (p_data->>'balanceAmountTopaid')::double precision,(p_data->>'tollParkingIncludes')::boolean,(p_data->>'driverWagesIncludes')::boolean,(p_data->>'driverWages')::double precision,
		   (p_data->>'description'),(p_data->>'bookingId'),(p_data->>'tripPlan'), portal.get_time_with_zone(json_build_object('timeZone',p_data->>'createdOn'))::timestamp)
		   returning booking_sno  INTO _booking_sno;
		
  return (select json_build_object('data',json_build_object('bookingSno',_booking_sno)));
  
  else
  
   return (select json_build_object('data',json_build_object('msg','This date is Already booking in this Vehicle')));

end if;  
end;
$BODY$
LANGUAGE 'plpgsql';


--get_booking
---------------

CREATE OR REPLACE FUNCTION rent.get_booking(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
--_booking_sno bigint;
_count bigint; 
begin
raise notice '%',p_data;
select count(*) into _count from rent.booking rb
inner join operator.org_vehicle ov
on rb.vehicle_sno=ov.vehicle_sno where org_sno = (p_data->>'orgSno')::bigint;

raise notice 'COUNT%',_count;

return (select  json_build_object('data',json_agg(json_build_object(
								 'bookingSno',rb.booking_sno,
								 'vehicleSno',rb.vehicle_sno,
	 							 'vehicleRegNumber',(select vehicle_reg_number from operator.vehicle where vehicle_sno = rb.vehicle_sno ),
	                             'companyName',(select org_name from operator.org where  org_sno=(p_data->>'orgSno')::bigint),
	                             'address',(select json_build_object('addressSno',ad.address_sno,
								  'addressLine1',ad.address_line1,
								  'addressLine2',ad.address_line2,
								  'pincode',ad.pincode,
								  'city',ad.city_name,
								  'state',ad.state_name,
								  'district',ad.district_name,
								  'countryCode',ad.country_code,
								  'country',ad.country_name,
								  'latitude',ad.latitude,
								  'longitude',ad.longitude         
								 )from operator.address ad 
		                          inner join operator.org_detail od on od.address_sno=ad.address_sno
	                              where od.org_sno=(p_data->>'orgSno')::bigint),
								 'startDate',rb.start_date,
								 'endDate',rb.end_date,
								 'customerName',rb.customer_name,
								 'customerAddress',rb.customer_address,
								 'contactNumber',rb.contact_number,
								 'noOfDaysBooked',rb.no_of_days_booked,
	                             'totalBookingAmount',rb.total_booking_amount,
								 'advancePaid',rb.advance_paid,
								 'balanceAmountTopaid',rb.balance_amount_to_paid,
								 'tollParkingIncludes',rb.toll_parking_includes,
								 'driverWagesIncludes',rb.driver_wages_includes,
								 'driverWages',rb.driver_wages,
								 'description',rb.description,
								 'bookingId',rb.booking_id,
							     'tripPlan',rb.trip_plan,
	                             'tripPlanArray',(SELECT(REPLACE(trip_plan::text, E'\n', ','))),
	                             'count',_count,
								 'createdOn',rb.created_on,	
								 'activeFlag',rb.active_flag)) ) from rent.booking rb 
		 						inner join operator.org_vehicle ov
								on rb.vehicle_sno=ov.vehicle_sno
								where org_sno=(p_data->>'orgSno')::bigint AND
		                        case when (p_data->>'bookingSno')::bigint is not null then rb.booking_sno=(p_data->>'bookingSno')::bigint else true end and
		                        case when (p_data->>'vehicleSno')::bigint is not null then rb.vehicle_sno=(p_data->>'vehicleSno')::bigint else true end and
								case when (p_data->>'activeFlag') is not null 
								then rb.active_flag=(p_data->>'activeFlag')::boolean else true end);

								

end;
$BODY$;

--delete_booking
-----------------

CREATE OR REPLACE FUNCTION rent.delete_booking(p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
   AS $BODY$
declare
_booking_sno bigint;
begin
raise notice '%',p_data;

update rent.booking 
set active_flag=false 
where booking_sno =(p_data->>'bookingSno')::bigint 

returning booking_sno into _booking_sno;

return (select json_build_object('data',json_build_object('bookingSno',_booking_sno)));

end;
$BODY$;


--get_contact_carrage
----------------------


CREATE OR REPLACE FUNCTION rent.get_contact_carrage(p_data json)
    RETURNS json
AS $BODY$
declare
isBooked boolean;
begin

return (select json_build_object('data',(json_agg(json_build_object('vehicleSno',f.vehicle_sno,
	   'vehicleRegNumber',f.vehicle_reg_number,
	   'vehicleName',f.vehicle_name,
		'videoTypeName',(select json_agg(json_build_object('videoType', cd_value))from (SELECT cd_value FROM portal.codes_dtl WHERE codes_dtl_sno = ANY (ARRAY[f.video_types_cd]))vt),
		'audioTypeName',(select json_agg(json_build_object('audioType', cd_value))from (SELECT cd_value FROM portal.codes_dtl WHERE codes_dtl_sno = ANY (ARRAY[f.audio_types_cd]))adt),															
		'coolType',(select portal.get_enum_name(f.cool_type_cd,'cool_type_cd')),
		'busType',(select portal.get_enum_name(f.suspension_type,'bus_type_cd')),
		'seatType',(select portal.get_enum_name(f.seat_type_cd,'seat_type_cd')),
		'fuelType',(select portal.get_enum_name(f.fuel_type_cd,'fuel_type_cd')),
		'lightingSystemName',(select json_agg(json_build_object('lightingSystem', cd_value))from (SELECT cd_value FROM portal.codes_dtl WHERE codes_dtl_sno = ANY (ARRAY[f.lighting_system_cd]))l),
	    'pricePerDay',f.price_perday,
	    'seatCapacity',f.seat_capacity,
		'luckageCount',f.luckage_count,
		'topLuckageCarrier',f.top_luckage_carrier,
		'vehicle_model',f.vehicle_model,
		'districtSno',f.district_sno,
		'districtName',(select district_name from master_data.district d where d.district_sno = f.district_sno),															
		'media',(select media.get_media_detail(json_build_object('mediaSno',f.image_sno))),
		'isBooked',(select count(*) as isBooked from rent.booking b where vehicle_sno = f.vehicle_sno and (start_date >= (p_data->>'startDate')::timestamp or end_date >= (p_data->>'startDate')::timestamp)),
																	
-- 		'isBooked',(select count(*) as isBooked  from rent.booking b where vehicle_sno = (p_data->>'vehicleSno')::bigint and active_flag = true and
-- (((b.start_date between (p_data->>'startDate')::timestamp and (p_data->>'endDate')::timestamp) or
-- (b.end_date between (p_data->>'startDate')::timestamp and (p_data->>'endDate')::timestamp)) or
-- (((p_data->>'startDate')::timestamp between b.start_date and b.end_date) or 
-- ((p_data->>'endDate')::timestamp between b.start_date and b.end_date)))),															
		'vehicleBooked',(select  json_build_object(
						'bookingSno',ms.booking_sno,
						'vehicleSno',ms.vehicle_sno,
			            'startDate',ms.start_date,
			            'endDate',ms.end_date,
						'activeFlag',ms.active_flag)from (select * from rent.booking b where vehicle_sno = f.vehicle_sno and (start_date >= (p_data->>'startDate')::timestamp or end_date >= (p_data->>'startDate')::timestamp))ms),															
		'vehicleMake',(select portal.get_enum_name(f.vehicle_make_cd,'vehicleMakeCd'))))
		)) from (SELECT v.vehicle_sno,v.vehicle_reg_number, v.vehicle_name,vd.cool_type_cd,vd.suspension_type,vd.seat_type_cd,vd.fuel_type_cd, vd.price_perday, vd.seat_capacity, 
						vd.luckage_count,vd.top_luckage_carrier,vd.vehicle_model,vd.district_sno,vd.image_sno,vd.vehicle_make_cd,vd.video_types_cd,vd.audio_types_cd,vd.lighting_system_cd from  operator.vehicle v 
inner join operator.vehicle_detail vd on vd.vehicle_sno=v.vehicle_sno
inner join master_data.district d on d.district_sno = vd.district_sno
where v.vehicle_type_cd=22 and
CASE WHEN (p_data->>'districtSno')::bigint IS NOT NULL THEN vd.district_sno = (p_data->>'districtSno')::bigint ELSE TRUE END and
CASE WHEN (p_data->>'districtName') IS NOT NULL THEN d.district_name = (p_data->>'districtName') ELSE TRUE END
				 order by vd.district_sno offset (p_data->>'skip')::bigint  limit (p_data->>'limit')::bigint)f);
end;
$BODY$
LANGUAGE 'plpgsql';


--update_booking
-----------------

CREATE OR REPLACE FUNCTION rent.update_booking(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
_booking_sno bigint;
begin
raise notice 'update_booking %',p_data; 

update rent.booking set
    vehicle_sno = (p_data->>'vehicleSno')::bigint,
    start_date = (p_data->>'startDate')::timestamp,
	end_date = (p_data->>'endDate')::timestamp,
    customer_name = (p_data->>'customerName'),
    customer_address = (p_data->>'customerAddress'),
    no_of_days_booked = (p_data->>'noOfDaysBooked')::bigint,
    total_booking_amount = (p_data->>'totalBookingAmount')::double precision,
    advance_paid = (p_data->>'advancePaid')::double precision,
	balance_amount_to_paid = (p_data->>'balanceAmountTopaid')::double precision,
    toll_parking_includes = (p_data->>'tollParkingIncludes')::boolean,
    driver_wages_includes = (p_data->>'driverWagesIncludes')::boolean,
    driver_wages = (p_data->>'driverWages')::double precision,
	description = (p_data->>'description'),
    booking_id = (p_data->>'bookingId'),
    trip_plan = (p_data->>'tripPlan')
where booking_sno = (p_data->>'bookingSno')::bigint

returning booking_sno into _booking_sno;

return(select json_build_object('data',json_build_object('bookingSno',_booking_sno)));
end;
$BODY$;


-- --get_vehicle_count
-- -------------------

-- CREATE OR REPLACE FUNCTION rent.get_vehicle_count(p_data json)
--     RETURNS json
-- AS $BODY$
-- declare
-- _count bigint;
-- begin
 
--  select count(*) into _count from operator.vehicle v 
-- inner join operator.vehicle_detail vd on vd.vehicle_sno=v.vehicle_sno
-- where v.vehicle_type_cd=22 and vd.district_sno = (p_data->>'districtSno')::bigint;				   
-- return (select  json_build_object('data',json_agg(json_build_object('count',_count)))); 

-- end;
-- $BODY$
-- LANGUAGE 'plpgsql';


--get_vehicle_count
-------------------

CREATE OR REPLACE FUNCTION rent.get_vehicle_count(p_data json)
    RETURNS json
AS $BODY$
declare
_count bigint;
begin
 
 select count(*) into _count from operator.vehicle v 
inner join operator.vehicle_detail vd on vd.vehicle_sno=v.vehicle_sno
inner join master_data.district d on d.district_sno = vd.district_sno
where ((v.vehicle_type_cd=22 and vd.district_sno = (p_data->>'districtSno')::bigint) or v.vehicle_type_cd=22 and d.district_name = (p_data->>'districtName'));				   
return (select  json_build_object('data',json_agg(json_build_object('count',_count)))); 

end;
$BODY$
LANGUAGE 'plpgsql';