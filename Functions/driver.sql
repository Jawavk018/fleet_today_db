--insert_driver
-------------------

CREATE OR REPLACE FUNCTION driver.insert_driver(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare 
-- profile_media json := p_data->> 'media';
driverSno bigint;
begin
raise notice'%',p_data->>'licenceExpiryDate';
insert into driver.driver(driver_name,driver_mobile_number,driver_whatsapp_number,dob,father_name,media_sno,blood_group_cd,licence_number,licence_expiry_date,transport_licence_expiry_date,driving_licence_type,current_address,current_district,address,kyc_status,licence_front_sno,licence_back_sno) 
   values ((p_data->>'driverName'),(p_data->>'driverMobileNumber'),(p_data->>'whatsappNumber'),(select TO_DATE((p_data->>'dob'), 'YYYY/MM/DD')),p_data->>'fatherName',(p_data->>'mediaSno')::bigint,(p_data->>'bloodGroupCd')::smallint,
		   p_data->>'licenceNumber',(select TO_DATE((p_data->>'licenceExpiryDate'), 'YYYY/MM/DD')),(select TO_DATE((p_data->>'transportlicenceExpiryDate'), 'YYYY/MM/DD')),(p_data->>'drivingLicenceType')::int[],p_data->>'currentAddress',p_data->>'currentDistrict',p_data->>'address',20,(p_data->>'licenceFrontSno')::bigint,(p_data->>'licenceBackSno')::bigint) returning driver_sno  INTO driverSno;
return (select json_build_object('data',json_build_object('driverSno',driverSno)));
end;
$BODY$;

--get_driver
------------

CREATE OR REPLACE FUNCTION driver.get_driver(p_data json)
    RETURNS json
AS $BODY$
declare 
mileageDtl json;
_driver_list json;
begin

if(p_data->>'driverSno')::smallint is not null then
		select json_build_object(
			'drivingLicenceType',cd_value,
		    'mileage',(select avg(mileage::float) from driver.driver_mileage 
						where driver_sno=(p_data->>'driverSno')::bigint and driving_type_cd=codes_dtl_sno))into mileageDtl 
		from portal.codes_dtl where codes_hdr_sno = 18;
end if;

with driver as (select d.driver_sno,d.driver_name,d.driver_mobile_number,d.dob::date,d.father_name,d.address,d.current_address,d.current_district,
d.driver_whatsapp_number,d.media_sno,d.licence_number,d.licence_expiry_date::date,d.transport_licence_expiry_date::date,
d.driving_licence_type,d.blood_group_cd,od.org_sno,d.active_flag,d.kyc_status from driver.driver d
inner join operator.operator_driver od on od.driver_sno = d.driver_sno
where od.accept_status_cd=122 and
	case when (p_data->>'orgSno')::bigint is not null then od.org_sno=(p_data->>'orgSno')::bigint else true end and
	case when (p_data->>'selecteDate' = 'Driver Licence Expiry') then d.transport_licence_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and	
    case when (p_data->>'selecteDate' = 'Driver Licence Expiry') then d.licence_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and				
	case when (p_data->>'driverSno') is not null then d.driver_sno=(p_data->>'driverSno')::bigint else true end and
	case when (p_data->>'activeFlag') is not null then d.active_flag=(p_data->>'activeFlag')::boolean else true end and
	case when (p_data->>'searchKey') is not null then ((trim(d.driver_name) ilike ('%' || trim(p_data->>'searchKey') || '%')) or
				(trim(d.licence_number) ilike ('%' || trim(p_data->>'searchKey') || '%')))
				else true end order by
		  case when (p_data->>'expiryType' = 'Driver Licence Expiry') and d.transport_licence_expiry_date is null then 1 end desc,
		  case when (p_data->>'expiryType' = 'Driver Licence Expiry') and (d.transport_licence_expiry_date < (p_data->>'today')::date) then d.transport_licence_expiry_date end asc,
		  case when (p_data->>'expiryType' = 'Driver Licence Expiry') and ((d.transport_licence_expiry_date::date = (p_data->>'today')::date) or (d.transport_licence_expiry_date >= (p_data->>'today')::date)) then d.transport_licence_expiry_date end asc,  
		  case when (p_data->>'expiryType' = 'Driver Licence Expiry') then d.transport_licence_expiry_date end desc,
			
		  case when (p_data->>'expiryType' = 'Driver License Expiry') and d.licence_expiry_date is null then 1 end desc,
		  case when (p_data->>'expiryType' = 'Driver License Expiry') and (d.licence_expiry_date < (p_data->>'today')::date) then d.licence_expiry_date end asc,
		  case when (p_data->>'expiryType' = 'Driver License Expiry') and ((d.licence_expiry_date::date = (p_data->>'today')::date) or (d.licence_expiry_date >= (p_data->>'today')::date)) then d.licence_expiry_date end asc,  
		  case when (p_data->>'expiryType' = 'Driver License Expiry') then d.licence_expiry_date end desc, d.driver_sno offset (p_data->>'skip')::bigint  limit (p_data->>'limit')::bigint)
select json_agg(json_build_object(
		'driverSno',d.driver_sno,
		'driverName',d.driver_name,
		'driverMobileNumber',d.driver_mobile_number,
		'dob',d.dob::date,
		'fatherName',d.father_name,
		'address',d.address,
		'currentAddress',d.current_address,
		'currentDistrict',d.current_district,		
		'whatsappNumber',d.driver_whatsapp_number,
		'media',(select media.get_media_detail(json_build_object('mediaSno',d.media_sno))->>0)::json,
-- 		'document',(select media.get_media_detail(json_build_object('mediaSno',d.certificate_sno))->>0)::json,
		'licenceNumber',d.licence_number,
		'licenceExpiryDate',case when d.licence_expiry_date::date<d.transport_licence_expiry_date::date then d.licence_expiry_date::date else d.transport_licence_expiry_date::date end,
		'transportlicenceExpiryDate',d.transport_licence_expiry_date::date,
		'drivingLicenceType',d.driving_licence_type,
		'bloodGroupCd',d.blood_group_cd,
		'drivingLicenceCdVal',(select * from driver.get_licence_type(json_build_object('drivingLicenceType',d.driving_licence_type ))),
		'orgSno',d.org_sno,
		'activeFlag',d.active_flag,
		'attendanceStatus',(select attendance_status_cd from driver.driver_attendance where driver_sno = d.driver_sno order by driver_attendance_sno  desc  limit 1),
		'kmsDrived', (select sum(end_value::bigint) - sum(start_value::bigint)
					  from driver.driver_attendance 
					  where driver_sno=(p_data->>'driverSno')::bigint and attendance_status_cd=29
					 ),
		'noOfDaysDrived', (select count(distinct(date(end_time)))
					  from driver.driver_attendance
					  where driver_sno=(p_data->>'driverSno')::bigint),
		'fuelConsumed', (select sum(fuel_quantity) 
						 from operator.fuel
						 where driver_sno=(p_data->>'driverSno')::bigint),
		'mileageDetail',mileageDtl,
		'kycStatus',kyc_status
	)) into _driver_list from driver d;

return (select json_build_object('data',_driver_list));
end;
$BODY$
LANGUAGE plpgsql;



--create_driver
---------------------

CREATE OR REPLACE FUNCTION driver.create_driver(
	p_data json)
    RETURNS json
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare 
driverSno bigint;
_app_user_sno bigint;
isAlreadyExists boolean;
isAlreadyLicenceExists boolean;
begin

select count(*) > 0 into isAlreadyExists from driver.driver d 
where d.driver_mobile_number =(p_data->>'driverMobileNumber');

select count(*) > 0 into isAlreadyLicenceExists from driver.driver d 
where d.licence_number =(p_data->>'licenceNumber');

if isAlreadyLicenceExists then
  return (select json_build_object('data',json_build_object('msg','This Driver is Already Exists')));
elseif isAlreadyExists then
  return (select json_build_object('data',json_build_object('msg','This Mobile Number is Already Exists')));
end if;

select (select driver.insert_driver(p_data)->>'data')::json->>'driverSno' into driverSno;
if (p_data->>'roleCd')::smallint=6 then
	select app_user_sno into _app_user_sno from portal.app_user 
	where mobile_no=(p_data->>'driverMobileNumber');
	
	perform notification.insert_notification(json_build_object(
			'title','Welcome ','message','welcome to Driver Today','actionId',null,'routerLink','bus-dashboard','fromId',p_data->>'appUserSno',
			'toId',p_data->>'appUserSno',
			'createdOn',p_data->>'createdOn'
			)); 
else
	_app_user_sno = (p_data->>'appUserSno')::bigint;
end if;

perform driver.insert_driver_user(json_build_object('appUserSno',_app_user_sno,'driverSno',driverSno));
return (select json_build_object('data',json_build_object('driverSno',driverSno)));

end;
$BODY$
LANGUAGE plpgsql;


--insert_driver_attendance
----------------------------------

CREATE OR REPLACE FUNCTION driver.insert_driver_attendance(p_data json)
    RETURNS json
AS $BODY$
declare 
driverAttendanceSno bigint;
_open bigint;
driverName text;
fuelCapacity int;
begin
raise notice'%',p_data;

if((select odo_meter_value from operator.vehicle_detail where vehicle_sno=(p_data->>'vehicleSno')::bigint) < (p_data->>'endValue')::bigint) then
update operator.vehicle_detail set odo_meter_value=(p_data->>'endValue')::bigint where vehicle_sno=(p_data->>'vehicleSno')::bigint ;
end if;

select driver_name into driverName from driver.driver d
inner join driver.driver_attendance da on da.driver_sno= d.driver_sno
where d.driver_sno=(p_data->>'driverSno')::bigint;

select count(*) into _open from driver.driver_attendance where   vehicle_sno=(p_data->>'vehicleSno')::bigint and attendance_status_cd=28 
and (start_time::date <= (p_data->>'startTime')::date or start_time::date <= (p_data->>'endTime')::date);

select fuel_capacity into fuelCapacity from operator.vehicle_detail where vehicle_sno=(p_data->>'vehicleSno')::bigint;

if _open=0 then
insert into driver.driver_attendance(driver_sno,
									 vehicle_sno,
									 start_lat_long,
									 end_lat_long,
									 start_media,
									 start_time,
									 end_time,
									 start_value,
									 end_value,
									 attendance_status_cd,
									 accept_status) 
     values ((p_data->>'driverSno')::bigint,
			 (p_data->>'vehicleSno')::bigint,
			 (p_data->>'startLatLong'),
			 (p_data->>'endLatLong'),
			 (p_data->>'media')::json,
			 (p_data->>'startTime')::timestamp,
			 (p_data->>'endTime')::timestamp,
			 (p_data->>'startValue'),
			 (p_data->>'endValue'),
			 (p_data->>'attendanceStatusCd')::smallint,
			 (p_data->>'acceptStatus')::boolean
            ) returning driver_attendance_sno  INTO driverAttendanceSno;
if (select count(*) from operator.fuel where vehicle_sno=(p_data->>'vehicleSno')::bigint)=0 then
perform operator.insert_fuel(json_build_object(
'vehicleSno',(p_data->>'vehicleSno')::bigint,
'driverSno',(p_data->>'driverSno')::bigint,
'driverAttendanceSno',driverAttendanceSno,
'fuelQuantity',fuelCapacity,
'fuelAmount',99.22119*fuelCapacity,
'odoMeterValue',(p_data->>'startValue')::bigint,
'filledDate',(p_data->>'startTime')::timestamp,
'pricePerLtr',99.22119,
'isFilled',true,
'isCalculated',true
));
end if;
  return (select json_build_object('data',json_build_object('driverAttendanceSno',driverAttendanceSno)));
else
  return (select json_build_object('data',json_build_object('msg','This vehicle or Driver is driving')));
end if;
end;
$BODY$
LANGUAGE plpgsql;




--get_driver_info
---------------------

CREATE OR REPLACE FUNCTION driver.get_driver_info(p_data json)
    RETURNS json
AS $BODY$
declare 
begin
raise notice '%',p_data;

 return (select (json_build_object(
'driverAttendanceSno',da.driver_attendance_sno,
'vehicleSno',da.vehicle_sno,
'vehicleRegNumber',v.vehicle_reg_number,
'vehicleName',v.vehicle_name,
'startTime',da.start_time,	
'startValue',da.start_value,
'attendanceStatusCd',da.attendance_status_cd
 ))
	from driver.driver_attendance da 
		 inner join operator.vehicle v on v.vehicle_sno=da.vehicle_sno
		 where da.driver_sno=(p_data->>'driverSno')::bigint and da.attendance_status_cd=28); 
end;
$BODY$
LANGUAGE plpgsql;


--insert_driver_user
--------------------

CREATE OR REPLACE FUNCTION driver.insert_driver_user(p_data json)
    RETURNS json
AS $BODY$
declare 
driverUserSno bigint;
begin
insert into driver.driver_user(driver_sno,app_user_sno) 
   values ((p_data->>'driverSno')::bigint,(p_data->>'appUserSno')::bigint
          ) returning driver_user_sno  INTO driverUserSno;
return (select json_build_object('data',json_build_object('driverUserSno',driverUserSno)));
end;
$BODY$
LANGUAGE plpgsql;



--get_licence_type
--------------------

CREATE OR REPLACE FUNCTION driver.get_licence_type(p_data json)
    RETURNS json
AS $BODY$
declare 
i int;
_licence json;
begin

-- FOREACH i in  Array  (p_data->>'drivingLicenceType')::int[]  loop
-- raise notice 'v_data%',i ;
-- end loop;

 select json_agg(cd_value) into _licence
	  from portal.codes_dtl where codes_hdr_sno = 18  and  ('{' || codes_dtl_sno || '}')::int[] &&  translate ((p_data->>'drivingLicenceType')::text,'[]','{}')::int[] ;
	  
return _licence;

end;
$BODY$
 LANGUAGE plpgsql;

--update_driver_attendance
----------------------------
CREATE OR REPLACE FUNCTION operator.update_driver_attendance(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
AS $BODY$
declare
reportId bigint;
begin

	if (p_data->>'reportId')::bigint is null then
	select report_id into reportId from operator.fuel where vehicle_sno=(p_data->>'vehicleSno')::bigint and is_calculated=false order by filled_date desc limit 1;
	else
	reportId:=(p_data->>'reportId')::bigint;
	end if;
raise notice 'update_org_sgl %',p_data;
update operator.vehicle_detail set odo_meter_value=(p_data->>'endValue')::bigint where vehicle_sno=(p_data->>'vehicleSno')::bigint ;
update driver.driver_attendance set end_media = (p_data->>'media')::json,
end_time = (p_data->>'endTime')::timestamp,
end_value = (p_data->>'endValue'),
attendance_status_cd = 29,
report_id=reportId
where driver_attendance_sno = (p_data->>'driverAttendanceSno')::bigint;
-- if (select count(*) from operator.fuel where driver_attendance_sno=(p_data->>'driverAttendanceSno')::bigint and is_filled=true)>0 then
-- perform driver.insert_bus_report((p_data::jsonb || json_build_object('driverAttendanceSno',(p_data->>'driverAttendanceSno')::bigint,
-- 																			'odoMeterValue',(p_data->>'odoMeterValue')::bigint,
-- 																			'driverSno',(p_data->>'driverSno')::bigint,
-- 																			'filledDate',(p_data->>'filledDate')::timestamp)::jsonb)::json);
-- end if;
return 
( json_build_object('data',json_build_object('driverAttendanceSno',(p_data->>'driverAttendanceSno')::bigint)));
end;
$BODY$;

--get_barcode_vehicles_dtl
---------------------------

CREATE OR REPLACE FUNCTION driver.get_barcode_vehicles_dtl(p_data json)
RETURNS json
AS $BODY$
declare 
begin
raise notice '%',p_data;
return (select json_build_object('data',json_build_object('vehicleSno',vehicle_sno,'vehicleName',vehicle_name))
    from operator.vehicle  where vehicle_reg_number=p_data->>'vehicleRegNumber' and active_flag = true); 
end;
$BODY$
LANGUAGE plpgsql;


--add_driver_mileage
---------------------
CREATE OR REPLACE FUNCTION driver.insert_driver_mileage(p_data json)
    RETURNS json
AS $BODY$
declare 
_driver_mileage_sno bigint;
begin
raise notice 'p_data %',p_data;
insert into driver.driver_mileage(driver_sno,driving_type_cd,mileage,fuel,kms,vehicle_sno,active_flag) 
values((p_data->>'driverSno')::bigint,
	   (p_data->>'drivingTypeCd')::bigint,
	   (p_data->>'mileage'),
	   (((p_data->>'drivedKm')::smallint)/((p_data->>'mileage')::double precision))::double precision,
	   (p_data->>'drivedKm'),
	   (p_data->>'vehicleSno')::bigint,true) 
returning driver_mileage_sno into _driver_mileage_sno;
return (select json_build_object('data', json_build_object('driverMileageSno',_driver_mileage_sno)));
end;
$BODY$
LANGUAGE plpgsql;


--update_driver
---------------

CREATE OR REPLACE FUNCTION driver.update_driver(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
_driver_sno bigint;
appUserSno bigint;
profile_media json := p_data->>'media';
licence_front json := p_data->>'licenceFrontMedia';
licence_back json := p_data->>'licenceBackMedia';
document_media json := p_data->>'document';
begin
select app_user_sno into appUserSno 
from driver.driver_user 
where driver_sno=(p_data->>'driverSno')::bigint;

update portal.app_user 
set mobile_no=(p_data->>'driverMobileNumber') 
where app_user_sno=appUserSno;

if (p_data->>'kycStatus')::smallint = 58 then
update driver.driver set kyc_status = 20
where driver_sno = (p_data->>'driverSno')::bigint;
end if;

update driver.driver 
set driver_name =(p_data->>'driverName'),
	driver_mobile_number = (p_data->>'driverMobileNumber'),
	driver_whatsapp_number = (p_data->>'whatsappNumber'),
	dob = (p_data->>'dob')::timestamp,
	father_name = (p_data->>'fatherName'),
	address = (p_data->>'address'),
	current_address = (p_data->>'currentAddress'),
	media_sno=(profile_media->>'mediaSno')::bigint,
-- 	certificate_sno=(document_media->>'mediaSno')::bigint,
--	certificate_description = (p_data->>'description'),
	licence_number=(p_data->>'licenceNumber'),
	licence_expiry_date = (p_data->>'licenceExpiryDate')::timestamp,
	transport_licence_expiry_date = (p_data->>'transportlicenceExpiryDate')::timestamp,
	driving_licence_type=(p_data->>'drivingLicenceType')::text[]::int[],
	current_district = (p_data->>'currentDistrict')::bigint,
	blood_group_cd = (p_data->>'bloodGroupCd')::smallint,
	licence_front_sno=(licence_front->>'licenceFrontSno')::bigint,
	licence_back_sno=(licence_back->>'licenceBackSno')::bigint
where driver_sno = (p_data->>'driverSno')::bigint
returning driver_sno into _driver_sno;

return(select json_build_object('data',_driver_sno));
end;
$BODY$;




--check_otometer_reading
-------------------------

CREATE OR REPLACE FUNCTION driver.check_odometer_reading(p_data json)
    RETURNS json
AS $BODY$
declare 
begin
return ( select json_build_object('data',(select json_agg(json_build_object(
	'currentOdoMeterValue',(select odo_meter_value from  operator.vehicle_detail where vehicle_sno=(p_data->>'vehicleSno')::bigint ))))) );
end;
$BODY$
LANGUAGE plpgsql;


--get_attendance_info
-----------------------

CREATE OR REPLACE FUNCTION driver.get_attendance_info(
	p_data json)
    RETURNS json
AS $BODY$
	declare 
	begin
	return (
	select json_build_object('data',(select json_agg(json_build_object(
	'driverSno',d.driver_sno,
	'vehicleNumber',d.vehicle_reg_number,
	'driverName',d.driver_name,
	'endLatLong',d.end_lat_long,
	'startLatLong',d.start_lat_long,
	'startMedia',d.start_media,
	'endMedia',d.end_media,
	'startTime',d.start_time,
	'endTime',d.end_time,
	'endValue',d.end_value,
	'driverAttendanceSno',d.driver_attendance_sno,
	'vehicleSno',d.vehicle_sno,
	'attendanceStatusCd',d.attendance_status_cd,
	'startValue',d.start_value,
	'endValue',d.end_value,
	'fuelQuantity',(select sum(fuel_quantity) from operator.fuel where price_per_ltr<>99.22119 and report_id=d.report_id and driver_attendance_sno=d.driver_attendance_sno),
	'acceptStatus',d.accept_status,
	'drivedKm',(d.end_value::bigint-d.start_value::bigint),
	'mileage',(select(select (sum(da.end_value::bigint)-sum(da.start_value::bigint)) from driver.driver_attendance da where report_id=d.report_id  and is_calculated=true)/(select sum(f.fuel_quantity) from operator.fuel f where report_id=d.report_id  and is_calculated=true))
	))))from(select da.driver_sno,v.vehicle_reg_number,dr.driver_name,da.end_lat_long,da.start_lat_long,da.start_media,
			  da.end_media,da.start_time,da.end_time,da.driver_attendance_sno,da.vehicle_sno,
			   da.attendance_status_cd,da.start_value,da.end_value,da.accept_status,da.report_id
				from driver.driver_attendance da
				inner join operator.vehicle v on v.vehicle_sno=da.vehicle_sno
				inner join driver.driver dr on dr.driver_sno=da.driver_sno
		  		inner join operator.org_vehicle ov on ov.vehicle_sno=da.vehicle_sno	 
		  where  ov.org_sno=(p_data->>'orgSno')::bigint  and
		da.active_flag=true and da.attendance_status_cd = 29 and
		case when (p_data->>'vehicleSno') is not null then da.vehicle_sno=(p_data->>'vehicleSno')::bigint else true end and
		case when (p_data->>'driverSno') is not null then da.driver_sno=(p_data->>'driverSno')::bigint else true end and
		case when (p_data->>'date')::date is not null then  da.end_time::date=(p_data->>'date')::date else true end	and
		case when ((p_data->>'vehicleSno') is null) and ((p_data->>'date')::date is null) and ((p_data->>'driverSno') is null) then da.start_time::date >= current_date - interval '7 days' else true end  
			   order by driver_attendance_sno desc

)d);
	end;
$BODY$
LANGUAGE 'plpgsql';


	
--get_driver_mileage
----------------------
CREATE OR REPLACE FUNCTION driver.get_driver_mileage(p_data json)
    RETURNS json
AS $BODY$
declare 
totalKms bigint;
minMileage bigint;
begin
raise notice 'update_org_sgl %',p_data;  
 select sum(dm.kms::double precision) into totalKms from driver.driver_mileage dm;
 select min(dm.mileage::double precision) into minMileage from driver.driver_mileage dm;
   
 return (select json_build_object('data',json_agg(json_build_object('driverMileageSno',dm.driver_mileage_sno,'driverSno',dm.driver_sno,'classTypeSno',dm.class_type_sno,'mileage',minMileage,'kms',kms,'driverName',d.driver_name,'photo',d.photo,'licenceNumber',d.licence_number))))
 from driver.driver_mileage dm
 inner join driver.driver d on d.driver_sno=dm.driver_sno 
	 where case when (p_data->>'driverSno') is Not null then dm.driver_sno=(p_data->>'driverSno')::bigint else true end;
end;
$BODY$
LANGUAGE plpgsql;


--get_driver_license
--------------------

CREATE OR REPLACE FUNCTION driver.get_driver_license(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
AS $BODY$
declare 
driver_count int := 0;
dataList json;
begin

select json_build_object('data',json_agg(json_build_object('driverSno',d.driver_sno,
   'driverName',d.driver_name,
   'driverMobileNumber',d.driver_mobile_number,
   'dob',d.dob::date,
   'fatherName',d.father_name,
   'mediaSno',case when d.media_sno is not null then (select media.get_media_detail(json_build_object('mediaSno',d.media_sno))->0) end,
   'licenceNumber',d.licence_number,
   'licenceExpiryDate',d.licence_expiry_date::date,
   'acceptStatusCd',(select accept_status_cd from operator.operator_driver od where od.driver_sno=d.driver_sno and od.org_sno = (p_data->>'orgSno')::bigint ),
-- 	'acceptStatusCdVal',(select portal.get_enum_name(d.accept_status_cd,'accept_status_cd')),
   'drivingLicenceType',d.driving_licence_type,
   'drivingLicenceCdVal',(select * from driver.get_licence_type(json_build_object('drivingLicenceType',d.driving_licence_type ))),
    'activeFlag',d.active_flag,
	'kycStatus',d.kyc_status
  ))) into dataList from driver.driver d where case when (p_data->>'activeFlag') is not null then d.active_flag=(p_data->>'activeFlag')::boolean else true end and
case when (p_data->>'searchKey' is not null) then ((d.licence_number ilike ('%' || trim((p_data->>'searchKey')::text) || '%')))
else false end and d.driver_sno not in
(with operator_driver as(select od.driver_sno from operator.operator_driver od where od.org_sno = (p_data->>'orgSno')::bigint and od.accept_status_cd=122)
select * from operator_driver od);

return dataList;

end;
$BODY$;

--insert_bus_report
---------------------

CREATE OR REPLACE FUNCTION driver.insert_bus_report(p_data json)
		RETURNS json
	AS $BODY$
	declare 
	busReportSno bigint;
	vehicleData json;
	v_data json;
	r_data json;
	begin
	raise notice'muthu123432%',p_data;
	for r_data in SELECT * FROM json_array_elements((p_data->>'reportId')::json) loop
	raise notice'r_data%',r_data;
	
	select json_agg(json_build_object( 
		'orgSno',(select org_sno from operator.org_vehicle where vehicle_sno=da.vehicle_sno),
		'vehicleSno',da.vehicle_sno,
		'driverSno',da.driver_sno,
		'driverAttendanceSno',da.driver_attendance_sno,
		'drivingTypeCd',(select driving_type_cd from operator.vehicle_detail where vehicle_sno=da.vehicle_sno),
		'startDate',da.start_time,
		 'endDate',da.end_time,
		 'startValue',da.start_value,
		 'endValue',da.end_value,
		'drivedKm',(da.end_value::bigint  - da.start_value::bigint),
		'fuelConsumed',(select sum(fuel_quantity) from operator.fuel where driver_attendance_sno=da.driver_attendance_sno and is_calculated=false),
	'totalKm',(	select (sum(da.end_value::bigint)-sum(da.start_value::bigint)) from driver.driver_attendance da where report_id=(r_data->>'reportId')::bigint and is_calculated=false),
	'totalFuel',(select sum(f.fuel_quantity) from operator.fuel f where report_id=1 and is_calculated=false),
	'mileage',((	select (sum(da.end_value::bigint)-sum(da.start_value::bigint)) from driver.driver_attendance da where report_id=(r_data->>'reportId')::bigint and is_calculated=false)/(select sum(f.fuel_quantity) from operator.fuel f where report_id=(r_data->>'reportId')::bigint and is_calculated=false))
		)) into vehicleData from driver.driver_attendance da
		where report_id=(r_data->>'reportId')::bigint and is_calculated=false;
	raise notice'vehicleData%',vehicleData;
	 for v_data in SELECT * FROM json_array_elements((vehicleData)::json) loop
	 raise notice'%v_data',v_data;
	  perform  driver.insert_driver_mileage(v_data);
	  insert into operator.bus_report(org_sno,vehicle_sno,driver_sno,driver_attendance_sno,driving_type_cd,start_km,end_km,drived_km,start_date,
		end_date,fuel_consumed,mileage,created_on) values
	  ((v_data->>'orgSno')::bigint,(v_data->>'vehicleSno')::bigint,(v_data->>'driverSno')::bigint,(v_data->>'driverAttendanceSno')::bigint,(v_data->>'drivingTypeCd')::smallint,
	   (v_data->>'startValue')::bigint,(v_data->>'endValue')::bigint,(v_data->>'drivedKm')::numeric,(v_data->>'startDate')::timestamp,
	   (v_data->>'endDate')::timestamp,(v_data->>'fuelConsumed')::double precision,
	   (v_data->>'mileage')::double precision,(select now()))
	   returning bus_report_sno into busReportSno;
	update operator.fuel set is_calculated=true where driver_attendance_sno=(v_data->>'driverAttendanceSno')::bigint;
	update driver.driver_attendance set is_calculated=true where driver_attendance_sno=(v_data->>'driverAttendanceSno')::bigint;
	end loop;
	end loop;
	return (select json_build_object('data',(select json_agg(json_build_object('isUpdated',true)))));
	end;
	$BODY$
	LANGUAGE plpgsql; 

--check_driver_org
-------------------
CREATE OR REPLACE FUNCTION driver.check_driver_org(p_data json)
RETURNS json
AS $BODY$
declare 
driverOrg json;
begin
select json_agg(json_build_object(
'orgSno',od.org_sno,'driverSno',od.driver_sno,'orgName',o.org_name,'ownerName',o.owner_name
)) from into driverOrg operator.operator_driver od 
inner join operator.org o on o.org_sno=od.org_sno where od.driver_sno=(p_data->>'driverSno')::bigint and o.org_status_cd=19;
return (select json_build_object('data',driverOrg));
end;
$BODY$
LANGUAGE plpgsql;


--get_driver_dtl
-----------------

CREATE OR REPLACE FUNCTION driver.get_driver_dtl(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare 
mileageDtl json;
driver_list json;
notification_count bigint;
notificationDtl json;
begin
raise notice 'update_vehicle %',p_data;

select count(*) into notification_count  from  notification.notification where to_id = (p_data->>'toId')::bigint and action_id = 5;
if(p_data->>'driverSno')::smallint is not null then
raise notice 'if1 %',notification_count;
		select json_agg(json_build_object(
			'drivingLicenceType',cd_value, 
		    'mileage',(select avg(mileage::float) from driver.driver_mileage  dm  
					   where dm.driver_sno=(p_data->>'driverSno')::bigint and dm.driving_type_cd = codes_dtl_sno 
					     and  dm.vehicle_sno  in ( select vehicle_sno from driver.driver_attendance where accept_status = true) 
					  ))into mileageDtl) 
		from portal.codes_dtl where codes_hdr_sno = 18 ;
end if;

raise notice 'notification_count %',notification_count;
if (notification_count > 0) then
raise notice 'if %',notification_count;
	select json_agg(json_build_object(
	'notificationSno',notification_sno,	
    'title',title, 
    'message',message,
    'actionId',action_id,
    'routerLink',router_link,
	'fromId',from_id,
	'toId',to_id,
	'createdOn',created_on,
	'notificationStatusCd',notification_status_cd )into notificationDtl) 
   from notification.notification where to_id = (p_data->>'toId')::bigint and action_id = 5;
end if;
raise notice 'notificationDtl %',notificationDtl;

with driver as(select * from driver.driver d where 
	case when (p_data->>'driverSno') is not null then d.driver_sno=(p_data->>'driverSno')::bigint else true end and
	case when (p_data->>'driverSno') is null then d.kyc_status = 19 else true end and
	case when (p_data->>'activeFlag') is not null then d.active_flag=(p_data->>'activeFlag')::boolean and d.kyc_status = 19 else true end and
	case when (p_data->>'searchKey' is not null) then ((d.driver_name ilike ('%' || trim((p_data->>'searchKey')::text) || '%')) or 
													   (d.licence_number ilike ('%' || trim((p_data->>'searchKey')::text) || '%')))
	else true end and
	case when (p_data->>'district' is not null and trim(p_data->>'district') <> '') then
	lower(trim(current_district)) in (select lower(trim(a::text)) from json_array_elements_text((p_data->>'district')::json)a)
	else true end order by d.driver_sno offset (p_data->>'skip')::bigint  limit (p_data->>'limit')::bigint)
	
	select json_agg(json_build_object(
		'driverSno',d.driver_sno,
		'driverName',d.driver_name,
		'driverMobileNumber',d.driver_mobile_number,
		'dob',d.dob::date,
		'fatherName',d.father_name,
		'address',d.address,
		'currentAddress',d.current_address,
		'currentDistrict',d.current_district,
		'currentDistrictName',(select district_name from master_data.district where district_sno = (d.current_district)::bigint),		
		'whatsappNumber',d.driver_whatsapp_number,
		'media',(select media.get_media_detail(json_build_object('mediaSno',d.media_sno))->>0)::json,
		'licenceFrontMedia',(select media.get_media_detail(json_build_object('mediaSno',d.licence_front_sno))->>0)::json,
		'licenceBackMedia',(select media.get_media_detail(json_build_object('mediaSno',d.licence_back_sno))->>0)::json,
-- 		'document',(select media.get_media_detail(json_build_object('mediaSno',d.certificate_sno))->>0)::json,
		'licenceNumber',d.licence_number,
		'licenceExpiryDate',d.licence_expiry_date::date,
		'transportlicenceExpiryDate',d.transport_licence_expiry_date::date,
		'drivingLicenceType',d.driving_licence_type,
		'drivingLicenceCdVal',(select * from driver.get_licence_type(json_build_object('drivingLicenceType',d.driving_licence_type ))),
-- 		'orgSno',od.org_sno,
		'bloodGroupCd',d.blood_group_cd,
		'bloodGroupType',(select portal.get_enum_name(d.blood_group_cd,'blood_group_cd')),
		'activeFlag',d.active_flag,
		'kmsDrived', (select sum(end_value::bigint) - sum(start_value::bigint)
					  from driver.driver_attendance 
					  where driver_sno=(p_data->>'driverSno')::bigint and attendance_status_cd=29
					 ),
		'noOfDaysDrived', (select count(distinct(date(end_time)))
					  from driver.driver_attendance
					  where driver_sno=(p_data->>'driverSno')::bigint),
		'fuelConsumed', (select sum(fuel_quantity) 
						 from operator.fuel
						 where driver_sno=(p_data->>'driverSno')::bigint and price_per_ltr<>99.22119),
		'mileageDetail',mileageDtl,
		'kycStatus',kyc_status,
		'rejectReason',reject_reason,
		'notificationDetails',notificationDtl
	)) into driver_list from driver d;
	
	raise notice 'notification %',notification_count;
return (select json_build_object('data',driver_list));

end;
$BODY$;



--get_all_driver_count
-----------------------

CREATE OR REPLACE FUNCTION driver.get_all_driver_count(p_data json)
	RETURNS json
	LANGUAGE 'plpgsql'
	AS $BODY$
	declare
	_count bigint;
	begin
	raise notice 'count%',(p_data);

	if(p_data->>'orgSno')::bigint is not null then
	raise notice 'if%',(p_data);
	
		with op_driver as (select * from operator.operator_driver od where od.org_Sno = (p_data->>'orgSno')::bigint and od.accept_status_cd=122 and od.active_flag = true) 
		select count(*) into _count from op_driver od
		inner join driver.driver d on d.driver_sno = od.driver_sno and d.kyc_status = 19 and d.active_flag=(p_data->>'activeFlag')::boolean where 
		od.org_sno=(p_data->>'orgSno')::bigint and od.accept_status_cd=122  and
		case when (p_data->>'selecteDate'  = 'Driver Licence Expiry')  then d.licence_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end or	
		case when (p_data->>'selecteDate'  = 'Driver Licence Expiry')  then d.transport_licence_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and
--         case when (p_data->>'selecteDate'  = 'Driver Licence Expiry')  then (d.licence_expiry_date::date) or (d.transport_licence_expiry_date::date) < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and	
		case when (p_data->>'district' is not null and trim(p_data->>'district') <> '') then
		lower(trim(current_district)) in (select lower(trim(a::text)) from json_array_elements_text((p_data->>'district')::json)a)
		else true end and
			case when (p_data->>'searchKey') is not null then ((trim(d.driver_name) ilike ('%' || trim(p_data->>'searchKey') || '%')) or
					(trim(d.licence_number) ilike ('%' || trim(p_data->>'searchKey') || '%')))
					else true end;
		return (select  json_build_object('data',json_agg(json_build_object('count',_count))));
	else
	raise notice 'else%',(p_data);
	
		select count(*) into _count from driver.driver d where d.kyc_status = 19 and
		case when (p_data->>'district' is not null and trim(p_data->>'district') <> '') then
		lower(trim(current_district)) in (select lower(trim(a::text)) from json_array_elements_text((p_data->>'district')::json)a)
		else true end and
		case when (p_data->>'searchKey') is not null then ((trim(d.driver_name) ilike ('%' || trim(p_data->>'searchKey') || '%')) or
					(trim(d.licence_number) ilike ('%' || trim(p_data->>'searchKey') || '%')))
					else true end;
		return (select  json_build_object('data',json_agg(json_build_object('count',_count))));
	end if;

	end;
	$BODY$;


--get_current_district
-----------------------

CREATE OR REPLACE FUNCTION driver.get_current_district(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare 
begin

return (select json_build_object('data',(select json_agg(json_build_object(
	'districtSno',md.district_sno,
	'districtName',md.district_name,
	'activeFlag',md.active_flag
))))from (select dd.active_flag,dd.district_sno,dd.district_name 
		  from master_data.district dd
		  inner join driver.driver d on cast(d.current_district as int) = dd.district_sno  group by dd.district_sno
		 )md);
	   

end;
$BODY$;


--update_driver_accept_status
-----------------------------


CREATE OR REPLACE FUNCTION driver.update_driver_accept_status(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare 
toId bigint;
token_list json;
orgSno bigint;
orgName text;
begin
raise notice ' p_dataii %',p_data;  

if (p_data->>'acceptStatusCd')::smallint = 123 then
raise notice ' if123 %',p_data;
select org_sno into orgSno from operator.org_owner where app_user_sno=(p_data->>'toId')::bigint;
raise notice ' org %',orgSno;
update notification.notification set action_id=null,active_flag=false where notification_sno=(p_data->>'notificationSno')::bigint;
delete from operator.operator_driver
where driver_sno = (p_data->>'driverSno')::bigint and org_sno = orgSno::bigint;

elseif (p_data->>'acceptStatusCd')::smallint = 122 then
select org_sno into orgSno from operator.org_owner where app_user_sno=(p_data->>'toId')::bigint;
update notification.notification set action_id=null,active_flag=false where notification_sno=(p_data->>'notificationSno')::bigint;
-- perform operator.insert_operator_driver((select (p_data)::jsonb || ('{"orgSno": ' || orgSno ||' }')::jsonb )::json);
update operator.operator_driver set accept_status_cd = (p_data->>'acceptStatusCd')::smallint where driver_sno=(p_data->>'driverSno')::bigint; 

elseif (p_data->>'acceptStatusCd')::smallint = 125 then
select org_name into orgName from operator.org where org_sno=(p_data->>'orgSno')::bigint;
p_data := (p_data::jsonb || jsonb_build_object('message',((p_data->>'message')::text||' '||orgName::text)))::json;
raise notice'%',p_data;
perform operator.insert_operator_driver(p_data);
end if;

select app_user_sno into toId from driver.driver_user where driver_sno=(p_data->>'driverSno')::bigint;
-- update driver.driver set accept_status_cd = (p_data->>'acceptStatusCd')::smallint where driver_sno=(p_data->>'driverSno')::bigint; 
perform notification.insert_notification(json_build_object(
			'title', p_data->>'title','message',(p_data->>'message') ,'actionId',case when (p_data->>'acceptStatusCd')::smallint = 125::smallint then 5 else null end,'routerLink','/driver','fromId',(p_data->>'appUserSno')::bigint,
			'toId',case when (p_data->>'toId')::bigint is not null then (p_data->>'toId')::bigint else toId end,
			'createdOn',p_data->>'createdOn'
			)); 
select (select notification.get_token(json_build_object('appUserList',json_agg(toId)))->>'tokenList')::json into token_list;

 return (select json_build_object('data',json_build_object('status','updated','notification',json_build_object('notification',json_build_object('title',p_data->>'title','body', (p_data->>'message') ,'data',''),
										'registration_ids',token_list))));
end;
$BODY$;


--get_driving_vehicle
---------------------

CREATE OR REPLACE FUNCTION driver.get_driving_vehicle(p_data json)
RETURNS json
AS $BODY$
declare 
begin
raise notice '%',p_data;

 return (select json_build_object('data',json_agg(json_build_object(
'driverAttendanceSno',vd.driver_attendance_sno,	 
'VehicleName',vd.vehicle_name,
'vehicleSno',vd.vehicle_sno,
'vehicleRegNumber',vd.vehicle_reg_number,
'driverName',vd.driver_name,
'mobileNumber',vd.driver_mobile_number,
'startValue',vd.start_value,	 
'startTime',vd.start_time
 )))			
		 from (select da.driver_attendance_sno,v.vehicle_name,v.vehicle_sno,v.vehicle_reg_number,d.driver_name,d.driver_mobile_number,da.start_value,da.start_time from driver.driver_attendance da
				inner join operator.vehicle v on v.vehicle_sno = da.vehicle_sno
				inner join driver.driver d on d.driver_sno = da.driver_sno
			    inner join operator.org_vehicle ov on ov.vehicle_sno = da.vehicle_sno where ov.org_sno=(p_data->>'orgSno')::bigint AND v.active_flag = true and da.attendance_status_cd=28 
			   and 	case when (p_data->>'searchKey') is not null then ((trim(d.driver_name) ilike ('%' || trim(p_data->>'searchKey') || '%')) or
				(trim(v.vehicle_reg_number) ilike ('%' || trim(p_data->>'searchKey') || '%')))
				else true end order by ov.org_sno asc offset (p_data->>'skip')::bigint limit (p_data->>'limit')::bigint)vd);

end;
$BODY$
LANGUAGE plpgsql;




--get_driving_vehicle_count
---------------------------


CREATE OR REPLACE FUNCTION driver.get_driving_vehicle_count(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
_count bigint;
begin
select count(*) into _count from driver.driver_attendance da
				inner join operator.vehicle v on v.vehicle_sno = da.vehicle_sno
				inner join driver.driver d on d.driver_sno = da.driver_sno
			    inner join operator.org_vehicle ov on ov.vehicle_sno = da.vehicle_sno where ov.org_sno= (p_data->>'orgSno')::bigint AND v.active_flag = true and da.attendance_status_cd=28 and
case when (p_data->>'vehicleSno')::bigint is not null then v.vehicle_sno=(p_data->>'vehicleSno')::bigint else true end and 
case when (p_data->>'driverSno')::bigint is not null then d.driver_sno=(p_data->>'driverSno')::bigint else true end and
case when (p_data->>'searchKey') is not null then ((trim(d.driver_name) ilike ('%' || trim(p_data->>'searchKey') || '%')) or
				(trim(v.vehicle_reg_number) ilike ('%' || trim(p_data->>'searchKey') || '%')))
				else true end;

return (select  json_build_object('data',json_agg(json_build_object('count',_count))));

end;
$BODY$;



--insert_job_post
-----------------

CREATE OR REPLACE FUNCTION driver.insert_job_post(
	p_data json)
    RETURNS json
AS $BODY$
declare 
jobPostSno bigint;
begin
raise notice 'insert_org_detail  %',p_data;

insert into driver.job_post(org_sno,driver_sno,role_cd,start_date,end_date,user_lat_long,lat,lng,contact_name,contact_number,app_user_sno,drive_type_cd,job_type_cd,active_flag,auth_type_cd,distance,description,posted_on,fuel_type_cd,transmission_type_cd ) 
     values (case when (p_data->>'orgSno')::bigint is not null then (p_data->>'orgSno')::bigint else null end,
			 case when (p_data->>'driverSno')::bigint is not null then (p_data->>'driverSno')::bigint else null end,
			 (p_data->>'roleCd')::smallint,
			 (p_data->>'startDate')::timestamp,
			 (p_data->>'endDate')::timestamp,
			 (p_data->>'userLatLong')::json,
			 (p_data->>'lat'),
			 (p_data->>'lng'),
			 case when (p_data->>'orgSno')::bigint is not null or (p_data->>'authTypeCd')::smallint = 167 then (p_data->>'contactName')::text else null end,
			 case when (p_data->>'orgSno')::bigint is not null or (p_data->>'authTypeCd')::smallint = 167 then (p_data->>'contactNumber')::text else null end,
			 (p_data->>'appUserSno')::smallint,
			 (p_data->>'driveTypeCd')::smallint[],
			 (p_data->>'jobTypeCd')::smallint[],
			 (p_data->>'activeFlag')::boolean,
			 (p_data->>'authTypeCd')::smallint,
			 (p_data->>'distance')::numeric,
			 (p_data->>'description'),
			 portal.get_time_with_zone(json_build_object('timeZone',p_data->>'postedOn'))::timestamp,
			 (p_data->>'fuelTypeCd')::smallint[],           
        	 (p_data->>'transmissionTypeCd')::smallint[] 
            ) returning job_post_sno  INTO jobPostSno;

  return (select json_build_object('data',json_build_object('jobPostSno',jobPostSno)));
  
end;
$BODY$
LANGUAGE 'plpgsql';





--get_job_post
--------------


CREATE OR REPLACE FUNCTION driver.get_job_post(
	p_data json)
    RETURNS json
AS $BODY$
declare 
begin
raise notice 'update_org_sgl %',p_data;  
 return (select json_build_object('data',json_agg(json_build_object(
	 'jobPostSno',vd.job_post_sno,
	 'orgSno',vd.org_sno,
	 'orgName',(select org_name from operator.org o inner join driver.job_post jp on jp.org_sno=o.org_sno where job_post_sno = vd.job_post_sno),
	 'roleCd',vd.role_cd,
	 'driverSno',vd.driver_sno,
	 'driverName',(select driver_name from driver.driver d inner join driver.job_post jp on jp.driver_sno = d.driver_sno where job_post_sno = vd.job_post_sno),
	 'media',(select media.get_media_detail(json_build_object('mediaSno',(select media_sno from driver.driver d where driver_sno = vd.driver_sno)))->>0)::json,
	 'startDate',vd.start_date,
	 'endDate',vd.end_date,
	 'userLocation',vd.user_lat_long,
	 'userLatLong',(SELECT user_lat_long -> 'place' As la FROM driver.job_post where job_post_sno = vd.job_post_sno),
	 'lat',vd.lat,
	 'lng',vd.lng,
	 'distance',vd.distance,
	 'contactName',vd.contact_name,
	 'contactNumber',vd.contact_number,
	  'driveTypeCd',vd.drive_type_cd,
	 'driveTypeName',(select operator.get_codesHdrType(json_build_object('codesHdrType',vd.drive_type_cd,'codesHdrSno',39))),
	  'jobTypeCd',vd.job_type_cd,
	 'jobTypename',(select operator.get_codesHdrType(json_build_object('codesHdrType',vd.job_type_cd,'codesHdrSno',40))),
	 'fuelTypeCd',vd.fuel_type_cd,
	 'fuelTypeName',(select operator.get_codesHdrType(json_build_object('codesHdrType',vd.fuel_type_cd,'codesHdrSno',9))),
	   'transmissionTypeCd',vd.transmission_type_cd,
	 'transmissionTypeName',(select operator.get_codesHdrType(json_build_object('codesHdrType',vd.transmission_type_cd,'codesHdrSno',41))),
	 'authTypeCd',vd.auth_type_cd,
	 'activeFlag',vd.active_flag,
	 -- 'appUserSno',vd.appUserSno,
	 'description',vd.description,
	 'postedOn',vd.posted_on
 )))
 from (select * from driver.job_post ov
-- inner join driver.driver d on d.driver_sno=ov.driver_sno 
 where case when (p_data->>'orgSno')::bigint is not null then ov.org_sno=(p_data->>'orgSno')::bigint else true end  and
 case when (p_data->>'driverSno')::bigint is not null then ov.driver_sno=(p_data->>'driverSno')::bigint else true end  and
	  case when (p_data->>'orgSno')::bigint is null and (p_data->>'driverSno')::bigint is null then ov.auth_type_cd = 167 and ov.app_user_sno=(p_data->>'appUserSno')::bigint else true end  and
	   case when ov.end_date >= current_date then ov.active_flag = true else false end  
	   order by job_post_sno desc offset (p_data->>'skip')::bigint limit (p_data->>'limit')::bigint)vd);
 
end;
$BODY$
LANGUAGE 'plpgsql';



--get_job_post_count
--------------------

CREATE OR REPLACE FUNCTION driver.get_job_post_count(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
_count bigint;
begin
select count(*) into _count from driver.job_post ov  where case when (p_data->>'orgSno')::bigint is not null then ov.org_sno=(p_data->>'orgSno')::bigint else true end and
 case when (p_data->>'driverSno')::bigint is not null then ov.driver_sno=(p_data->>'driverSno')::bigint else true end and case when ov.end_date >= current_date then ov.active_flag = true else false end;
return (select  json_build_object('data',json_agg(json_build_object('count',_count)))); 

end;
$BODY$;


--update_job_post
-----------------


CREATE OR REPLACE FUNCTION driver.update_job_post(
	p_data json)
    RETURNS json
AS $BODY$
declare 
begin
raise notice 'update_post %',p_data;

update driver.job_post set start_date = (p_data->>'startDate')::timestamp,
end_date = (p_data->>'endDate')::timestamp,user_lat_long = (p_data->>'userLatLong')::json,
lat = (p_data->>'lat')::json,lng = (p_data->>'lng'),
contact_name = (p_data->>'contactName'),contact_number = (p_data->>'contactNumber'),
app_user_sno = (p_data->>'appUserSno')::bigint,distance = (p_data->>'distance')::numeric,
drive_type_cd = (p_data->>'driveTypeCd')::smallint[],job_type_cd = (p_data->>'jobTypeCd')::smallint[],
active_flag = (p_data->>'activeFlag')::boolean,auth_type_cd = (p_data->>'authTypeCd')::smallint,
description = (p_data->>'description'),fuel_type_cd = (p_data->>'fuelTypeCd')::smallint[],
transmission_type_cd = (p_data->>'transmissionTypeCd')::smallint[] where job_post_sno = (p_data->>'jobPostSno')::bigint;

return 
( json_build_object('data',json_build_object('jobPostSno',(p_data->>'jobPostSno')::bigint)));
end;
$BODY$
LANGUAGE 'plpgsql';


--delete_job_post
-----------------


CREATE OR REPLACE FUNCTION driver.delete_job_post(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
AS $BODY$
declare 
jobPostSno bigint;
begin
 delete from driver.job_post
 where job_post_sno = (p_data->>'jobPostSno')::bigint;
 
 return(json_build_object('data',json_agg(json_build_object('isdelete',true))));
end;
$BODY$;






--find_distance
---------------
	
CREATE OR REPLACE FUNCTION driver.find_distance(p_data json)
RETURNS double precision
AS $BODY$
declare 
_distance double precision;
begin _distance := (
    select
        earth_distance(
            ll_to_earth(
                (p_data ->> 'fromLat')::double precision,
                (p_data ->> 'fromLng')::double precision
            ),
            ll_to_earth(
                (p_data ->> 'toLat')::double precision,
                (p_data ->> 'toLng')::double precision
            )
        ) :: int / 1000
);
 
return _distance;
 
end;
$BODY$ 
LANGUAGE plpgsql;


--find_job
----------

CREATE OR REPLACE FUNCTION driver.find_job(
	p_data json)
    RETURNS json
AS $BODY$
declare 
mileageDtl json;
begin

with job_post as(SELECT * FROM driver.job_post jp where jp.driver_sno is not null)
select (select json_agg(json_build_object(
			'drivingLicenceType',cd_value, 
		    'mileage',(select avg(mileage::float) from driver.driver_mileage  dm  
					   where dm.driver_sno=jp.driver_sno and dm.driving_type_cd = codes_dtl_sno 
					     and  dm.vehicle_sno  in ( select vehicle_sno from driver.driver_attendance where accept_status = true) 
					  ))) into mileageDtl from portal.codes_dtl where codes_hdr_sno = 18) from job_post jp;

raise notice '%',(p_data->>'vehicleSno');
 return (select json_build_object('data',(
 select json_agg(json_build_object(
	  'orgSno',po.org_sno,
	 'orgName',(select org_name from operator.org o inner join driver.job_post jp on jp.org_sno=o.org_sno where job_post_sno = po.job_post_sno),
     'driverSno',po.driver_sno,
	 'driverName',(select driver_name from driver.driver d inner join driver.job_post jp on jp.driver_sno = d.driver_sno where job_post_sno = po.job_post_sno),
	  'media',(select (select media.get_media_detail(json_build_object('mediaSno',d.media_sno))->>0)::json as _mediaUrl 
from driver.driver d  inner join driver.job_post jp on jp.driver_sno = d.driver_sno where job_post_sno = po.job_post_sno),
	 'driverNumber',(select driver_mobile_number from driver.driver d inner join driver.job_post jp on jp.driver_sno = d.driver_sno where job_post_sno = po.job_post_sno),
	 'licenceNumber',(select licence_number from driver.driver d inner join driver.job_post jp on jp.driver_sno = d.driver_sno where job_post_sno = po.job_post_sno),
	 -- 'bloodGroupType',(select portal.get_enum_name(po.blood_group_cd,'blood_group_cd')),
	 'drivingLicenceType',(select * from driver.get_licence_type(json_build_object('drivingLicenceType',(select driving_licence_type from driver.driver d where driver_sno = po.driver_sno)))),
	 'licenceExpiryDate',(select licence_expiry_date::date from driver.driver d inner join driver.job_post jp on jp.driver_sno = d.driver_sno where job_post_sno = po.job_post_sno),
	 'transportlicenceExpiryDate',(select transport_licence_expiry_date::date from driver.driver d inner join driver.job_post jp on jp.driver_sno = d.driver_sno where job_post_sno = po.job_post_sno),
     'fatherName',(select father_name from driver.driver d inner join driver.job_post jp on jp.driver_sno = d.driver_sno where job_post_sno = po.job_post_sno),
	 'dob',(select dob::date from driver.driver d inner join driver.job_post jp on jp.driver_sno = d.driver_sno where job_post_sno = po.job_post_sno),
	 'address',(select address from driver.driver d inner join driver.job_post jp on jp.driver_sno = d.driver_sno where job_post_sno = po.job_post_sno),
	 'whatsappNumber',(select driver_whatsapp_number from driver.driver d inner join driver.job_post jp on jp.driver_sno = d.driver_sno where job_post_sno = po.job_post_sno),
	 'roleCd',po.role_cd,
     'jobPostSno',po.job_post_sno,
	 'startDate',po.start_date,
	 'endDate',po.end_date,
	 'userLocation',po.user_lat_long,
	 'userLatLong',(SELECT user_lat_long -> 'place' As la FROM driver.job_post where job_post_sno = po.job_post_sno),
	 'lat',po.lat,
	 'lng',po.lng,
	 'km',po.distance,
	 'contactName',po.contact_name,
	 'contactNumber',po.contact_number,
	 'authTypeCd',po.auth_type_cd,
	  'driveTypeCd',po.drive_type_cd,
	 'driveTypeName',(select operator.get_codesHdrType(json_build_object('codesHdrType',po.drive_type_cd,'codesHdrSno',39))),
	  'jobTypeCd',po.job_type_cd,
	 'jobTypename',(select operator.get_codesHdrType(json_build_object('codesHdrType',po.job_type_cd,'codesHdrSno',40))),
	  'fuelTypeCd',po.fuel_type_cd,
	 'fuelTypename',(select operator.get_codesHdrType(json_build_object('codesHdrType',po.fuel_type_cd,'codesHdrSno',9))),
	  'transmissionTypeCd',po.transmission_type_cd,
	 'transmissionTypename',(select operator.get_codesHdrType(json_build_object('codesHdrType',po.transmission_type_cd,'codesHdrSno',41))),
	 'description',po.description,
	 'postedOn',po.posted_on,
	 'kmsDrived', (select sum(end_value::bigint) - sum(start_value::bigint)
					  from driver.driver_attendance 
					  where driver_sno = po.driver_sno and attendance_status_cd=29),
	 'noOfDaysDrived', (select count(distinct(date(end_time)))
					  from driver.driver_attendance
					  where driver_sno= po.driver_sno),
	 'fuelConsumed', (select sum(fuel_quantity) 
						 from operator.fuel
						 where driver_sno = po.driver_sno and price_per_ltr<>99.22119),
	 'mileageDetail',mileageDtl,
     'distance', (select driver.find_distance(json_build_object('fromLat',p_data ->> 'fromLat',
        'fromLng',p_data ->> 'fromLng','toLat',po.lat,'toLng',po.lng))
        )
)) from (select jp.org_sno, jp.driver_sno,jp.role_cd,jp.job_post_sno,jp.start_date,jp.end_date,
			   jp.user_lat_long,jp.lat,jp.lng,jp.contact_name,jp.contact_number,jp.auth_type_cd,jp.drive_type_cd,jp.job_type_cd,jp.fuel_type_cd,jp.transmission_type_cd,jp.distance,jp.description,jp.posted_on
		 from driver.job_post jp
		 inner join portal.codes_dtl dtl on  dtl.codes_dtl_sno = jp.role_cd
		 -- inner join driver.driver d on  d.driver_sno = jp.driver_sno
where case when jp.end_date >= current_date then jp.active_flag = true else false end and 
case when (p_data->>'orgSno')::bigint is not null then jp.driver_sno is not null else true end and
case when (p_data->>'orgSno')::bigint is null and (p_data->>'driverSno')::bigint is null then jp.driver_sno is not null  else true end and	 
case when (p_data->>'driverSno')::bigint is not null then (jp.org_sno is not null or jp.auth_type_cd = 167) else true end and	
	 
		 case when (p_data->>'jobTypeCd')::smallint[] is not null  then jp.job_type_cd && (p_data->>'jobTypeCd')::smallint[] else true end and
	 case when (p_data->>'fuelTypeCd')::smallint[] is not null  then jp.fuel_type_cd && (p_data->>'fuelTypeCd')::smallint[] else true end and
	 case when (p_data->>'transmissionTypeCd')::smallint[] is not null  then jp.transmission_type_cd && (p_data->>'transmissionTypeCd')::smallint[] else true end and
		 case when ((p_data->>'fromDate') is not null) or ((p_data->>'toDate') is not null) then
     (((p_data->>'fromDate')::date BETWEEN start_date::date  AND end_date::date) and 
	((p_data->>'toDate')::date BETWEEN start_date::date  AND end_date::date)) else true end and
	case when jp.distance is not null then jp.distance >= (select driver.find_distance(
    json_build_object('fromLat',(p_data ->> 'fromLat')::double precision,'fromLng',(p_data ->> 'fromLng')::double precision,'toLat',jp.lat,'toLng',jp.lng))) else
	50 >= (select driver.find_distance(
    json_build_object('fromLat',(p_data ->> 'fromLat')::double precision,'fromLng',(p_data ->> 'fromLng')::double precision,'toLat',jp.lat,'toLng',jp.lng))) end 
    order by posted_on desc
	offset (p_data->>'skip')::bigint limit (p_data->>'limit')::bigint) po)));
end;
$BODY$
LANGUAGE 'plpgsql';



