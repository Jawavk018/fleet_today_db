--
-- PostgreSQL database dump
--

-- Dumped from database version 12.18 (Ubuntu 12.18-0ubuntu0.20.04.1)
-- Dumped by pg_dump version 12.18 (Ubuntu 12.18-0ubuntu0.20.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: config; Type: SCHEMA; Schema: -; Owner: bus_admin
--

CREATE SCHEMA config;


ALTER SCHEMA config OWNER TO bus_admin;

--
-- Name: driver; Type: SCHEMA; Schema: -; Owner: bus_admin
--

CREATE SCHEMA driver;


ALTER SCHEMA driver OWNER TO bus_admin;

--
-- Name: master_data; Type: SCHEMA; Schema: -; Owner: bus_admin
--

CREATE SCHEMA master_data;


ALTER SCHEMA master_data OWNER TO bus_admin;

--
-- Name: media; Type: SCHEMA; Schema: -; Owner: bus_admin
--

CREATE SCHEMA media;


ALTER SCHEMA media OWNER TO bus_admin;

--
-- Name: notification; Type: SCHEMA; Schema: -; Owner: bus_admin
--

CREATE SCHEMA notification;


ALTER SCHEMA notification OWNER TO bus_admin;

--
-- Name: operator; Type: SCHEMA; Schema: -; Owner: bus_admin
--

CREATE SCHEMA operator;


ALTER SCHEMA operator OWNER TO bus_admin;

--
-- Name: portal; Type: SCHEMA; Schema: -; Owner: bus_admin
--

CREATE SCHEMA portal;


ALTER SCHEMA portal OWNER TO bus_admin;

--
-- Name: rent; Type: SCHEMA; Schema: -; Owner: bus_admin
--

CREATE SCHEMA rent;


ALTER SCHEMA rent OWNER TO bus_admin;

--
-- Name: stage_carriage; Type: SCHEMA; Schema: -; Owner: bus_admin
--

CREATE SCHEMA stage_carriage;


ALTER SCHEMA stage_carriage OWNER TO bus_admin;

--
-- Name: tyre; Type: SCHEMA; Schema: -; Owner: bus_admin
--

CREATE SCHEMA tyre;


ALTER SCHEMA tyre OWNER TO bus_admin;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: cube; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS cube WITH SCHEMA public;


--
-- Name: EXTENSION cube; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION cube IS 'data type for multidimensional cubes';


--
-- Name: earthdistance; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS earthdistance WITH SCHEMA public;


--
-- Name: EXTENSION earthdistance; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION earthdistance IS 'calculate great-circle distances on the surface of the Earth';


--
-- Name: get_config(json); Type: FUNCTION; Schema: config; Owner: postgres
--

CREATE FUNCTION config.get_config(in_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
	i_environment_sno smallint := (in_data->>'environmentSno')::smallint;
	i_module_sno smallint := (in_data->>'moduleSno')::smallint;
	i_sub_module_sno smallint := (in_data->>'subModuleSno')::smallint;
	
begin
	return (select(json_build_object('data',json_agg(json_build_object(key1.config_key_attribute,conf.config_value)))))								
	FROM config.config conf, config.config_key key1 
	where 
	(conf.environment_sno in (0) 
	or (conf.environment_sno = i_environment_sno and conf.module_sno =0) 
	or (conf.environment_sno = i_environment_sno and conf.module_sno in (i_module_sno) and  
		conf.sub_module_sno in (0, i_sub_module_sno) ) )
	and conf.config_key_sno = key1.config_key_sno;		
end;
$$;


ALTER FUNCTION config.get_config(in_data json) OWNER TO postgres;

--
-- Name: check_driver_org(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.check_driver_org(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
driverOrg json;
begin
select json_agg(json_build_object(
'orgSno',od.org_sno,'driverSno',od.driver_sno,'orgName',o.org_name,'ownerName',o.owner_name
)) from into driverOrg operator.operator_driver od 
inner join operator.org o on o.org_sno=od.org_sno where od.driver_sno=(p_data->>'driverSno')::bigint and o.org_status_cd=19;
return (select json_build_object('data',driverOrg));
end;
$$;


ALTER FUNCTION driver.check_driver_org(p_data json) OWNER TO postgres;

--
-- Name: check_odometer_reading(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.check_odometer_reading(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
return ( select json_build_object('data',(select json_agg(json_build_object(
	'currentOdoMeterValue',(select odo_meter_value from  operator.vehicle_detail where vehicle_sno=(p_data->>'vehicleSno')::bigint ))))) );
end;
$$;


ALTER FUNCTION driver.check_odometer_reading(p_data json) OWNER TO postgres;

--
-- Name: create_driver(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.create_driver(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
else
	_app_user_sno = (p_data->>'appUserSno')::bigint;
end if;

perform driver.insert_driver_user(json_build_object('appUserSno',_app_user_sno,'driverSno',driverSno));
return (select json_build_object('data',json_build_object('driverSno',driverSno)));

end;
$$;


ALTER FUNCTION driver.create_driver(p_data json) OWNER TO postgres;

--
-- Name: delete_job_post(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.delete_job_post(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
jobPostSno bigint;
begin
 delete from driver.job_post
 where job_post_sno = (p_data->>'jobPostSno')::bigint;
 
 return(json_build_object('data',json_agg(json_build_object('isdelete',true))));
end;
$$;


ALTER FUNCTION driver.delete_job_post(p_data json) OWNER TO postgres;

--
-- Name: find_distance(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.find_distance(p_data json) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION driver.find_distance(p_data json) OWNER TO postgres;

--
-- Name: find_job(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.find_job(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION driver.find_job(p_data json) OWNER TO postgres;

--
-- Name: get_all_driver_count(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.get_all_driver_count(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
	$$;


ALTER FUNCTION driver.get_all_driver_count(p_data json) OWNER TO postgres;

--
-- Name: get_attendance_info(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.get_attendance_info(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION driver.get_attendance_info(p_data json) OWNER TO postgres;

--
-- Name: get_barcode_vehicles_dtl(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.get_barcode_vehicles_dtl(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
raise notice '%',p_data;
return (select json_build_object('data',json_build_object('vehicleSno',vehicle_sno,'vehicleName',vehicle_name))
    from operator.vehicle  where vehicle_reg_number=p_data->>'vehicleRegNumber' and active_flag = true); 
end;
$$;


ALTER FUNCTION driver.get_barcode_vehicles_dtl(p_data json) OWNER TO postgres;

--
-- Name: get_current_district(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.get_current_district(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION driver.get_current_district(p_data json) OWNER TO postgres;

--
-- Name: get_driver(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.get_driver(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION driver.get_driver(p_data json) OWNER TO postgres;

--
-- Name: get_driver_dtl(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.get_driver_dtl(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION driver.get_driver_dtl(p_data json) OWNER TO postgres;

--
-- Name: get_driver_info(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.get_driver_info(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION driver.get_driver_info(p_data json) OWNER TO postgres;

--
-- Name: get_driver_license(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.get_driver_license(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION driver.get_driver_license(p_data json) OWNER TO postgres;

--
-- Name: get_driver_mileage(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.get_driver_mileage(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION driver.get_driver_mileage(p_data json) OWNER TO postgres;

--
-- Name: get_driving_vehicle(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.get_driving_vehicle(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION driver.get_driving_vehicle(p_data json) OWNER TO postgres;

--
-- Name: get_driving_vehicle_count(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.get_driving_vehicle_count(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION driver.get_driving_vehicle_count(p_data json) OWNER TO postgres;

--
-- Name: get_job_post(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.get_job_post(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION driver.get_job_post(p_data json) OWNER TO postgres;

--
-- Name: get_job_post_count(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.get_job_post_count(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
_count bigint;
begin
select count(*) into _count from driver.job_post ov  where case when (p_data->>'orgSno')::bigint is not null then ov.org_sno=(p_data->>'orgSno')::bigint else true end and
 case when (p_data->>'driverSno')::bigint is not null then ov.driver_sno=(p_data->>'driverSno')::bigint else true end and case when ov.end_date >= current_date then ov.active_flag = true else false end;
return (select  json_build_object('data',json_agg(json_build_object('count',_count)))); 

end;
$$;


ALTER FUNCTION driver.get_job_post_count(p_data json) OWNER TO postgres;

--
-- Name: get_licence_type(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.get_licence_type(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION driver.get_licence_type(p_data json) OWNER TO postgres;

--
-- Name: insert_bus_report(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.insert_bus_report(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
	$$;


ALTER FUNCTION driver.insert_bus_report(p_data json) OWNER TO postgres;

--
-- Name: insert_driver(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.insert_driver(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION driver.insert_driver(p_data json) OWNER TO postgres;

--
-- Name: insert_driver_attendance(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.insert_driver_attendance(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION driver.insert_driver_attendance(p_data json) OWNER TO postgres;

--
-- Name: insert_driver_mileage(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.insert_driver_mileage(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION driver.insert_driver_mileage(p_data json) OWNER TO postgres;

--
-- Name: insert_driver_user(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.insert_driver_user(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
driverUserSno bigint;
begin
insert into driver.driver_user(driver_sno,app_user_sno) 
   values ((p_data->>'driverSno')::bigint,(p_data->>'appUserSno')::bigint
          ) returning driver_user_sno  INTO driverUserSno;
return (select json_build_object('data',json_build_object('driverUserSno',driverUserSno)));
end;
$$;


ALTER FUNCTION driver.insert_driver_user(p_data json) OWNER TO postgres;

--
-- Name: insert_job_post(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.insert_job_post(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION driver.insert_job_post(p_data json) OWNER TO postgres;

--
-- Name: update_driver(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.update_driver(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION driver.update_driver(p_data json) OWNER TO postgres;

--
-- Name: update_driver_accept_status(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.update_driver_accept_status(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION driver.update_driver_accept_status(p_data json) OWNER TO postgres;

--
-- Name: update_job_post(json); Type: FUNCTION; Schema: driver; Owner: postgres
--

CREATE FUNCTION driver.update_job_post(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION driver.update_job_post(p_data json) OWNER TO postgres;

--
-- Name: create_city(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.create_city(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
citySno bigint;
_count bigint;
begin
select count(city_name) into _count from master_data.city c inner join master_data.district d on d.district_sno = c.district_sno where c.city_name ilike ('%' || (p_data->>'cityName')::text || '%') and c.district_sno = (p_data->>'districtSno')::bigint;
if _count=0 then
insert into master_data.city(city_name,district_sno) values ((p_data->>'cityName'),(p_data->>'districtSno')::bigint) 
returning city_sno into citySno;
return (select json_build_object('citySno',citySno));
else
return (select json_build_object('msg','City  Already Exists'));
end if;
end;
$$;


ALTER FUNCTION master_data.create_city(p_data json) OWNER TO postgres;

--
-- Name: create_district(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.create_district(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
districtSno bigint;
begin

insert into master_data.district(district_name,state_sno) values ((p_data->>'districtName'),(p_data->>'stateSno')::bigint) 
returning district_sno into districtSno;

return (select json_build_object('districtSno',districtSno));
end;
$$;


ALTER FUNCTION master_data.create_district(p_data json) OWNER TO postgres;

--
-- Name: create_route(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.create_route(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
v_data json;
routeSno bigint;
returnRouteSno bigint;
begin
select operator.check_route(p_data) into v_data;

if (v_data->>'routeSno' is null) then  
   select master_data.insert_route(p_data) into v_data;
end if;

if (select  operator.check_operator_route(json_build_object('operatorSno',p_data->>'operatorSno','routeSno',v_data->>'routeSno'))) = 0 then
	 perform operator.insert_operator_route(json_build_object('operatorSno',p_data->>'operatorSno','routeSno',(v_data->>'routeSno'),'returnRouteSno',(v_data->>'returnRouteSno'),'viaList',p_data));  
	return (select json_build_object('data',json_build_object('isSuccess',true)));
else 
	return (select json_build_object('data',json_build_object('isSuccess',false,'msg','This route is already exist')));
end if;
end;
$$;


ALTER FUNCTION master_data.create_route(p_data json) OWNER TO postgres;

--
-- Name: create_state(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.create_state(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
stateSno bigint;
begin
insert into master_data.state(state_name) values ((p_data->>'stateName')) returning state_sno into stateSno;

return (select json_build_object('stateSno',stateSno));
end;
$$;


ALTER FUNCTION master_data.create_state(p_data json) OWNER TO postgres;

--
-- Name: delete_city(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.delete_city(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
citySno bigint;
begin
   
--    delete from master_data.city where  city_sno = (p_data->>'citySno')::bigint returning city_sno into citySno;
	
	update master_data.city set active_flag = false where city_sno = (p_data->>'citySno')::bigint returning city_sno into citySno;

return (select json_build_object('citySno',citySno));

end;
$$;


ALTER FUNCTION master_data.delete_city(p_data json) OWNER TO postgres;

--
-- Name: delete_district(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.delete_district(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
districtSno bigint;
begin
   
   delete from master_data.district where district_sno = (p_data->>'districtSno')::bigint returning district_sno into districtSno;

return (select json_build_object('districtSno',districtSno));

end;
$$;


ALTER FUNCTION master_data.delete_district(p_data json) OWNER TO postgres;

--
-- Name: delete_route(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.delete_route(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
routeSno bigint;
begin
   
   delete from master_data.route where route_sno = (p_data->>'routeSno')::bigint returning route_sno into routeSno;

return (select json_build_object('routeSno',routeSno));

end;
$$;


ALTER FUNCTION master_data.delete_route(p_data json) OWNER TO postgres;

--
-- Name: delete_state(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.delete_state(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
stateSno bigint;
begin
   
   delete from master_data.state where state_sno = (p_data->>'stateSno')::bigint returning state_sno into stateSno;

return (select json_build_object('stateSno',stateSno));

end;
$$;


ALTER FUNCTION master_data.delete_state(p_data json) OWNER TO postgres;

--
-- Name: get_city(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.get_city(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin

return ( select json_build_object('data', json_agg(json_build_object(
	'citySno',f.city_sno,
	'cityName',f.city_name,
	'districtSno',f.district_sno,
	'stateSno',f.state_sno,
	'activeFlag',f.active_flag,
	'districtName',f.district_name
))) from (select city_sno,city_name,c.district_sno,d.state_sno,c.active_flag,d.district_name from master_data.city c
		inner join master_data.district d on c.district_sno=d.district_sno
		where 
 case when (p_data->>'districtSno')::bigint is not null then  c.district_sno = (p_data->>'districtSno')::bigint
	   else true end order by city_name asc
	   offset (p_data->>'skip')::bigint limit (p_data->>'limit')::bigint)f);
end;
$$;


ALTER FUNCTION master_data.get_city(p_data json) OWNER TO postgres;

--
-- Name: get_city_bus(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.get_city_bus(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
results json;
begin

raise notice 'Padhu%',p_data;

select json_agg(json_build_object(
 'vehicleSno',f.vehicle_sno,	
 'routeSno', f.route_sno,	 
 'vehicleName',f.vehicle_name,
 'vehicleRegNumber',f.vehicle_reg_number,
 'startingTime',f.starting_time,
 'cityName',(select json_agg(c.city_name) from operator.via va 
							   inner join master_data.city c on c.city_sno = va.city_sno where va.operator_route_sno = f.operator_route_sno and 
			case when (p_data->>'viaCitySno' is not null) then ('{' || va.city_sno ||'}')::int[] &&  ('{' || (p_data->>'viaCitySno') ||'}')::int[]  else true end)
 )) into results from (select v.vehicle_sno, r.route_sno, v.vehicle_name, v.vehicle_reg_number, sr.starting_time,vr.operator_route_sno from operator.vehicle_route vr
  inner join operator.operator_route  opr on vr.operator_route_sno = opr.operator_route_sno
  inner join master_data.route r on r.route_sno = opr.route_sno and  r.source_city_sno = (p_data->>'sourceCitySno')::bigint and r.destination_city_sno = (p_data->>'destinationCitySno')::bigint
  inner join operator.single_route sr on sr.route_sno = r.route_sno and vr.vehicle_sno =  sr.vehicle_sno 
  inner join operator.vehicle v on v.vehicle_sno = vr.vehicle_sno	 
  where case when (p_data->>'viaCitySno' is not null) then  opr.operator_route_sno in (select  va.operator_route_sno  from  operator.via va
									where ('{' || va.city_sno ||'}')::int[] &&  ('{' || (p_data->>'viaCitySno') ||'}')::int[] ) else true end
	  order by 
 case when sr.starting_time::time < portal.get_time_with_zone(json_build_object('timeZone',p_data->>'createdOn'))::time then true else false end,sr.starting_time::time,vr.operator_route_sno offset (p_data->>'skip')::bigint  limit (p_data->>'limit')::bigint)f;
 return (select json_build_object('data',results));	 
	 

end;
$$;


ALTER FUNCTION master_data.get_city_bus(p_data json) OWNER TO postgres;

--
-- Name: get_city_bus_count(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.get_city_bus_count(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
_count bigint;
begin
 
	 
 SELECT  count(*) into _count from operator.vehicle_route vr
  inner join operator.operator_route  opr on vr.operator_route_sno = opr.operator_route_sno
  inner join master_data.route r on r.route_sno = opr.route_sno and  r.source_city_sno = (p_data->>'sourceCitySno')::bigint and
  r.destination_city_sno = (p_data->>'destinationCitySno')::bigint
  inner join operator.single_route sr on sr.route_sno = r.route_sno and vr.vehicle_sno =  sr.vehicle_sno 
  inner join operator.vehicle v on v.vehicle_sno = vr.vehicle_sno	 
  where case when (p_data->>'viaCitySno' is not null) then  opr.operator_route_sno in (select  va.operator_route_sno  from  operator.via va
									where ('{' || va.city_sno ||'}')::int[] &&  ('{' || (p_data->>'viaCitySno') ||'}')::int[] ) else true end; 				   
return (select  json_build_object('data',json_agg(json_build_object('count',_count)))); 

end;
$$;


ALTER FUNCTION master_data.get_city_bus_count(p_data json) OWNER TO postgres;

--
-- Name: get_city_count(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.get_city_count(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
_count bigint;
begin
select count(*) into _count from master_data.city;
return (select  json_build_object('data',json_agg(json_build_object('count',_count))));

end;
$$;


ALTER FUNCTION master_data.get_city_count(p_data json) OWNER TO postgres;

--
-- Name: get_district(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.get_district(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin

return (select json_build_object('data',(select json_agg(json_build_object(
	'districtSno',md.district_sno,
	'districtName',md.district_name,
	'stateSno',md.state_sno,
	'activeFlag',md.active_flag
))))from (select * from master_data.district d where 
	   case when (p_data->>'stateSno') is not null then state_sno = (p_data->>'stateSno')::bigint 
	   else true end order by district_name asc
	   offset (p_data->>'skip')::bigint limit (p_data->>'limit')::bigint)md);
   
end;
$$;


ALTER FUNCTION master_data.get_district(p_data json) OWNER TO postgres;

--
-- Name: get_district_count(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.get_district_count(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
_count bigint;
begin
select count(*) into _count from master_data.district;
return (select  json_build_object('data',json_agg(json_build_object('count',_count))));

end;
$$;


ALTER FUNCTION master_data.get_district_count(p_data json) OWNER TO postgres;

--
-- Name: get_route(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.get_route(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
routerList json;
begin
  
select json_build_object('data',json_agg(json_build_object('routeSno',d.route_sno,
	'operatorRouteSno',d.operator_route_sno,
	'sourceCitySno',d.source_city_sno,
	'destinationCitySno',d.destination_city_sno,
	'sourceCityName', (select json_agg(json_build_object('cityName',city_name)) from master_data.city c
where city_sno = d.source_city_sno ),
	'destinationCityName',(select json_agg(json_build_object('cityName',city_name)) from master_data.city c
where city_sno = d.destination_city_sno ),
		'viaList',(select json_agg(json_build_object('viaSno',v.via_sno,'citySno',c.city_sno,'cityName',c.city_name,'activeFlag',c.active_flag)) from operator.operator_route oe
				inner join operator.via v on v.operator_route_sno = oe.operator_route_sno
				inner join operator.vehicle_route vr on vr.operator_route_sno = v.operator_route_sno   
				inner join master_data.city c on c.city_sno=v.city_sno
				where vr.operator_route_sno=v.operator_route_sno and vr.vehicle_sno = (p_data->>'vehicleSno')::bigint  and v.active_flag = true and
			    oe.operator_sno=(p_data->>'orgSno')::bigint  and oe.route_sno= d.route_sno),
'busList',(select json_agg(json_build_object('vehicleRouteSno',vr.vehicle_route_sno,'vehicleSno',v.vehicle_sno,'vehicleName',v.vehicle_name,'vehicleRegNumber',v.vehicle_reg_number) )
			   from operator.operator_route oe
					inner join operator.vehicle_route vr on vr.operator_route_sno=oe.operator_route_sno
					inner join operator.vehicle v on v.vehicle_sno=vr.vehicle_sno 
					where oe.operator_route_sno=vr.operator_route_sno and oe.operator_sno=(p_data->>'orgSno')::bigint 
			  and oe.route_sno= d.route_sno),
'activeFlag',d.active_flag
								  ))) into routerList  from (
select r.route_sno,oe.operator_route_sno,r.source_city_sno,r.destination_city_sno,r.active_flag from master_data.route r
inner join operator.operator_route oe on oe.route_sno=r.route_sno 
where oe.operator_route_sno in (
select operator_route_sno from operator.org_vehicle ov 
inner join operator.vehicle_route vr on vr.vehicle_sno = ov.vehicle_sno
where ov.org_sno = (p_data->>'orgSno')::bigint and ov.vehicle_sno = (p_data->>'vehicleSno')::bigint)
order by r.route_sno asc)d;

return routerList;

end;
$$;


ALTER FUNCTION master_data.get_route(p_data json) OWNER TO postgres;

--
-- Name: get_state(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.get_state(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin

return (select  json_build_object('data',json_agg(json_build_object(
	'stateSno',ms.state_sno,
	'stateName',ms.state_name,
	'activeFlag',ms.active_flag)))from (select * from master_data.state s
 order by s.state_sno asc 
 offset (p_data->>'skip')::bigint limit (p_data->>'limit')::bigint)ms);	
end;
$$;


ALTER FUNCTION master_data.get_state(p_data json) OWNER TO postgres;

--
-- Name: get_state_count(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.get_state_count(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
_count bigint;
begin
select count(*) into _count from master_data.state;
return (select  json_build_object('data',json_agg(json_build_object('count',_count))));

end;
$$;


ALTER FUNCTION master_data.get_state_count(p_data json) OWNER TO postgres;

--
-- Name: get_tyre_company(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.get_tyre_company(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin

return (select  json_build_object('data',json_agg(json_build_object(
	'tyreCompanySno',tc.tyre_company_sno,
	'tyreCompany',tc.tyre_company,
	'activeFlag',tc.active_flag)))from master_data.tyre_company tc where tc.active_flag=true);	
		
end;
$$;


ALTER FUNCTION master_data.get_tyre_company(p_data json) OWNER TO postgres;

--
-- Name: get_tyre_type(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.get_tyre_type(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
tyre_list json;
begin
		
select json_agg(json_build_object('tyreTypeSno',tt.tyre_type_sno,
								  'tyreType',tt.tyre_type,
								  'activeFlag',tt.active_flag,
								  'tyreSizeList',(select json_agg(json_build_object(
								  'tyreSizeSno',ts.tyre_size_sno,
								  'tyreSize',ts.tyre_size,
								  'activeFlag',ts.active_flag
								  )) from master_data.tyre_size ts where ts.tyre_type_sno=tt.tyre_type_sno and ts.active_flag=true)
)) into tyre_list from master_data.tyre_type tt where tt.active_flag=true;

return (select  json_build_object('data',json_agg(json_build_object('tyreList',tyre_list))));
end;
$$;


ALTER FUNCTION master_data.get_tyre_type(p_data json) OWNER TO postgres;

--
-- Name: get_via_route(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.get_via_route(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
results json;
-- via_name text;
routeSno bigint;

begin

raise notice 'Padhu%',p_data;

-- SELECT route_sno from INTO routeSno master_data.route r where r.source_city_sno = (p_data->>'sourceCitySno')::bigint and 
-- r.destination_city_sno = (p_data->>'destinationCitySno')::bigint;

raise notice 'routeSno%',routeSno;

select json_agg(json_build_object(
 'viaName',f.city_name,
 'viaSno', f.city_sno
 )) into results from (
-- select DISTINCT c.city_name,va.city_sno from operator.via va 
-- inner join master_data.city c on c.city_sno = va.city_sno
-- inner join operator.vehicle_route vr on vr.operator_route_sno = va.operator_route_sno					   
-- where va.operator_route_sno in (vr.operator_route_sno) 
  	select DISTINCT md.city_name,md.city_sno from master_data.route r 
	inner join operator.operator_route ro on ro.route_sno = r.route_sno 
	inner join operator.via v on v.operator_route_sno = ro.operator_route_sno 
	inner join master_data.city md on md.city_sno = v.city_sno
	 where r.source_city_sno = (p_data->>'sourceCitySno')::bigint and r.destination_city_sno = (p_data->>'destinationCitySno')::bigint

 )f;

 return (select json_build_object('data',results)); 

end;
$$;


ALTER FUNCTION master_data.get_via_route(p_data json) OWNER TO postgres;

--
-- Name: insert_route(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.insert_route(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
routeSno bigint;
returnRouteSno bigint;
begin

insert into master_data.route(source_city_sno,destination_city_sno) values ((p_data->>'sourceCitySno')::bigint,(p_data->>'destinationCitySno')::bigint)
returning route_sno into routeSno; 
insert into master_data.route(source_city_sno,destination_city_sno) values ((p_data->>'destinationCitySno')::bigint,(p_data->>'sourceCitySno')::bigint) 
returning route_sno into returnRouteSno;
return (select json_build_object('routeSno',routeSno,'returnRouteSno',returnRouteSno));
end;
$$;


ALTER FUNCTION master_data.insert_route(p_data json) OWNER TO postgres;

--
-- Name: update_city(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.update_city(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
citySno bigint;
begin
-- raise notice '%',p_data;
update master_data.city set active_flag = (p_data->>'activeFlag')::boolean, city_name = (p_data->>'cityName'),district_sno = (p_data->>'districtSno')::bigint
								where city_sno = (p_data->>'citySno')::bigint 
								returning city_sno into citySno;

  return (select json_build_object('citySno',citySno));

end;
$$;


ALTER FUNCTION master_data.update_city(p_data json) OWNER TO postgres;

--
-- Name: update_district(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.update_district(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
districtSno bigint;
begin
-- raise notice '%',p_data;
update master_data.district set district_name = (p_data->>'districtName'),state_sno = (p_data->>'stateSno')::bigint
								where district_sno = (p_data->>'districtSno')::bigint 
								returning district_sno into districtSno;

  return (select json_build_object('districtSno',districtSno));

end;
$$;


ALTER FUNCTION master_data.update_district(p_data json) OWNER TO postgres;

--
-- Name: update_route(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.update_route(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
routeSno bigint;
returnRouteSno bigint;
isAlready boolean;
indexSno bigint;
v_doc json;
z_data bigint;
begin
raise notice'update_route_123% ',p_data;
for z_data in SELECT * FROM json_array_elements((p_data->>'removeRouteList')::json) loop
raise notice'z_data_123% ',z_data;
	delete from operator.via where operator_route_sno=z_data;
	delete from operator.vehicle_route where operator_route_sno=z_data;
	delete from operator.operator_route where operator_route_sno=z_data;
end loop;


for v_doc in SELECT * FROM json_array_elements((p_data->>'routeList')::json) loop
-- 	raise notice '%',v_doc;
raise notice 'routeSnooooo%',(v_doc);
select count(*) > 0 into isAlready  from master_data.route where source_city_sno = (v_doc->>'sourceCitySno')::bigint
and destination_city_sno = (v_doc->>'destinationCitySno')::bigint ;
raise notice'isAlready %',isAlready;
if isAlready is false  then
	--perform master_data.create_route(p_data);
	insert into master_data.route(source_city_sno,destination_city_sno) values ((v_doc->>'sourceCitySno')::bigint,(v_doc->>'destinationCitySno')::bigint)
	returning route_sno into routeSno;
	insert into master_data.route(source_city_sno,destination_city_sno) values ((v_doc->>'destinationCitySno')::bigint,(v_doc->>'sourceCitySno')::bigint)
	returning route_sno into returnRouteSno;
	
	if v_doc->>'operatorRouteSno' is not null then
		update operator.operator_route set route_sno = routeSno where operator_route_sno = (v_doc->>'operatorRouteSno')::bigint;
-- 		update operator.operator_route set route_sno = routeSno where operator_route_sno = (v_doc->>'operatorRouteSno')::bigint;
	else
	perform operator.insert_operator_route(json_build_object('operatorSno',p_data->>'operatorSno',
															 'routeSno',routeSno,'returnRouteSno',
															 returnRouteSno,'viaList',v_doc,'vehicleSno',(p_data->>'vehicleSno')::bigint));
   exit;															 
   end if;
   
else

raise notice'123456987% ',(v_doc->>'routeSno')::bigint;
if (v_doc->>'routeSno')::bigint is null then
raise notice'8956968596% ',v_doc;
select route_sno into routeSno from master_data.route where source_city_sno=(v_doc->>'sourceCitySno')::bigint
and destination_city_sno=(v_doc->>'destinationCitySno')::bigint;
select route_sno into returnRouteSno from master_data.route where source_city_sno=(v_doc->>'destinationCitySno')::bigint
and destination_city_sno=(v_doc->>'sourceCitySno')::bigint;
perform operator.insert_operator_route(json_build_object('operatorSno',p_data->>'operatorSno',
															 'routeSno',routeSno,'returnRouteSno',
															 returnRouteSno,'viaList',v_doc,'vehicleSno',(p_data->>'vehicleSno')::bigint));
exit;															 
else

raise notice'muthu123456987% ',(v_doc->>'routeSno')::bigint;
	perform operator.update_via((v_doc::jsonb || jsonb_build_object('deleteList',p_data->>'deleteList'))::json);
	perform operator.update_operator_vehicle_route(v_doc);
	perform operator.update_vehicle_route((v_doc::jsonb || jsonb_build_object('operatorRouteSno',p_data->>'operatorRouteSno'))::json);

exit;
end if;
end if;

end loop;

return (select json_build_object('data',json_agg(json_build_object('routeSno',routeSno))));

end;
$$;


ALTER FUNCTION master_data.update_route(p_data json) OWNER TO postgres;

--
-- Name: update_state(json); Type: FUNCTION; Schema: master_data; Owner: postgres
--

CREATE FUNCTION master_data.update_state(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
stateSno bigint;
begin
-- raise notice '%',p_data;
update master_data.state set state_name = (p_data->>'stateName')
								where state_sno = (p_data->>'stateSno')::bigint 
								returning state_sno into stateSno;

  return (select json_build_object('stateSno',stateSno));

end;
$$;


ALTER FUNCTION master_data.update_state(p_data json) OWNER TO postgres;

--
-- Name: delete_media(json); Type: FUNCTION; Schema: media; Owner: postgres
--

CREATE FUNCTION media.delete_media(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
mediaSno bigint;
begin
   
   delete from media.media_detail where media_sno = (p_data->>'mediaSno')::bigint; 

   delete from media.media where media_sno = (p_data->>'mediaSno')::bigint 
   									returning media_sno into mediaSno;

return (select json_build_object('data',json_build_object('isdelete',true)));

end;
$$;


ALTER FUNCTION media.delete_media(p_data json) OWNER TO postgres;

--
-- Name: get_media_detail(json); Type: FUNCTION; Schema: media; Owner: postgres
--

CREATE FUNCTION media.get_media_detail(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
begin
raise notice 'data %',p_data;
return (select json_agg(json_build_object(
'mediaDetailSno',d.media_detail_sno,
'mediaSno',d.media_sno,
'mediaUrl',d.media_url,
'thumbnailUrl',d.thumbnail_url,
'mediaType',d.media_type,
'contentType',d.content_type,
'azureId',d.azure_id,
'mediaSize',d.media_size,	
'mediaDetailDescription',d.media_detail_description,
'isUploaded',d.isUploaded	
)) from (select * from media.media_detail where media_sno=(p_data->>'mediaSno')::bigint)d);

end;
$$;


ALTER FUNCTION media.get_media_detail(p_data json) OWNER TO postgres;

--
-- Name: insert_media(json); Type: FUNCTION; Schema: media; Owner: postgres
--

CREATE FUNCTION media.insert_media(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
mediaSno bigint;
media json;
mediaDetail json;

begin
raise notice '%',p_data;

-- raise notice '%',_mediaList;
	if (p_data->>'mediaSno')::bigint is null then
  		insert into media.media(container_name) values (p_data->>'containerName')
  		returning media_sno into mediaSno;
	else
  		mediaSno:= (p_data->>'mediaSno')::bigint;
	end if;

if((p_data->>'deleteMediaList') is not null) then
for mediaDetail in SELECT * FROM json_array_elements((p_data->>'deleteMediaList')::json) loop
	raise notice 'mediaDetail %d',mediaDetail;
	delete from media.media_detail where media_detail_sno = (mediaDetail->>'mediaDetailSno')::bigint;
end loop;
end if;

for media in SELECT * FROM json_array_elements((p_data->>'mediaList')::json) loop
-- 	raise notice 'media %d',media;
	if (media->>'mediaDetailSno')::bigint is null then
	raise notice '%d','if';
		 insert into media.media_detail(media_sno,media_url,thumbnail_url,media_type,content_type,media_size,media_detail_description,azure_id,isUploaded)
		 values(mediaSno,media->>'mediaUrl',media->>'thumbnailUrl',media->>'mediaType',media->>'contentType',(media->>'mediaSize')::int,media->>'mediaDetailDescription',(media->>'azureId'),(media->>'isUploaded')::boolean);  
	else
	raise notice '%d','else';
		 update media.media_detail set media_url = media->>'mediaUrl',
									thumbnail_url = media->>'thumbnailUrl',
									media_type = media->>'mediaType',
									content_type = media->>'contentType',
									azure_id = media->>'azureId',
									media_size = (media->>'mediaSize')::int,
									media_detail_description = media->>'mediaDetailDescription'
									where media_detail_sno = (media->>'mediaDetailSno')::bigint;
	end if;
end loop;

return (select json_build_object('mediaSno',mediaSno));
end;
$$;


ALTER FUNCTION media.insert_media(p_data json) OWNER TO postgres;

--
-- Name: get_notification(json); Type: FUNCTION; Schema: notification; Owner: postgres
--

CREATE FUNCTION notification.get_notification(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
return (select json_build_object('data',(select json_agg(json_build_object(
						  'title',n.title,
						 'message',n.message,
						 'actionId',n.action_id,
						 'routerLink',n.router_link,
						 'fromId',n.from_id,
						 'toId',n.to_id,
						 'createdOn',n.created_on,
						 'notificationStatusCd',n.notification_status_cd,
						 'notificationSno',n.notification_sno
)) from (select * from notification.notification  where active_flag = true and to_id = (p_data->>'appUserSno')::bigint
										 order by notification_sno desc 
										 offset (p_data->>'skip')::bigint limit (p_data->>'limit')::bigint
										)n))); 
end;
$$;


ALTER FUNCTION notification.get_notification(p_data json) OWNER TO postgres;

--
-- Name: get_notification_count(json); Type: FUNCTION; Schema: notification; Owner: postgres
--

CREATE FUNCTION notification.get_notification_count(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
_count bigint;
begin
select count(*) into _count from notification.notification  where active_flag = true and to_id = (p_data->>'appUserSno')::bigint and notification_status_cd =117;
return (select  json_build_object('data',json_agg(json_build_object('count',_count))));
end;
$$;


ALTER FUNCTION notification.get_notification_count(p_data json) OWNER TO postgres;

--
-- Name: get_token(json); Type: FUNCTION; Schema: notification; Owner: postgres
--

CREATE FUNCTION notification.get_token(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
tokenList json;
begin
raise notice 'get_token %',p_data;
select json_agg(push_token_id) into tokenList from portal.signin_config where active_flag = true and 
push_token_id is not null and 
app_user_sno in (select value::text::bigint from json_array_elements((p_data->>'appUserList')::json));
  return (select json_build_object('tokenList',tokenList));
end;
$$;


ALTER FUNCTION notification.get_token(p_data json) OWNER TO postgres;

--
-- Name: insert_notification(json); Type: FUNCTION; Schema: notification; Owner: postgres
--

CREATE FUNCTION notification.insert_notification(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
notificationSno bigint;
begin
insert into notification.notification(title,message,action_id,router_link,from_id,to_id,created_on,
							   notification_status_cd) values
(p_data->>'title',p_data->>'message',(p_data->>'actionId')::bigint,p_data->>'routerLink'
 ,(p_data->>'fromId')::bigint,(p_data->>'toId')::bigint,portal.get_time_with_zone(json_build_object('timeZone',p_data->>'createdOn'))::timestamp,
117)
returning notification_sno into notificationSno;
  return (select json_build_object('data',json_build_object('notificationSno',notificationSno)));
end;
$$;


ALTER FUNCTION notification.insert_notification(p_data json) OWNER TO postgres;

--
-- Name: update_notification(json); Type: FUNCTION; Schema: notification; Owner: postgres
--

CREATE FUNCTION notification.update_notification(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
update notification.notification set notification_status_cd = 116 where  notification_sno = (p_data->>'notificationSno')::bigint;
return (select json_build_object('data',json_build_object('notificationStatusCd',116)));
end;
$$;


ALTER FUNCTION notification.update_notification(p_data json) OWNER TO postgres;

--
-- Name: accept_reject_driver_kyc(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.accept_reject_driver_kyc(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
toId bigint;
token_list json;
driverName text;
reason text;
begin

select app_user_sno, driver_name into toId, driverName from  driver.driver_user du inner join driver.driver d on d.driver_sno = du.driver_sno
where du.driver_sno=(p_data->>'driverSno')::bigint;
if (p_data->>'kycStatus')::smallint=19 then
perform notification.insert_notification(json_build_object(
'title','Verified ','message','Dear ' || driverName || ' your KYC is Successfully verified ','actionId',null,'routerLink','driver','fromId',p_data->>'appUserSno',
'toId',toId,
'createdOn',p_data->>'createdOn'
));
reason:='Dear ' || driverName || ' your KYC is Successfully verified';
else
perform notification.insert_notification(json_build_object(
'title','Rejected ','message','Dear ' || driverName || ' Your Kyc is rejected due to  '||(p_data->>'rejectReason')||'','actionId',null,'routerLink','driver','fromId',p_data->>'appUserSno',
'toId',toId,
'createdOn',p_data->>'createdOn'
)); 
raise notice'%',p_data->>'rejectReason';
reason:='Dear ' || driverName || ' Your Kyc is rejected due to  '|| (p_data->>'rejectReason')::text;
end if;
raise notice '%',toId;
select (select notification.get_token(json_build_object('appUserList',json_agg(toId)))->>'tokenList')::json into token_list;
update driver.driver set kyc_status = (p_data->>'kycStatus')::smallint,
reject_reason = (p_data->>'rejectReason')
where driver_sno = (p_data->>'driverSno')::bigint;

return 
( json_build_object('data',json_build_object('driverSno',(p_data->>'driverSno')::bigint,
 'notification',json_build_object('notification',json_build_object('title','Rejected','body', reason ,'data',''),
'registration_ids',token_list)
)));
end;
$$;


ALTER FUNCTION operator.accept_reject_driver_kyc(p_data json) OWNER TO postgres;

--
-- Name: accept_reject_operator_kyc(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.accept_reject_operator_kyc(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
_count int = 0;
_reject_reason_sno  bigint;
token_list json;
toId bigint;
begin
raise notice '%',p_data;
select app_user_sno from into toId operator.org_owner where org_sno=(p_data->>'orgSno')::bigint;

update  operator.org set org_status_cd = (p_data->>'orgStatusCd')::smallint where org_sno = (p_data->>'orgSno')::bigint;

if( p_data->>'type' = 'Reject' ) then

select count(*) into _count from operator.reject_reason where org_sno = (p_data->>'orgSno')::bigint ;

raise notice 'count %',_count;
perform notification.insert_notification(json_build_object(
			'title','Rejected ','message','Dear operator your kyc rejected due to  '||(p_data->>'reason')||'','actionId',null,'routerLink','operator','fromId',p_data->>'appUserSno',
			'toId',toId,
			'createdOn',p_data->>'createdOn'
			)); 
			select (select notification.get_token(json_build_object('appUserList',json_agg(toId)))->>'tokenList')::json into token_list;

if(_count <> 0) then
update operator.reject_reason set reason = p_data->>'reason'  where org_sno = (p_data->>'orgSno')::bigint returning reject_reason_sno into _reject_reason_sno ;
else
insert into operator.reject_reason(org_sno,reason)values((p_data->>'orgSno')::bigint,p_data->>'reason') returning reject_reason_sno into _reject_reason_sno;
end if;

end if;
return (select json_build_object('orgsno',(p_data->>'orgSno')::bigint,
								 'notification',json_build_object('notification',json_build_object('title','Rejected','body','Dear operator your kyc rejected due to  '||(p_data->>'reason')||'','data',''),
										'registration_ids',token_list)
								));
end;
$$;


ALTER FUNCTION operator.accept_reject_operator_kyc(p_data json) OWNER TO postgres;

--
-- Name: accept_reject_vehicle_kyc(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.accept_reject_vehicle_kyc(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
toId bigint;
token_list json;
reason text;
begin

select app_user_sno into toId from  operator.org_owner where org_sno=(p_data->>'orgSno')::bigint;
if (p_data->>'kycStatus')::smallint=19 then
perform notification.insert_notification(json_build_object(
			'title','Verified ','message','Dear operator kyc of your vehicle successfully verified ','actionId',null,'routerLink','registervehicle','fromId',p_data->>'appUserSno',
			'toId',toId,
			'createdOn',p_data->>'createdOn'
			));
			reason:='Dear operator kyc of your vehicle successfully verified';
else
perform notification.insert_notification(json_build_object(
			'title','Rejected ','message','Dear operator kyc of your vehicle rejected due to  '||(p_data->>'rejectReason')||'','actionId',null,'routerLink','registervehicle','fromId',p_data->>'appUserSno',
			'toId',toId,
			'createdOn',p_data->>'createdOn'
			)); 
			raise notice'%',p_data->>'rejectReason';
			reason:='Dear operator kyc of your vehicle rejected due to  '|| (p_data->>'rejectReason')::text;
end if;
raise notice '%',toId;
			select (select notification.get_token(json_build_object('appUserList',json_agg(toId)))->>'tokenList')::json into token_list;
update operator.vehicle set kyc_status = (p_data->>'kycStatus')::smallint,
reject_reason = (p_data->>'rejectReason')
where vehicle_sno = (p_data->>'vehicleSno')::bigint;

return 
( json_build_object('data',json_build_object('vehicleSno',(p_data->>'vehicleSno')::bigint,
											 'notification',json_build_object('notification',json_build_object('title','Rejected','body', reason ,'data',''),
										'registration_ids',token_list)
								)));
end;
$$;


ALTER FUNCTION operator.accept_reject_vehicle_kyc(p_data json) OWNER TO postgres;

--
-- Name: add_vehicle_info(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.add_vehicle_info(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
vehicleSno bigint;
v_doc json;
t_doc json;
isAlreadyExists boolean;
begin

	select count(*) < 1 into isAlreadyExists from operator.vehicle v where trim(lower(v.vehicle_reg_number)) = trim(lower(p_data->>'vehicleRegNumber')) and v.active_flag = true;

if isAlreadyExists then

select (select operator.insert_vehicle(p_data)->>'data')::json->>'vehicleSno' into vehicleSno;
raise notice ' code 0 %',p_data;

perform operator.insert_org_vehicle(json_build_object('orgSno',(p_data->>'orgSno')::bigint,'vehicleSno',vehicleSno));

perform operator.
insert_vehicle_detail(
	json_build_object('vehicleDetails',(p_data->>'vehicleDetails')::json,'contractCarriage',(p_data->>'contractCarriage')::json,'OthersList',
					  (p_data->>'OthersList')::json,'vehicleSno',vehicleSno)::json);

perform operator.insert_vehicle_owner((select (p_data)::jsonb || ('{"vehicleSno": ' || vehicleSno || '}')::jsonb )::json);

-- raise notice  'daaaaaaaaaaaaaa%',p_data->>'routeForm';
for v_doc in SELECT * FROM json_array_elements((p_data->>'routeList')::json) loop
raise notice ' print1 %',v_doc;
 perform master_data.create_route((select (v_doc)::jsonb || ('{"vehicleSno": ' || vehicleSno || '}')::jsonb || ('{"operatorSno": ' || (p_data->>'orgSno') || '}')::jsonb )::json );
end loop;


perform operator.insert_toll_pass_detail(
	json_build_object('passList',(p_data->>'passList')::json,'orgSno',(p_data->>'orgSno')::bigint,'vehicleSno',vehicleSno));

perform operator.insert_vehicle_due_fixed_pay(
	json_build_object('loanList',(p_data->>'loanList')::json,'orgSno',(p_data->>'orgSno')::bigint,'vehicleSno',vehicleSno));
raise notice  'padhu%',p_data->>'loanList';

  return (select json_build_object('data',json_build_object('vehicleSno',vehicleSno)));
   else
  return (select json_build_object('data',json_build_object('msg','This Vehicle Number is Already Exists')));
end if;
end;
$$;


ALTER FUNCTION operator.add_vehicle_info(p_data json) OWNER TO postgres;

--
-- Name: check_operator_route(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.check_operator_route(p_data json) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
declare 
begin
return(select count(*) from operator.operator_route  where operator_sno=(p_data->>'operatorSno')::bigint and route_sno=(p_data->>'routeSno')::bigint);
end;
$$;


ALTER FUNCTION operator.check_operator_route(p_data json) OWNER TO postgres;

--
-- Name: check_route(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.check_route(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
routeSno bigint;
returnRouteSno bigint;
begin
select route_sno INTO routeSno from master_data.route where source_city_sno=(p_data->>'sourceCitySno')::bigint and 
destination_city_sno=(p_data->>'destinationCitySno')::bigint;

select route_sno INTO returnRouteSno from master_data.route where source_city_sno= (p_data->>'destinationCitySno')::bigint and 
destination_city_sno=(p_data->>'sourceCitySno')::bigint;

return (select json_build_object('data',json_build_object('routeSno',routeSno,'returnRouteSno',returnRouteSno)));
end;
$$;


ALTER FUNCTION operator.check_route(p_data json) OWNER TO postgres;

--
-- Name: create_operator_driver(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.create_operator_driver(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
driverSno bigint;
_app_user_sno bigint;
isAlreadyExists bigint;
begin
raise notice ' p_data1 %',p_data;
select count(*) into isAlreadyExists from driver.driver d 
where d.driver_mobile_number =(p_data->>'driverMobileNumber');

if isAlreadyExists = 0 then
	select count(*) into isAlreadyExists from portal.app_user au where trim(au.mobile_no) = trim(p_data->>'driverMobileNumber');
end if;

if isAlreadyExists=0 then
	select (select driver.insert_driver(p_data)->>'data')::json->>'driverSno' into driverSno;
	raise notice ' driverSno %',driverSno;

	select app_user_sno into _app_user_sno from portal.app_user 
	where mobile_no=(p_data->>'driverMobileNumber');

	INSERT INTO portal.app_user( mobile_no,user_status_cd)
		VALUES (p_data->>'driverMobileNumber',
		portal.get_enum_sno('{"cd_value":"InActive","cd_type":"user_status_cd"}')) 
		returning app_user_sno into _app_user_sno;

	-- perform operator.insert_operator_driver((select (p_data)::jsonb || ('{"driverSno": ' || driverSno ||' }')::jsonb )::json);
	
	perform driver.insert_driver_user(json_build_object('appUserSno',_app_user_sno,'driverSno',driverSno));
	perform portal.create_app_user_role(json_build_object('appUserSno',_app_user_sno,'roleCd',(p_data->>'roleCd')::smallint));

  return (select json_build_object('data',json_build_object('driverSno',driverSno)));
 else
  return (select json_build_object('data',json_build_object('msg','This Mobile Number is Already Exists')));
  end if;
end;
$$;


ALTER FUNCTION operator.create_operator_driver(p_data json) OWNER TO postgres;

--
-- Name: create_org(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.create_org(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
orgSno bigint;
addressSno bigint;
v_doc json;
logo json;
coverImage json;
_app_user_sno bigint;
begin

for v_doc in SELECT * FROM json_array_elements((p_data->>'media')::json) loop
  raise notice 'media %',v_doc ;
 if (v_doc->>'keyName') = 'logo' then
 logo := v_doc;
 elseif (v_doc->>'keyName') = 'coverImage' then
  coverImage := v_doc;
 end if;
end loop;

select (select operator.insert_org(p_data)->>'data')::json->>'orgSno' into orgSno;
raise notice ' orgSno %',orgSno;

select (select operator.insert_address((p_data->>'address')::json)->>'data')::json->>'addressSno' into addressSno;

perform operator.insert_org_detail((select (p_data->>'orgDetails')::jsonb || ('{"orgSno": ' || orgSno ||', "logo": ' || coalesce(logo,json_build_object()) ||', "coverImage": ' || coalesce(coverImage,json_build_object()) ||',"addressSno": ' || addressSno ||'}')::jsonb )::json);

if(p_data->>'appUserSno' is null)  then

INSERT INTO portal.app_user( mobile_no,user_status_cd)
	VALUES (p_data->>'mobileNumber',
	portal.get_enum_sno('{"cd_value":"InActive","cd_type":"user_status_cd"}')) returning app_user_sno into _app_user_sno;
	p_data := (p_data :: jsonb || jsonb_build_object('appUserSno',_app_user_sno)):: json;
end if;

perform operator.insert_org_owner((select (p_data)::jsonb || ('{"orgSno": ' || orgSno ||' }')::jsonb )::json);


perform operator.insert_org_contact((select (p_data)::jsonb || ('{"orgSno": ' || orgSno ||' }')::jsonb )::json);

perform operator.insert_org_account((select (p_data)::jsonb || ('{"orgSno": ' || orgSno ||' }')::jsonb )::json);

perform operator.insert_org_social_link((select (p_data)::jsonb || ('{"orgSno": ' || orgSno ||' }')::jsonb )::json);

perform portal.update_app_user_role((select (p_data)::jsonb || ('{"roleCd": ' || 2 ||' }')::jsonb )::json);

  return (select json_build_object('data',json_build_object('orgSno',orgSno,
														   'menus',(select * from portal.get_menu_role(json_build_object('roleCd',2)) ))));

end;
$$;


ALTER FUNCTION operator.create_org(p_data json) OWNER TO postgres;

--
-- Name: delete_all_vehicle(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.delete_all_vehicle(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin

 delete from operator.vehicle where vehicle_sno=(p_data->>'vehicleSno')::bigint;
 delete from operator.org_vehicle where vehicle_sno=(p_data->>'vehicleSno')::bigint;
 delete from operator.vehicle_detail where vehicle_sno=(p_data->>'vehicleSno')::bigint;
 delete from operator.vehicle_owner where vehicle_sno=(p_data->>'vehicleSno')::bigint;
 
return(json_build_object('data',json_agg(json_build_object('isdelete',true))));

end;
$$;


ALTER FUNCTION operator.delete_all_vehicle(p_data json) OWNER TO postgres;

--
-- Name: delete_single_route(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.delete_single_route(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
dates json;
singleRouteSno bigint;
begin
 delete from operator.single_route 
 where vehicle_sno =(p_data->>'vehicleSno')::bigint and route_sno=(p_data->>'routeSno')::bigint;
 
 return(json_build_object('data',json_agg(json_build_object('isdelete',true))));
end;
$$;


ALTER FUNCTION operator.delete_single_route(p_data json) OWNER TO postgres;

--
-- Name: delete_toll_pass_detail(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.delete_toll_pass_detail(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
tollPassDetailSno bigint;
begin
 delete from operator.toll_pass_detail
 where toll_pass_detail_sno =(p_data->>'tollPassDetailSno')::bigint;
 
 return(json_build_object('data',json_agg(json_build_object('isdelete',true))));
end;
$$;


ALTER FUNCTION operator.delete_toll_pass_detail(p_data json) OWNER TO postgres;

--
-- Name: delete_variable_pay(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.delete_variable_pay(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
vehicleDueSno bigint;
vehicleDueVariablePaySno bigint;
begin
 
delete from operator.vehicle_due_variable_pay
 where vehicle_due_sno =(p_data->>'vehicleDueSno')::bigint;
 
 delete from operator.vehicle_due_fixed_pay
 where vehicle_due_sno =(p_data->>'vehicleDueSno')::bigint;
 
 return(json_build_object('data',json_agg(json_build_object('isdelete',true))));
end;
$$;


ALTER FUNCTION operator.delete_variable_pay(p_data json) OWNER TO postgres;

--
-- Name: delete_vehicle_due_fixed_pay(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.delete_vehicle_due_fixed_pay(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
vehicleDueSno bigint;
begin
 delete from operator.vehicle_due_fixed_pay
 where vehicle_due_sno =(p_data->>'vehicleDueSno')::bigint;
 
 return(json_build_object('data',json_agg(json_build_object('isdelete',true))));
end;
$$;


ALTER FUNCTION operator.delete_vehicle_due_fixed_pay(p_data json) OWNER TO postgres;

--
-- Name: fuel_data(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.fuel_data(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
begin
raise notice'p_data%',p_data;
 return (select (json_build_object(
	'fuel_sno',f.fuel_sno,
	'filledDate',f.filled_date,
	'fuelConsumed',f.fuel_quantity,
	'pricePerLiter',f.price_per_ltr,
	'fuelAmount',f.fuel_amount,
	'fuelOdoMeterValue',f.odo_meter_value)) from operator.fuel f 
		 where driver_attendance_sno=(p_data->>'driverAttendanceSno')::bigint and is_calculated=false); 
end;
$$;


ALTER FUNCTION operator.fuel_data(p_data json) OWNER TO postgres;

--
-- Name: get_address(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_address(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
raise notice 'Muhtu%',p_data;
return ( select json_build_object('addressSno',ad.address_sno,
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
	   where od.org_sno=(p_data->>'orgSno')::bigint);

end;
$$;


ALTER FUNCTION operator.get_address(p_data json) OWNER TO postgres;

--
-- Name: get_address_city(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_address_city(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin

return (
with city_name as(
select DISTINCT lower(trim(city_name)) as city from operator.address)
select json_build_object('data',(select json_agg(city))) from city_name
);
   
end;
$$;


ALTER FUNCTION operator.get_address_city(p_data json) OWNER TO postgres;

--
-- Name: get_address_district(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_address_district(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin

return (
with district_name as(
select DISTINCT lower(trim(district_name)) as district from operator.address)
select json_build_object('data',(select json_agg(district))) from district_name
);
   
end;
$$;


ALTER FUNCTION operator.get_address_district(p_data json) OWNER TO postgres;

--
-- Name: get_all_org_count(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_all_org_count(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
_count bigint;
begin
select count(*) into _count from operator.org;
return (select  json_build_object('data',json_agg(json_build_object('count',_count))));

end;
$$;


ALTER FUNCTION operator.get_all_org_count(p_data json) OWNER TO postgres;

--
-- Name: get_all_toll_expiry(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_all_toll_expiry(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
_count bigint;
tollCount bigint;
passExpireList json;
begin
raise notice '%selecteDate',(p_data);

select count(*) into _count from operator.toll_pass_detail td inner join operator.vehicle v on v.vehicle_sno = td.vehicle_sno inner join operator.org_vehicle ov on ov.vehicle_sno= td.vehicle_sno where ov.org_sno=(p_data->>'orgSno')::bigint
and td.is_paid = false and case when (p_data->>'selecteDate' = 'Toll Expiry')  then td.pass_end_date::date < (SELECT CURRENT_DATE +  INTERVAL '5 days') else true end and v.active_flag=true;
 
 
 	select count(*) into tollCount from operator.toll_pass_detail where org_sno = (p_data->>'orgSno')::bigint;
 
 if(p_data->>'expiryType' = 'Monthly Toll Pass') then
 raise notice '%if',(p_data);
 
select json_agg(json_build_object(
'orgSno',obj.org_sno,
'vehicleSno',obj.vehicle_sno,
'vehicleRegNumber',obj.vehicle_reg_number,
'vehicleName',obj.vehicle_name,
'tollPassDetailSno',obj.toll_pass_detail_sno,
'tollName',obj.toll_name,
'tollAmount',obj.toll_amount,
'passEndDate',obj.pass_end_date, 
-- 'passList',(select operator.get_toll_pass_detail(json_build_object('vehicleSno',obj.vehicle_sno))),  
'activeFlag',obj.active_flag::text
 )) into passExpireList from (select ov.org_sno,v.vehicle_sno,v.vehicle_reg_number,v.vehicle_name,td.toll_pass_detail_sno,td.toll_name,
    td.toll_amount,td.pass_end_date,v.active_flag::text
    from operator.org_vehicle ov 
    inner join  operator.vehicle v on v.vehicle_sno=ov.vehicle_sno
    inner join operator.toll_pass_detail td on td.vehicle_sno = v.vehicle_sno  
    where ov.org_sno = (p_data->>'orgSno')::bigint)obj;
-- 	return (select json_agg(json_build_object('dueExpireList',dueExpireList)));
	return (select json_agg(json_build_object('passExpireList',passExpireList,'count',tollCount)));

end if;

 
 select json_agg(json_build_object(
'orgSno',obj.org_sno,
'vehicleSno',obj.vehicle_sno,
'vehicleRegNumber',obj.vehicle_reg_number,
'vehicleName',obj.vehicle_name,
'tollPassDetailSno',obj.toll_pass_detail_sno,
'tollName',obj.toll_name,
'tollAmount',obj.toll_amount,
'passEndDate',obj.pass_end_date, 
-- 'passList',(select operator.get_toll_pass_detail(json_build_object('vehicleSno',obj.vehicle_sno))),  
'activeFlag',obj.active_flag::text
 )) into passExpireList from (select ov.org_sno,v.vehicle_sno,v.vehicle_reg_number,v.vehicle_name,td.toll_pass_detail_sno,td.toll_name,
    td.toll_amount,td.pass_end_date,v.active_flag::text
    from operator.org_vehicle ov 
    inner join  operator.vehicle v on v.vehicle_sno=ov.vehicle_sno
    left join operator.toll_pass_detail td on td.vehicle_sno = v.vehicle_sno where td.is_paid = false and
case when (p_data->>'orgSno')::bigint is not null  then ov.org_sno=(p_data->>'orgSno')::bigint
else true end and

 case when (p_data->>'selecteDate' = 'Toll Expiry')  then td.pass_end_date::date < (SELECT CURRENT_DATE +  INTERVAL '5 days') else true end and
 
      
case when (p_data->>'activeFlag') is not null then v.active_flag = (p_data->>'activeFlag')::boolean else v.kyc_status = 19 end and
case when (p_data->>'searchKey' is not null) then
  ((v.vehicle_name ilike ('%' || trim((p_data->>'searchKey')::text) || '%')) or (v.vehicle_reg_number::text ilike ('%' || trim((p_data->>'searchKey')::text) || '%')))
  else true end and
case when (p_data->>'vehicleSno' is not null) then ov.vehicle_sno = (p_data->>'vehicleSno')::bigint else true end  
  

order by  
    case when (p_data->>'expiryType' = 'Toll Expiry') and td.pass_end_date is null then 1 end desc,
    case when (p_data->>'expiryType' = 'Toll Expiry') and (td.pass_end_date < (p_data->>'today')::date) then td.pass_end_date end asc,    
    case when (p_data->>'expiryType' = 'Toll Expiry') and ((td.pass_end_date::date = (p_data->>'today')::date) or (td.pass_end_date >= (p_data->>'today')::date)) then td.pass_end_date end asc,
    case when (p_data->>'expiryType' = 'Toll Expiry') then td.pass_end_date end desc,
    td.vehicle_sno desc offset (p_data->>'skip')::bigint limit (p_data->>'limit')::bigint
   )obj; 
   
    return (select json_agg(json_build_object('passExpireList',passExpireList,'count',_count)));

end;
$$;


ALTER FUNCTION operator.get_all_toll_expiry(p_data json) OWNER TO postgres;

--
-- Name: get_all_tyre_size(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_all_tyre_size(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
tyreSize json;
begin
raise notice'%love',p_data;
 select json_agg(tyre_size) into tyreSize
	  from master_data.tyre_size where  ('{' || tyre_size_sno || '}')::int[] &&  
	  translate ((p_data->>'tyreSizeSno')::text,'[]','{}')::int[] ;
return tyreSize;
end;
$$;


ALTER FUNCTION operator.get_all_tyre_size(p_data json) OWNER TO postgres;

--
-- Name: get_all_tyre_type(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_all_tyre_type(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
tyreType json;
begin
raise notice'%love',p_data;
 select json_agg(tyre_type) into tyreType
	  from master_data.tyre_type where  ('{' || tyre_type_sno || '}')::int[] &&  
	  translate ((p_data->>'tyreTypeSno')::text,'[]','{}')::int[] ;
return tyreType;
end;
$$;


ALTER FUNCTION operator.get_all_tyre_type(p_data json) OWNER TO postgres;

--
-- Name: get_all_vehicle_count(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_all_vehicle_count(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
_count bigint;
begin
raise notice 'count%',(p_data);

if(p_data->>'orgSno')::bigint is not null then
raise notice 'jawa%',p_data;
select count(*) into _count from operator.vehicle v
inner join operator.org_vehicle ov on ov.vehicle_sno = v.vehicle_sno
 left join operator.vehicle_detail vd on vd.vehicle_sno = v.vehicle_sno 
  left join operator.toll_pass_detail td on td.vehicle_sno = v.vehicle_sno where 		  
 ov.org_Sno = (p_data->>'orgSno')::bigint and case when (p_data->>'selecteDate' = 'FC Expiry') then vd.fc_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and	
case when (p_data->>'selecteDate' = 'Insurance Expiry') then vd.insurance_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and	
case when (p_data->>'selecteDate'  = 'Pollution Expiry') then vd.pollution_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and	
case when (p_data->>'selecteDate'  = 'Tax Expiry')  then vd.tax_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and	
case when (p_data->>'selecteDate' = 'Permit Expiry')  then vd.permit_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and 
case when (p_data->>'selecteDate' = 'Toll Expiry')  then td.pass_end_date::date < (SELECT CURRENT_DATE +  INTERVAL '5 days') else true end and 
case when (p_data->>'vehicleTypeCd')::smallint is not null  then v.vehicle_type_cd =(p_data->>'vehicleTypeCd')::smallint
else true end and
case when (p_data->>'activeFlag') is not null then v.active_flag = (p_data->>'activeFlag')::boolean else v.kyc_status = 19 end and case when (p_data->>'searchKey' is not null) then
		((v.vehicle_name ilike ('%' || trim((p_data->>'searchKey')::text) || '%')) or (v.vehicle_reg_number::text ilike ('%' || trim((p_data->>'searchKey')::text) || '%')))
		else true end and
case when (p_data->>'vehicleSno' is not null) then ov.vehicle_sno = (p_data->>'vehicleSno')::bigint else true end and 
case when (p_data->>'vehicleTypes' is not null) then v.vehicle_type_cd in (select json_array_elements((p_data->>'vehicleTypes')::json)::text::smallint)  else true end;
return (select  json_build_object('data',json_agg(json_build_object('count',_count))));
else
raise notice 'Raaaj%',p_data;
select count(*) into _count from operator.vehicle v 
inner join operator.org_vehicle ov on ov.vehicle_sno = v.vehicle_sno where case when (p_data->>'vehicleTypeCd')::smallint is not null  then v.vehicle_type_cd =(p_data->>'vehicleTypeCd')::smallint
else true end and
case when (p_data->>'status' = 'Active Vehicle') then v.active_flag = true else true end and  		  

case when (p_data->>'status' = 'Inactive Vehicle') then v.active_flag = false else true end and  
case when (p_data->>'activeFlag') is not null then v.active_flag = (p_data->>'activeFlag')::boolean else v.kyc_status = 19 end and case when (p_data->>'searchKey' is not null) then
		((v.vehicle_name ilike ('%' || trim((p_data->>'searchKey')::text) || '%')) or (v.vehicle_reg_number::text ilike ('%' || trim((p_data->>'searchKey')::text) || '%')))
		else true end and

case when (p_data->>'vehicleSno' is not null) then ov.vehicle_sno = (p_data->>'vehicleSno')::bigint else true end and 		
case when (p_data->>'vehicleTypes' is not null) then v.vehicle_type_cd in (select json_array_elements((p_data->>'vehicleTypes')::json)::text::smallint)  else true end;
return (select  json_build_object('data',json_agg(json_build_object('count',_count))));
end if;
end;
$$;


ALTER FUNCTION operator.get_all_vehicle_count(p_data json) OWNER TO postgres;

--
-- Name: get_approval(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_approval(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
org_list json;
vehicle_list json;
driver_list json;
begin

with waiting_approval_org as (select wao.org_sno as col1,wao.org_name as col2,wao.owner_name as col3,wao.org_status_cd as col4,ad.city_name as col5,
ad.district_name as col6,rr.reason as col7,rr.reject_reason_sno as col8 from waiting_approval_org wao
inner join operator.org_detail od on od.org_sno = wao.org_sno
inner join operator.address ad on ad.address_sno = od.address_sno
left join operator.reject_reason rr on rr.org_sno = wao.org_sno)
select json_agg(json_build_object('orgSno',al.col1,
						 'orgName',al.col2,
						 'ownerName',al.col3,
						 'orgStatusCd',al.col4,
						 'cityName',al.col5,
						 'districtName',al.col6,
						 'reason',al.col7,
						 'rejectReasonSno',al.col8
					 )) into org_list from waiting_approval_org al;

with waiting_approval_org as(select wav.vehicle_reg_number as col1,wav.vehicle_name as col2,wav.vehicle_banner_name as col3,wav.kyc_status as col4,
dtl.cd_value as col5,wav.reject_reason as col6,wav.vehicle_sno as col7,ov.org_sno as col8 from waiting_approval_vehicle wav
inner join portal.codes_dtl dtl on dtl.codes_dtl_sno = wav.vehicle_type_cd
inner join operator.org_vehicle ov on ov.vehicle_sno = wav.vehicle_sno)
select json_agg(json_build_object(
					  'vehicleRegNumber',al.col1,
					  'vehicleName',al.col2,
					  'vehicleBannerName',al.col3,
					  'kycStatus',al.col4,
-- 					  'kycStatusValue',case when al.col4 = 58 then 'Out of service' 
-- 									   when al.col4 = 20 then 'Not Verified' 
-- 									   else 'Running' end,
-- 					  'colorClass',case when al.col4 = 58 then 'text-danger' 
-- 									   when al.col4 = 20 then 'text-secondary' 
-- 									   else 'text-success' end,
					  'vehicleTypeCd',al.col5,
					  'reason',al.col6,
					  'ownerList',(select operator.get_operator_vehicle_owner(json_build_object('vehicleSno',al.col7))),
					  'vehicleSno',al.col7,
					  'isShow',false,
					  'vehicleSno',al.col7,
					  'orgSno',al.col8
					 )) into vehicle_list from waiting_approval_org al;

with waiting_approval_org as(select wad.driver_sno as col1,wad.driver_name as col2,od.org_sno as col3,o.org_name as col4,
							 o.owner_name as col5,wad.licence_number as col6,wad.driving_licence_type as col7,wad.kyc_status as col8,
							 wad.reject_reason as col9 from waiting_approval_driver wad
left join operator.operator_driver od on od.driver_sno = wad.driver_sno
left join operator.org o on o.org_sno = od.org_sno)
select json_agg(json_build_object('driverSno',al.col1,
								  'driverName',al.col2,
								  'orgSno',al.col3,
								  'orgName',al.col4,
								  'ownerName',al.col5,
								  'licenceNumber',al.col6,
								  'kycStatus',al.col8,
								  'reason',al.col9,
								  'drivingLicenceCdVal',(select * from driver.get_licence_type(json_build_object('drivingLicenceType',al.col7)))
								 )) into driver_list from waiting_approval_org al;
								 
return (select json_agg(json_build_object('orgList',org_list,'vehicleList',vehicle_list,'driverList',driver_list)));
end;
$$;


ALTER FUNCTION operator.get_approval(p_data json) OWNER TO postgres;

--
-- Name: get_assign_driver_count(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_assign_driver_count(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
_count bigint;
begin
select count(*) into _count from operator.vehicle_driver vd
inner join operator.org_vehicle ov on vd.vehicle_sno = ov.vehicle_sno
where org_sno = (p_data->>'orgSno')::bigint and
case when (p_data->>'driverSno')::bigint is not null then vd.driver_sno=(p_data->>'driverSno')::bigint else true end and
case when (p_data->>'vehicleSno')::bigint is not null then vd.vehicle_sno=(p_data->>'vehicleSno')::bigint else true end;
return (select  json_build_object('data',json_agg(json_build_object('count',_count))));

end;
$$;


ALTER FUNCTION operator.get_assign_driver_count(p_data json) OWNER TO postgres;

--
-- Name: get_assign_un_assigin_user(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_assign_un_assigin_user(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
operatorUserSno bigint;
begin
raise notice '%',p_data;
select app_user_sno into operatorUserSno from operator.org_owner where org_sno=(p_data->>'orgSno')::bigint;
raise notice '%operatorUserSno',operatorUserSno;

return (json_build_object('data',json_agg(json_build_object(
	'unAssignUserList',(select json_agg((select(
		select * from operator.get_org_contact_dtl (json_build_object('appUserSno',ou.role_user_Sno,
																  'appMenuSno',(p_data->>'appMenuSno')::bigint,
																 'type','unAssign')))::json->0 )) 
		from operator.org_user ou where ou.operator_user_sno=operatorUserSno),
	'assignUserList',(select json_agg((select(
		select * from operator.get_org_contact_dtl (json_build_object('appUserSno',ou.role_user_Sno,'type','assign',
																	  'appMenuSno',(p_data->>'appMenuSno')::bigint)))::json->0 ))from operator.org_user ou
inner join portal.app_menu_user amu on amu.app_user_sno=ou.role_user_sno
where ou.operator_user_sno=operatorUserSno and amu.app_menu_sno=(p_data->>'appMenuSno')::bigint)
														   ))));
end;
$$;


ALTER FUNCTION operator.get_assign_un_assigin_user(p_data json) OWNER TO postgres;

--
-- Name: get_bus_report(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_bus_report(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin

raise notice '%',(p_data->>'vehicleSno');
 return (select json_build_object('data',(
 select json_agg(json_build_object(
	 'driverSno',d.driver_sno,
	 'driverName',d.driver_name,
	 'vehicleSno',d.vehicle_sno,
	 'vehicleRegNumber',d.vehicle_reg_number,
	 'vehicleName',d.vehicle_name,
	 'startTime',d.start_date,
	 'endTime',d.end_date,
	 'startValue',d.start_km,
	 'endValue',d.end_km,
	 'totalDrivingKm',d.drived_km,
	 'fuelQty',d.fuel_consumed,
	 'mileage',d.mileage,
	 'drivingType',(select portal.get_enum_name(d.driving_type_cd,'driving_type_cd'))
)) from (select br.driver_sno,dr.driver_name,br.vehicle_sno,v.vehicle_reg_number,v.vehicle_name,br.start_date,
br.end_date,br.start_km,br.end_km,br.drived_km,br.fuel_consumed,br.mileage,br.driving_type_cd 
		 from operator.bus_report br
inner join operator.vehicle v on v.vehicle_sno=br.vehicle_sno
inner join driver.driver dr on dr.driver_sno = br.driver_sno 
where br.org_sno=(p_data->>'orgSno')::bigint and 
case when (p_data->>'vehicleSno') is not null then br.vehicle_sno=(p_data->>'vehicleSno')::bigint else true end and 
case when (p_data->>'driverSno') is not null then br.driver_sno=(p_data->>'driverSno')::bigint else true end  and
case when ((p_data->>'fromDate') is not null) or ((p_data->>'toDate') is not null) then
((start_date::date BETWEEN (p_data->>'fromDate')::date  AND (p_data->>'toDate')::date) and 
	(end_date::date BETWEEN (p_data->>'fromDate')::date  AND (p_data->>'toDate')::date)) else true end 
	order by end_date desc
	offset (p_data->>'skip')::bigint limit (p_data->>'limit')::bigint) d)));
end;
$$;


ALTER FUNCTION operator.get_bus_report(p_data json) OWNER TO postgres;

--
-- Name: get_bus_report_count(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_bus_report_count(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
_count bigint;
begin
select count(*) into _count from operator.bus_report br where org_Sno = (p_data->>'orgSno')::bigint and 
case when (p_data->>'vehicleSno') is not null then br.vehicle_sno=(p_data->>'vehicleSno')::bigint else true end and 
case when (p_data->>'driverSno') is not null then br.driver_sno=(p_data->>'driverSno')::bigint else true end  and
case when ((p_data->>'fromDate') is not null) or ((p_data->>'toDate') is not null) then
((start_date::date BETWEEN (p_data->>'fromDate')::date  AND (p_data->>'toDate')::date) and 
	(end_date::date BETWEEN (p_data->>'fromDate')::date  AND (p_data->>'toDate')::date)) else true end ;
return (select  json_build_object('data',json_agg(json_build_object('count',_count))));

end;
$$;


ALTER FUNCTION operator.get_bus_report_count(p_data json) OWNER TO postgres;

--
-- Name: get_codeshdrtype(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_codeshdrtype(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
_codesHdrType json;
begin

 select json_agg(cd_value) into _codesHdrType
	  from portal.codes_dtl where codes_hdr_sno = (p_data->>'codesHdrSno')::smallint  and  ('{' || codes_dtl_sno || '}')::int[] &&  
	  translate ((p_data->>'codesHdrType')::text,'[]','{}')::int[] ;
	  
return _codesHdrType;

end;
$$;


ALTER FUNCTION operator.get_codeshdrtype(p_data json) OWNER TO postgres;

--
-- Name: get_dashboard_count(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_dashboard_count(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
fc_expiry_count bigint;
insurance_expiry_count bigint;
pollution_expiry_count bigint;
tax_expiry_count bigint;
permit_expiry_count bigint;
toll_expiry_count bigint;
vehicle_count bigint;
driver_count bigint;
driver_running_count bigint;
vehicle_running_count bigint;
tyre_running_count bigint;
tyre_stock_count bigint;
route_count bigint;
booking_count bigint;
notification_count bigint;
org_app_count int;
vehi_app_count int;
driver_app_count int;
org_count bigint;
driver_license_count bigint;
driver_transport_license_count bigint;
active_vehicle_count bigint;
inactive_vehicle_count bigint;
dltl_count bigint;
-- due_fixed_expiry_count bigint;
-- due_variable_expiry_count bigint;
due_count bigint;
-- due_expiry_list json;
    tolls_count bigint;
dues_count bigint;

begin
if (p_data->>'roleCd')::int =2 or (p_data->>'roleCd')::int =127 or (p_data->>'roleCd')::int =128 then 
select count(*) into fc_expiry_count from operator.vehicle_detail vd inner join operator.vehicle v on v.vehicle_sno = vd.vehicle_sno inner join operator.org_vehicle ov on ov.vehicle_sno= vd.vehicle_sno where fc_expiry_date::date < (SELECT CURRENT_DATE + INTERVAL '10 days') and ov.org_sno=(p_data->>'orgSno')::bigint 
and case when (p_data->>'selecteDate' = 'FC Expiry') then vd.fc_expiry_date::date < (SELECT (p_data ->> 'currentDate')::date +  INTERVAL '10 days') else true end and v.active_flag=true ;

select count(*) into insurance_expiry_count from operator.vehicle_detail vd inner join operator.vehicle v on v.vehicle_sno = vd.vehicle_sno inner join operator.org_vehicle ov on ov.vehicle_sno= vd.vehicle_sno where insurance_expiry_date::date < (SELECT CURRENT_DATE + INTERVAL '10 days') and ov.org_sno=(p_data->>'orgSno')::bigint
and case when (p_data->>'selecteDate' = 'Insurance Expiry') then vd.insurance_expiry_date::date < (SELECT (p_data ->> 'currentDate')::date +  INTERVAL '10 days') else true end and v.active_flag=true;

select count(*) into pollution_expiry_count from operator.vehicle_detail vd inner join operator.vehicle v on v.vehicle_sno = vd.vehicle_sno inner join operator.org_vehicle ov on ov.vehicle_sno= vd.vehicle_sno where pollution_expiry_date::date < (SELECT CURRENT_DATE + INTERVAL '10 days') and ov.org_sno=(p_data->>'orgSno')::bigint
and case when (p_data->>'selecteDate'  = 'Pollution Expiry') then vd.pollution_expiry_date::date < (SELECT (p_data ->> 'currentDate')::date +  INTERVAL '10 days') else true end and v.active_flag=true;

select count(*) into tax_expiry_count from operator.vehicle_detail vd inner join operator.vehicle v on v.vehicle_sno = vd.vehicle_sno inner join operator.org_vehicle ov on ov.vehicle_sno= vd.vehicle_sno where tax_expiry_date::date < (SELECT CURRENT_DATE + INTERVAL '10 days') and ov.org_sno=(p_data->>'orgSno')::bigint 
and case when (p_data->>'selecteDate'  = 'Tax Expiry')  then vd.tax_expiry_date::date < (SELECT (p_data ->> 'currentDate')::date +  INTERVAL '10 days') else true end and v.active_flag=true;

select count(*) into permit_expiry_count from operator.vehicle_detail vd inner join operator.vehicle v on v.vehicle_sno = vd.vehicle_sno inner join operator.org_vehicle ov on ov.vehicle_sno= vd.vehicle_sno where permit_expiry_date::date < (SELECT CURRENT_DATE + INTERVAL '10 days') and ov.org_sno=(p_data->>'orgSno')::bigint
and case when (p_data->>'selecteDate' = 'Permit Expiry')  then vd.permit_expiry_date::date < (SELECT (p_data ->> 'currentDate')::date +  INTERVAL '10 days') else true end and v.active_flag=true;

select count(*) into toll_expiry_count from operator.toll_pass_detail td inner join operator.vehicle v on v.vehicle_sno = td.vehicle_sno inner join operator.org_vehicle ov on ov.vehicle_sno= td.vehicle_sno where td.is_paid = false and pass_end_date::date < (SELECT CURRENT_DATE + INTERVAL '5 days') and ov.org_sno=(p_data->>'orgSno')::bigint
and case when (p_data->>'selecteDate' = 'Toll Expiry')  then td.pass_end_date::date < (SELECT (p_data ->> 'currentDate')::date +  INTERVAL '5 days') else true end and v.active_flag=true;


    select count(*) into due_count from operator.vehicle_due_variable_pay vp
    inner join operator.vehicle_due_fixed_pay vd on vp.vehicle_due_sno = vd.vehicle_due_sno and org_sno = (p_data->>'orgSno')::bigint 
    inner join operator.vehicle v on v.vehicle_sno = vd.vehicle_sno
    where vp.is_pass_paid = false and (vp.due_pay_date::date - (p_data->>'currentDate')::date) <= 5  and v.active_flag = true;

select count(*) into vehicle_count from operator.org_vehicle ov inner join operator.vehicle v on v.vehicle_sno=ov.vehicle_sno where org_sno=(p_data->>'orgSno')::bigint and v.active_flag=true;
select count(*) into driver_count from operator.operator_driver od
inner join driver.driver d on d.driver_sno=od.driver_sno where od.org_sno=(p_data->>'orgSno')::bigint and d.active_flag=true;


select count(*) into driver_running_count from driver.driver_attendance da inner join operator.operator_driver od on od.driver_sno = da.driver_sno inner join driver.driver d on d.driver_sno = da.driver_sno where od.org_sno = (p_data->>'orgSno')::bigint and d.active_flag = true and da.attendance_status_cd = 28;
select count(*) into vehicle_running_count from driver.driver_attendance da inner join operator.vehicle v on v.vehicle_sno = da.vehicle_sno inner join operator.operator_driver od on od.driver_sno = da.driver_sno where od.org_sno = (p_data->>'orgSno')::bigint and v.active_flag = true and da.attendance_status_cd = 28;
select count(*) into tyre_running_count from tyre.tyre  where org_sno = (p_data->>'orgSno')::bigint and is_running = true;
select count(*) into tyre_stock_count from tyre.tyre  where org_sno = (p_data->>'orgSno')::bigint and is_running = false and is_bursted = false;

select count(distinct route_sno) into route_count from operator.single_route sr inner join operator.vehicle v on v.vehicle_sno = sr.vehicle_sno where sr.org_sno= (p_data->>'orgSno')::bigint and v.active_flag = true;
-- select count(*) into booking_count from rent.booking b inner join operator.org_vehicle ov on b.vehicle_sno = ov.vehicle_sno where ov.org_sno=(p_data->>'orgSno')::bigint and b.active_flag=true;
    select count(*) into booking_count from rent.booking b inner join operator.org_vehicle ov on b.vehicle_sno = ov.vehicle_sno where ov.org_sno= (p_data->>'orgSno')::bigint and b.active_flag=true and end_date >= current_timestamp;
select count(*) into notification_count from notification.notification where notification_status_cd = 117 and to_id=(select app_user_sno from operator.org_owner where org_sno=(p_data->>'orgSno')::bigint);
select count(*) into driver_license_count from operator.operator_driver od
inner join driver.driver d on d.driver_sno=od.driver_sno
where od.org_sno=(p_data->>'orgSno')::bigint and d.active_flag=true and d.licence_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days');

select count(*) into driver_transport_license_count from operator.operator_driver od
inner join driver.driver d on d.driver_sno=od.driver_sno
where od.org_sno=(p_data->>'orgSno')::bigint and d.active_flag=true and d.transport_licence_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days');

select count(*) into dues_count from operator.vehicle_due_fixed_pay vd
    inner join operator.vehicle v on v.vehicle_sno = vd.vehicle_sno
    where vd.org_sno = (p_data->>'orgSno')::bigint and v.active_flag = true;

select count(*) into tolls_count from operator.toll_pass_detail where org_sno = (p_data->>'orgSno')::bigint;

dltl_count = (driver_transport_license_count + driver_license_count);

raise notice 'dues_count %',(dues_count);

raise notice 'tolls_count %',(tolls_count);


  return (select json_build_object('data',json_agg(json_build_object(
  'dashboard',(select  
json_agg(json_build_object('title','Total Vehicles','count',vehicle_count,'class','text-warning','icon','fa fa-bus','path','registervehicle'))::jsonb ||
json_agg(json_build_object('title','Total Bookings','count',booking_count,'class','text-success','icon','fa fa-ticket','path','view-booking'))::jsonb ||
json_agg(json_build_object('title','Total Drivers','count',driver_count,'class','text-info','icon','fa fa-id-card-o','path','driver'))::jsonb || 
json_agg(json_build_object('title','Running Routes','count',route_count,'class','text-danger','icon','fa fa-route','path','single'))::jsonb || 
json_agg(json_build_object('title','Notification','count',notification_count,'class','text-primary','icon','fa fa-bell','path','notification'))::jsonb 
 ),
   'dashboardList',(select  
-- json_agg(json_build_object('title','Driver License Expiry','count',driver_license_count,'class','text-danger bg-danger', 'icon','fa fa-id-card-o','path','driver'))::jsonb || 
json_agg(json_build_object('title','Total Running Drivers/Vehicle','count',driver_running_count,'class','text-secondary bg-secondary','icon','bi bi-person-circle','path','driving-action'))::jsonb ||
-- json_agg(json_build_object('title','Total Running Vehicle','count',vehicle_running_count,'class','text-warning bg-warning','icon','bi bi-bus-front','path','driving-action'))::jsonb || 
 json_agg(json_build_object('title','Total Running Tyres','count',tyre_running_count,'class','text-primary bg-primary','icon','bi bi-record-circle','path','tyre'))::jsonb || 
json_agg(json_build_object('title','Total Stock Tyres','count',tyre_stock_count,'class','text-success bg-success','icon','bi bi-record-circle','path','tyre'))::jsonb ||
json_agg(json_build_object('title','Monthly Toll Pass','count',tolls_count,'class','text-dark bg-dark','icon','fa fa-road','path','tolldetail'))::jsonb ||
json_agg(json_build_object('title','No of Emi/Payments','count',dues_count,'class','text-warning bg-warning','icon','fa fa-inr','path','due-details'))::jsonb 
 ), 
   'expiryList',(select
json_agg(json_build_object('title','FC Expiry','count',fc_expiry_count,'class','bg-primary','icon','fa fa-bus','path','registervehicle'))::jsonb ||
json_agg(json_build_object('title','Insurance Expiry','count',insurance_expiry_count,'class','bg-danger','icon','fa fa-truck','path','registervehicle'))::jsonb ||
json_agg(json_build_object('title','Pollution Expiry','count',pollution_expiry_count,'class','bg-success','icon','fa fa-sun','path','registervehicle'))::jsonb ||
json_agg(json_build_object('title','Tax Expiry','count',tax_expiry_count,'class','bg-info','icon','fa fa-bus','path','registervehicle'))::jsonb 
  ),
'expiryListDtl',(select
json_agg(json_build_object('title','Permit Expiry','count',permit_expiry_count,'class','bg-secondary','icon','fa fa-route','path','registervehicle'))::jsonb ||
-- json_agg(json_build_object('title','Transport License Expiry','count',driver_transport_license_count,'class','bg-warning','icon','fa fa-user-circle-o','path','driver'))::jsonb || 
json_agg(json_build_object('title','Driver Licence Expiry','count',dltl_count,'class','bg-warning','icon','fa fa-user-circle-o','path','driver'))::jsonb ||
json_agg(json_build_object('title','Toll Expiry','count',toll_expiry_count,'class','bg-dark','icon','fa fa-road','path','tolldetail'))::jsonb ||
json_agg(json_build_object('title','Due Expiry','count',due_count,'class','card-booking','icon','fa fa-inr','path','due-details'))::jsonb 
  )  
  )))
   );
else
select count(*) into org_app_count from operator.org where org_status_cd = 20;
select count(*) into vehi_app_count from operator.vehicle where kyc_status = 20;
select count(*) into driver_app_count from driver.driver where kyc_status = 20;
select count(*) into org_count from operator.org  where org_status_cd = 19;
select count(*) into vehicle_count from operator.vehicle where kyc_status = 19 ;
select count(*) into driver_count from driver.driver where kyc_status = 19 ;
-- select count(*) into driver_count from operator.driver where kyc_status = 19;
select count(*) into notification_count from notification.notification where notification_status_cd = 117 and to_id=1;
select count(*) into active_vehicle_count from operator.vehicle v where active_flag = true and kyc_status = 19;
select count(*) into inactive_vehicle_count from operator.vehicle v where active_flag = false AND kyc_status<>58;
return (select json_build_object('data',json_agg(json_build_object(
  'dashboard',(select  
json_agg(json_build_object('title','Total Operators','count',org_count,'class','text-danger','icon','fa fa-user','path','operatorlist'))::jsonb ||
json_agg(json_build_object('title','Total Vehicles','count',vehicle_count,'class','text-warning','icon','fa fa-bus','path','vehiclelist'))::jsonb ||
json_agg(json_build_object('title','Total Drivers','count',driver_count,'class','text-success','icon','fa fa-user-circle-o','path','driverlist'))::jsonb || 
json_agg(json_build_object('title','Waiting Approvals','count',(org_app_count+vehi_app_count+driver_app_count),'class','text-info','icon','fa fa-ticket','path','approval'))::jsonb || 
json_agg(json_build_object('title','Notification','count',notification_count,'class','text-primary','icon','fa fa-bell','path','notification'))::jsonb ||
json_agg(json_build_object('title','Active Vehicle','count',active_vehicle_count,'class','text-dark','icon','fa fa-bus','path','vehiclelist'))::jsonb ||
json_agg(json_build_object('title','Inactive Vehicle','count',inactive_vehicle_count,'class','text-secondary','icon','fa fa-truck','path','vehiclelist'))::jsonb 

   --      json_agg(json_build_object('title','Inactive Vehicle','count',inactive_vehicle_count,'class','text-secondary','icon','fa fa-truck','path','vehiclelist'))::jsonb        
 )

  )))
   );
end if;
end;

$$;


ALTER FUNCTION operator.get_dashboard_count(p_data json) OWNER TO postgres;

--
-- Name: get_driver_report(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_driver_report(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
licenseList json;
v_doc json;
report jsonb;
reportList json='[]';
begin
select json_agg(json_build_object('codesDtlSno',codes_dtl_sno,'codesHdrSno',codes_hdr_sno,'cdValue',cd_value))
into licenseList from portal.codes_dtl where codes_hdr_sno=18;
raise notice'licenseList%',licenseList;

raise notice'p_data%',p_data;
for v_doc in SELECT * FROM json_array_elements(licenseList) loop
select (json_build_object('kms',sum(kms::bigint),
						  'vehicleType',(v_doc->>'cdValue'),
						 'fuel',sum(fuel::double precision),
						 'mileage',(sum(kms::bigint)/sum(fuel::double precision))::double precision)) into report from driver.driver_mileage
where driver_sno=(p_data->>'driverSno')::bigint and driving_type_cd=(v_doc->>'codesDtlSno')::smallint;
raise notice'report%',report;
reportList=reportList::jsonb || report::jsonb ;
raise notice'reportList%',reportList;
end loop;

 return (reportList); 
end;
$$;


ALTER FUNCTION operator.get_driver_report(p_data json) OWNER TO postgres;

--
-- Name: get_driver_report_dtl(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_driver_report_dtl(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
begin
return(select json_build_object('data',json_agg(json_build_object('report',(with driver_list as (select distinct d.driver_sno, d.driver_name from driver.driver d
	inner join operator.operator_driver od on od.driver_sno=d.driver_sno 
	where od.org_sno=(p_data->>'orgSno')::bigint and 
	case when (p_data->>'driverSno')::bigint is not null then d.driver_sno=(p_data->>'driverSno')::bigint else true end )
	SELECT json_agg(json_build_object('driverSno',dl.driver_sno,'driverName',dl.driver_name,
	'report',(select * from operator.fuel_data(json_build_object('driverSno',dl.driver_sno))))) FROM driver_list dl))))
);
end;
$$;


ALTER FUNCTION operator.get_driver_report_dtl(p_data json) OWNER TO postgres;

--
-- Name: get_fc_expiry_date(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_fc_expiry_date(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
_app_user_sno bigint;
token_list json;
_date timestamp := current_date + INTERVAL '7day';
begin
select oo.app_user_sno  into _app_user_sno from operator.vehicle_detail vd
				 inner join operator.vehicle v on v.vehicle_sno=vd.vehicle_sno
	inner join operator.org_vehicle ov on ov.vehicle_sno=v.vehicle_sno
	inner join operator.org_owner oo on oo.org_sno=ov.org_sno
		 where vd.fc_expiry_date= current_date + INTERVAL '7day';
raise notice'_app_user_sno%',(_app_user_sno);
raise notice'date%',(_date);

perform notification.insert_notification(json_build_object(
			'title','Expiry Message','message','Your vehicle fc is expire on ' || (SELECT to_char(_date, 'DD/MM/YYYY')) ,'actionId',null,'routerLink','registervehicle','fromId',_app_user_sno,
			'toId',_app_user_sno,
			'createdOn','Asia/Kolkata')); 
select (select notification.get_token(json_build_object('appUserList',json_agg(_app_user_sno)))->>'tokenList')::json into token_list;
 return (select json_build_object('data',json_agg(json_build_object(
	 'vehicleRegNumber',v.vehicle_reg_number,
	 'vehicleName',v.vehicle_name,
	 'fcExpiryDate',vd.fc_expiry_date,
	 'notification',json_build_object('notification',json_build_object('title','Expiry','message','welcome to Bus Today','body',v.vehicle_name||' ('|| (v.vehicle_reg_number) || ') ' ||'fc is expire on ' || (SELECT to_char(_date, 'DD/MM/YYYY'))  ),
										'registration_ids',token_list))))from operator.vehicle_detail vd 
 	inner join operator.vehicle v on v.vehicle_sno=vd.vehicle_sno
	inner join operator.org_vehicle ov on ov.vehicle_sno=v.vehicle_sno
	inner join operator.org_owner oo on oo.org_sno=ov.org_sno
		 where vd.fc_expiry_date= current_date + INTERVAL '7day' );
end;
$$;


ALTER FUNCTION operator.get_fc_expiry_date(p_data json) OWNER TO postgres;

--
-- Name: get_fuel_info(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_fuel_info(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
raise notice '%',p_data;
 return (select json_build_object('data',(select json_agg(json_build_object(
	 'fuelSno',d.fuel_sno,
	 'vehicleSno',d.vehicle_sno,
	 'driverSno',d.driver_sno,
	 'bunkSno',d.bunk_sno,
	 'latLong',d.lat_long,
	 'fuelMedia',d.fuel_media,
	 'tankMedia',d.tank_media,
	 'odoMeterMedia',d.odo_meter_media,
	 'fuelQuantity',d.fuel_quantity,
	 'fuelAmount',d.fuel_amount,
	 'odoMeterValue',d.odo_meter_value,
	 'filledDate',d.filled_date,
	 'pricePerLtr',d.price_per_ltr,
	 'driverName',d.driver_name,
	 'vehicleNumber',d.vehicle_reg_number,
	 'acceptStatus',d.accept_status,
	 'isFilled',d.is_filled,
	 'mileage',(select(select (sum(da.end_value::bigint)-sum(da.start_value::bigint)) from driver.driver_attendance da where is_calculated=false)/(select sum(f.fuel_quantity) from operator.fuel f where is_calculated=false))
 ))from (select f.fuel_sno,f.vehicle_sno,f.driver_sno,f.bunk_sno,f.lat_long,f.fuel_media,f.tank_media,f.odo_meter_media,f.fuel_quantity,
		 f.fuel_amount,f.odo_meter_value,f.filled_date,f.price_per_ltr,dr.driver_name,v.vehicle_reg_number,f.accept_status,f.is_filled
	from operator.fuel f 
		 inner join operator.org_vehicle ov on ov.vehicle_sno=f.vehicle_sno
		 inner join driver.driver dr on dr.driver_sno=f.driver_sno
		 inner join operator.vehicle v on v.vehicle_sno=f.vehicle_sno
		 inner join driver.driver_attendance da on da.driver_attendance_sno=f.driver_attendance_sno
		 where ov.org_sno=(p_data->>'orgSno')::bigint and f.active_flag=true and f.price_per_ltr<>99.22119 and f.filled_date::date >= current_date - interval '7 days' and
		case when (p_data->>'vehicleSno') is not null then f.vehicle_sno=(p_data->>'vehicleSno')::bigint else true end and
		case when (p_data->>'driverSno') is not null then f.driver_sno=(p_data->>'driverSno')::bigint else true end and
		case when (p_data->>'date')::date is not null then  f.filled_date::date=(p_data->>'date')::date else true end and
		case when ((p_data->>'vehicleSno') is null) and ((p_data->>'date')::date is null) and ((p_data->>'driverSno') is null) then da.start_time::date >= current_date - interval '7 days' else true end  

		 order by fuel_sno desc
)d))); 
end;
$$;


ALTER FUNCTION operator.get_fuel_info(p_data json) OWNER TO postgres;

--
-- Name: get_fuel_report(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_fuel_report(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
dates json;
singleRouteSno bigint;
begin
return(
	with driver_attendance_list as (select distinct f.driver_attendance_sno from operator.org_vehicle ov
inner join operator.fuel f on f.vehicle_sno=ov.vehicle_sno
inner join driver.driver dr on dr.driver_sno=f.driver_sno
where ov.org_sno=(p_data->>'orgSno')::bigint and
case when (p_data->>'vehicleSno')::bigint is not null then ov.vehicle_sno=(p_data->>'vehicleSno')::bigint else true end and 
case when (p_data->>'driverSno')::bigint is not null then dr.driver_sno=(p_data->>'driverSno')::bigint else true end and
case when (p_data->>'filledDate')::timestamp is not null and (p_data->>'toDate')::timestamp is not null then f.filled_date::date 
									between (p_data->>'filledDate')::date 
									and (p_data->>'toDate')::date else true end and
case when (p_data->>'filledDate')::timestamp is not null and (p_data->>'toDate')::timestamp is null then f.filled_date::date=(p_data->>'filledDate')::date else true end order by f.driver_attendance_sno desc
								   offset (p_data->>'skip')::bigint limit (p_data->>'limit')::bigint)
(select json_build_object('data',(select json_agg(json_build_object('FuelList',(select * from operator.get_sum_odometer_reading(json_build_object(
	'driverAttendanceSno',dal.driver_attendance_sno,
	'orgSno',(p_data->>'orgSno')::bigint,
	'driverSno',(p_data->>'driverSno')::bigint,
   'vehicleSno',(p_data->>'vehicleSno')::bigint) )
								 ))) from driver_attendance_list dal ))));
end;
$$;


ALTER FUNCTION operator.get_fuel_report(p_data json) OWNER TO postgres;

--
-- Name: get_fuel_report_count(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_fuel_report_count(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
_count bigint;
begin
-- select count(*) into _count from operator.fuel;

select count(distinct f.driver_attendance_sno) into _count from operator.org_vehicle ov
inner join operator.fuel f on f.vehicle_sno = ov.vehicle_sno
inner join driver.driver dr on dr.driver_sno = f.driver_sno
where ov.org_Sno = (p_data->>'orgSno')::bigint and 
case when (p_data->>'vehicleSno')::bigint is not null then ov.vehicle_sno=(p_data->>'vehicleSno')::bigint else true end and 
case when (p_data->>'driverSno')::bigint is not null then dr.driver_sno=(p_data->>'driverSno')::bigint else true end and
case when (p_data->>'filledDate')::timestamp is not null and (p_data->>'toDate')::timestamp is not null then f.filled_date::date 
									between (p_data->>'filledDate')::date 
									and (p_data->>'toDate')::date else true end and
case when (p_data->>'filledDate')::timestamp is not null and (p_data->>'toDate')::timestamp is null then f.filled_date::date=(p_data->>'filledDate')::date else true end;

return (select  json_build_object('data',json_agg(json_build_object('count',_count))));

end;
$$;


ALTER FUNCTION operator.get_fuel_report_count(p_data json) OWNER TO postgres;

--
-- Name: get_insurance_expiry_date(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_insurance_expiry_date(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
_app_user_sno bigint;
token_list json;
_date timestamp := current_date + INTERVAL '7day';
begin
select oo.app_user_sno  into _app_user_sno from operator.vehicle_detail vd
				 inner join operator.vehicle v on v.vehicle_sno=vd.vehicle_sno
	inner join operator.org_vehicle ov on ov.vehicle_sno=v.vehicle_sno
	inner join operator.org_owner oo on oo.org_sno=ov.org_sno
		 where vd.insurance_expiry_date= current_date + INTERVAL '7day';
raise notice'_app_user_sno%',(_app_user_sno);
raise notice'date%',(_date);

perform notification.insert_notification(json_build_object(
			'title','Expiry Message','message','Your vehicle insurance is expire on ' || (SELECT to_char(_date, 'DD/MM/YYYY')) ,'actionId',null,'routerLink','registervehicle','fromId',_app_user_sno,
			'toId',_app_user_sno,
			'createdOn','Asia/Kolkata')); 
select (select notification.get_token(json_build_object('appUserList',json_agg(_app_user_sno)))->>'tokenList')::json into token_list;
 return (select json_build_object('data',json_agg(json_build_object(
	 'vehicleRegNumber',v.vehicle_reg_number,
	 'vehicleName',v.vehicle_name,
	 'insuranceExpiryDate',vd.insurance_expiry_date,
	 'notification',json_build_object('notification',json_build_object('title','Expiry','message','welcome to Bus Today','body',v.vehicle_name||' ('|| (v.vehicle_reg_number) || ')' ||' insurance is expire on ' || (SELECT to_char(_date, 'DD/MM/YYYY'))  ),
										'registration_ids',token_list))))from operator.vehicle_detail vd 
 	inner join operator.vehicle v on v.vehicle_sno=vd.vehicle_sno
	inner join operator.org_vehicle ov on ov.vehicle_sno=v.vehicle_sno
	inner join operator.org_owner oo on oo.org_sno=ov.org_sno
		 where vd.insurance_expiry_date= current_date + INTERVAL '7day' );
end;
$$;


ALTER FUNCTION operator.get_insurance_expiry_date(p_data json) OWNER TO postgres;

--
-- Name: get_mileage_dtl(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_mileage_dtl(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
raise notice 'Padhu%',p_data;

return (select json_build_object('data',json_build_object(
	  'avgMileage',(select avg(mileage::float)),
	  'minMileage',(select min(mileage::float)),
	  'maxMileage',(select max(mileage::float))
	 ))from operator.bus_report 
		where vehicle_sno=(p_data->>'vehicleSno')::bigint);
end;
$$;


ALTER FUNCTION operator.get_mileage_dtl(p_data json) OWNER TO postgres;

--
-- Name: get_operator_vehicle(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_operator_vehicle(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
 return (select  json_build_object('data',json_agg(json_build_object(
'orgSno',obj.org_sno,
'orgName',obj.org_Name,
'vehicleSno',obj.vehicle_sno,
'vehicleRegNumber',obj.vehicle_reg_number,
'vehicleName',obj.vehicle_name,
'vehicleBanner',obj.vehicle_banner_name,
'chaseNumber',obj.chase_number,
'engineNumber',obj.engine_number,	 
'mediaSno',obj.media_sno,	
'vehicleTypeCd',obj.vehicle_type_cd,
'vehicleTypeName',(select portal.get_enum_name(obj.vehicle_type_cd,'vehicle_type_cd')),
'tyreTypeCd',obj.tyre_type_cd,
-- 'tyreTypeName',(select portal.get_enum_name(obj.tyre_type_cd,'tyre_type_cd')),
'tyreTypeName',(select * from operator.get_all_tyre_type(json_build_object('tyreTypeSno',obj.tyre_type_cd))),
'tyreSizeCd',obj.tyre_size_cd,
-- 'tyreSizeName',(select portal.get_enum_name(obj.tyre_size_cd,'tyre_size_cd')),
'tyreSizeName',(select * from operator.get_all_tyre_size(json_build_object('tyreSizeSno',obj.tyre_size_cd))),
'routeList',(select * from master_data.get_route(json_build_object('orgSno',obj.org_sno,'roleCd',6,'vehicleSno',obj.vehicle_sno))),
'vehicleDetails',(select operator.get_operator_vehicle_dtl(json_build_object('vehicleSno',obj.vehicle_sno))),
'ownerList',(select operator.get_operator_vehicle_owner(json_build_object('vehicleSno',obj.vehicle_sno))),
'passList',(select operator.get_toll_pass_detail(json_build_object('vehicleSno',obj.vehicle_sno))),
'loanList',(select operator.get_vehicle_due_fixed_pay(json_build_object('vehicleSno',obj.vehicle_sno))),
'kycStatus',( select portal.get_enum_name(obj.kyc_status,'organization_status_cd')),
'rejectReason',obj.reject_reason,
'activeFlag',obj.active_flag::text,
'tyreCountCd',obj.tyre_count_cd,
'tyreCountName',(select portal.get_enum_name(obj.tyre_count_cd,'tyre_count_cd'))	 	 
 )))from (select ov.org_sno,o.org_Name,v.vehicle_sno,v.vehicle_reg_number,v.vehicle_name,v.vehicle_banner_name,
		  v.chase_number,v.engine_number,v.media_sno,v.vehicle_type_cd,v.tyre_type_cd,v.tyre_size_cd,v.kyc_status,
		  v.reject_reason,v.active_flag::text,v.tyre_count_cd
		  from operator.org_vehicle ov
inner join  operator.vehicle v on v.vehicle_sno=ov.vehicle_sno
 inner join operator.org o on o.org_sno=ov.org_sno
 left join operator.vehicle_detail vd on vd.vehicle_sno = v.vehicle_sno
--  left join operator.toll_pass_detail td on td.vehicle_sno = v.vehicle_sno
		  where 		  
case when (p_data->>'orgSno')::bigint is not null  then ov.org_sno=(p_data->>'orgSno')::bigint
else true end and
case when (p_data->>'selecteDate' = 'FC Expiry') then vd.fc_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and	
case when (p_data->>'selecteDate' = 'Insurance Expiry') then vd.insurance_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and	
case when (p_data->>'selecteDate'  = 'Pollution Expiry') then vd.pollution_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and	
case when (p_data->>'selecteDate'  = 'Tax Expiry')  then vd.tax_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and	
case when (p_data->>'selecteDate' = 'Permit Expiry')  then vd.permit_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and	
-- case when (p_data->>'selecteDate' = 'Toll Expiry')  then td.pass_end_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and
		  
		  
case when (p_data->>'vehicleTypeCd')::smallint is not null  then v.vehicle_type_cd =(p_data->>'vehicleTypeCd')::smallint
else true end and
case when (p_data->>'activeFlag') is not null then v.active_flag = (p_data->>'activeFlag')::boolean else v.kyc_status = 19 end and
case when (p_data->>'searchKey' is not null) then
		((v.vehicle_name ilike ('%' || trim((p_data->>'searchKey')::text) || '%')) or (v.vehicle_reg_number::text ilike ('%' || trim((p_data->>'searchKey')::text) || '%')))
		else true end and
case when (p_data->>'vehicleSno' is not null) then ov.vehicle_sno = (p_data->>'vehicleSno')::bigint else true end and 
		  
-- case when (p_data->>'status' = 'All') then  true end and  

case when (p_data->>'status' = 'Active Vehicle') then v.active_flag = true else true end and  		  

case when (p_data->>'status' = 'Inactive Vehicle') then v.active_flag = false else true end and  		  
		  
case when (p_data->>'vehicleTypes' is not null) then v.vehicle_type_cd in (select json_array_elements((p_data->>'vehicleTypes')::json)::text::smallint)  else true end
		  
order by 
		  case when (p_data->>'expiryType' = 'FC Expiry') and vd.fc_expiry_date is null then 1 end desc,
		  case when (p_data->>'expiryType' = 'FC Expiry') and (vd.fc_expiry_date < (p_data->>'today')::date) then vd.fc_expiry_date end asc,
		  case when (p_data->>'expiryType' = 'FC Expiry') and ((vd.fc_expiry_date::date = (p_data->>'today')::date) or (vd.fc_expiry_date >= (p_data->>'today')::date)) then vd.fc_expiry_date end asc,
		  
		  case when (p_data->>'expiryType' = 'FC Expiry') then vd.fc_expiry_date end desc,
		  
		  case when (p_data->>'expiryType' = 'Insurance Expiry') and vd.insurance_expiry_date is null then 1 end desc,
		  case when (p_data->>'expiryType' = 'Insurance Expiry') and (vd.insurance_expiry_date < (p_data->>'today')::date) then vd.insurance_expiry_date end asc,
		  case when (p_data->>'expiryType' = 'Insurance Expiry') and ((vd.insurance_expiry_date::date = (p_data->>'today')::date) or (vd.insurance_expiry_date >= (p_data->>'today')::date)) then vd.insurance_expiry_date end asc,
		  case when (p_data->>'expiryType' = 'Insurance Expiry') then vd.insurance_expiry_date end desc,
		  
		  case when (p_data->>'expiryType' = 'Pollution Expiry') and vd.pollution_expiry_date is null then 1 end desc,
		  case when (p_data->>'expiryType' = 'Pollution Expiry') and (vd.pollution_expiry_date < (p_data->>'today')::date) then vd.pollution_expiry_date end asc,
		  case when (p_data->>'expiryType' = 'Pollution Expiry') and ((vd.pollution_expiry_date::date = (p_data->>'today')::date) or (vd.pollution_expiry_date >= (p_data->>'today')::date)) then vd.pollution_expiry_date end asc,
		  case when (p_data->>'expiryType' = 'Pollution Expiry') then vd.pollution_expiry_date end desc,
		  
		  case when (p_data->>'expiryType' = 'Tax Expiry') and vd.tax_expiry_date is null then 1 end desc,
		  case when (p_data->>'expiryType' = 'Tax Expiry') and (vd.tax_expiry_date < (p_data->>'today')::date) then vd.tax_expiry_date end asc,
		  case when (p_data->>'expiryType' = 'Tax Expiry') and ((vd.tax_expiry_date::date = (p_data->>'today')::date) or (vd.tax_expiry_date >= (p_data->>'today')::date)) then vd.tax_expiry_date end asc,
		  case when (p_data->>'expiryType' = 'Tax Expiry') then vd.tax_expiry_date end desc,
		  
		  case when (p_data->>'expiryType' = 'Permit Expiry') and vd.permit_expiry_date is null then 1 end desc,
		  case when (p_data->>'expiryType' = 'Permit Expiry') and (vd.permit_expiry_date < (p_data->>'today')::date) then vd.permit_expiry_date end asc,
		  case when (p_data->>'expiryType' = 'Permit Expiry') and ((vd.permit_expiry_date::date = (p_data->>'today')::date) or (vd.permit_expiry_date >= (p_data->>'today')::date)) then vd.permit_expiry_date end asc,
		  case when (p_data->>'expiryType' = 'Permit Expiry') then vd.permit_expiry_date end desc,
-- case when (p_data->>'expiryType' = 'Toll Expiry') and ((td.pass_end_date::date = (p_data->>'today')::date) or (td.pass_end_date >= (p_data->>'today')::date)) then td.pass_end_date end asc,
-- 		  case when (p_data->>'expiryType' = 'Toll Expiry') then td.pass_end_date end desc,
		  vd.vehicle_sno desc offset (p_data->>'skip')::bigint limit (p_data->>'limit')::bigint
		 )obj); 
end;
$$;


ALTER FUNCTION operator.get_operator_vehicle(p_data json) OWNER TO postgres;

--
-- Name: get_operator_vehicle_dtl(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_operator_vehicle_dtl(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
 return (
select json_build_object('vehicleRegDate',vd.vehicle_reg_date,
						 'fcExpiryDate',vd.fc_expiry_date,
						 'fcExpiryAmount',vd.fc_expiry_amount,
						 'insuranceExpiryDate',vd.insurance_expiry_date,
						 'insuranceExpiryAmount',vd.insurance_expiry_amount,
						 'pollutionExpiryDate',vd.pollution_expiry_date,
						 'permitExpiryDate',vd.permit_expiry_date,
						 'taxExpiryDate',vd.tax_expiry_date,
						 'taxExpiryAmount',vd.tax_expiry_amount,
						 'odoMeterValue',vd.odo_meter_value,
						 'fuelCapacity',vd.fuel_capacity,
						 'fuelTypeCd',vd.fuel_type_cd,
						 'fuelTypeName',(select portal.get_enum_name(vd.fuel_type_cd,'fuel_type_cd')),
						 'seatCapacity',vd.seat_capacity,
						 'videoType',vd.video_types_cd,
						 'videoTypeName',(select operator.get_codesHdrType(json_build_object('codesHdrType',vd.video_types_cd,'codesHdrSno',11 ))),
						 'vehicleLogo',vd.vehicle_logo,
						 'seatType',vd.seat_type_cd,
						 'seatTypeName',(select portal.get_enum_name(vd.seat_type_cd,'seat_Type_cd')),
						 'audioType',vd.audio_types_cd,
						 'audioTypeName',(select operator.get_codesHdrType(json_build_object('codesHdrType',vd.audio_types_cd,'codesHdrSno',12 ))),
						 'coolType',vd.cool_type_cd,
						 'coolName',(select portal.get_enum_name(vd.cool_type_cd,'Cool_type_cd')),
						 'vehicleMakeCd',vd.vehicle_make_cd,
						 'vehicleMake',(select portal.get_enum_name(vd.vehicle_make_cd,'vehicleMakeCd')),
						 'vehicleModelCd',vd.vehicle_model,
						 'wheelsCd',vd.wheels_cd,
						 'stepnyCd',vd.stepny_cd,
						 'fuelNormsCd',vd.fuel_norms_cd,
						 'fuelNorm',(select portal.get_enum_name(vd.fuel_norms_cd,'fuelNormsCd')),
						 'suspensionType',vd.suspension_type,
						 'suspensionName',(select portal.get_enum_name(vd.suspension_type,'bus_type_cd')),
						 'luckageCount',vd.luckage_count,
						 'districtsSno',vd.district_sno,
						 'districtName',(select district_name from master_data.district where district_sno=vd.district_sno ),
						 'stateSno',vd.state_sno,
						 'media',(select media.get_media_detail(json_build_object('mediaSno',vd.image_sno))),
						 'stateName',(select state_name from master_data.state where state_sno=vd.state_sno ),
						 'pricePerday',vd.price_perday,
						 'drivingType',vd.driving_type_cd,
						 'drivingTypeCd',(select portal.get_enum_name(vd.driving_type_cd,'driving_type_cd')),
						 'wheelType',vd.wheelbase_type_cd,
						 'wheelTypeName',(select portal.get_enum_name(vd.wheelbase_type_cd,'wheel_type_cd')),
						 'publicAddressingSystem',vd.public_addressing_system_cd,
						 'publicAddressingSystemName',(select operator.get_codesHdrType(json_build_object('codesHdrType',vd.public_addressing_system_cd,'codesHdrSno',30 ))),
						 'lightingSystem',vd.lighting_system_cd,
						 'lightingSystemName',(select operator.get_codesHdrType(json_build_object('codesHdrType',vd.lighting_system_cd,'codesHdrSno',31 ))),
						 'othersList',vd.otherslist,
						 'topCarrier',vd.top_luckage_carrier
						 )from operator.vehicle_detail vd where vd.vehicle_sno = (p_data->>'vehicleSno')::bigint); 
end;
$$;


ALTER FUNCTION operator.get_operator_vehicle_dtl(p_data json) OWNER TO postgres;

--
-- Name: get_operator_vehicle_owner(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_operator_vehicle_owner(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
raise notice '%',p_data;
 return (select json_agg(json_build_object(
'vehicleOwnerSno',vehicle_owner_sno,
'ownerName',owner_name,
'ownerNumber',owner_number,
'currentOwner',current_owner,
'appUserSno',app_user_sno
	 
))	from operator.vehicle_owner where vehicle_sno=(p_data->>'vehicleSno')::bigint); 
end;
$$;


ALTER FUNCTION operator.get_operator_vehicle_owner(p_data json) OWNER TO postgres;

--
-- Name: get_org(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_org(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
raise notice '%',p_data;
--if (p_data->>'orgSno') is not null then
return ( select json_build_object('data',(
	select json_agg(json_build_object(
		'orgSno',ao.org_sno,
		'orgName',ao.org_name,
		'mobileNumber',(select mobile_no from portal.app_user where app_user_sno = ao.app_user_sno),
		'orgStatusCd',ao.org_status_cd,
		'ownerDetails',(json_build_object('ownerName',ao.owner_name,'vehicleNumber',ao.vehicle_number)),
		'orgDetails',(select operator.get_org_detail(('{"orgSno": ' || ao.org_sno ||' }')::json)),
-- 		'orgOwner',(select operator.get_org_owner(('{"orgSno": ' || o.org_sno ||' }')::json)),
		'contactList',(select operator.get_org_contact(json_build_object('orgSno', ao.org_sno , 'appUserSno',(p_data->>'appUserSno')::bigint))),
		'accountList',(select operator.get_org_account(json_build_object('orgSno', ao.org_sno))),
		'social',(select operator.get_org_social_link(('{"orgSno": ' || ao.org_sno ||' }')::json)),
		'address',(select operator.get_address(('{"orgSno": ' || ao.org_sno ||' }')::json)),
		'rejectReason',ao.reason
	))  
	from (select o.org_sno,o.org_name,o.org_status_cd,o.owner_name,
		  o.vehicle_number,rr.reason,ow.app_user_sno from operator.org o
		  
	inner join operator.org_detail od on od.org_sno = o.org_sno
	inner join operator.address ad on ad.address_sno = od.address_sno
	inner join operator.org_owner ow on ow.org_sno = o.org_sno
	left join operator.reject_reason rr on rr.org_sno = o.org_sno
	where case when ((p_data->>'orgSno') is not null and (p_data->>'orgSno') <>'null') then o.org_sno=(p_data->>'orgSno')::bigint else o.org_status_cd = 19 end and
	case when (p_data->>'activeFlag') is not null then o.active_flag = (p_data->>'activeFlag')::boolean else true end and
	case when (p_data->>'searchKey' is not null) then
		((o.org_name ilike ('%' || trim((p_data->>'searchKey')::text) || '%')) or (o.owner_name ilike ('%' || trim((p_data->>'searchKey')::text) || '%')))
		else true end 
	and
	case when (p_data->>'district' is not null and trim(p_data->>'district') <> '') then
	lower(trim(district_name)) in (select lower(trim(a::text)) from json_array_elements_text((p_data->>'district')::json)a)
	else true end and
	case when (p_data->>'city' is not null and trim(p_data->>'city') <> '') then
	lower(trim(ad.city_name)) in (select lower(trim(a::text)) from json_array_elements_text((p_data->>'city')::json)a)
	else true end order by o.org_sno offset (p_data->>'skip')::bigint  limit (p_data->>'limit')::bigint)ao
	

)));
--end if;
end;
$$;


ALTER FUNCTION operator.get_org(p_data json) OWNER TO postgres;

--
-- Name: get_org_account(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_org_account(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
raise notice '%',p_data;
return ( select json_agg(json_build_object('bankAccountDetailSno',od.bank_account_detail_sno,
										   'bankAccountName',od.bank_account_name
										  ))from operator.bank_account_detail od
		where od.org_sno = (p_data->>'orgSno')::bigint and case when (od.bank_account_name is null)  then od.bank_account_detail_sno=(p_data->>'bankAccountDetailSno')::bigint else true end);
end;
$$;


ALTER FUNCTION operator.get_org_account(p_data json) OWNER TO postgres;

--
-- Name: get_org_contact(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_org_contact(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
raise notice '%',p_data;
return ( select json_agg(json_build_object('orgContactSno',oc.org_contact_sno,
										   'contactSno',c.contact_sno,
										   'name',c.name,
										   'contactRoleCd',c.contact_role_cd,
										   'contactRoleCdValue',(select portal.get_enum_name(c.contact_role_cd,'role_cd')),
										   'mobileNumber',c.mobile_number,
										   'email',c.email,
										   'isShow',c.is_show
-- 										   'contactDetails',(select portal.get_contact(json_build_object('contactSno',contact_sno))),
										  ))from operator.org_contact oc
		inner join portal.contact c on  c.contact_sno= oc.contact_sno and case when p_data->>'appUserSno' is not null then c.app_user_sno = (p_data->>'appUserSno')::bigint else true end 
		where org_sno = (p_data->>'orgSno')::bigint);
end;
$$;


ALTER FUNCTION operator.get_org_contact(p_data json) OWNER TO postgres;

--
-- Name: get_org_contact_dtl(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_org_contact_dtl(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
raise notice '%',p_data;

if (p_data->>'type')='assign' then
raise notice '%muthu',p_data;

return ( select json_agg(json_build_object(
										   'contactSno',c.contact_sno,
										   'name',c.name,
										   'contactRoleCd',c.contact_role_cd,
										   'contactRoleCdValue',(select portal.get_enum_name(c.contact_role_cd,'role_cd')),
										   'mobileNumber',c.mobile_number,
										   'email',c.email,
										   'isShow',c.is_show,
										   'appUserSno',c.app_user_sno,
	                                       'isAdmin',(select is_admin from portal.app_menu_user where 
													  app_user_sno=c.app_user_sno and app_menu_sno=(p_data->>'appMenuSno')::bigint)
										  ))from portal.contact c
		where app_user_sno = (p_data->>'appUserSno')::bigint);
else
	if (select count(*) from portal.app_menu_user where app_user_sno=(p_data->>'appUserSno')::bigint and app_menu_sno=(p_data->>'appMenuSno')::bigint)=0 then
	return ( select json_agg(json_build_object(
										   'contactSno',c.contact_sno,
										   'name',c.name,
										   'contactRoleCd',c.contact_role_cd,
										   'contactRoleCdValue',(select portal.get_enum_name(c.contact_role_cd,'role_cd')),
										   'mobileNumber',c.mobile_number,
										   'email',c.email,
										   'isShow',c.is_show,
										   'appUserSno',c.app_user_sno
										  ))from portal.contact c
		where app_user_sno = (p_data->>'appUserSno')::bigint);
	else
	return null;
	end if;
end if;
end;
$$;


ALTER FUNCTION operator.get_org_contact_dtl(p_data json) OWNER TO postgres;

--
-- Name: get_org_contract_vehicle(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_org_contract_vehicle(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin

 return (select json_build_object('data',json_agg(json_build_object(
	'vehicleSno',d.vehicle_sno,
	'vehicleName',d.vehicle_name,
	'vehicleRegNumber',d.vehicle_reg_number
)))	from (select v.vehicle_sno,v.vehicle_name,v.vehicle_reg_number 
		  from operator.org_vehicle ov 
		  inner join operator.vehicle v on v.vehicle_sno=ov.vehicle_sno 	
		  where ov.org_sno=(p_data->>'orgSno')::bigint and v.kyc_status=19 and v.vehicle_type_cd=22 and v.active_flag=true  AND
		  		  CASE WHEN (p_data->>'roleCd')::smallint<>2 THEN  v.vehicle_sno not in (select vehicle_sno from driver.driver_attendance da 
								where da.vehicle_sno = v.vehicle_sno  and da.attendance_status_cd=28) ELSE TRUE END
		)d); 
end;
$$;


ALTER FUNCTION operator.get_org_contract_vehicle(p_data json) OWNER TO postgres;

--
-- Name: get_org_detail(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_org_detail(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
raise notice '%',p_data;
return ( select json_build_object('detailSno',org_detail_sno,
										   'logo',org_logo,
										   'coverImage',org_banner,
										   'website',org_website )from operator.org_detail where 
		org_sno = (p_data->>'orgSno')::bigint);
end;
$$;


ALTER FUNCTION operator.get_org_detail(p_data json) OWNER TO postgres;

--
-- Name: get_org_route(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_org_route(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
 return (
 select json_build_object('data',json_agg(json_build_object('routeSno',r.route_sno,
								'source',(select city_name from master_data.city where city_sno=r.source_city_sno),
								'destination',(select city_name from master_data.city where city_sno=r.destination_city_sno)))) 
								from operator.operator_route oe
inner join master_data.route r on r.route_sno=oe.route_sno
inner join operator.vehicle_route vr on vr.operator_route_sno=oe.operator_route_sno
where oe.operator_sno=(P_data->>'orgSno')::bigint and vr.vehicle_sno=(p_data->>'vehicleSno')::bigint
		);
end;
$$;


ALTER FUNCTION operator.get_org_route(p_data json) OWNER TO postgres;

--
-- Name: get_org_social_link(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_org_social_link(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
raise notice '%',p_data;
return ( select json_agg(json_build_object('orgSocialLinkSno',osl.org_social_link_sno,
										   'socialLinkSno',sl.social_link_sno,
										   'urlLink',sl.social_url,
										   'socialTypeCd',sl.social_link_type_cd,
										   'socialTypeName',(select portal.get_enum_name(social_link_type_cd,'social_type_cd'))
-- 										   'social',(select portal.get_social_link(json_build_object('socialLinkSno',social_link_sno))),
										  ))from operator.org_social_link osl
		inner join portal.social_link sl on sl.social_link_sno= osl.social_link_sno
		where org_sno = (p_data->>'orgSno')::bigint);
end;
$$;


ALTER FUNCTION operator.get_org_social_link(p_data json) OWNER TO postgres;

--
-- Name: get_org_vehicle(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_org_vehicle(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
driverInfo json;
assign_count bigint;
begin
raise notice'%',p_data;
if (p_data->>'driverSno')::bigint is not null then 
select json_build_object(
	'driverName',d.driver_name,
	'drivedKm',sum(da.end_value::bigint) - sum(da.start_value::bigint) ) into driverInfo from driver.driver d
				left join driver.driver_attendance da on da.driver_sno=d.driver_sno and da.attendance_status_cd=29 where d.driver_sno=(p_data->>'driverSno')::bigint 
				group by d.driver_sno;
end if;

select count(*) into assign_count from operator.vehicle_driver vdr
inner join operator.org_vehicle ov on vdr.vehicle_sno = ov.vehicle_sno
where org_sno = (p_data->>'orgSno')::bigint and driver_sno = (p_data->>'driverSno')::bigint;
raise notice '%assign_count',assign_count;
return (select json_build_object('data',json_agg(json_build_object(
	'vehicleSno',v.vehicle_sno,
	'vehicleName',v.vehicle_name,
	'vehicleRegNumber',v.vehicle_reg_number,
	'fuelTankCapacity',vdt.fuel_capacity,
	'driverInfo',driverInfo
))) from operator.org_vehicle ov
inner join operator.vehicle v on v.vehicle_sno = ov.vehicle_sno
inner join operator.vehicle_detail vdt on vdt.vehicle_sno=ov.vehicle_sno
left join operator.vehicle_driver vd on vd.vehicle_sno=vdt.vehicle_sno 
where org_sno = (p_data->>'orgSno')::bigint and
case when (p_data->>'vehicleType') is null then v.vehicle_type_cd=21 else true end and v.active_flag=true  AND
CASE WHEN (p_data->>'roleCd')::smallint<>2 THEN  v.vehicle_sno not in (select vehicle_sno from driver.driver_attendance da 
where da.vehicle_sno = v.vehicle_sno  and da.attendance_status_cd=28) ELSE TRUE END and
case when assign_count > 0 then driver_sno=(p_data->>'driverSno')::bigint else true end
	   );


end;
$$;


ALTER FUNCTION operator.get_org_vehicle(p_data json) OWNER TO postgres;

--
-- Name: get_permit_expiry_date(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_permit_expiry_date(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
_app_user_sno bigint;
token_list json;
_date timestamp := current_date + INTERVAL '7day';
begin
select oo.app_user_sno  into _app_user_sno from operator.vehicle_detail vd
				 inner join operator.vehicle v on v.vehicle_sno=vd.vehicle_sno
	inner join operator.org_vehicle ov on ov.vehicle_sno=v.vehicle_sno
	inner join operator.org_owner oo on oo.org_sno=ov.org_sno
		 where vd.permit_expiry_date= current_date + INTERVAL '7day';
raise notice'_app_user_sno%',(_app_user_sno);
raise notice'date%',(_date);

perform notification.insert_notification(json_build_object(
			'title','Expiry Message','message','Your vehicle permit is expire on ' || (SELECT to_char(_date, 'DD/MM/YYYY')) ,'actionId',null,'routerLink','registervehicle','fromId',_app_user_sno,
			'toId',_app_user_sno,
			'createdOn','Asia/Kolkata')); 
select (select notification.get_token(json_build_object('appUserList',json_agg(_app_user_sno)))->>'tokenList')::json into token_list;
 return (select json_build_object('data',json_agg(json_build_object(
	 'vehicleRegNumber',v.vehicle_reg_number,
	 'vehicleName',v.vehicle_name,
	 'permitExpiryDate',vd.permit_expiry_date,
	 'notification',json_build_object('notification',json_build_object('title','Expiry','message','welcome to Bus Today','body',v.vehicle_name||' ('|| (v.vehicle_reg_number) || ') ' ||'permit is expire on ' || (SELECT to_char(_date, 'DD/MM/YYYY'))  ),
										'registration_ids',token_list))))from operator.vehicle_detail vd 
 	inner join operator.vehicle v on v.vehicle_sno=vd.vehicle_sno
	inner join operator.org_vehicle ov on ov.vehicle_sno=v.vehicle_sno
	inner join operator.org_owner oo on oo.org_sno=ov.org_sno
		 where vd.permit_expiry_date= current_date + INTERVAL '7day' );
end;
$$;


ALTER FUNCTION operator.get_permit_expiry_date(p_data json) OWNER TO postgres;

--
-- Name: get_pollution_expiry_date(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_pollution_expiry_date(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
_app_user_sno bigint;
token_list json;
_date timestamp := current_date + INTERVAL '7day';
begin
select oo.app_user_sno  into _app_user_sno from operator.vehicle_detail vd
				 inner join operator.vehicle v on v.vehicle_sno=vd.vehicle_sno
	inner join operator.org_vehicle ov on ov.vehicle_sno=v.vehicle_sno
	inner join operator.org_owner oo on oo.org_sno=ov.org_sno
		 where vd.pollution_expiry_date= current_date + INTERVAL '7day';
raise notice'_app_user_sno%',(_app_user_sno);
raise notice'date%',(_date);

perform notification.insert_notification(json_build_object(
			'title','Expiry Message','message','Your vehicle pollution is expire on ' || (SELECT to_char(_date, 'DD/MM/YYYY')) ,'actionId',null,'routerLink','registervehicle','fromId',_app_user_sno,
			'toId',_app_user_sno,
			'createdOn','Asia/Kolkata')); 
select (select notification.get_token(json_build_object('appUserList',json_agg(_app_user_sno)))->>'tokenList')::json into token_list;
 return (select json_build_object('data',json_agg(json_build_object(
	 'vehicleRegNumber',v.vehicle_reg_number,
	 'vehicleName',v.vehicle_name,
	 'pollutionExpiryDate',vd.pollution_expiry_date,
	 'notification',json_build_object('notification',json_build_object('title','Expiry','message','welcome to Bus Today','body',v.vehicle_name||' ('|| (v.vehicle_reg_number) || ') ' ||'pollution is expire on ' || (SELECT to_char(_date, 'DD/MM/YYYY'))  ),
										'registration_ids',token_list))))from operator.vehicle_detail vd 
 	inner join operator.vehicle v on v.vehicle_sno=vd.vehicle_sno
	inner join operator.org_vehicle ov on ov.vehicle_sno=v.vehicle_sno
	inner join operator.org_owner oo on oo.org_sno=ov.org_sno
		 where vd.pollution_expiry_date= current_date + INTERVAL '7day' );
end;
$$;


ALTER FUNCTION operator.get_pollution_expiry_date(p_data json) OWNER TO postgres;

--
-- Name: get_search_available_tyre(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_search_available_tyre(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
tyre_list json;
begin
raise notice '% muthu',p_data;

select json_agg(json_build_object('tyreSno',t.tyre_sno,
								  'tyreSerialNumber',t.tyre_serial_number,
								  'typeTypeValue',tt.tyre_type,
								  'isNew',t.is_new,
								  'retreadingCount',(select count(*) from tyre.tyre_activity where tyre_activity_type_cd = 99 and tyre_sno = t.tyre_sno and vehicle_sno is not  null )
								 )) into tyre_list from tyre.tyre t 
inner join master_data.tyre_type tt on tt.tyre_type_sno = t.tyre_type_sno
where t.active_flag = true and t.is_bursted = false and ('{' || t.tyre_type_sno || '}')::int[] &&  
(select tyre_type_cd from operator.vehicle where vehicle_sno=(p_data->>'vehicleSno')::bigint)::int[] and
 ('{' || t.tyre_size_sno || '}')::int[] &&  (select tyre_size_cd from operator.vehicle where vehicle_sno=(p_data->>'vehicleSno')::bigint)::int[] and
case when p_data->>'orgSno' is not null then
t.org_sno = (p_data->>'orgSno')::bigint and t.is_running = false
when p_data->>'tyreSno' is not null then 
t.tyre_sno =  (p_data->>'tyreSno')::bigint
else false end;
return tyre_list;
end;
$$;


ALTER FUNCTION operator.get_search_available_tyre(p_data json) OWNER TO postgres;

--
-- Name: get_search_operator_vehicle(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_search_operator_vehicle(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
vehicle_list json;
begin
		
select json_agg(json_build_object('VehicleSno',v.vehicle_sno,
								  'vehicleRegNumber',v.vehicle_reg_number,
								  'tyreCountCd',v.tyre_count_cd,
								  'tyreCount',dtl.filter_1,
								  'stepnyCount',vd.stepny_cd,
								  'tyreCount',dtl.filter_1,
								  'tyreCountCd',v.tyre_count_cd,
								  'stepnyCount',vd.stepny_cd,
								--   'retreadingCount',(select count(*) from tyre.tyre_activity where tyre_activity_type_cd = 99 and vehicle_sno = v.vehicle_sno and tyre_sno =),
-- 								  'tyrePositionList',(select operator.get_tyre_position(json_build_object('VehicleSno',v.vehicle_sno,'tyreCount',dtl.filter_1,'tyreCountCd',v.tyre_count_cd,'stepnyCount',vd.stepny_cd))),
								  'odoMeterValue',vd.odo_meter_value
								 )) into vehicle_list from operator.org_vehicle ov
inner join operator.vehicle v on case when p_data->>'vehicleSno' is not null then v.vehicle_sno = (p_data->>'vehicleSno')::bigint else true end and v.vehicle_sno=ov.vehicle_sno
inner join operator.vehicle_detail vd on vd.vehicle_sno = v.vehicle_sno
left join portal.codes_dtl dtl on dtl.codes_dtl_sno = v.tyre_count_cd
where ov.org_sno = (p_data->>'orgSno')::bigint and
v.active_flag = true and kyc_status = 19;

return vehicle_list;
end;
$$;


ALTER FUNCTION operator.get_search_operator_vehicle(p_data json) OWNER TO postgres;

--
-- Name: get_separate_single_route(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_separate_single_route(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
dates json;
begin
 return (select json_agg(json_build_object(
	 'routeSno',d.route_sno,
	 'singleRouteSno',d.single_route_sno,
	 'routeName',route_name,
	 'startingTime',d.starting_time,
	 'runningTime',d.running_time,
	 'status',d.active_flag
 ))from (select r.route_sno,sr.single_route_sno,c.city_name||' --> '||des.city_name as route_name,sr.starting_time,sr.running_time,sr.active_flag
		 from operator.single_route sr 
 	inner join master_data.route r on r.route_sno=sr.route_sno 
	inner join master_data.city c on c.city_sno=r.source_city_sno 
	inner join master_data.city des on des.city_sno=r.destination_city_sno
	where sr.route_sno =(p_data->>'routeSno')::bigint and sr.org_sno = (p_data->>'orgSno')::bigint and sr.vehicle_sno = (p_data->>'vehicleSno')::bigint
	order by sr.starting_time asc)d
		); 
end;
$$;


ALTER FUNCTION operator.get_separate_single_route(p_data json) OWNER TO postgres;

--
-- Name: get_single_route(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_single_route(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
dates json;
singleRouteSno bigint;
begin
 return (select json_build_object('data',json_agg(json_build_object(
	 'orgSno',d.org_sno,
	 'vehicleSno',d.vehicle_sno,
	 'routeList',(select operator.get_separate_single_route(json_build_object('routeSno',d.route_sno,'orgSno',(p_data->>'orgSno')::bigint,'vehicleSno',(p_data->>'vehicleSno')::bigint)))
)))from (select sr.org_sno,sr.vehicle_sno,r.route_sno from operator.single_route sr 
 	inner join master_data.route  r on  r.route_sno=sr.route_sno 
	inner join master_data.city c on c.city_sno=r.source_city_sno 
	inner join master_data.city des on des.city_sno=r.destination_city_sno
		where sr.org_sno=(p_data->>'orgSno')::bigint and sr.vehicle_sno=(p_data->>'vehicleSno')::bigint group by sr.vehicle_sno,sr.org_sno,r.route_sno)d); 

end;
$$;


ALTER FUNCTION operator.get_single_route(p_data json) OWNER TO postgres;

--
-- Name: get_sum_odometer_reading(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_sum_odometer_reading(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
vehicleSno bigint;
begin
raise notice '%',p_data;
select vehicle_sno into vehicleSno from operator.fuel where driver_attendance_sno=(p_data->>'driverAttendanceSno')::bigint group by vehicle_sno;

return ( select json_build_object('fuelQuantity', sum(f.fuel_quantity) ,
								  'fuelAmount',sum(f.fuel_amount) ,
								  'driverSno',(select driver_sno from operator.fuel where driver_attendance_sno=(p_data->>'driverAttendanceSno')::bigint group by driver_sno),
 								  'isFilled',(json_agg(f.is_filled)),
								  'driverName',(select driver_name from driver.driver dr
												inner join operator.fuel f on f.driver_sno=dr.driver_sno
												where driver_attendance_sno=(p_data->>'driverAttendanceSno')::bigint group by dr.driver_name),
								  'odoMeterValue', Max(f.odo_meter_value),
								  'vehicleSno',vehicleSno,
								  'vehicleRegNumber',(select vehicle_reg_number from operator.vehicle v
													 inner join operator.fuel f on f.vehicle_sno=v.vehicle_sno
													 where driver_attendance_sno=(p_data->>'driverAttendanceSno')::bigint group by vehicle_reg_number),
								  'filledDate',(json_agg(f.filled_date)),
								  'runningKm',(select (da.end_value::bigint - da.start_value::bigint) from driver.driver_attendance da
where da.driver_attendance_sno=(p_data->>'driverAttendanceSno')::bigint),
									'drivingType',(select portal.get_enum_name((select driving_type_cd from operator.vehicle_detail where vehicle_sno=vehicleSno),'driving_type_cd'))
								 )from operator.fuel f where f.driver_attendance_sno = (p_data->>'driverAttendanceSno')::bigint
		and f.price_per_ltr<>99.22119
	   );
end;
$$;


ALTER FUNCTION operator.get_sum_odometer_reading(p_data json) OWNER TO postgres;

--
-- Name: get_tax_expiry_date(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_tax_expiry_date(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
_app_user_sno bigint;
token_list json;
_date timestamp := current_date + INTERVAL '7day';
begin
select oo.app_user_sno  into _app_user_sno from operator.vehicle_detail vd
				 inner join operator.vehicle v on v.vehicle_sno=vd.vehicle_sno
	inner join operator.org_vehicle ov on ov.vehicle_sno=v.vehicle_sno
	inner join operator.org_owner oo on oo.org_sno=ov.org_sno
		 where vd.tax_expiry_date= current_date + INTERVAL '7day';
raise notice'_app_user_sno%',(_app_user_sno);
raise notice'date%',(_date);

perform notification.insert_notification(json_build_object(
			'title','Expiry Message','message','Your vehicle tax is expire on ' || (SELECT to_char(_date, 'DD/MM/YYYY')) ,'actionId',null,'routerLink','registervehicle','fromId',_app_user_sno,
			'toId',_app_user_sno,
			'createdOn','Asia/Kolkata')); 
select (select notification.get_token(json_build_object('appUserList',json_agg(_app_user_sno)))->>'tokenList')::json into token_list;
 return (select json_build_object('data',json_agg(json_build_object(
	 'vehicleRegNumber',v.vehicle_reg_number,
	 'vehicleName',v.vehicle_name,
	 'taxExpiryDate',vd.tax_expiry_date,
	 'notification',json_build_object('notification',json_build_object('title','Expiry','message','welcome to Bus Today','body',v.vehicle_name||' ('|| (v.vehicle_reg_number) || ') ' ||'tax is expire on ' || (SELECT to_char(_date, 'DD/MM/YYYY'))  ),
										'registration_ids',token_list))))from operator.vehicle_detail vd 
 	inner join operator.vehicle v on v.vehicle_sno=vd.vehicle_sno
	inner join operator.org_vehicle ov on ov.vehicle_sno=v.vehicle_sno
	inner join operator.org_owner oo on oo.org_sno=ov.org_sno
		 where vd.tax_expiry_date= current_date + INTERVAL '7day' );
end;
$$;


ALTER FUNCTION operator.get_tax_expiry_date(p_data json) OWNER TO postgres;

--
-- Name: get_toll_pass_detail(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_toll_pass_detail(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
raise notice '%',p_data;
 return (select json_agg(json_build_object(
'tollPassDetailSno',td.toll_pass_detail_sno,
'vehicleSno',td.vehicle_sno,
'orgSno',td.org_sno,
'passStartDate',td.pass_start_date,
'passEndDate',td.pass_end_date,
'tollAmount',td.toll_amount,
'tollId',td.toll_id,
'tollName',td.toll_name,
-- 'remainderTypeCd',td.remainder_type_cd,	 
-- 'remainderTypeCdName',(select operator.get_codesHdrType(json_build_object('codesHdrType',td.remainder_type_cd,'codesHdrSno',37 ))),
'activeFlag',td.active_flag	 
	 
))	from operator.toll_pass_detail td where td.vehicle_sno=(p_data->>'vehicleSno')::bigint); 
end;
$$;


ALTER FUNCTION operator.get_toll_pass_detail(p_data json) OWNER TO postgres;

--
-- Name: get_trip_all_vehicle(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_trip_all_vehicle(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
return ( select json_build_object('data',(select json_agg(json_build_object('orgSno',ov.org_sno,
								  'vehicleRegNumber',v.vehicle_reg_number,
								  'vehicleName',v.vehicle_name,
								  'districtName',a.district_name,
								  'stateName',a.state_name)))) from operator.org_vehicle ov 
inner join operator.vehicle v on v.vehicle_sno=ov.vehicle_sno
inner join operator.org_detail od on od.org_sno=ov.org_sno
inner join operator.address a on a.address_sno=od.address_sno);

end;
$$;


ALTER FUNCTION operator.get_trip_all_vehicle(p_data json) OWNER TO postgres;

--
-- Name: get_variable_pay(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_variable_pay(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin

return (select json_agg(json_build_object(
	 'vehicleDueVariablePaySno',vv.vehicle_due_variable_pay_sno,
	 'duePayDate',vv.due_pay_date,
	 'variableDueAmount',vv.due_amount,
	 'vehicleDueSno',vv.vehicle_due_sno
-- 	 'variableActiveFlag',vv.active_flag
 ))from operator.vehicle_due_variable_pay vv 
   inner join operator.vehicle_due_fixed_pay vf on vf.vehicle_due_sno = vv.vehicle_due_sno
	where vf.vehicle_sno = (p_data->>'vehicleSno')::bigint and vf.vehicle_due_sno=(p_data->>'vehicleDueSno')::bigint); 
end;
$$;


ALTER FUNCTION operator.get_variable_pay(p_data json) OWNER TO postgres;

--
-- Name: get_vehicle_driver(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_vehicle_driver(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
raise notice 'update_org_sgl %',p_data;  
 return (select json_build_object('data',json_agg(json_build_object(
	 'vehicleDriverSno',vd.vehicle_driver_sno,
	 'vehicleSno',vd.vehicle_sno,
	 'driverSno',vd.driver_sno,
	 'vehicleRegNumber',vd.vehicle_reg_number,
	 'driverName',vd.driver_name
 )))
 from (select vdr.vehicle_driver_sno,vdr.vehicle_sno,vdr.driver_sno,v.vehicle_reg_number,d.driver_name 
	   from operator.org_vehicle ov
inner join operator.vehicle_driver vdr on vdr.vehicle_sno =ov.vehicle_sno
inner join operator.vehicle v on v.vehicle_sno=vdr.vehicle_sno
inner join driver.driver d on d.driver_sno=vdr.driver_sno 
 where ov.org_sno=(p_data->>'orgSno')::bigint and
 case when (p_data->>'driverSno')::bigint is not null then vdr.driver_sno=(p_data->>'driverSno')::bigint else true end and
 case when (p_data->>'vehicleSno')::bigint is not null then vdr.vehicle_sno=(p_data->>'vehicleSno')::bigint 
	   else true end order by vdr.driver_sno asc
	   offset (p_data->>'skip')::bigint limit (p_data->>'limit')::bigint)vd);
 
end;
$$;


ALTER FUNCTION operator.get_vehicle_driver(p_data json) OWNER TO postgres;

--
-- Name: get_vehicle_due_expiry_details(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_vehicle_due_expiry_details(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
dueExpireList json;
due_count bigint;
dues_count int;
begin

select count(*) into due_count from operator.vehicle_due_variable_pay vp
inner join operator.vehicle_due_fixed_pay vd on vp.vehicle_due_sno = vd.vehicle_due_sno and org_sno = (p_data->>'orgSno')::bigint 	
inner join operator.vehicle v on v.vehicle_sno = vd.vehicle_sno
where vp.is_pass_paid = false and (vp.due_pay_date::date - (p_data->>'currentDate')::date) <= 5  and v.active_flag = true;
		
select count(*) into dues_count from operator.vehicle_due_fixed_pay vd
inner join operator.vehicle v on v.vehicle_sno = vd.vehicle_sno
where vd.org_sno = (p_data->>'orgSno')::bigint and v.active_flag = true;

if(p_data->>'expiryType' = 'No of Emi/Payments') then
raise notice 'if%',(p_data);
			select json_agg(json_build_object(
	 'orgSno',ld.org_sno,
	 'vehicleSno',ld.vehicle_sno,
	 'vehicleDueSno',ld.vehicle_due_sno,
	 'dueTypeCd',ld.due_type_cd,
	 'dueDate',ld.due_close_date,
	 'bankName',ld.bank_name,
	 'bankAccountNumber',ld.bank_account_number,
	 'bankAccountDetailSno',ld.bank_account_detail_sno,
	 'vehicleDueVariablePaySno',ld.vehicle_due_variable_pay_sno,
	 'duePayDate',ld.due_pay_date,
	 'variableDueAmount',ld.due_amount,	
	 'discription',ld.discription,
	 'vehicleName',ld.vehicle_name,
	 'vehicleRegNumber',ld.vehicle_reg_number
 )) into  dueExpireList from (with d as(select vd.org_sno,v.vehicle_sno,vd.vehicle_due_sno,vd.due_type_cd,vd.due_close_date,vd.bank_name,
		        vd.bank_account_number,vd.bank_account_detail_sno,vp.vehicle_due_variable_pay_sno,vp.due_pay_date,vp.due_amount,vd.discription,v.vehicle_name,v.vehicle_reg_number from operator.vehicle_due_fixed_pay vd
				 inner join operator.vehicle_due_variable_pay vp on vp.vehicle_due_sno = vd.vehicle_due_sno		  
				 inner join operator.vehicle v on v.vehicle_sno = vd.vehicle_sno where org_sno = (p_data->>'orgSno')::bigint  and v.active_flag = true)select * from d where d.due_pay_date >= (p_data->>'currentDate')::date  order by d.due_pay_date asc limit dues_count)ld;
				 return (select json_agg(json_build_object('dueExpireList',dueExpireList, 'count',dues_count)));
else

	select json_agg(json_build_object(
	 'orgSno',ld.org_sno,
	 'vehicleSno',ld.vehicle_sno,
	 'vehicleDueSno',ld.vehicle_due_sno,
	 'dueTypeCd',ld.due_type_cd,
	 'dueDate',ld.due_close_date,
	 'bankName',ld.bank_name,
	 'bankAccountNumber',ld.bank_account_number,
	 'bankAccountDetailSno',ld.bank_account_detail_sno,
	 'vehicleDueVariablePaySno',ld.vehicle_due_variable_pay_sno,
	 'duePayDate',ld.due_pay_date,
	 'variableDueAmount',ld.due_amount,
	 'expiryDays',(ld.due_pay_date - (p_data ->>'currentDate')::date),	
	 'discription',ld.discription,
	 'vehicleName',ld.vehicle_name,
	 'vehicleRegNumber',ld.vehicle_reg_number,
	 'expiryDays',case when expiryDays >=0 then expiryDays::text else 'Expiry'::text end
	)) into  dueExpireList from (select vd.org_sno,v.vehicle_sno,vd.vehicle_due_sno,vd.due_type_cd,vd.due_close_date,vd.bank_name,
		        vd.bank_account_number,vd.bank_account_detail_sno,vp.vehicle_due_variable_pay_sno,vp.due_pay_date,vp.due_amount,vd.discription,v.vehicle_name,v.vehicle_reg_number,
(vp.due_pay_date::date - (p_data->>'currentDate')::date) as expiryDays
							  from operator.vehicle_due_variable_pay vp
inner join operator.vehicle_due_fixed_pay vd on vp.vehicle_due_sno = vd.vehicle_due_sno and org_sno = (p_data->>'orgSno')::bigint
inner join operator.vehicle v on v.vehicle_sno = vd.vehicle_sno
where vp.is_pass_paid = false and (vp.due_pay_date::date - (p_data->>'currentDate')::date) <= 5 and v.active_flag = true and
case when (p_data->>'searchKey' is not null) then 
((v.vehicle_name ilike ('%' || trim((p_data->>'searchKey')::text) || '%')) or (v.vehicle_reg_number::text ilike ('%' || trim((p_data->>'searchKey')::text) || '%')))
else true end and case when (p_data->>'vehicleSno' is not null) then v.vehicle_sno = (p_data->>'vehicleSno')::bigint else true end order by 
case when (p_data->>'expiryType' = 'Due Expiry') and vd.due_close_date is null then 1 end desc,
case when (p_data->>'expiryType' = 'Due Expiry') and (vd.due_close_date < (p_data->>'today')::date) then vd.due_close_date end asc,
case when (p_data->>'expiryType' = 'Due Expiry') and ((vd.due_close_date::date = (p_data->>'today')::date) or (vd.due_close_date >= (p_data->>'today')::date)) then vd.due_close_date end asc,
case when (p_data->>'expiryType' = 'Due Expiry') then vd.due_close_date end desc,
v.vehicle_sno desc offset (p_data->>'skip')::bigint limit (p_data->>'limit')::bigint)ld;
			  return (select json_agg(json_build_object('dueExpireList',dueExpireList, 'count',due_count)));

end if;
						 
end;
$$;


ALTER FUNCTION operator.get_vehicle_due_expiry_details(p_data json) OWNER TO postgres;

--
-- Name: get_vehicle_due_fixed_pay(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_vehicle_due_fixed_pay(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin

return (select json_agg(json_build_object(
	 'orgSno',vd.org_sno,
	 'vehicleSno',vd.vehicle_sno,
	 'vehicleDueSno',vd.vehicle_due_sno,
	 'dueTypeCd',vd.due_type_cd,
	 'dueCloseDate',vd.due_close_date,
	 'remainderTypeCd',vd.remainder_type_cd,
         'remainderTypeCdName',(select operator.get_codesHdrType(json_build_object('codesHdrType',vd.remainder_type_cd,'codesHdrSno',37 ))),
	 'dueAmount',vd.due_amount,
	 'activeFlag',vd.active_flag,
	 'bankName',vd.bank_name,
	 'bankAccountNumber',vd.bank_account_number,
	'bankAccountDetailSno',vd.bank_account_detail_sno,
	'bankAccountName',(select bank_account_name from operator.bank_account_detail where bank_account_detail_sno = vd.bank_account_detail_sno ),
	'dueList',(select operator.get_variable_pay(json_build_object('vehicleSno',vd.vehicle_sno,'vehicleDueSno',vd.vehicle_due_sno))),	 
	'discription',vd.discription
 ))from operator.vehicle_due_fixed_pay vd where vd.vehicle_sno = (p_data->>'vehicleSno')::bigint); 
end;
$$;


ALTER FUNCTION operator.get_vehicle_due_fixed_pay(p_data json) OWNER TO postgres;

--
-- Name: get_vehicles_and_drivers(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_vehicles_and_drivers(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
bus_list json;
driver_list json;
begin

select json_agg(json_build_object('vehicleSno',v.vehicle_sno,
								  'vehicleName',v.vehicle_name,
								  'vehicleRegNumber',v.vehicle_reg_number)) into bus_list from operator.org_vehicle ov 
inner join operator.vehicle v on v.vehicle_sno=ov.vehicle_sno and v.active_flag = true and v.kyc_status=19 
where ov.org_sno = (p_data->>'orgSno')::bigint;

select json_agg(json_build_object('driverSno',d.driver_sno,'driverName',driver_name)) into driver_list from operator.operator_driver od
inner join driver.driver d on d.driver_sno =od.driver_sno 
where od.org_sno = (p_data->>'orgSno')::bigint;

return (select json_build_object('data',json_agg(json_build_object(
'busList',bus_list,
'driverList',driver_list
)))); 
end;
$$;


ALTER FUNCTION operator.get_vehicles_and_drivers(p_data json) OWNER TO postgres;

--
-- Name: get_verify_data(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_verify_data(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
dataList json;
startTime date;
endTime date;
begin
raise notice 'reportId%',p_data;
	
	select min(start_time) into startTime from driver.driver_attendance where report_id = (p_data->>'reportId')::bigint;
	select max(end_time) into endTime from driver.driver_attendance where report_id = (p_data->>'reportId')::bigint;
	
 return (select json_agg(json_build_object('driverAttendanceSno',f.driver_attendance_sno,
										  'driveKm',(f.end_value::bigint-f.start_value::bigint),
										  'startTime',startTime,
										  'endTime',endTime,
										  'reportId',f.report_id,
										   'reNumber',(select vehicle_reg_number from operator.vehicle where vehicle_sno=f.vehicle_sno),
										  'vehicleSno',f.vehicle_sno,
										   	'fuelConsumed',(select sum(fuel_quantity) from operator.fuel where driver_attendance_sno=f.driver_attendance_sno and is_calculated=false),
										   'driverName',f.driver_name)) from  (select da.driver_attendance_sno,
		da.end_value,da.start_value,da.report_id,da.vehicle_sno,d.driver_name from driver.driver_attendance da
		 inner join driver.driver d on d.driver_sno=da.driver_sno
		 where  report_id=(p_data->>'reportId')::bigint and is_calculated=false  and da.accept_status=true order by driver_attendance_sno desc)f); 
end;
$$;


ALTER FUNCTION operator.get_verify_data(p_data json) OWNER TO postgres;

--
-- Name: get_verify_report(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.get_verify_report(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
raise notice '%',p_data;
 return (select json_build_object('data',(select json_agg(json_build_object(
	 'report',(select * from operator.get_verify_data(json_build_object('reportId',d.report_id)))))									  
	from (select da.report_id from  driver.driver_attendance da
	where  da.accept_status=true and da.is_calculated=false and da.vehicle_sno=(p_data->>'vehicleSno')::bigint
	group by report_id  order by report_id desc)d ))); 
end;
$$;


ALTER FUNCTION operator.get_verify_report(p_data json) OWNER TO postgres;

--
-- Name: getclassname(smallint, text, smallint); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.getclassname(position_no smallint, type text, tyre_count_cd smallint) RETURNS text
    LANGUAGE plpgsql
    AS $$
declare 
begin
raise notice '%',tyre_count_cd;
if (tyre_count_cd = 113) then
return (select case 
		when position_no = 1 and type ='M'  then 'top-left' 
		when position_no = 2 and type ='M' then 'top-right'
		when position_no = 3 and type ='M' then 'bottom-left1'
		when position_no = 4 and type ='M' then 'bottom-left2'
		when position_no = 5 and type ='M' then 'bottom-right1'
		when position_no = 6 and type ='M' then 'bottom-right2'
		when position_no = 1 and type ='S' then 'centered'
		when position_no = 2 and type ='S' then 'centered1'
		else null end); 
end if;
return null;
end;
$$;


ALTER FUNCTION operator.getclassname(position_no smallint, type text, tyre_count_cd smallint) OWNER TO postgres;

--
-- Name: insert_address(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_address(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
addressSno bigint;
begin
-- raise notice ' %',p_data;

insert into operator.address(address_line1,address_line2,pincode,city_name,state_name,district_name,country_name,country_code,latitude,longitude) 
   values ((p_data->>'addressLine1'),(p_data->>'addressLine2'),(p_data->>'pincode')::int,(p_data->>'city'),
		   (p_data->>'state'),(p_data->>'district'),(p_data->>'country'),(p_data->>'countryCode')::smallint,
		   (p_data->>'latitude'),(p_data->>'longitude')
          ) returning address_sno  INTO addressSno;

  return (select json_build_object('data',json_build_object('addressSno',addressSno)));
  
end;
$$;


ALTER FUNCTION operator.insert_address(p_data json) OWNER TO postgres;

--
-- Name: insert_attendance_manually(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_attendance_manually(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
_driver_sno smallint;
datas json;
_open bigint;
_running bigint;
fuelDatas json;
driverAttendanceSno bigint;
reportId bigint;
begin
    
	select count(*) into _running from driver.driver_attendance where  attendance_status_cd=28 and (driver_sno=(p_data->>'driverSno')::bigint or vehicle_sno=(p_data->>'vehicleSno')::bigint);  
	
	select count(*) into _open from driver.driver_attendance where driver_sno=(p_data->>'driverSno')::bigint  and attendance_status_cd=28 
    and (start_time::date <= (p_data->>'startTime')::date or start_time::date <= (p_data->>'endTime')::date);

if _open=0 and _running=0 then
raise notice '_close%',_open;
	select driver.insert_driver_attendance(p_data)->>'data' into datas;
		raise notice 'datas%',datas;
		driverAttendanceSno=(datas->>'driverAttendanceSno')::bigint;
		raise notice 'driverAttendanceSno%',driverAttendanceSno;
				raise notice 'p_data%',p_data;

if(driverAttendanceSno is not null) then
raise notice 'driverAttendanceSSSno%',driverAttendanceSno;
	if (p_data->>'fuelFillTypeCd')::smallint = 133 or (p_data->>'fuelFillTypeCd')::smallint = 134 then
	select operator.insert_fuel((p_data::jsonb || json_build_object('driverAttendanceSno',driverAttendanceSno,'isCalculated',false)::jsonb)::json )->>'data' into fuelDatas;
			raise notice 'fuelDatas%',fuelDatas->0;
	reportId=(fuelDatas->0->>'reportId')::bigint;
			raise notice 'reportId123%',reportId;
	
	update driver.driver_attendance set report_id=reportId where driver_attendance_sno=driverAttendanceSno;
	else
	raise notice 'reportIdJack%',reportId;
	update driver.driver_attendance set report_id=(p_data->>'reportId')::bigint where driver_attendance_sno=driverAttendanceSno;
	end if;
return (select json_build_object('data',json_build_object('driverAttendanceSno',driverAttendanceSno)));

else
  raise notice 'pPPP_data%',p_data;
  return (select json_build_object('data',datas));
end if;
else
  return (select json_build_object('data',json_build_object('msg','This vehicle or Driver is driving')));
end if;

end;
$$;


ALTER FUNCTION operator.insert_attendance_manually(p_data json) OWNER TO postgres;

--
-- Name: insert_fuel(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_fuel(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
v json;
fuelSno bigint;
fuelMedia json;
tankMedia json;
odoMeterMedia json;
driverAttendanceSno bigint;
reportId bigint;
begin
 raise notice'%mutup_data',p_data;
if (p_data->>'filledDate')::date=(select current_date)::date then
update operator.vehicle_detail set odo_meter_value=(p_data->>'odoMeterValue')::bigint where vehicle_sno=(p_data->>'vehicleSno')::bigint ;
end if;
raise notice 'p_data %',p_data->>'media';
 for v in SELECT * FROM json_array_elements((p_data->>'media')::json) loop
raise notice 'v %',v;
if v->>'keyName' ='OdoReading' then
 	odoMeterMedia=v;
 elseif v->>'keyName' = 'tankReading' then
	tankMedia = v;
 elseif v->>'keyName' = 'fuelReading' then
 	fuelMedia=v;
 end if;
 end loop;
if (p_data->>'reportId')::bigint is not null then 
reportId:=(p_data->>'reportId')::bigint;
else
	if (p_data->>'isFilled')::boolean=true then
		select report_id into reportId from operator.fuel where vehicle_sno=(p_data->>'vehicleSno')::bigint order by report_id desc limit 1;
			 raise notice'%reportId',reportId;
			if reportId is not null then
			reportId:=reportId+1;
			else
			select max(report_id) into reportId from operator.fuel;
				if reportId is null then
					reportId:=0;
				else
					reportId:=reportId+1;
				end if;
			end if;
	else
		select report_id into reportId from operator.fuel where vehicle_sno=(p_data->>'vehicleSno')::bigint order by report_id desc limit 1;
	end if;
end if;
  insert into operator.fuel(vehicle_sno,driver_sno,driver_attendance_sno,bunk_sno,lat_long,fuel_media,odo_meter_media,tank_media,fuel_quantity,filled_date,
	fuel_amount,odo_meter_value,price_per_ltr,is_filled,accept_status,fuel_fill_type_cd,is_calculated,report_id) values
  ((p_data->>'vehicleSno')::bigint,(p_data->>'driverSno')::bigint,(p_data->>'driverAttendanceSno')::bigint,(p_data->>'bunkSno')::bigint,p_data->>'latLong',
   fuelMedia,odoMeterMedia,tankMedia,(p_data->>'fuelQuantity')::double precision,(p_data->>'filledDate')::timestamp,
   (p_data->>'fuelAmount')::double precision,(p_data->>'odoMeterValue')::bigint,(p_data->>'pricePerLtr')::double precision,
   (p_data->>'isFilled')::boolean,(p_data->>'acceptStatus')::boolean,(p_data->>'fuelFillTypeCd')::smallint,(p_data->>'isCalculated')::boolean,reportId)
   returning fuel_sno into fuelSno;
   raise notice'1234433%',p_data->>'isFilled';
  if (p_data->>'fuelFillTypeCd')::smallint = 133 then 
	perform driver.insert_bus_report(json_build_object('reportId',(p_data->>'reportId')::bigint));
  end if;
return (select json_build_object('data',json_agg(json_build_object('fuelSno',fuelSno,'reportId',reportId,'driverAttendanceSno',driverAttendanceSno))));
end;
$$;


ALTER FUNCTION operator.insert_fuel(p_data json) OWNER TO postgres;

--
-- Name: insert_operator_driver(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_operator_driver(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
operatorDriverSno bigint;
_count int = 0; 
begin
raise notice ' p_data %',p_data;  
select count(*) into _count from operator.operator_driver where org_sno = (p_data->>'orgSno')::bigint and driver_sno = (p_data->>'driverSno')::bigint;
if(_count = 0) then
insert into operator.operator_driver(org_sno,driver_sno,accept_status_cd) 
   values ((p_data->>'orgSno')::bigint,(p_data->>'driverSno')::bigint,(p_data->>'acceptStatusCd')::smallint
          ) returning operator_driver_sno  INTO operatorDriverSno;

  return (select json_build_object('operatorDriverSno',operatorDriverSno));
  else 
  return (select json_build_object('msg','this driver already exists'));
  end if;
end;
$$;


ALTER FUNCTION operator.insert_operator_driver(p_data json) OWNER TO postgres;

--
-- Name: insert_operator_route(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_operator_route(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
operatorRouteSno bigint;
returnOperatorRouteSno bigint;
routeSno bigint;
_viaList json := (p_data->>'viaList');
v json;
viaSno bigint;
begin
raise notice 'muthufirster78%',p_data;
raise notice 'jawahar%',p_data->>'viaList';


insert into operator.operator_route(route_sno,operator_sno)  values(
(p_data->>'routeSno')::bigint,(p_data->>'operatorSno')::bigint
) returning operator_route_sno  INTO operatorRouteSno;


insert into operator.operator_route(route_sno,operator_sno)  values(
(p_data->>'returnRouteSno')::bigint,(p_data->>'operatorSno')::bigint
) returning operator_route_sno  INTO returnOperatorRouteSno;

raise notice '_viaListsasd%',_viaList;
 for v in SELECT * FROM json_array_elements((_viaList->>'viaList')::json) loop
raise notice 'v1225488%',v;

 insert into operator.via(operator_route_sno,city_sno) values(operatorRouteSno,(v->>'citySno')::bigint);
 insert into operator.via(operator_route_sno,city_sno) values(returnOperatorRouteSno,(v->>'citySno')::bigint)
 
 returning via_sno into viaSno; 	
end loop;
perform operator.insert_vehicle_route((select (p_data)::jsonb || ('{ "operatorRouteSno":' || operatorRouteSno || ',"returnOperatorRouteSno":' || returnOperatorRouteSno || '}')::jsonb)::json);
 return (select json_build_object('data',json_build_object('operatorRouteSno',operatorRouteSno,'returnOperatorRouteSno',returnOperatorRouteSno,'viaSno',viaSno))); 
end;
$$;


ALTER FUNCTION operator.insert_operator_route(p_data json) OWNER TO postgres;

--
-- Name: insert_org(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_org(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
orgSno bigint;
v_data json =( p_data->>'ownerDetails');
begin
raise notice '%',p_data;
raise notice 'v_data%',v_data;


insert into operator.org(org_name,org_status_cd,owner_name,vehicle_number) 
   values ((p_data->>'orgName'),(p_data->>'orgStatusCd')::smallint,(v_data->>'ownerName'),(v_data->>'vehicleNumber')
          ) returning org_sno  INTO orgSno;

  return (select json_build_object('data',json_build_object('orgSno',orgSno)));
  
end;
$$;


ALTER FUNCTION operator.insert_org(p_data json) OWNER TO postgres;

--
-- Name: insert_org_account(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_org_account(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
bankAccountDetailSno bigint;
v_doc json;
begin
 raise notice 'kgf%',p_data;

for v_doc in SELECT * FROM json_array_elements((p_data->>'accountList')::json) loop
raise notice 'v_doc  %',v_doc;
insert into operator.bank_account_detail(org_sno,bank_account_name) 
   values ((p_data->>'orgSno')::bigint,(v_doc->>'bankAccountName')
          ) returning bank_account_detail_sno  INTO bankAccountDetailSno;
		  
end loop;

  return (select json_build_object('data',json_build_object('bankAccountDetailSno',bankAccountDetailSno)));
  
end;
$$;


ALTER FUNCTION operator.insert_org_account(p_data json) OWNER TO postgres;

--
-- Name: insert_org_contact(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_org_contact(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
orgContactSno bigint;
contactSno bigint;
v_doc json;
begin
 raise notice 'kgf%',p_data;

for v_doc in SELECT * FROM json_array_elements((p_data->>'contactList')::json) loop
raise notice 'v_doc  %',v_doc;
select(select portal.create_contact((v_doc::jsonb || json_build_object('userSno',(p_data->>'appUserSno')::bigint)::jsonb)::json)->>'data')::json->>'contactSno' INTO contactSno;
raise notice 'contactSno %',contactSno;
insert into operator.org_contact(org_sno,contact_sno) 
   values ((p_data->>'orgSno')::bigint,contactSno
          ) returning org_contact_sno  INTO orgContactSno;
		  
end loop;

  return (select json_build_object('data',json_build_object('orgContactSno',orgContactSno)));
  
end;
$$;


ALTER FUNCTION operator.insert_org_contact(p_data json) OWNER TO postgres;

--
-- Name: insert_org_detail(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_org_detail(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
orgDetailSno bigint;
begin
raise notice 'insert_org_detail  %',p_data;

insert into operator.org_detail(org_sno,org_logo,org_banner,address_sno,org_website) 
     values ((p_data->>'orgSno')::bigint,
			 (p_data->>'logo')::json,
             (p_data->>'coverImage')::json,
			 (p_data->>'addressSno')::bigint,
			 (p_data->>'website')
            ) returning org_detail_sno  INTO orgDetailSno;

  return (select json_build_object('data',json_build_object('orgDetailSno',orgDetailSno)));
  
end;
$$;


ALTER FUNCTION operator.insert_org_detail(p_data json) OWNER TO postgres;

--
-- Name: insert_org_owner(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_org_owner(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
orgOwnerSno bigint;
begin
--  raise notice '%',p_data;

insert into operator.org_owner(org_sno,app_user_sno) 
   values ((p_data->>'orgSno')::bigint,
           (p_data->>'appUserSno')::bigint
          ) returning org_owner_sno  INTO orgOwnerSno;

  return (select json_build_object('data',json_build_object('orgOwnerSno',orgOwnerSno)));
  
end;
$$;


ALTER FUNCTION operator.insert_org_owner(p_data json) OWNER TO postgres;

--
-- Name: insert_org_social_link(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_org_social_link(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
orgSocialLinkSno bigint;
socialLinkSno bigint;
v_doc json;
begin
raise notice 'insert_org_social_link %',p_data;

for v_doc in SELECT * FROM json_array_elements((p_data->>'social')::json) loop
raise notice 'v_doc %',v_doc;
select(select portal.create_social_link(v_doc)->>'data')::json->>'socialLinkSno' INTO socialLinkSno;

insert into operator.org_social_link(org_sno,social_link_sno) 
   values ((p_data->>'orgSno')::bigint,socialLinkSno
          ) returning org_social_link_sno  INTO orgSocialLinkSno;
		  
end loop;

  return (select json_build_object('data',json_build_object('orgSocialLinkSno',orgSocialLinkSno)));
  
end;
$$;


ALTER FUNCTION operator.insert_org_social_link(p_data json) OWNER TO postgres;

--
-- Name: insert_org_vehicle(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_org_vehicle(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
orgVehicleSno bigint;
begin
insert into operator.org_vehicle(org_sno,vehicle_sno) 
     values ((p_data->>'orgSno')::bigint,
			 (p_data->>'vehicleSno')::bigint
            ) returning org_vehicle_sno  INTO orgVehicleSno;

  return (select json_build_object('data',json_build_object('orgVehicleSno',orgVehicleSno)));
end;
$$;


ALTER FUNCTION operator.insert_org_vehicle(p_data json) OWNER TO postgres;

--
-- Name: insert_single(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_single(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
singleSno bigint;
begin
--  raise notice '%',p_data;

insert into operator.org_owner(route_sno,org_sno,vehicle_sno,starting_time,running_time,active_flag)  values(
(p_data->>'routeSno')::bigint,(p_data->>'orgSno')::bigint,(p_data->>'vehicleSno')::bigint,(p_data->>'starting_time')::time,(p_data->>'running_time')::time,(p_data->>'activeFlag')::boolean
) returning single_sno  INTO singleSno;

 return (select json_build_object('data',json_build_object('singleSno',singleSno))); 
end;
$$;


ALTER FUNCTION operator.insert_single(p_data json) OWNER TO postgres;

--
-- Name: insert_single_route(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_single_route(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
dates json;
singleRouteSno bigint;
begin
 for dates in SELECT * FROM json_array_elements((p_data->>'dateList')::json) loop
 raise notice '%',dates;
  insert into operator.single_route(route_sno,org_sno,vehicle_sno,starting_time,running_time) values
  ((p_data->>'routeSno')::bigint,
   (p_data->>'orgSno')::bigint,
   (p_data->>'vehicleSno')::bigint,
   (dates->>'startTime')::timestamp,
   (dates->>'runTime')::bigint)
  returning single_route_sno into singleRouteSno;
end loop;
return (select json_build_object('data',json_agg(json_build_object('singleRouteSno',singleRouteSno))));
end;
$$;


ALTER FUNCTION operator.insert_single_route(p_data json) OWNER TO postgres;

--
-- Name: insert_toll_pass_detail(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_toll_pass_detail(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
v_doc json;
tollPassDetailSno bigint;
begin
 raise notice 'JAWA%',v_doc;
 
 for v_doc in SELECT * FROM json_array_elements((p_data->>'passList')::json) loop
raise notice 'v_doc  %',v_doc;
	insert into operator.toll_pass_detail(vehicle_sno,org_sno,toll_id,toll_name,toll_amount,pass_start_date,pass_end_date,active_flag)  values(
(p_data->>'vehicleSno')::bigint,(p_data->>'orgSno')::bigint,(v_doc->>'tollId'),(v_doc->>'tollName'),(v_doc->>'tollAmount')::double precision,(v_doc->>'passStartDate')::date,(v_doc->>'passEndDate')::date,(v_doc->>'activeFlag')::boolean
) returning toll_pass_detail_sno  INTO tollPassDetailSno;
end loop;
 return (select json_build_object('data',json_build_object('tollPassDetailSno',tollPassDetailSno))); 
end;
$$;


ALTER FUNCTION operator.insert_toll_pass_detail(p_data json) OWNER TO postgres;

--
-- Name: insert_trip(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_trip(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
tripSno bigint;
begin
raise notice '%',p_data;

insert into operator.trip(source_name,destination,start_date,end_date,district_sno) 
   values ((p_data->>'sourceName'),
		   (p_data->>'destination'),
           (p_data->>'startDate')::timestamp,
           (p_data->>'endDate')::timestamp,
           (p_data->>'districtSno')::bigint
          ) returning trip_sno  INTO tripSno;
perform operator.insert_trip_route(((p_data)::jsonb || ('{"tripSno": ' || tripSno ||' }')::jsonb )::json );
	return (select json_build_object('data',json_build_object('tripSno',tripSno)));
end;
$$;


ALTER FUNCTION operator.insert_trip(p_data json) OWNER TO postgres;

--
-- Name: insert_trip_route(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_trip_route(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
v_doc json;
tripRouteSno bigint;
begin
--  raise notice '%',p_data;
for v_doc in SELECT * FROM json_array_elements((p_data->>'tripRoute')::json) loop
raise notice 'v_doc  %',v_doc;
insert into operator.trip_route(trip_sno,via_name,latitude,longitude) 
   values ((p_data->>'tripSno')::bigint,
		   (v_doc->>'viaName'),
		   (v_doc->>'latitude'),
		   (v_doc->>'longitude')
          ) returning trip_route_sno  INTO tripRouteSno;
end loop;

  return (select json_build_object('tripRouteSno',tripRouteSno));
  
end;
$$;


ALTER FUNCTION operator.insert_trip_route(p_data json) OWNER TO postgres;

--
-- Name: insert_variable_pay(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_variable_pay(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
_vehicle_due_sno bigint;
vehicleDueVariablePaySno bigint;
bankAccountDetailSno bigint;
v_doc json;
z_doc json;
begin
raise notice 'padhu%',(p_data);

for v_doc in SELECT * FROM json_array_elements((p_data->>'loanList')::json) loop

raise notice 'Loan if%',v_doc;

bankAccountDetailSno := (v_doc->>'bankAccountDetailSno')::bigint;

if bankAccountDetailSno is null then

insert into operator.bank_account_detail(org_sno,bank_account_name) values ((p_data->>'orgSno')::bigint,(v_doc->>'bankAccountName')) returning bank_account_detail_sno into bankAccountDetailSno;

-- 	raise notice 'bankAccountDetailSno%',bankAccountDetailSno;	

end if;


insert into operator.vehicle_due_fixed_pay(vehicle_sno,org_sno,due_type_cd,due_close_date,remainder_type_cd,
										   due_amount,bank_name,bank_account_number,bank_account_detail_sno,discription) 
		values ((p_data->>'vehicleSno')::bigint,
				(p_data->>'orgSno')::bigint,(v_doc->>'dueTypeCd')::smallint,(v_doc->>'dueCloseDate')::date,(v_doc->>'remainderTypeCd')::int[],
				(v_doc->>'dueAmount')::double precision,(v_doc->>'bankName'),
				(v_doc->>'bankAccountNumber'),bankAccountDetailSno,(v_doc->>'discription'))
				returning vehicle_due_sno INTO _vehicle_due_sno;
				
raise notice 'vehicle_due_sno%',_vehicle_due_sno;

for z_doc in SELECT * FROM json_array_elements((v_doc->>'dueList')::json) loop
raise notice 'dueList%',(v_doc->>'dueList');

insert into operator.vehicle_due_variable_pay(vehicle_due_sno,due_pay_date,due_amount)
        values(_vehicle_due_sno,(z_doc->>'duePayDate')::date,(z_doc->>'variableDueAmount')::double precision) 
			   returning vehicle_due_variable_pay_sno INTO vehicleDueVariablePaySno;
			   
end loop;
end loop;
return (select json_build_object('data',json_build_object('_vehicle_due_sno',_vehicle_due_sno)));

end;
$$;


ALTER FUNCTION operator.insert_variable_pay(p_data json) OWNER TO postgres;

--
-- Name: insert_vehicle(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_vehicle(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
vehicleSno bigint;
begin
-- raise notice '%',p_data;
insert into operator.vehicle(vehicle_reg_number,
			 vehicle_name,
			 media_sno,
			 vehicle_banner_name,
			 chase_number,engine_number,
			 vehicle_type_cd,
			 tyre_type_cd,
			 tyre_size_cd,
			 tyre_count_cd,
			 kyc_status) 
   values (p_data->>'vehicleRegNumber',
		   p_data->>'vehicleName',
		   (p_data->>'mediaSno')::bigint,
		   p_data->>'vehicleBanner',
		   p_data->>'chaseNumber',
		   p_data->>'engineNumber',
		   (p_data->>'vehicleTypeCd')::smallint,
		    (p_data->>'tyreTypeCd')::smallint[],
		    (p_data->>'tyreSizeCd')::smallint[],
			(p_data->>'tyreCountCd')::smallint,
		   (p_data->>'kycStatus')::smallint
          ) returning vehicle_sno  INTO vehicleSno;
  return (select json_build_object('data',json_build_object('vehicleSno',vehicleSno)));
end;
$$;


ALTER FUNCTION operator.insert_vehicle(p_data json) OWNER TO postgres;

--
-- Name: insert_vehicle_detail(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_vehicle_detail(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
vehicleDetail jsonb := (p_data->>'vehicleDetails')::jsonb;
contractCarriage jsonb := (p_data->>'contractCarriage')::jsonb;
vehicleDetailSno bigint;
OthersList json:= (p_data->>'OthersList')::jsonb;
begin
raise notice 'p_data%',vehicleDetail;
insert into operator.vehicle_detail(vehicle_sno,vehicle_reg_date,fc_expiry_date,fc_expiry_amount,insurance_expiry_date,insurance_expiry_amount,pollution_expiry_date,
									tax_expiry_date,tax_expiry_amount,permit_expiry_date,state_sno,district_sno,top_luckage_carrier,
									luckage_count,odo_meter_value,fuel_capacity,fuel_type_cd,vehicle_logo,
									price_perday,driving_type_cd,wheelbase_type_cd,vehicle_make_cd,vehicle_model,wheels_cd,
									stepny_cd,seat_capacity,video_types_cd,seat_type_cd,audio_types_cd,cool_type_cd,
									suspension_type,public_addressing_system_cd,lighting_system_cd,otherslist,fuel_norms_cd,image_sno) 
		values ((p_data->>'vehicleSno')::bigint,(vehicleDetail->>'vehicleRegDate')::timestamp,(vehicleDetail->>'fcExpiryDate')::timestamp,
				(vehicleDetail->>'fcExpiryAmount')::double precision,(vehicleDetail->>'insuranceExpiryDate')::timestamp,
				(vehicleDetail->>'insuranceExpiryAmount')::double precision,(vehicleDetail->>'pollutionExpiryDate')::timestamp,
			 (vehicleDetail->>'taxExpiryDate')::timestamp,(vehicleDetail->>'taxExpiryAmount')::double precision,
			(vehicleDetail->>'permitExpiryDate')::timestamp,(vehicleDetail->>'stateSno')::bigint,(vehicleDetail->>'districtsSno')::bigint,
			 (contractCarriage->>'topCarrier')::boolean,(contractCarriage->>'luckageCount')::smallint,
		     (vehicleDetail->>'odoMeterValue')::bigint,(vehicleDetail->>'fuelCapacity')::int,
			 (vehicleDetail->>'fuelTypeCd')::smallint,
			 (vehicleDetail->>'vehicleLogo')::json,(contractCarriage->>'pricePerday')::bigint,
			 (vehicleDetail->>'drivingType')::smallint,(vehicleDetail->>'wheelType')::smallint, 
			 (vehicleDetail->>'vehicleMakeCd')::smallint,vehicleDetail->>'vehicleModelCd',
			 (vehicleDetail->>'wheelsCd')::smallint,(vehicleDetail->>'stepnyCd')::smallint,
			 (vehicleDetail->>'seatCapacity')::smallint,(contractCarriage->>'videoType')::int[],
			 (contractCarriage->>'seatType')::smallint,(contractCarriage->>'audioType')::int[], 
			 (contractCarriage->>'coolType')::smallint,(contractCarriage->>'suspensionType')::smallint,
			 (contractCarriage->>'publicAddressingSystem')::int[],(contractCarriage->>'lightingSystem')::int[],
			 OthersList,(vehicleDetail->>'fuelNormsCd')::smallint,(contractCarriage->>'mediaSno')::bigint
            ) returning vehicle_detail_sno  INTO vehicleDetailSno;
  return (select json_build_object('data',json_build_object('vehicleDetailSno',vehicleDetailSno)));
end;
$$;


ALTER FUNCTION operator.insert_vehicle_detail(p_data json) OWNER TO postgres;

--
-- Name: insert_vehicle_driver(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_vehicle_driver(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
vehicleDriverSno bigint;
begin
raise notice 'DATA%',p_data;
if (p_data->>'vehicleDriverSno')::bigint is not null then 
	delete from operator.vehicle_driver where vehicle_driver_sno=(p_data->>'vehicleDriverSno')::bigint;
	return (select json_build_object('data',json_build_object('msg','Deleted successfully')));
else
	if (select count(*) from operator.vehicle_driver where driver_sno=(p_data->>'driverSno')::bigint and vehicle_sno=(p_data->>'vehicleSno')::bigint)>0 then 
	raise notice 'count%',p_data;
	return (select json_build_object('data',json_build_object('msg','You have already assigned a vehicle to this driver')));
-- 	elseif (select count(*) from operator.vehicle_driver where vehicle_sno=(p_data->>'vehicleSno')::bigint)>0 then
-- 	return (select json_build_object('data',json_build_object('msg','You have already assigned a driver for this vehicle')));
	else
	insert into operator.vehicle_driver(driver_sno,vehicle_sno,created_on) values
	((p_data->>'driverSno')::bigint,
	 (p_data->>'vehicleSno')::bigint,
	 portal.get_time_with_zone(json_build_object('timeZone',p_data->>'createdOn'))::timestamp)
	returning vehicle_driver_sno into vehicleDriverSno;
	  return (select json_build_object('data',json_build_object('vehicleDriverSno',vehicleDriverSno)));
	  end if;
end if;
end;
$$;


ALTER FUNCTION operator.insert_vehicle_driver(p_data json) OWNER TO postgres;

--
-- Name: insert_vehicle_due(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_vehicle_due(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
_vehicle_due_sno bigint;
vehicleDueVariablePaySno bigint;
bankAccountDetailSno bigint;
v_doc json;
z_doc json;
begin
raise notice 'padhu%',(p_data);

for v_doc in SELECT * FROM json_array_elements((p_data->>'loanList')::json) loop

bankAccountDetailSno := (v_doc->>'bankAccountDetailSno')::bigint;

if((v_doc->>'dueTypeCd')::smallint = 130) then
raise notice 'Loan if%',v_doc;

if bankAccountDetailSno is null then

insert into operator.bank_account_detail(org_sno,bank_account_name) values ((p_data->>'orgSno')::bigint,(v_doc->>'bankAccountName')) returning bank_account_detail_sno into bankAccountDetailSno;

raise notice 'bankAccountDetailSno%',bankAccountDetailSno;

end if;

	insert into operator.vehicle_due_fixed_pay(vehicle_sno,org_sno,due_type_cd,due_close_date,remainder_type_cd,
											   due_amount,bank_name,bank_account_number,bank_account_detail_sno,discription) 
			values ((p_data->>'vehicleSno')::bigint,
					(p_data->>'orgSno')::bigint,(v_doc->>'dueTypeCd')::smallint,(v_doc->>'dueCloseDate')::date,(v_doc->>'remainderTypeCd')::int[],
					(v_doc->>'dueAmount')::double precision,(v_doc->>'bankName'),
					(v_doc->>'bankAccountNumber'),bankAccountDetailSno,(v_doc->>'discription'))
					returning vehicle_due_sno INTO _vehicle_due_sno;

	raise notice 'vehicle_due_sno%',_vehicle_due_sno;

	for z_doc in SELECT * FROM json_array_elements((v_doc->>'dueList')::json) loop
	raise notice 'dueList%',(v_doc->>'dueList');

	insert into operator.vehicle_due_variable_pay(vehicle_due_sno,due_pay_date,due_amount)
			values(_vehicle_due_sno,(z_doc->>'duePayDate')::date,(z_doc->>'variableDueAmount')::double precision) 
				   returning vehicle_due_variable_pay_sno INTO vehicleDueVariablePaySno;

	end loop;

else
raise notice 'Loan else%',(p_data);

raise notice ' VDOC %',v_doc;
insert into operator.vehicle_due_fixed_pay(vehicle_sno,org_sno,due_type_cd,due_close_date,remainder_type_cd,
										   due_amount,bank_name,bank_account_number,bank_account_detail_sno,discription) 
		values ((p_data->>'vehicleSno')::bigint,
				(p_data->>'orgSno')::bigint,(v_doc->>'dueTypeCd')::smallint,(v_doc->>'dueCloseDate')::date,(v_doc->>'remainderTypeCd')::int[],
				(v_doc->>'dueAmount')::double precision,(v_doc->>'bankName'),
				(v_doc->>'bankAccountNumber'),(v_doc->>'bankAccountDetailSno')::bigint,(v_doc->>'discription'))
				returning vehicle_due_sno INTO _vehicle_due_sno;
end if;
end loop;

  return (select json_build_object('data',json_build_object('_vehicle_due_sno',_vehicle_due_sno)));
end;
$$;


ALTER FUNCTION operator.insert_vehicle_due(p_data json) OWNER TO postgres;

--
-- Name: insert_vehicle_due_fixed_pay(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_vehicle_due_fixed_pay(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
_vehicle_due_sno bigint;
vehicleDueVariablePaySno bigint;
bankAccountDetailSno bigint;
bankAccountName text;
v_doc json;
z_doc json;
begin
raise notice 'padhu%',(p_data);

for v_doc in SELECT * FROM json_array_elements((p_data->>'loanList')::json) loop

raise notice 'Loan if%',v_doc;

bankAccountDetailSno := (v_doc->>'bankAccountDetailSno')::bigint;

bankAccountName := (v_doc->>'bankAccountName')::text;

if bankAccountName is not null then

if bankAccountDetailSno is null then

insert into operator.bank_account_detail(org_sno,bank_account_name) values ((p_data->>'orgSno')::bigint,(v_doc->>'bankAccountName')) returning bank_account_detail_sno into bankAccountDetailSno;

-- 	raise notice 'bankAccountDetailSno%',bankAccountDetailSno;	

end if;

end if;


insert into operator.vehicle_due_fixed_pay(vehicle_sno,org_sno,due_type_cd,due_close_date,remainder_type_cd,
										   due_amount,bank_name,bank_account_number,bank_account_detail_sno,discription) 
		values ((p_data->>'vehicleSno')::bigint,
				(p_data->>'orgSno')::bigint,(v_doc->>'dueTypeCd')::smallint,(v_doc->>'dueCloseDate')::date,(v_doc->>'remainderTypeCd')::int[],
				(v_doc->>'dueAmount')::double precision,(v_doc->>'bankName'),
				(v_doc->>'bankAccountNumber'),bankAccountDetailSno,(v_doc->>'discription'))
				returning vehicle_due_sno INTO _vehicle_due_sno;
				
raise notice 'vehicle_due_sno%',_vehicle_due_sno;

for z_doc in SELECT * FROM json_array_elements((v_doc->>'dueList')::json) loop
raise notice 'dueList%',(v_doc->>'dueList');

insert into operator.vehicle_due_variable_pay(vehicle_due_sno,due_pay_date,due_amount)
        values(_vehicle_due_sno,(z_doc->>'duePayDate')::date,(z_doc->>'variableDueAmount')::double precision) 
			   returning vehicle_due_variable_pay_sno INTO vehicleDueVariablePaySno;
			   
end loop;
end loop;
return (select json_build_object('data',json_build_object('_vehicle_due_sno',_vehicle_due_sno)));

end;
$$;


ALTER FUNCTION operator.insert_vehicle_due_fixed_pay(p_data json) OWNER TO postgres;

--
-- Name: insert_vehicle_owner(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_vehicle_owner(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
vehicleOwnerSno bigint;
v_doc json;
begin
  for v_doc in SELECT * FROM json_array_elements((p_data->>'ownerList')::json) loop
  raise notice 'owner %',v_doc ;
 insert into operator.vehicle_owner(vehicle_sno,owner_name,owner_number,current_owner,purchase_date,app_user_sno) 
     values ((p_data->>'vehicleSno')::bigint,v_doc->>'ownerName',v_doc->>'ownerNumber',(v_doc->>'currentOwner')::boolean,(v_doc->>'purchaseDate')::timestamp,
            (v_doc->>'appUserSno')::bigint) returning vehicle_owner_sno  INTO vehicleOwnerSno;
end loop;
return (select json_build_object('data',json_build_object('vehicleOwnerSno',vehicleOwnerSno)));
end;
$$;


ALTER FUNCTION operator.insert_vehicle_owner(p_data json) OWNER TO postgres;

--
-- Name: insert_vehicle_route(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.insert_vehicle_route(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
vehicleRouteSno bigint;
v_data json := p_data->>'viaList';
v bigint;
begin
raise notice 'vehicleSno%',v_data->>'vehicleSno';

insert into operator.vehicle_route(operator_route_sno,vehicle_sno) 
   values ((p_data->>'operatorRouteSno')::bigint,case when (v_data->>'vehicleSno')::bigint is not null then (v_data->>'vehicleSno')::bigint else (p_data->>'vehicleSno')::bigint end) ;
   insert into operator.vehicle_route(operator_route_sno,vehicle_sno) 
   values ((p_data->>'returnOperatorRouteSno')::bigint,case when (v_data->>'vehicleSno')::bigint is not null then (v_data->>'vehicleSno')::bigint else (p_data->>'vehicleSno')::bigint end)
   returning vehicle_route_sno  INTO vehicleRouteSno;
  return (select json_build_object('data',json_build_object('vehicleRouteSno',vehicleRouteSno)));
  
end;
$$;


ALTER FUNCTION operator.insert_vehicle_route(p_data json) OWNER TO postgres;

--
-- Name: update_active_status(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_active_status(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
raise notice '%',p_data;

update operator.vehicle set active_flag = false
where vehicle_sno = (p_data->>'vehicleSno')::bigint;

return 
( json_build_object('data',json_build_object('vehicleSno',(p_data->>'vehicleSno')::bigint)));
end;
$$;


ALTER FUNCTION operator.update_active_status(p_data json) OWNER TO postgres;

--
-- Name: update_address(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_address(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
raise notice 'update_address %',p_data;

update operator.address set address_line1 = (p_data->>'addressLine1'),
address_line2 = (p_data->>'addressLine2'),pincode = (p_data->>'pincode')::int,
city_name = (p_data->>'city'),state_name = (p_data->>'state'),
district_name = (p_data->>'district'),country_name = (p_data->>'country'),
country_code = (p_data->>'countryCode')::smallint,latitude = (p_data->>'latitude'),
longitude = (p_data->>'longitude') where address_sno = (p_data->>'addressSno')::bigint;

return 
( json_build_object('data',json_build_object('addressSno',(p_data->>'addressSno')::bigint)));
end;
$$;


ALTER FUNCTION operator.update_address(p_data json) OWNER TO postgres;

--
-- Name: update_driver_attendance(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_driver_attendance(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION operator.update_driver_attendance(p_data json) OWNER TO postgres;

--
-- Name: update_driver_status(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_driver_status(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
-- update driver.driver set accept_status_cd=124 where driver_sno=(p_data->>'driverSno')::bigint;
delete from operator.operator_driver 
where driver_sno = (p_data->>'driverSno')::bigint and org_sno = (p_data->>'orgSno')::bigint;

return (json_build_object('data',json_build_object('driverSno',(p_data->>'driverSno')::bigint)));
end;
$$;


ALTER FUNCTION operator.update_driver_status(p_data json) OWNER TO postgres;

--
-- Name: update_due_fixed_pay(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_due_fixed_pay(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
vehicleDueVariablePaySno bigint;
begin
raise notice '%',p_data;
update operator.vehicle_due_variable_pay set is_pass_paid = (p_data->>'isPassPaid')::boolean
								where vehicle_due_variable_pay_sno = (p_data->>'vehicleDueVariablePaySno')::bigint 
								returning vehicle_due_variable_pay_sno into vehicleDueVariablePaySno;

  return (select json_build_object('vehicleDueVariablePaySno',vehicleDueVariablePaySno));

end;
$$;


ALTER FUNCTION operator.update_due_fixed_pay(p_data json) OWNER TO postgres;

--
-- Name: update_operator_vehicle_route(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_operator_vehicle_route(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
routeSno bigint;
isAlready boolean;
begin
	raise notice 'update_operator_vehicle_route %',p_data;
	select route_sno into routeSno from master_data.route where source_city_sno = (p_data->>'sourceCitySno')::bigint
	and destination_city_sno = (p_data->>'destinationCitySno')::bigint;
	
	raise notice 'routeSno %',routeSno;

	update operator.operator_route set route_sno = routeSno
	where operator_route_sno = (p_data->>'operatorRouteSno')::bigint;
	
  return (select json_build_object('data',json_agg(json_build_object('routeSno',routeSno))));

end;
$$;


ALTER FUNCTION operator.update_operator_vehicle_route(p_data json) OWNER TO postgres;

--
-- Name: update_org(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_org(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
v_doc json;
logo json;
coverImage json;
begin
raise notice 'update_org %',p_data;

for v_doc in SELECT * FROM json_array_elements((p_data->>'media')::json) loop
  raise notice 'media %',v_doc ;
 if (v_doc->>'keyName') = 'logo' then
 logo := v_doc;
 elseif (v_doc->>'keyName') = 'coverImage' then
  coverImage := v_doc;
 end if;
end loop;

perform operator.update_org_sgl(p_data::json);
perform operator.update_address((p_data->>'address')::json);
perform operator.update_org_detail((select (p_data->>'orgDetails')::jsonb || ('{"logo": ' || coalesce(logo,json_build_object()) ||', "coverImage": ' || coalesce(coverImage,json_build_object()) ||'}')::jsonb )::json);
perform operator.update_org_contact(p_data::json);
perform operator.update_org_account(p_data::json);
perform operator.update_org_social_link(p_data::json);
return 
( json_build_object('data',json_build_object('orgSno',(p_data->>'orgSno')::bigint)));
end;
$$;


ALTER FUNCTION operator.update_org(p_data json) OWNER TO postgres;

--
-- Name: update_org_account(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_org_account(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
bankAccountDetailSno bigint;
v_doc json;
begin
 raise notice 'kgf%',p_data;

for v_doc in SELECT * FROM json_array_elements((p_data->>'accountList')::json) loop
raise notice 'v_doc  %',v_doc;
if (v_doc->>'bankAccountDetailSno') is not null then

update operator.bank_account_detail set 
    org_sno = (p_data->>'orgSno')::bigint,bank_account_name = (v_doc->>'bankAccountName')
			where bank_account_detail_sno = (v_doc->>'bankAccountDetailSno')::bigint;
else

perform operator.insert_org_account(json_build_object('accountList',(json_agg(v_doc)),'orgSno',(p_data->>'orgSno')::bigint));

end if;		  
end loop;

  return (select json_build_object('data',json_build_object('bankAccountDetailSno',bankAccountDetailSno)));
  
end;
$$;


ALTER FUNCTION operator.update_org_account(p_data json) OWNER TO postgres;

--
-- Name: update_org_attendance(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_org_attendance(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
createdOn timestamp;
mileages double precision;
begin
raise notice 'p_data %',p_data;
if p_data->>'acceptStatus' then 
update operator.vehicle_detail set odo_meter_value=(p_data->>'endValue')::bigint where vehicle_sno=(p_data->>'vehicleSno')::bigint ;
end if ;
update driver.driver_attendance set 
start_value = (p_data->>'startValue'),
end_value = (p_data->>'endValue'),
end_time = (p_data->>'endTime')::timestamp,
accept_status=(p_data->>'acceptStatus')::boolean,
attendance_status_cd=(p_data->>'attendanceStatusCd')::smallint
where driver_attendance_sno = (p_data->>'driverAttendanceSno')::bigint;
-- select created_on into createdOn from operator.bus_report where driver_attendance_sno=(p_data->>'driverAttendanceSno')::bigint;
-- select (sum(drived_km)/sum(fuel_consumed))::double precision into mileages from operator.bus_report where created_on = createdOn;
-- raise notice 'drived_km %',mileages;
-- raise notice 'fuelConsumed %',mileages;

-- update operator.bus_report set 
-- start_km = (p_data->>'startValue')::bigint,
-- end_km = (p_data->>'endValue')::bigint,
-- drived_km=((p_data->>'endValue')::bigint-(p_data->>'startValue')::bigint)::bigint
-- where driver_attendance_sno = (p_data->>'driverAttendanceSno')::bigint;
-- update operator.bus_report set mileage = mileages::double precision where created_on = createdOn;

return 
( json_build_object('data',json_build_object('driverAttendanceSno',(p_data->>'driverAttendanceSno')::bigint,'isUpdated',true)));
end;
$$;


ALTER FUNCTION operator.update_org_attendance(p_data json) OWNER TO postgres;

--
-- Name: update_org_contact(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_org_contact(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
v_doc json;
contactSno bigint;
_contact_list jsonb := '[]';
appUserSno bigint;
begin
raise notice 'update_org_contact %',p_data;

for v_doc in SELECT * FROM json_array_elements((p_data->>'contactList')::json) loop
  raise notice 'v_doc  %',v_doc;
  if (v_doc->>'contactSno') is not null then
  update portal.contact set 
  name = (v_doc->>'name'),
  contact_role_cd = (v_doc->>'contactRoleCd')::smallint,
  mobile_number = (v_doc->>'mobileNumber'),
  email = (v_doc->>'email'),
  is_show = (v_doc->>'isShow')::boolean 
  where contact_sno = (v_doc->>'contactSno')::bigint;
  select app_user_sno into appUserSno from portal.app_user where mobile_no=(v_doc->>'mobileNumber');
  update portal.app_user_role set role_cd=(v_doc->>'contactRoleCd')::smallint 
  where app_user_sno=appUserSno;
  else
 raise notice '****************esle  %',v_doc;
_contact_list = (_contact_list ||  v_doc::jsonb);
  end if;
end loop;

if(_contact_list <> '[]') then
perform operator.insert_org_contact(json_build_object('appUserSno',(p_data->>'appUserSno')::bigint,'orgSno',p_data->>'orgSno','contactList',_contact_list::json));
end if;

return 
( json_build_object('data',json_build_object('contactSno',(p_data->>'contactSno')::bigint)));
end;
$$;


ALTER FUNCTION operator.update_org_contact(p_data json) OWNER TO postgres;

--
-- Name: update_org_detail(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_org_detail(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
raise notice 'update_org_detail %',p_data;

update operator.org_detail set org_logo = (p_data->>'logo')::json,
org_banner = (p_data->>'coverImage')::json,
org_website = (p_data->>'website')
where org_detail_sno = (p_data->>'detailSno')::bigint;

return 
( json_build_object('data',json_build_object('detailSno',(p_data->>'detailSno')::bigint)));
end;
$$;


ALTER FUNCTION operator.update_org_detail(p_data json) OWNER TO postgres;

--
-- Name: update_org_fuel(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_org_fuel(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
createdOn timestamp;
mileages double precision;
begin
if p_data->>'acceptStatus' then
update operator.fuel set 
fuel_quantity = (p_data->>'fuelQuantity')::double precision,
price_per_ltr = (p_data->>'pricePerLtr')::double precision,
fuel_amount = (p_data->>'fuelAmount')::double precision,
odo_meter_value = (p_data->>'odoMetervalue')::bigint,
accept_status=(p_data->>'acceptStatus')::boolean
where fuel_sno = (p_data->>'fuelSno')::bigint;
else 
update operator.fuel set 
accept_status=(p_data->>'acceptStatus')::boolean,
is_filled=(p_data->>'isFilled')::boolean,
active_flag=false
where fuel_sno = (p_data->>'fuelSno')::bigint;
end if;
return 
( json_build_object('data',json_build_object('fuelSno',(p_data->>'fuelSno')::bigint)));
end;
$$;


ALTER FUNCTION operator.update_org_fuel(p_data json) OWNER TO postgres;

--
-- Name: update_org_sgl(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_org_sgl(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
v_data json =p_data->>'ownerDetails';
begin
update operator.org set org_name = (p_data->>'orgName'),
owner_name = (v_data->>'ownerName'),
vehicle_number = (v_data->>'vehicleNumber')
where org_sno = (p_data->>'orgSno')::bigint;

if (p_data->>'orgStatusCd')::smallint = 58 then
update operator.org set org_status_cd = 20
where org_sno = (p_data->>'orgSno')::bigint;

end if;

return 
( json_build_object('data',json_build_object('orgSno',(p_data->>'orgSno')::bigint)));
end;
$$;


ALTER FUNCTION operator.update_org_sgl(p_data json) OWNER TO postgres;

--
-- Name: update_org_social_link(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_org_social_link(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
v_doc json;
begin
raise notice 'update_org_social_link %',p_data;
for v_doc in SELECT * FROM json_array_elements((p_data->>'social')::json) loop
  raise notice 'v_doc  %',v_doc;
  update portal.social_link set social_url = (v_doc->>'urlLink'),
  social_link_type_cd = (v_doc->>'socialTypeCd')::int where social_link_sno = (v_doc->>'socialLinkSno')::bigint;
end loop;

return 
( json_build_object('data',json_build_object('contactSno',(p_data->>'contactSno')::bigint)));
end;
$$;


ALTER FUNCTION operator.update_org_social_link(p_data json) OWNER TO postgres;

--
-- Name: update_single_route(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_single_route(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
dates json;
v_data bigint;
singleRouteSno bigint;
begin

    for v_data in SELECT * FROM json_array_elements((p_data->>'delete')::json) loop
    raise notice 'v_data %',v_data;
        delete from operator.single_route where single_route_sno = v_data ;
    end loop;
    
    for dates in SELECT * FROM json_array_elements((p_data->>'dateList')::json) loop
    raise notice 'Single %',dates;
        update operator.single_route 
        set route_sno=(p_data->>'routeSno')::bigint,
        org_sno=(p_data->>'orgSno')::bigint,
        vehicle_sno=(p_data->>'vehicleSno')::bigint,
        starting_time=(dates->>'startTime')::timestamp,
        running_time=(dates->>'runTime')::bigint,
        active_flag=(p_data->>'activeFlag')::boolean
        where single_route_sno=(dates->>'singleRouteSno')::bigint
        returning single_route_sno into singleRouteSno;
    end loop;
return (select json_build_object('data',json_agg(json_build_object('singleRouteSno',singleRouteSno))));
end;
$$;


ALTER FUNCTION operator.update_single_route(p_data json) OWNER TO postgres;

--
-- Name: update_toll_paid_details(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_toll_paid_details(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
tollPassDetailSno bigint;
begin
raise notice '%',p_data;
update operator.toll_pass_detail set is_paid = (p_data->>'isPaid')::boolean
								where toll_pass_detail_sno = (p_data->>'tollPassDetailSno')::bigint 
								returning toll_pass_detail_sno into tollPassDetailSno;

  return (select json_build_object('tollPassDetailSno',tollPassDetailSno));

end;
$$;


ALTER FUNCTION operator.update_toll_paid_details(p_data json) OWNER TO postgres;

--
-- Name: update_toll_pass_detail(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_toll_pass_detail(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
tollPassDetailSno bigint;
begin
raise notice 'update_due %',p_data;

update operator.toll_pass_detail
set pass_start_date =(p_data->>'passStartDate')::date,
	pass_end_date = (p_data->>'passEndDate')::date,
	toll_amount = (p_data->>'tollAmount')::double precision,
	toll_name = (p_data->>'tollName'),
	toll_id = (p_data->>'tollId'),
	active_flag = (p_data->>'activeFlag')::boolean
where toll_pass_detail_sno = (p_data->>'tollPassDetailSno')::bigint
returning toll_pass_detail_sno into tollPassDetailSno;

return(select json_build_object('data',json_build_object('tollPassDetailSno',tollPassDetailSno)));
end;
$$;


ALTER FUNCTION operator.update_toll_pass_detail(p_data json) OWNER TO postgres;

--
-- Name: update_variable_pay(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_variable_pay(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
_vehicle_due_variable_pay_sno bigint;
begin
raise notice 'update_due %',p_data;

delete from operator.vehicle_due_variable_pay
 where vehicle_due_sno =(p_data->>'vehicleDueSno')::bigint;
 
 delete from operator.vehicle_due_fixed_pay
 where vehicle_due_sno =(p_data->>'vehicleDueSno')::bigint;
 
perform operator.insert_variable_pay(p_data);
raise notice  'padhu%',p_data->>'loanList';
 
 return(json_build_object('data',json_agg(json_build_object('isUpdate',true))));

end;
$$;


ALTER FUNCTION operator.update_variable_pay(p_data json) OWNER TO postgres;

--
-- Name: update_vehicle(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_vehicle(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
raise notice 'update_vehicle %',p_data;

if (p_data->>'kycStatus') = 'KYC Rejected' then
update operator.vehicle set kyc_status = 20
where vehicle_sno = (p_data->>'vehicleSno')::bigint;
end if;

update operator.vehicle 
set vehicle_reg_number = (p_data->>'vehicleRegNumber'),
vehicle_name = (p_data->>'vehicleName'),
vehicle_banner_name=(p_data->>'vehicleBanner'),
engine_number = (p_data->>'engineNumber'),
chase_number = (p_data->>'chaseNumber'), 
media_sno = (p_data->>'mediaSno')::bigint,
vehicle_type_cd = (p_data->>'vehicleTypeCd')::smallint,
tyre_type_cd = (p_data->>'tyreTypeCd')::smallint[],
tyre_size_cd = (p_data->>'tyreSizeCd')::smallint[],
tyre_count_cd = (p_data->>'tyreCountCd')::smallint
where vehicle_sno = (p_data->>'vehicleSno')::bigint;

return 
( json_build_object('data',json_build_object('vehicleSno',(p_data->>'vehicleSno')::bigint)));
end;
$$;


ALTER FUNCTION operator.update_vehicle(p_data json) OWNER TO postgres;

--
-- Name: update_vehicle_detail(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_vehicle_detail(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
contractCarriage jsonb := (p_data->>'contractCarriage')::jsonb;
vehicleDtl jsonb := (p_data->>'vehicleDetails')::jsonb;

begin
raise notice 'update_vehicle_detail %',p_data;
raise notice 'seat_type_cd %',contractCarriage;

update operator.vehicle_detail set 
vehicle_reg_date = (vehicleDtl->>'vehicleRegDate')::timestamp,
fc_expiry_date = (vehicleDtl->>'fcExpiryDate')::timestamp,
fc_expiry_amount = (vehicleDtl->>'fcExpiryAmount')::double precision,
insurance_expiry_date = (vehicleDtl->>'insuranceExpiryDate')::timestamp,
insurance_expiry_amount = (vehicleDtl->>'insuranceExpiryAmount')::double precision,
pollution_expiry_date = (vehicleDtl->>'pollutionExpiryDate')::timestamp,
tax_expiry_date = (vehicleDtl->>'taxExpiryDate')::timestamp,
tax_expiry_amount = (vehicleDtl->>'taxExpiryAmount')::double precision,
permit_expiry_date = (vehicleDtl->>'permitExpiryDate')::timestamp,
state_sno=(vehicleDtl->>'stateSno')::bigint,
district_sno=(vehicleDtl->>'districtsSno')::bigint,
driving_type_cd=(vehicleDtl->>'drivingType')::smallint,
wheelbase_type_cd=(vehicleDtl->>'wheelType')::smallint, 
vehicle_make_cd = (vehicleDtl->>'vehicleMakeCd')::smallint,
vehicle_model = (vehicleDtl->>'vehicleModelCd'),
vehicle_logo = (vehicleDtl->>'vehicleLogo')::json,
wheels_cd = (vehicleDtl->>'wheelsCd')::smallint,
stepny_cd = (vehicleDtl->>'stepnyCd')::smallint,
fuel_norms_cd = (vehicleDtl->>'fuelNormsCd')::smallint,
seat_capacity = (vehicleDtl->>'seatCapacity')::smallint,
seat_type_cd = (contractCarriage->>'seatType')::smallint,
audio_types_cd = (contractCarriage->>'audioType')::int[],
cool_type_cd = (contractCarriage->>'coolType')::smallint,
video_types_cd = (contractCarriage->>'videoType')::int[],
suspension_type = (contractCarriage->>'suspensionType')::smallint,
top_luckage_carrier = (contractCarriage->>'topCarrier')::boolean,
luckage_count = (contractCarriage->>'luckageCount')::smallint,
price_perday = (contractCarriage->>'pricePerday')::bigint,
odo_meter_value = (vehicleDtl->>'odoMeterValue')::bigint,
fuel_capacity = (vehicleDtl->>'fuelCapacity')::int,
fuel_type_cd = (vehicleDtl->>'fuelTypeCd')::smallint,
public_addressing_system_cd = (contractCarriage->>'publicAddressingSystem')::int[],
lighting_system_cd = (contractCarriage->>'lightingSystem')::int[],
image_sno = (contractCarriage->>'mediaSno')::bigint
where vehicle_sno = (p_data->>'vehicleSno')::bigint;

return 
( json_build_object('data',json_build_object('vehicleSno',(p_data->>'vehicleSno')::bigint)));
end;
$$;


ALTER FUNCTION operator.update_vehicle_detail(p_data json) OWNER TO postgres;

--
-- Name: update_vehicle_due_fixed_pay(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_vehicle_due_fixed_pay(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
_vehicle_due_sno bigint;
begin
raise notice 'update_due %',p_data;

update operator.vehicle_due_fixed_pay
set due_type_cd =(p_data->>'dueTypeCd')::smallint,
	due_close_date = (p_data->>'dueCloseDate')::date,
	remainder_type_cd = (p_data->>'remainderTypeCd')::int[],
	due_amount = (p_data->>'dueAmount')::double precision,
	active_flag = (p_data->>'activeFlag')::boolean,
	bank_name = (p_data->>'bankName'),
	bank_account_number = (p_data->>'bankAccountNumber'),
	bank_account_detail_sno = (p_data->>'bankAccountDetailSno')::bigint,
	discription = (p_data->>'discription')
where vehicle_due_sno = (p_data->>'vehicleDueSno')::bigint
returning vehicle_due_sno into _vehicle_due_sno;
	
	perform operator.update_org_account(p_data);


return(select json_build_object('data',json_build_object('vehicleDueSno',_vehicle_due_sno)));
end;
$$;


ALTER FUNCTION operator.update_vehicle_due_fixed_pay(p_data json) OWNER TO postgres;

--
-- Name: update_vehicle_info(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_vehicle_info(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
vehicleSno bigint;
begin

perform operator.update_vehicle(p_data);

perform operator.update_vehicle_detail((p_data::jsonb || jsonb_build_object('vehicleSno',p_data->>'vehicleSno'))::json);

perform operator.update_vehicle_owner((p_data::jsonb || jsonb_build_object('vehicleSno',p_data->>'vehicleSno',
																		  'removeUserList',(p_data->>'removeUserList')::json
																		  ))::json);
raise notice '%','update_route';
perform master_data.update_route(json_build_object('vehicleSno',p_data->>'vehicleSno','operatorSno',p_data->>'orgSno',
												  'deleteList',(p_data->>'deleteList')::json,'removeRouteList',(p_data->>'removeRouteList')::json,
												   'routeList',(p_data->>'routeList')::json));
												   

return (select json_build_object('data',json_build_object('vehicleSno',p_data->>'vehicleSno')));

end;
$$;


ALTER FUNCTION operator.update_vehicle_info(p_data json) OWNER TO postgres;

--
-- Name: update_vehicle_owner(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_vehicle_owner(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
v_doc json;
vehicleSno bigint := (p_data->>'vehicleSno')::bigint;
indexSno bigint;

begin
raise notice 'update_vehicle_owner %',p_data;
for v_doc in SELECT * FROM json_array_elements((p_data->>'ownerList')::json) loop
raise notice 'v_doc %',v_doc;
if (v_doc->>'vehicleOwnerSno') is not null then
raise notice 'if %',v_doc;
update operator.vehicle_owner set owner_name = (v_doc->>'ownerName'),
owner_number = (v_doc->>'ownerNumber'),
current_owner = (v_doc->>'currentOwner')::boolean,
purchase_date = (v_doc->>'purchaseDate')::timestamp,
app_user_sno = (v_doc->>'appUserSno')::bigint
where vehicle_sno = (p_data->>'vehicleSno')::bigint;
else
raise notice 'else %',v_doc;
perform operator.insert_vehicle_owner(json_build_object('ownerList',(json_agg(v_doc)),'vehicleSno',vehicleSno));
end if;
end loop;

for indexSno in  SELECT * FROM json_array_elements((p_data->>'removeUserList')::json) loop
	delete from operator.vehicle_owner where vehicle_owner_sno = indexSno;
end loop;

return 
( json_build_object('data',json_build_object('vehicleSno',(p_data->>'vehicleSno')::bigint)));
end;
$$;


ALTER FUNCTION operator.update_vehicle_owner(p_data json) OWNER TO postgres;

--
-- Name: update_vehicle_route(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_vehicle_route(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
v_data json;
vehicleRouteSno bigint;
begin
raise notice 'update_vehicle_route %',p_data;
delete from operator.vehicle_route where operator_route_sno=(p_data->>'operatorRouteSno')::bigint;
for v_data in SELECT * FROM json_array_elements((p_data->>'viaList')::json) loop
	insert into operator.vehicle_route(operator_route_sno,vehicle_sno) values((p_data->>'operatorRouteSno')::bigint,(p_data->>'vehicleSno')::bigint);
end loop;
  return (select json_agg(json_build_object('vehicleRouteSno',vehicleRouteSno)));
end;
$$;


ALTER FUNCTION operator.update_vehicle_route(p_data json) OWNER TO postgres;

--
-- Name: update_via(json); Type: FUNCTION; Schema: operator; Owner: postgres
--

CREATE FUNCTION operator.update_via(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
v_data json;
z_data bigint;
begin
raise notice 'update_via %',p_data;
for v_data in SELECT * FROM json_array_elements((p_data->>'viaList')::json) loop
raise notice 'update_viav_data %',v_data;

if v_data->>'viaSno' is not null then
	update operator.via set city_sno = (v_data->>'citySno')::bigint where via_sno = (v_data->>'viaSno')::bigint ;
else
	insert into operator.via(operator_route_sno,city_sno) values ((p_data->>'operatorRouteSno')::bigint,(v_data->>'citySno')::bigint);

end if;
end loop;

for z_data in SELECT * FROM json_array_elements((p_data->>'deleteList')::json) loop
	delete from operator.via where via_sno = z_data ;
end loop;

  return (select json_agg(json_build_object('operatorRouteSno','success')));
end;
$$;


ALTER FUNCTION operator.update_via(p_data json) OWNER TO postgres;

--
-- Name: change_mobile_number(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.change_mobile_number(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
_otp_count int := 0;
begin

  select count(*) into _otp_count from portal.otp where active_flag = true and app_user_sno = (p_data->>'appUserSno')::int and sim_otp = p_data->>'simOtp'
  and push_otp = p_data->>'pushOtp' and api_otp = p_data->>'apiOtp' and device_id = p_data->>'deviceId' 
  and to_char(expire_time::timestamp,'YYYY-MM-DD HH24:MI')::timestamp >=  to_char((select portal.get_time_with_zone(json_build_object('timeZone',p_data->>'timeZone'))::timestamp ),'YYYY-MM-DD HH24:MI')::timestamp ;
  raise notice '_otp_count%',p_data;
  if (_otp_count <> 0) then
  	update portal.app_user set mobile_no = (p_data->>'newMobileNumber')
			where app_user_sno = (p_data->>'appUserSno')::bigint;	
			
			return ( json_build_object('data',json_build_object('appUserSno',(p_data->>'appUserSno')::bigint)));
	else
			return (select json_build_object('msg','Invalid  OTP'));
			
end if;  
end;
$$;


ALTER FUNCTION portal.change_mobile_number(p_data json) OWNER TO postgres;

--
-- Name: check_mobile_number(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.check_mobile_number(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
_app_user_sno bigint := (p_data->>'appUserSno')::bigint;
is_old_number boolean := false;
_sim_otp text:= (SELECT LEFT(CAST(random()*1000000000+999999 AS INT)::text,6)::int as INT);
_api_otp text:= (SELECT LEFT(CAST(random()*1000000000+999999 AS INT)::text,10)::int as INT);
_push_otp text:= (SELECT LEFT(CAST(random()*1000000000+999999 AS INT)::text,10)::int as INT);
time_cd_value text;

begin

select count(*) > 0 into is_old_number from portal.app_user au where mobile_no = (p_data->>'newMobileNumber');

if is_old_number is false then	
		 select cd.cd_value into time_cd_value from portal.codes_dtl cd where cd.filter_1 = 'true';
 
 		update portal.otp set active_flag = false where app_user_sno = _app_user_sno and device_id = p_data->>'deviceId';
	
		INSERT INTO portal.otp(
	 app_user_sno, api_otp, push_otp, sim_otp, device_id, expire_time)
	VALUES (_app_user_sno, _api_otp, _push_otp , _sim_otp,p_data->>'deviceId',(select portal.get_time_with_zone(json_build_object('timeZone',p_data->>'timeZone'))::timestamp + (time_cd_value::int * interval '1 minute'))); 

   return  (select json_build_object('data', json_agg(json_build_object(
	   									   'isNewUser',true,
	    								  'appUserSno',_app_user_sno,
										  'simOtp',_sim_otp,
										  'pushOtp',_push_otp,
										  'apiOtp',_api_otp
										 ))));
	else
		
					 return (select json_build_object('data',json_agg(json_build_object('msg','This Mobile Number is Already Exists'))));
	end if;

end;
$$;


ALTER FUNCTION portal.check_mobile_number(p_data json) OWNER TO postgres;

--
-- Name: check_role_mobile_number(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.check_role_mobile_number(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
is_old_number boolean := false;
begin

select count(*) > 0 into is_old_number from portal.app_user au where mobile_no = (p_data->>'mobileNumber');

if is_old_number is true then	
		
					 return (select json_build_object('data',json_agg(json_build_object('msg','This Mobile Number is Already Exists'))));
					 else
					 return null;
end if;
end;
$$;


ALTER FUNCTION portal.check_role_mobile_number(p_data json) OWNER TO postgres;

--
-- Name: create_app_menu_role(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.create_app_menu_role(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
appMenuRoleSno bigint;
begin
-- raise notice '%',p_data;

insert into portal.app_menu_role (app_menu_sno,
								  role_cd) values ((p_data->>'appMenuSno')::integer,
												   (p_data->>'roleCd')::integer
												 ) returning app_menu_role_sno into appMenuRoleSno;

  return (select json_build_object('appMenuRoleSno',appMenuRoleSno));

end;
$$;


ALTER FUNCTION portal.create_app_menu_role(p_data json) OWNER TO postgres;

--
-- Name: create_app_user(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.create_app_user(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
_app_user_sno bigint;
_api_otp text:= (SELECT LEFT(CAST(random()*1000000000+999999 AS INT)::text,10)::int as INT);
_push_otp text:= (SELECT LEFT(CAST(random()*1000000000+999999 AS INT)::text,10)::int as INT);
_sim_otp text:= (SELECT LEFT(CAST(random()*1000000000+999999 AS INT)::text,6)::int as INT);
time_cd_value text;
begin

INSERT INTO portal.app_user( mobile_no,user_status_cd,password,confirm_password) values
(p_data->>'mobileNumber',portal.get_enum_sno(json_build_object('cd_value',p_data->>'status','cd_type','user_status_cd')),p_data->>'password',p_data->>'confirmPassword') returning app_user_sno into _app_user_sno;

perform portal.create_app_user_role(json_build_object('appUserSno',_app_user_sno,'roleCd',
													  portal.get_enum_sno(json_build_object('cd_value',p_data->>'role','cd_type','role_cd'))));

select cd.cd_value into time_cd_value from portal.codes_dtl cd where cd.filter_1 = 'true';

	INSERT INTO portal.otp(
	 app_user_sno,api_otp,push_otp, sim_otp,device_id,expire_time)
	VALUES (_app_user_sno, _api_otp, _push_otp ,_sim_otp,p_data->>'deviceId',(select portal.get_time_with_zone(json_build_object('timeZone',p_data->>'timeZone'))::timestamp + (time_cd_value::int * interval '1 minute')));


return (select(json_build_object('appUserSno',_app_user_sno)));

end;
$$;


ALTER FUNCTION portal.create_app_user(p_data json) OWNER TO postgres;

--
-- Name: create_app_user_role(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.create_app_user_role(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
appUserRoleSno bigint;
begin

insert into portal.app_user_role(app_user_sno,
				role_cd) values 
((p_data->>'appUserSno')::bigint,
 (p_data->>'roleCd')::smallint) returning app_user_role_sno  INTO appUserRoleSno;
  return (select json_build_object('appUserRoleSno',appUserRoleSno));

end;
$$;


ALTER FUNCTION portal.create_app_user_role(p_data json) OWNER TO postgres;

--
-- Name: create_codes_dtl(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.create_codes_dtl(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
 codesDtlSno bigint;
 _codesDtlSno bigint;
 seqNo int;
 
begin
raise notice '%',p_data;
select (max(codes_dtl_sno)+1) into _codesDtlSno from portal.codes_dtl;
select (max(codes_dtl_sno)+1) into seqNo from portal.codes_dtl where codes_hdr_sno=(p_data->>'codesHdrSno')::bigint;

insert into portal.codes_dtl (codes_dtl_sno,codes_hdr_sno,cd_value,seqno,filter_1,filter_2,active_flag) values 
(_codesDtlSno,(p_data->>'codesHdrSno')::smallint,(p_data->>'cdValue')::text,seqNo,
(p_data->>'filter1')::text,(p_data->>'filter2')::text,(p_data->>'activeFlag')::boolean) 
	returning codes_dtl_sno into codesDtlSno;

  return (select json_build_object('data',(json_build_object('codesDtlSno',codesDtlSno))));

end;
$$;


ALTER FUNCTION portal.create_codes_dtl(p_data json) OWNER TO postgres;

--
-- Name: create_contact(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.create_contact(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
contactSno bigint;
_app_user_sno bigint;
begin
raise notice'%kfc',p_data;
if (p_data->>'contactRoleCd')::smallint <> 2 then
	INSERT INTO portal.app_user( mobile_no,user_status_cd) VALUES (p_data->>'mobileNumber',
	portal.get_enum_sno('{"cd_value":"InActive","cd_type":"user_status_cd"}')) 
		returning app_user_sno into _app_user_sno;
		INSERT INTO operator.org_user( operator_user_sno,role_user_sno) VALUES ((p_data->>'userSno')::bigint,
	_app_user_sno);
	perform portal.create_app_user_role(json_build_object('appUserSno',_app_user_sno,'roleCd',(p_data->>'contactRoleCd')::smallint));
end if;

insert into portal.contact(name,contact_role_cd,mobile_number,email,is_show,app_user_sno) 
   values ((p_data->>'name'),
		   (p_data->>'contactRoleCd')::smallint,
	   	   (p_data->>'mobileNumber'),
           (p_data->>'email'),
           (p_data->>'isShow')::boolean,
		  case when (p_data->>'contactRoleCd')::smallint<>2 then _app_user_sno else (p_data->>'userSno')::bigint end) returning contact_sno INTO contactSno;


  return (select json_build_object('data',json_build_object('contactSno',contactSno)));
  
end;
$$;


ALTER FUNCTION portal.create_contact(p_data json) OWNER TO postgres;

--
-- Name: create_menu(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.create_menu(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
 _app_menu_sno int; 
 _app_menu_role int;
 id int;
 role_cd  int[]:= (p_data->>'roleCd')::int[];

 begin
 
	   INSERT INTO portal.app_menu(title,
										 href,
										 icon,
										 has_sub_menu,
										 parent_menu_sno,
										 router_link
										 ) 
	   VALUES (p_data->>'title',
			   p_data->>'href',
			   p_data->>'icon',
		 	  (p_data->>'hasSubMenu')::boolean,
			   (p_data->>'parentMenuSno')::integer,
			   p_data->>'routerLink'
			   )  
	   returning app_menu_sno into _app_menu_sno;
		
		 perform portal.createMenuByRole(_app_menu_sno,role_cd);
		return (select json_agg(json_build_object('appMenuSno',_app_menu_sno)));
	
	end;
$$;


ALTER FUNCTION portal.create_menu(p_data json) OWNER TO postgres;

--
-- Name: create_social_link(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.create_social_link(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
socialLinkSno bigint;
begin
-- raise notice '%',p_data;

insert into portal.social_link(social_url,social_link_type_cd) 
   values ((p_data->>'urlLink'),
           (p_data->>'socialTypeCd')::int
          ) returning social_link_sno INTO socialLinkSno;

  return (select json_build_object('data',json_build_object('socialLinkSno',socialLinkSno)));
  
end;
$$;


ALTER FUNCTION portal.create_social_link(p_data json) OWNER TO postgres;

--
-- Name: createmenubyrole(integer, integer[]); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.createmenubyrole(p_app_menu integer, role_cd integer[]) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare 
 id int;
 begin
       delete from portal.app_menu_role where app_menu_sno = p_app_menu; 
		    foreach  id in  array role_cd loop
		       INSERT INTO portal.app_menu_role(app_menu_sno,role_cd) 
	           VALUES (p_app_menu,(id)::integer);
		    end loop;
 end;
$$;


ALTER FUNCTION portal.createmenubyrole(p_app_menu integer, role_cd integer[]) OWNER TO postgres;

--
-- Name: delete_menu_user_and_role(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.delete_menu_user_and_role(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
delete from portal.app_menu_role where app_menu_sno=(p_data->>'appMenuSno')::bigint and role_cd=(p_data->>'roleCd')::bigint;
delete from portal.app_menu_user where app_menu_sno=(p_data->>'appMenuSno')::bigint and app_user_sno=(p_data->>'appUserSno')::bigint;
return(json_build_object('data',json_agg(json_build_object('isdelete',true))));
end;
$$;


ALTER FUNCTION portal.delete_menu_user_and_role(p_data json) OWNER TO postgres;

--
-- Name: generate_otp(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.generate_otp(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$

declare 

_app_user_sno bigint := (p_data->>'appUserSno')::bigint;
-- _role_cd smallint := (select * from portal.get_enum_sno((json_build_object('cd_value',p_data->>'roleName','cd_type','role_cd'))));
_api_otp text:= (SELECT LEFT(CAST(random()*1000000000+999999 AS INT)::text,10)::int as INT);
_push_otp text:= (SELECT LEFT(CAST(random()*1000000000+999999 AS INT)::text,10)::int as INT);
_sim_otp text:= (SELECT LEFT(CAST(random()*1000000000+999999 AS INT)::text,6)::int as INT);
-- _sigin_config_sno int;
time_cd_value text;
otpRegCount int := 0;

begin

---- raise notice '_role_cd% ',_role_cd;
-- raise notice '_api_otp% ',_api_otp;
-- raise notice '_push_otp% ',_push_otp;
-- raise notice '_email_otp% ',_email_otp;


 -- raise notice 'app_user_sno% ' ,_app_user_sno;
 select cd.cd_value into time_cd_value from portal.codes_dtl cd where cd.filter_1 = 'true';
 
 	update portal.otp set active_flag = false where app_user_sno = _app_user_sno and device_id = p_data->>'deviceId';
	
	INSERT INTO portal.otp(
	 app_user_sno, api_otp, push_otp, sim_otp, device_id, expire_time)
	VALUES (_app_user_sno, _api_otp, _push_otp , _sim_otp,p_data->>'deviceId',(select portal.get_time_with_zone(json_build_object('timeZone',p_data->>'timeZone'))::timestamp + (time_cd_value::int * interval '1 minute')));

 return  (select json_build_object('appUserSno',_app_user_sno,
										  'simOtp',_sim_otp,
										  'pushOtp',_push_otp,
										  'apiOtp',_api_otp
										 ));

end;
$$;


ALTER FUNCTION portal.generate_otp(p_data json) OWNER TO postgres;

--
-- Name: get_address(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.get_address(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin

return (select json_agg(json_build_object(
	'address_line1',c.address_line1,
	'address_line2',c.address_line2,
	'city',c.city,
	'state',c.state,
	'pincode',c.pincode,
	'latitude',c.latitude,
	'latitude',c.longitude
)) from (select * from portal.address where address_sno = (p_data->>'addressSno')::bigint )c);
   
end;
$$;


ALTER FUNCTION portal.get_address(p_data json) OWNER TO postgres;

--
-- Name: get_all_app_user(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.get_all_app_user(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin	
return (select(json_build_object('data', (select json_agg(json_build_object('appUserSno',app_user_sno,
										  'mobileNo',mobile_no,
										  'Password',password,
										  'conformPassword',confirm_password,
										  'userStatusCd',user_status_cd
										  ))from portal.app_user))));
end;
$$;


ALTER FUNCTION portal.get_all_app_user(p_data json) OWNER TO postgres;

--
-- Name: get_app_user(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.get_app_user(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin

return (select(json_build_object('data',(select json_agg(json_build_object(
	'appUserSno',ap.app_user_sno,
    'mobileNo',ap.mobile_no,
    'Password',ap.password,
    'conformPassword',ap.confirm_password,
    'userStatusCd',ap.user_status_cd
)) from (select * from portal.app_user where app_user_sno = (p_data->>'appUserSno')::bigint )ap))));
   
end;
$$;


ALTER FUNCTION portal.get_app_user(p_data json) OWNER TO postgres;

--
-- Name: get_app_user_contact(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.get_app_user_contact(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
raise notice 'Muhtu%',p_data;
 return (select  json_build_object('data',json_agg(json_build_object(
   'appUserContactSno',ac.app_user_contact_sno,
   'appUserSno',ac.app_user_sno,
  'roleCd',ac.user_status_cd,
  'userName',ac.user_name,
  'mobileNumber',ac.mobile_no,
  'alternateMobileNumber',ac.alternative_mobile_no,
  'email',ac.email        
 )))from portal.app_user_contact ac 
   where ac.app_user_sno=(p_data->>'appUserSno')::bigint);

end;
$$;


ALTER FUNCTION portal.get_app_user_contact(p_data json) OWNER TO postgres;

--
-- Name: get_code_type(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.get_code_type(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
	declare 
	begin
 return (select(json_build_object('data', (select json_agg(json_build_object(
'codesHdrSno',ch.codes_hdr_sno,
'codeType',ch.code_type																				 
))  from portal.codes_hdr ch ))));
 
	end;
$$;


ALTER FUNCTION portal.get_code_type(p_data json) OWNER TO postgres;

--
-- Name: get_codes_dtl(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.get_codes_dtl(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
	declare 
	begin
return (select(json_build_object('data', (select json_agg(json_build_object(
			'codesDtlSno',cd.codes_dtl_sno,
			'codesHdrSno',cd.codes_hdr_sno,
			'cdValue',cd.cd_value,
			'seqno',cd.seqno,
			'filter1',cd.filter_1,
			'filter2',cd.filter_2	,
			'activeFlag',cd.active_flag	
))  from portal.codes_dtl cd ))));
 
end;
$$;


ALTER FUNCTION portal.get_codes_dtl(p_data json) OWNER TO postgres;

--
-- Name: get_contact(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.get_contact(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
raise notice '%',p_data;
return (select json_agg(json_build_object('contactSno',contact_sno,
										   'mobileNumber',mobile_number,
										   'email',email,
										   'activeFlag',active_flag
										  ))from portal.contact);
end;
$$;


ALTER FUNCTION portal.get_contact(p_data json) OWNER TO postgres;

--
-- Name: get_enum_name(integer, text); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.get_enum_name(p_cd_sno integer, p_cd_type text) RETURNS text
    LANGUAGE plpgsql
    AS $$
declare 
  cd_value text;
begin

   select d.cd_value into cd_value from portal.codes_dtl d 
   inner join portal.codes_hdr h on d.codes_hdr_sno = h.codes_hdr_sno 
   where d.codes_dtl_sno = p_cd_sno and UPPER(h.code_type) = UPPER(p_cd_type) ;
   
   return cd_value;
end;
$$;


ALTER FUNCTION portal.get_enum_name(p_cd_sno integer, p_cd_type text) OWNER TO postgres;

--
-- Name: get_enum_names(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.get_enum_names(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin

return (select(json_build_object('data', (select json_agg(json_build_object('codesDtlSno',d.codes_dtl_sno,'cdValue',d.cd_value,'filter1',d.filter_1,'filter2',d.filter_2,'activeFlag',d.active_flag))
										  from (select * from portal.codes_dtl cdl where  
cdl.codes_hdr_sno = (select hdr.codes_hdr_sno from portal.codes_hdr hdr where hdr.code_type = p_data->>'codeType') and 
	case when p_data->>'filter1' is not null then ('{' || cdl.filter_1 ||'}')::text[] &&   (p_data->>'filter1')::text[]  else true end  order by cdl.seqno asc)d
))));
end;
$$;


ALTER FUNCTION portal.get_enum_names(p_data json) OWNER TO postgres;

--
-- Name: get_enum_sno(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.get_enum_sno(p_data json) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare 
  cd_sno smallint;
begin
   select d.codes_dtl_sno into cd_sno from portal.codes_dtl d 
   inner join portal.codes_hdr h on d.codes_hdr_sno = h.codes_hdr_sno 
   where UPPER(d.cd_value)=UPPER(p_data->>'cd_value') and UPPER(h.code_type) = UPPER(p_data->>'cd_type') ;
   
   return cd_sno;
end;
$$;


ALTER FUNCTION portal.get_enum_sno(p_data json) OWNER TO postgres;

--
-- Name: get_menu(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.get_menu(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
	declare 
	begin
	return (select json_agg(json_build_object(
		'title',am.title,
		'href',am.href,
		'icon',am.icon,
		'appMenuSno',am.app_menu_sno,
		'hasSubMenu',am.has_sub_menu,
		'parentMenuSno',am.parent_menu_sno,
		'routerLink',am.router_link
									)) from portal.app_menu am );
	end;
	$$;


ALTER FUNCTION portal.get_menu(p_data json) OWNER TO postgres;

--
-- Name: get_menu_role(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.get_menu_role(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
appMenuSno smallint;
menuList json;
begin
raise notice '%',p_data;

	select json_agg(json_build_object(
	'title',f.title,
	'href',f.href,
	'icon',f.icon,
	'appMenuSno',f.app_menu_sno,
 	'hasSubMenu',f.has_sub_menu,
    'parentMenuSno',f.parent_menu_sno,
    'routerLink',f.router_link,
	'isAdmin',coalesce(f.is_admin,false)
								 )) into menuList from 
	
	(
		select e.title,e.href,e.icon,e.app_menu_sno,e.has_sub_menu,e.parent_menu_sno,e.router_link,e.is_admin from (
			select am.title,am.href,am.icon,am.app_menu_sno,am.has_sub_menu,am.parent_menu_sno,am.router_link,
			(select is_admin from portal.app_menu_user where app_user_sno = (p_data->>'appUserSno')::bigint and app_menu_sno = am.app_menu_sno)
			from portal.app_menu_role amr 
		inner join portal.app_menu am on am.app_menu_sno = amr.app_menu_sno
			left join portal.app_menu_user amu on amu.app_menu_sno = amr.app_menu_sno
		where amr.role_cd = (p_data->>'roleCd')::int and 
			case when (((p_data->>'roleCd')::int<>2) and ((p_data->>'roleCd')::int<>5)) then 
			(amu.app_user_sno is null or amu.app_user_sno = (p_data->>'appUserSno')::bigint) else true end

		union
		
		select am.title,am.href,am.icon,am.app_menu_sno,am.has_sub_menu,am.parent_menu_sno,am.router_link,
			(select is_admin from portal.app_menu_user where app_user_sno = (p_data->>'appUserSno')::bigint and app_menu_sno = am.app_menu_sno)
			from portal.app_menu_role amr 
		inner join portal.app_menu am on am.app_menu_sno = amr.app_menu_sno
			left join portal.app_menu_user amu on amu.app_menu_sno = amr.app_menu_sno

		where
			  
			case when (((p_data->>'roleCd')::int<>2) and ((p_data->>'roleCd')::int<>5)) then 
			(amu.app_user_sno is null or amu.app_user_sno = (p_data->>'appUserSno')::bigint) else true end and
		am.app_menu_sno in (select app_menu_sno from portal.app_menu_user where app_user_sno = (p_data->>'appUserSno')::bigint)) e ORDER BY e.app_menu_sno
	)f;
	if (p_data->>'name')='menu' then
return (json_build_object('data',menuList));
else 
return menuList;
end if;
end;
$$;


ALTER FUNCTION portal.get_menu_role(p_data json) OWNER TO postgres;

--
-- Name: get_mobile_verification(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.get_mobile_verification(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
existUser boolean := false;
return_msg json;
_api_otp text;
_push_otp text;
_sim_otp text;
time_cd_value text;
_app_user_sno bigint := (p_data->>'appUserSno')::bigint;
counts smallint;
begin

select count(*) > 0 into existUser from portal.app_user au where au.user_status_cd <> 9 and trim(au.mobile_no) = trim(p_data->>'mobileNumber');

if existUser then
	select json_build_object('data',(
		select json_build_object('msg','This mobile number is already exists'))) into return_msg;
	return return_msg;
else
	_api_otp := (SELECT LEFT(CAST(random()*1000000000+999999 AS INT)::text,10)::int as INT);
	_push_otp := (SELECT LEFT(CAST(random()*1000000000+999999 AS INT)::text,10)::int as INT);
	_sim_otp := (SELECT LEFT(CAST(random()*1000000000+999999 AS INT)::text,6)::int as INT);
	
	select cd.cd_value into time_cd_value from portal.codes_dtl cd where cd.filter_1 = 'true';
	select count(*) into counts from portal.otp where app_user_sno = _app_user_sno and active_flag = true and device_id =p_data->>'deviceId'; 
	if counts = 0 then
		insert into portal.otp(
		 app_user_sno, api_otp, push_otp, sim_otp, device_id, expire_time)
		VALUES (_app_user_sno, _api_otp, _push_otp , _sim_otp,p_data->>'deviceId',(select portal.get_time_with_zone(json_build_object('timeZone',p_data->>'timeZone'))::timestamp + (time_cd_value::int * interval '1 minute')));
	else
		update portal.otp set api_otp = _api_otp,push_otp = _push_otp,sim_otp=_sim_otp ,device_id =p_data->>'deviceId',
			expire_time =(select portal.get_time_with_zone(json_build_object('timeZone',p_data->>'timeZone'))::timestamp + (time_cd_value::int * interval '1 minute')) where app_user_sno = _app_user_sno;
    end if;
	
	select json_build_object('data',(select json_build_object(
		'simOtp',_sim_otp,
		'pushOtp',_push_otp,
		'apiOtp',_api_otp
	))) into return_msg;
	return return_msg;
end if;

end;
$$;


ALTER FUNCTION portal.get_mobile_verification(p_data json) OWNER TO postgres;

--
-- Name: get_social_link(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.get_social_link(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
raise notice '%',p_data;
return ( select json_agg(json_build_object('socialLinkSno',social_link_sno,
	                                       'socialUrl',social_url,
										   'socialLinkTypeCd',social_link_type_cd,
										   'activeFlag',active_flag
										  ))from portal.social_link);
end;
$$;


ALTER FUNCTION portal.get_social_link(p_data json) OWNER TO postgres;

--
-- Name: get_time_with_zone(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.get_time_with_zone(p_data json) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
return (select (select now() AT TIME ZONE (p_data->>'timeZone')::text)::text);
END;
$$;


ALTER FUNCTION portal.get_time_with_zone(p_data json) OWNER TO postgres;

--
-- Name: get_user_contact(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.get_user_contact(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
return ( select json_build_object('email',email,'phone',phone,'address',address) from portal.user_contact where app_user_sno = (p_data->>'appUserSno')::bigint);
end;
$$;


ALTER FUNCTION portal.get_user_contact(p_data json) OWNER TO postgres;

--
-- Name: get_user_push_tokens(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.get_user_push_tokens(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$

declare 

_push_tokens json;

begin

select json_agg(push_token_id) into _push_tokens from portal.signin_config where active_flag = true 
and app_user_sno = (p_data->>'app_user_sno')::int;

return (select(json_build_object('pushTokens',_push_tokens)));

end;
$$;


ALTER FUNCTION portal.get_user_push_tokens(p_data json) OWNER TO postgres;

--
-- Name: get_verify_email(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.get_verify_email(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare _app_user_sno int;
declare otp jsonb;
begin
   select app_user_sno into _app_user_sno from portal.app_user where lower(email) =  lower(p_data->>'email');

 if(_app_user_sno is not null) then
p_data = (select p_data::jsonb || concat('{"appUserSno":',_app_user_sno,'}')::jsonb) ;
-- raise notice 'data %', p_data;
select * from portal.generate_otp(p_data) into otp;
-- raise notice 'otp_json %', otp;
return (select json_build_object('isVerifyEmail',true,'appUserSno',_app_user_sno,
  'emailOtp',otp->>'emailOtp',
  'pushOtp',otp->>'pushOtp',
  'apiOtp',otp->>'apiOtp'
));
else
return (select json_build_object('isVerifyEmail',false,'msg','This email is not registered'
));
 end if;
 
end;
 $$;


ALTER FUNCTION portal.get_verify_email(p_data json) OWNER TO postgres;

--
-- Name: get_verify_mobile_number(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.get_verify_mobile_number(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
-- existUser smallint;
-- _sim_otp text:= (SELECT LEFT(CAST(random()*1000000000+999999 AS INT)::text,6)::int as INT);
_app_user_sno bigint;
_count int;
begin
select au.app_user_sno into _app_user_sno from portal.app_user au 
inner join portal.app_user_role ar on ar.app_user_sno=au.app_user_sno
where mobile_no=p_data->>'mobileNumber';
raise notice'%',_app_user_sno;
if _app_user_sno is not null then
	if (p_data->>'roleCd')::smallint=6 then
		if (select count(*) from portal.app_user_role where app_user_sno=_app_user_sno and role_cd=2)>0 then
		return (select json_build_object('data',(
		select json_agg(json_build_object('isMobileNumber',false,'msg','Operator can not be act as a driver','data',true)))
		));
		else
		 return ( select json_build_object('data',(select json_agg(json_build_object(
			'appUserSno',app_user_sno,
			'isMobileNumber',true,
				'password',password,
		'otp',case when (p_data->>'pageName' is not null) then (select * from portal.generate_otp(json_build_object('appUserSno',_app_user_sno,'deviceId',(p_data->>'deviceId'),'timeZone',(p_data->>'timeZone')))) else null end
		))from portal.app_user where mobile_no=(p_data->>'mobileNumber'))
		));
		end if;
		
	else
		if (select count(*) from portal.app_user_role where app_user_sno=_app_user_sno and role_cd=6)>0 then
		return (select json_build_object('data',(
		select json_agg(json_build_object('isMobileNumber',false,'msg','Driver can not be act as a operator','data',true)))
		));
		else
		 return ( select json_build_object('data',(select json_agg(json_build_object(
			'appUserSno',app_user_sno,
			'isMobileNumber',true,
				'password',password,
		'otp',case when (p_data->>'pageName' is not null) then (select * from portal.generate_otp(json_build_object('appUserSno',_app_user_sno,'deviceId',(p_data->>'deviceId'),'timeZone',(p_data->>'timeZone')))) else null end
		))from portal.app_user where mobile_no=(p_data->>'mobileNumber'))
		));
		end if;
	end if;
else
return (select json_build_object('data',(
	select json_agg(json_build_object('isMobileNumber',false,'msg','New User')))
));
end if;
end;
$$;


ALTER FUNCTION portal.get_verify_mobile_number(p_data json) OWNER TO postgres;

--
-- Name: getverifyemail(text); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.getverifyemail(p_email text) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare _app_user_sno int;
begin
 	  select app_user_sno into _app_user_sno from portal.app_user where email =  p_email;
	  
	  return (select json_agg(json_build_object('appUserSno',_app_user_sno
										 )));
end;
 $$;


ALTER FUNCTION portal.getverifyemail(p_email text) OWNER TO postgres;

--
-- Name: getverifyemailandpassword(text, text); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.getverifyemailandpassword(p_email text, p_password text) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare _app_user_sno int;
begin
   select app_user_sno into _app_user_sno from portal.app_user  
  where email = p_email and password = p_password;
  
  return  (select json_agg(json_build_object('appUserSno',_app_user_sno
										 )));
end;
 $$;


ALTER FUNCTION portal.getverifyemailandpassword(p_email text, p_password text) OWNER TO postgres;

--
-- Name: insert_app_menu_user(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.insert_app_menu_user(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
appMenuUserSno bigint;
begin
insert into portal.app_menu_role(app_menu_sno,role_cd) values
((p_data->>'appMenuSno')::int,(p_data->>'roleCd')::int);
insert into portal.app_menu_user(app_menu_sno,app_user_sno,is_admin) values
((p_data->>'appMenuSno')::int,(p_data->>'appUserSno')::bigint,(p_data->>'isAdmin')::boolean)
returning app_menu_user_sno into appMenuUserSno;
  return (select json_build_object('data',json_build_object('appMenuUserSno',appMenuUserSno)));
end;
$$;


ALTER FUNCTION portal.insert_app_menu_user(p_data json) OWNER TO postgres;

--
-- Name: insert_app_user_contact(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.insert_app_user_contact(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
appUserContactSno bigint;
begin
-- raise notice ' %',p_data;

insert into portal.app_user_contact(app_user_sno,user_status_cd,user_name,mobile_no,alternative_mobile_no,email) 
   values ((p_data->>'appUserSno')::bigint,(p_data->>'roleCd')::smallint,(p_data->>'userName'),(p_data->>'mobileNumber'),
   (p_data->>'alternateMobileNumber'),(p_data->>'email')
          ) returning app_user_contact_sno  INTO appUserContactSno;

  return (select json_build_object('data',json_build_object('appUserContactSno',appUserContactSno)));
  
end;
$$;


ALTER FUNCTION portal.insert_app_user_contact(p_data json) OWNER TO postgres;

--
-- Name: insert_user_profile(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.insert_user_profile(in_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
i_app_user_sno bigint := (in_data->>'appUserSno')::bigint;
i_f_name text := (in_data->>'firstName');
i_l_name text := (in_data->>'lastName');
i_mobile_no text := (in_data->>'mobileNumber');
i_gender_cd smallint := (in_data->>'genderCd')::smallint;
i_image text := (in_data->>'image');
i_birthday timestamp := (in_data->>'birthday')::timestamp;
o_user_profile_sno bigint;
begin
 insert into portal.user_profile (app_user_sno,first_name,last_name,mobile,gender_cd,photo,dob) values (i_app_user_sno,i_f_name,i_l_name,i_mobile_no,i_gender_cd,i_image,i_birthday) returning user_profile_sno into o_user_profile_sno;  
 return (select(json_build_object('data',json_build_object('userProfileSno',o_user_profile_sno))));
end;
$$;


ALTER FUNCTION portal.insert_user_profile(in_data json) OWNER TO postgres;

--
-- Name: login(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.login(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
appUserSno bigint;
_sigin_config_sno bigint;
driverInfo json;
roleCd smallint;
roleCdValue text;
driverSno bigint;
orgSno bigint;
driverDtl json;
begin

	select app_user_sno into appUserSno from portal.app_user 
	where mobile_no=(p_data->>'mobileNumber') and password=(p_data->>'password');
if appUserSno is not null then
	select dtl.cd_value,aur.role_cd into roleCdValue,roleCd from portal.app_user_role aur
	inner join portal.codes_dtl dtl on  dtl.codes_dtl_sno = aur.role_cd where aur.app_user_sno = appUserSno order by aur.role_cd asc;
	if (p_data->>'roleCd')::smallint=6 then
		if (select count(*) from driver.driver_user where app_user_sno=appUserSno)> 0 then
				roleCdValue='Driver';
				roleCd=6;
		  select driver_sno into driverSno from driver.driver where driver_mobile_number =(p_data->>'mobileNumber');
			select org_sno into orgSno from operator.operator_driver od 
			left join driver.driver d on d.driver_sno = od.driver_sno where od.driver_sno=driverSno;
		  raise notice 'p_data %',driverSno;
			select driver.get_driver_info(json_build_object('driverSno',driverSno)) into driverInfo;
			select json_build_object(
			'driverName',d.driver_name,
			'drivedKm',sum(da.end_value::bigint) - sum(da.start_value::bigint) ) into driverDtl from driver.driver d
						left join driver.driver_attendance da on da.driver_sno=d.driver_sno and da.attendance_status_cd=29 where d.driver_sno=driverSno 
						group by d.driver_sno;
			else
			driverInfo=(select json_build_object('msg','driver profile not added'));
		end if;	
	elseif roleCd=127 or roleCd=128 then
		select oc.org_sno into orgSno from operator.org_contact oc
		inner join portal.contact c on c.contact_sno=oc.contact_sno where c.contact_role_cd=roleCd and c.mobile_number=(p_data->>'mobileNumber') ;
	else
		select org_sno into orgSno from operator.org_owner where app_user_sno = appUserSno;
	end if;
	

	if (select count(*) from portal.signin_config where device_id = p_data->>'deviceId' and app_user_sno = appUserSno) = 0 then
	
		    INSERT INTO portal.signin_config(app_user_sno, push_token_id, device_type_cd, device_id)
	   	 	VALUES (appUserSno, p_data->>'pushToken', portal.get_enum_sno((json_build_object('cd_value',p_data->>'deviceTypeName','cd_type','device_type_cd'))),		
			p_data->>'deviceId') returning signin_config_sno into _sigin_config_sno;
			
	else
	
	        update portal.signin_config set push_token_id = p_data->>'pushToken' where device_id = p_data->>'deviceId' and  app_user_sno = appUserSno  returning signin_config_sno into _sigin_config_sno;

	
	end if;
else
return  (select json_build_object('msg','Invalid Password'));
end if;

return  (select json_build_object(
									'appUserSno',appUserSno,
									'siginConfigSno', _sigin_config_sno,
									'menus',(select * from portal.get_menu_role(json_build_object('roleCd',roleCd)) ),
								    'roleCdValue',roleCdValue,
								    'roleCd',roleCd,
								  	'driverSno',driverSno,
								  	'orgSno',orgSno,
									'driverInfo',driverInfo,
									'driverDtl',driverDtl, 
									'msg','Login Success',
									'isVerifiedUser',true,
	 								'operatorName',( select owner_name from operator.org_owner ow
 														inner join operator.org o on o.org_sno = ow.org_sno
 												where ow.app_user_sno = appUserSno))
		 
		);
end;
$$;


ALTER FUNCTION portal.login(p_data json) OWNER TO postgres;

--
-- Name: logout(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.logout(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
signinConfigSno bigint;
begin
-- raise notice '%',p_data;

update portal.signin_config set active_flag = false
								where signin_config_sno = (p_data->>'signinConfigSno')::bigint 
								returning signin_config_sno into signinConfigSno;

  return (select json_build_object('signinConfigSno',signinConfigSno));

end;
$$;


ALTER FUNCTION portal.logout(p_data json) OWNER TO postgres;

--
-- Name: otp_verify(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.otp_verify(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$

declare 

_is_verified_user boolean := false;
_otp_count int := 0;
_invalid_otp int = 0;
_sigin_config_sno int;

begin

  select count(*) into _otp_count from portal.otp where active_flag = true and app_user_sno = (p_data->>'appUserSno')::int and sim_otp = p_data->>'simOtp'
  and push_otp = p_data->>'pushOtp' and api_otp = p_data->>'apiOtp' and device_id = p_data->>'deviceId' 
  and to_char(expire_time::timestamp,'YYYY-MM-DD HH24:MI')::timestamp >=  to_char((select portal.get_time_with_zone(json_build_object('timeZone',p_data->>'timeZone'))::timestamp ),'YYYY-MM-DD HH24:MI')::timestamp ; 
    
  if (_otp_count <> 0) then
      _is_verified_user := true;
  			update portal.app_user set user_status_cd = portal.get_enum_sno(json_build_object('cd_value','Active','cd_type','user_status_cd'))
			where app_user_sno = (p_data->>'appUserSno')::int;	
					
      	if (select count(*) from portal.signin_config where device_id = p_data->>'deviceId' and app_user_sno = (p_data->>'appUserSno')::int) = 0 then
	    	INSERT INTO portal.signin_config(app_user_sno, push_token_id, device_type_cd, device_id)
	   	 	VALUES ( (p_data->>'appUserSno')::int, p_data->>'pushToken', portal.get_enum_sno((json_build_object('cd_value',p_data->>'deviceTypeName','cd_type','device_type_cd'))),		
			p_data->>'deviceId') returning signin_config_sno into _sigin_config_sno;
    	 else
        	update portal.signin_config set push_token_id = p_data->>'pushToken' where device_id = p_data->>'deviceId' returning signin_config_sno into _sigin_config_sno;
     	end if;
			
	   return  (select json_build_object('isVerifiedUser',_is_verified_user, 'siginConfigSno', _sigin_config_sno));
else 
		select count(*) into _invalid_otp from portal.otp where active_flag = true and app_user_sno = (p_data->>'appUserSno')::int
  		and sim_otp = p_data->>'simOtp' and push_otp = p_data->>'pushOtp' and api_otp = p_data->>'apiOtp' and device_id = p_data->>'deviceId';
		
  		if(_invalid_otp = 0) then
			return  (select json_build_object('isVerifiedUser',false, 'msg', 'Invalid OTP.Please check OTP.'));
		else 
			return  (select json_build_object('isVerifiedUser',false, 'msg', 'Your OTP was expired.please click resend otp'));
		end if;
	 
end if;
end;
$$;


ALTER FUNCTION portal.otp_verify(p_data json) OWNER TO postgres;

--
-- Name: resend_otp(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.resend_otp(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
_email_otp text;
_otp_sno bigint;
_expire_time timestamp;
_email text;
_time_cd_value text;
begin

select otp_sno,email_otp into _otp_sno,_email_otp from portal.otp where device_id = (p_data->>'deviceId') 
and app_user_sno = (p_data->>'appUserSno')::bigint and EXTRACT(EPOCH FROM (portal.get_time_with_zone(json_build_object('timeZone','Asia/Calcutta'))::timestamp - expire_time)) < 0;

-- raise notice 'otp_sno%',_otp_sno;
-- raise notice 'email_otp%',_email_otp;

select email into _email from portal.app_user where app_user_sno = (p_data->>'appUserSno')::bigint;

if _otp_sno is null then

_email_otp := (SELECT LEFT(CAST(random()*1000000000+999999 AS INT)::text,6)::int as INT)::text;

select cd.cd_value into _time_cd_value from portal.codes_dtl cd where cd.filter_1 = 'true';

update portal.otp set email_otp = _email_otp,expire_time=(select portal.get_time_with_zone(json_build_object('timeZone','Asia/Calcutta'))::timestamp + (_time_cd_value::int * interval '1 minute')) where device_id = (p_data->>'deviceId') 
and app_user_sno = (p_data->>'appUserSno')::bigint;

end if;

return (select json_build_object('emailOtp',_email_otp,'email',_email));
										 
end;
$$;


ALTER FUNCTION portal.resend_otp(p_data json) OWNER TO postgres;

--
-- Name: reset_password(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.reset_password(p_reset_password json) RETURNS json
    LANGUAGE plpgsql
    AS $$
DECLARE
r_app_user_sno bigint;
v_pass_word text := p_reset_password->>'password';
v_app_user_sno integer := p_reset_password->>'appUserSno';

BEGIN

update portal.app_user set password = v_pass_word
where app_user_sno = v_app_user_sno returning app_user_sno into r_app_user_sno;

return  (select json_build_object('appUserSno',r_app_user_sno
										 ));
 END;
$$;


ALTER FUNCTION portal.reset_password(p_reset_password json) OWNER TO postgres;

--
-- Name: signin(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.signin(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
_app_user_sno bigint;
isMobilecount int := 0;
roleCd smallint;
roleCdValue text;
--_role_cd smallint := (select * from portal.get_enum_sno((json_build_object('cd_value',p_data->>'roleName','cd_type','role_cd'))));
_api_otp text:= (SELECT LEFT(CAST(random()*1000000000+999999 AS INT)::text,10)::int as INT);
_push_otp text:= (SELECT LEFT(CAST(random()*1000000000+999999 AS INT)::text,10)::int as INT);
_sim_otp text:= (SELECT LEFT(CAST(random()*1000000000+999999 AS INT)::text,6)::int as INT);
time_cd_value text;
counts bigint := 0;
isAlreadyExists bigint :=0;

begin

select au.app_user_sno into _app_user_sno  from portal.app_user au
where au.mobile_no = p_data->>'mobileNumber';

select count(*) into isAlreadyExists from portal.app_user_role aur 
inner join portal.app_user au on au.app_user_sno=aur.app_user_sno
where role_cd=(p_data->>'roleCd')::smallint and au.mobile_no=(p_data->>'mobileNumber');

if isAlreadyExists =0 and 6=(p_data->>'roleCd')::smallint then
if _app_user_sno is not null and (select count(*) from portal.app_user_role where app_user_sno=_app_user_sno and role_cd=(p_data->>'roleCd')::smallint)=0 then
	raise notice'muthu%',isAlreadyExists;
	
	perform portal.create_app_user_role(json_build_object('appUserSno',_app_user_sno,'roleCd',(p_data->>'roleCd')::smallint));
  else
INSERT INTO portal.app_user(mobile_no,user_status_cd)
	VALUES (p_data->>'mobileNumber',
	portal.get_enum_sno('{"cd_value":"InActive","cd_type":"user_status_cd"}')) returning app_user_sno into _app_user_sno;
	raise notice'muthu%',_app_user_sno;
	if (p_data->>'roleCd')::smallint <>6 then
	perform portal.create_app_user_role(json_build_object('appUserSno',_app_user_sno,'roleCd',portal.get_enum_sno(json_build_object('cd_value','User','cd_type','role_cd'))));
	else
	perform portal.create_app_user_role(json_build_object('appUserSno',_app_user_sno,'roleCd',portal.get_enum_sno(json_build_object('cd_value','Driver','cd_type','role_cd'))));
	end if;
	select cd.cd_value into time_cd_value from portal.codes_dtl cd where cd.filter_1 = 'true';
	INSERT INTO portal.otp(
	 app_user_sno, api_otp, push_otp, sim_otp, device_id, expire_time)
	VALUES (_app_user_sno, _api_otp, _push_otp , _sim_otp,p_data->>'deviceId',(select portal.get_time_with_zone(json_build_object('timeZone',p_data->>'timeZone'))::timestamp + (time_cd_value::int * interval '1 minute')));
end if;
end if;


 if (_app_user_sno is not null) then
 
	select dtl.cd_value,aur.role_cd into roleCdValue,roleCd from portal.app_user_role aur
	inner join portal.codes_dtl dtl on  dtl.codes_dtl_sno = aur.role_cd where aur.app_user_sno = _app_user_sno;
	select cd.cd_value into time_cd_value from portal.codes_dtl cd where cd.filter_1 = 'true';
		select count(*) into counts from portal.otp where app_user_sno = _app_user_sno and active_flag = true and device_id =p_data->>'deviceId'; 
	
	if counts = 0 then
		INSERT INTO portal.otp(app_user_sno, api_otp, push_otp, sim_otp, device_id, expire_time)
			VALUES (_app_user_sno, _api_otp, _push_otp , _sim_otp,p_data->>'deviceId',(select portal.get_time_with_zone(json_build_object('timeZone',p_data->>'timeZone'))::timestamp + (time_cd_value::int * interval '1 minute')));
		else
		update portal.otp set api_otp = _api_otp,push_otp = _push_otp,sim_otp=_sim_otp ,device_id =p_data->>'deviceId',
			expire_time =(select portal.get_time_with_zone(json_build_object('timeZone',p_data->>'timeZone'))::timestamp + (time_cd_value::int * interval '1 minute')) where app_user_sno = _app_user_sno;
     end if;
	
else
	raise notice'muthu%',p_data;

	INSERT INTO portal.app_user(mobile_no,user_status_cd)
	VALUES (p_data->>'mobileNumber',
	portal.get_enum_sno('{"cd_value":"InActive","cd_type":"user_status_cd"}')) returning app_user_sno into _app_user_sno;
	raise notice'muthu%',_app_user_sno;
	perform portal.create_app_user_role(json_build_object('appUserSno',_app_user_sno,'roleCd',portal.get_enum_sno(json_build_object('cd_value','User','cd_type','role_cd'))));
	select cd.cd_value into time_cd_value from portal.codes_dtl cd where cd.filter_1 = 'true';
	INSERT INTO portal.otp(
	 app_user_sno, api_otp, push_otp, sim_otp, device_id, expire_time)
	VALUES (_app_user_sno, _api_otp, _push_otp , _sim_otp,p_data->>'deviceId',(select portal.get_time_with_zone(json_build_object('timeZone',p_data->>'timeZone'))::timestamp + (time_cd_value::int * interval '1 minute')));


 end if;
 
 return (select json_build_object('isLogin',true,'appUserSno',_app_user_sno,
								   'roleCdValue',roleCdValue,
								   --'menus',(select * from portal.get_menu_role(json_build_object('roleCd',roleCd)) ),
								   'roleCd',roleCd,
								    'simOtp',_sim_otp,
									'pushOtp',_push_otp,
									'apiOtp',_api_otp
										 ));

end;
$$;


ALTER FUNCTION portal.signin(p_data json) OWNER TO postgres;

--
-- Name: tnbus_verify_mobilenumber_change_otp(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.tnbus_verify_mobilenumber_change_otp(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
_otp_count int := 0;
_invalid_otp int = 0;
_app_user_sno bigint := (p_data->>'appUserSno')::bigint;
msg json;
begin

select count(*) into _otp_count from portal.otp where active_flag = true and app_user_sno = _app_user_sno and sim_otp = p_data->>'simOtp' 
and push_otp = p_data->>'pushOtp' and api_otp = p_data->>'apiOtp' and device_id = p_data->>'deviceId' 
and to_char(expire_time::timestamp,'YYYY-MM-DD HH24:MI')::timestamp >=  to_char((select portal.get_time_with_zone(json_build_object('timeZone',p_data->>'timeZone'))::timestamp ),'YYYY-MM-DD HH24:MI')::timestamp ; 

  if _otp_count > 0 then
    
update portal.app_user set mobile_no = (p_data->>'mobileNumber') where app_user_sno = _app_user_sno;

  update driver.driver set driver_mobile_number = (p_data->>'mobileNumber') where driver_sno = 
(select du.driver_sno from driver.driver_user du where du.app_user_sno = _app_user_sno);

    update portal.app_user_contact set mobile_no = (p_data->>'mobileNumber') where app_user_contact_sno = 
(select ac.app_user_contact_sno from portal.app_user_contact ac where ac.app_user_sno = _app_user_sno);

  msg := (select json_build_object('isUpdated',true,'msg','Update Success'));
return msg;
  else
  select count(*) into _invalid_otp from portal.otp where active_flag = true and app_user_sno = _app_user_sno 
and sim_otp = p_data->>'simOtp' and push_otp = p_data->>'pushOtp' and api_otp = p_data->>'apiOtp' and device_id = p_data->>'deviceId';
  if _invalid_otp = 0 then
msg := (select json_build_object('isUpdated',false,'msg','Invalid OTP.Please check OTP.'));
return msg;
else 
msg := (select json_build_object('isUpdated',false,'msg','Your OTP was expired.please click resend otp'));
return msg;
end if;
  end if;
  
end;
$$;


ALTER FUNCTION portal.tnbus_verify_mobilenumber_change_otp(p_data json) OWNER TO postgres;

--
-- Name: update_app_menu_user(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.update_app_menu_user(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
appMenuUserSno bigint;
begin		
raise notice '%',p_data;

update  portal.app_menu_user set is_admin = (p_data->>'isAdmin')::boolean 
where app_menu_sno=(p_data->>'appMenuSno')::bigint and app_user_sno=(p_data->>'appUserSno')::bigint

returning app_menu_user_sno  INTO appMenuUserSno;

return (select json_build_object('appMenuUserSno',appMenuUserSno));

end;
$$;


ALTER FUNCTION portal.update_app_menu_user(p_data json) OWNER TO postgres;

--
-- Name: update_app_user(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.update_app_user(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
roleCdValue text;
roleCd int;
begin
update portal.app_user set 
password = (p_data->>'password'),
confirm_password = (p_data->>'confirmPassword')
where app_user_sno = (p_data->>'appUserSno')::bigint;
 select dtl.cd_value,aur.role_cd into roleCdValue,roleCd from portal.app_user_role aur
   inner join portal.codes_dtl dtl on  dtl.codes_dtl_sno = aur.role_cd where aur.app_user_sno = (p_data->>'appUserSno')::int;
 
return 
( json_build_object('data',json_build_object('appUserSno',(p_data->>'appUserSno')::bigint)));
end;
$$;


ALTER FUNCTION portal.update_app_user(p_data json) OWNER TO postgres;

--
-- Name: update_app_user_contact(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.update_app_user_contact(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
raise notice 'update_address %',p_data;

update portal.app_user_contact set app_user_sno = (p_data->>'appUserSno')::bigint,
user_status_cd = (p_data->>'roleCd')::smallint,user_name = (p_data->>'userName'),
mobile_no = (p_data->>'mobileNumber'),alternative_mobile_no = (p_data->>'alternateMobileNumber'),
email = (p_data->>'email') where app_user_contact_sno = (p_data->>'appUserContactSno')::bigint;

return 
( json_build_object('data',json_build_object('appUserContactSno',(p_data->>'appUserContactSno')::bigint)));
end;
$$;


ALTER FUNCTION portal.update_app_user_contact(p_data json) OWNER TO postgres;

--
-- Name: update_app_user_role(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.update_app_user_role(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
appUserRoleSno bigint;
begin		
raise notice '%',p_data;

update  portal.app_user_role set role_cd = (p_data->>'roleCd')::smallint where app_user_sno = (p_data->>'appUserSno')::bigint  returning app_user_role_sno  INTO appUserRoleSno;

return (select json_build_object('appUserRoleSno',appUserRoleSno));

end;
$$;


ALTER FUNCTION portal.update_app_user_role(p_data json) OWNER TO postgres;

--
-- Name: update_codes_dtl(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.update_codes_dtl(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
_codesDtlSno smallint;
--activeFlag boolean;
begin
raise notice '%',p_data;

update portal.codes_dtl set cd_value=(p_data->>'cdValue'),filter_1=(p_data->>'filter1'),filter_2=(p_data->>'filter2'),
active_flag = (p_data->>'activeFlag')::boolean where codes_dtl_sno=(p_data->>'codesDtlSno')::smallint 
returning codes_dtl_sno into _codesDtlSno;

return (select json_build_object('data',json_build_object('codesDtlSno',_codesDtlSno)));
end;
$$;


ALTER FUNCTION portal.update_codes_dtl(p_data json) OWNER TO postgres;

--
-- Name: verify_otp(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.verify_otp(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
_is_verified_user boolean := false;
_otp_count int := 0;
_invalid_otp int = 0;
_sigin_config_sno int;
roleCd smallint;
roleCdValue text;
driverSno bigint;
orgSno bigint;
driverInfo json;
token_list json;
massage text := 'welcome to Bus Today';
begin
  raise notice 'count %',_otp_count;
  select count(*) into _otp_count from portal.otp where active_flag = true and app_user_sno = (p_data->>'appUserSno')::int and sim_otp = p_data->>'simOtp'
  and push_otp = p_data->>'pushOtp' and api_otp = p_data->>'apiOtp' and device_id = p_data->>'deviceId' 
  and to_char(expire_time::timestamp,'YYYY-MM-DD HH24:MI')::timestamp >=  to_char((select portal.get_time_with_zone(json_build_object('timeZone',p_data->>'timeZone'))::timestamp ),'YYYY-MM-DD HH24:MI')::timestamp ; 
   select dtl.cd_value,aur.role_cd into roleCdValue,roleCd from portal.app_user_role aur
   inner join portal.codes_dtl dtl on  dtl.codes_dtl_sno = aur.role_cd where aur.app_user_sno = (p_data->>'appUserSno')::int;
   
   raise notice'roleCd%',roleCd;
if (p_data->>'roleCd')::smallint=6 then
  raise notice 'p_data %','in ********************driver';
  select driver_sno into driverSno from driver.driver where driver_mobile_number =(p_data->>'mobileNumber');
select org_sno into orgSno from operator.operator_driver od 
left join driver.driver d on d.driver_sno = od.driver_sno where od.driver_sno=driverSno;
select driver.get_driver_info(json_build_object('driverSno',driverSno)) into driverInfo;
else
if roleCd=127 or roleCd=128 then
  raise notice 'p_data %',p_data->>'mobileNumber';

select oc.org_sno into orgSno from operator.org_contact oc
inner join portal.contact c on c.contact_sno=oc.contact_sno where c.contact_role_cd=roleCd and c.app_user_sno= (p_data->>'appUserSno')::bigint ;
 else
select org_sno into orgSno from operator.org_owner where app_user_sno=(p_data->>'appUserSno')::int;
  end if;
end if;
 
  raise notice 'if %',_otp_count != 0;
  if (_otp_count <> 0) then
  raise notice 'if %',_otp_count;
      _is_verified_user := true;
  update portal.app_user set user_status_cd = portal.get_enum_sno(json_build_object('cd_value','Active','cd_type','user_status_cd'))
where app_user_sno = (p_data->>'appUserSno')::int;
  
      if (select count(*) from portal.signin_config where device_id = p_data->>'deviceId' and app_user_sno = (p_data->>'appUserSno')::int) = 0 then
raise notice 'count %','if';
    INSERT INTO portal.signin_config(app_user_sno, push_token_id, device_type_cd, device_id)
    VALUES ( (p_data->>'appUserSno')::int, p_data->>'pushToken', portal.get_enum_sno((json_build_object('cd_value',p_data->>'deviceTypeName','cd_type','device_type_cd'))),
p_data->>'deviceId') returning signin_config_sno into _sigin_config_sno;

if (p_data->>'roleCd')::smallint=6 then
massage := 'Welcome to Driver Today';
end if;

perform notification.insert_notification(json_build_object(
'title','Welcome ','message',massage,'actionId',null,'routerLink','bus-dashboard','fromId',p_data->>'appUserSno',
'toId',p_data->>'appUserSno',
'createdOn',p_data->>'createdOn'
)); 
select (select notification.get_token(json_build_object('appUserList',json_agg((p_data->>'appUserSno')::bigint)))->>'tokenList')::json into token_list;

     else
 raise notice 'count %','else';
        update portal.signin_config set push_token_id = p_data->>'pushToken' where device_id = p_data->>'deviceId' and  app_user_sno = (p_data->>'appUserSno')::int  returning signin_config_sno into _sigin_config_sno;
     end if;

 raise notice 'count %',_sigin_config_sno;
raise notice 'example %','true';
   return  (select json_build_object('isVerifiedUser',_is_verified_user, 
 'appUserSno',(p_data->>'appUserSno')::int,
 'siginConfigSno', _sigin_config_sno,
 'menus',(select * from portal.get_menu_role(json_build_object('roleCd',roleCd)) ),
         'roleCdValue',roleCdValue,
         'roleCd',roleCd,
  'driverSno',driverSno,
  'orgSno',orgSno,
'driverInfo',driverInfo,
'notification',case when (roleCd = 6) then (select json_build_object('notification',json_build_object('title','Welcome','body','welcome to Driver Today','data',''))) else (select json_build_object('notification',json_build_object('title','Welcome','body','welcome to Bus Today','data',''))) end,
'registration_ids',token_list));
else 
RAISE NOTICE '%Vijitha','muhtuh';
select count(*) into _invalid_otp from portal.otp where active_flag = true and app_user_sno = (p_data->>'appUserSno')::int
  and sim_otp = p_data->>'simOtp' and push_otp = p_data->>'pushOtp' and api_otp = p_data->>'apiOtp' and device_id = p_data->>'deviceId';

  if(_invalid_otp = 0) then
-- raise exception 'invalid otp';
return  (select json_build_object('isVerifiedUser',false, 'msg', 'Invalid OTP.Please check OTP.'));
else 
-- raise exception 'otp expired';
return  (select json_build_object('isVerifiedUser',false, 'msg', 'Your OTP was expired.please click resend otp'));
end if;
end if;
end;
$$;


ALTER FUNCTION portal.verify_otp(p_data json) OWNER TO postgres;

--
-- Name: verify_user(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.verify_user(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$

declare 

_app_user_sno bigint;
_inActiveUserSno bigint;
_api_otp text:= (SELECT LEFT(CAST(random()*1000000000+999999 AS INT)::text,10)::int as INT);
_push_otp text:= (SELECT LEFT(CAST(random()*1000000000+999999 AS INT)::text,10)::int as INT);
_sim_otp text:= (SELECT LEFT(CAST(random()*1000000000+999999 AS INT)::text,6)::int as INT);
_sigin_config_sno int;
time_cd_value text;
created_on TIMESTAMP;

begin

select au.app_user_sno into _app_user_sno  from portal.app_user au
where lower(au.mobile_number) = lower(p_data->>'mobileNumber');

 
 if (_app_user_sno is null) then
 	INSERT INTO portal.app_user( mobile_number,user_status_cd)
	VALUES (p_data->>'mobileNumber',
	portal.get_enum_sno('{"cd_value":"InActive","cd_type":"user_status_cd"}')) returning app_user_sno into _app_user_sno;
	
	perform portal.create_app_user_role(json_build_object('appUserSno',_app_user_sno,'roleCd',portal.get_enum_sno(json_build_object('cd_value','User','cd_type','role_cd'))));
	
	select cd.cd_value into time_cd_value from portal.codes_dtl cd where cd.filter_1 = 'true';
	
	INSERT INTO portal.otp(
	 app_user_sno, api_otp, push_otp, sim_otp, device_id, expire_time)
	VALUES (_app_user_sno, _api_otp, _push_otp , _sim_otp,p_data->>'deviceId',(select portal.get_time_with_zone(json_build_object('timeZone',p_data->>'timeZone'))::timestamp + (time_cd_value::int * interval '1 minute'))); 

   return  (select (json_build_object(
	   									   'isNewUser',true,
	    								  'appUserSno',_app_user_sno,
										  'simOtp',_sim_otp,
										  'pushOtp',_push_otp,
										  'apiOtp',_api_otp
										 )));
 else
 
 	update portal.otp set active_flag = false where app_user_sno = _app_user_sno;
	
	select cd.cd_value into time_cd_value from portal.codes_dtl cd where cd.filter_1 = 'true';
	
	INSERT INTO portal.otp(
	 app_user_sno, api_otp, push_otp, sim_otp, device_id, expire_time)
	VALUES (_app_user_sno, _api_otp, _push_otp , _sim_otp,p_data->>'deviceId',(select portal.get_time_with_zone(json_build_object('timeZone',p_data->>'timeZone'))::timestamp + (time_cd_value::int * interval '1 minute'))); 

	return (select json_build_object('isNewUser',false,
										  'appUserSno',_app_user_sno,
										  'simOtp',_sim_otp,
										  'pushOtp',_push_otp,
										  'apiOtp',_api_otp
										 ));
	
 end if;

end;
$$;


ALTER FUNCTION portal.verify_user(p_data json) OWNER TO postgres;

--
-- Name: verify_user_otp(json); Type: FUNCTION; Schema: portal; Owner: postgres
--

CREATE FUNCTION portal.verify_user_otp(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$

declare 

_is_verified_user boolean := false;
_otp_count int := 0;
_invalid_otp int = 0;
_sigin_config_sno int;

begin

  select count(*) into _otp_count from portal.otp where active_flag = true and app_user_sno = (p_data->>'appUserSno')::int and email_otp = p_data->>'emailOtp'
  and push_otp = p_data->>'pushOtp' and api_otp = p_data->>'apiOtp' and device_id = p_data->>'deviceId' 
  and to_char(expire_time::timestamp,'YYYY-MM-DD HH24:MI')::timestamp >=  to_char((select portal.get_time_with_zone(json_build_object('timeZone',p_data->>'timeZone'))::timestamp ),'YYYY-MM-DD HH24:MI')::timestamp ; 
  
  -- raise notice 'count %',_otp_count;
   
  if (_otp_count <> 0) then
      _is_verified_user := true;
 	
	   return  (select json_build_object('isVerifiedUser',_is_verified_user));
else 
		select count(*) into _invalid_otp from portal.otp where active_flag = true and app_user_sno = (p_data->>'appUserSno')::int
  		and email_otp = p_data->>'emailOtp' and push_otp = p_data->>'pushOtp' and api_otp = p_data->>'apiOtp' and device_id = p_data->>'deviceId';
		-- raise notice 'otp_validation%',_invalid_otp;
  		if(_invalid_otp = 0) then
-- 			raise exception 'invalid otp';
			return  (select json_build_object('isVerifiedUser',false, 'msg', 'Invalid OTP.Please check OTP.'));
		else 
-- 		raise exception 'otp expired';
			return  (select json_build_object('isVerifiedUser',false, 'siginConfigSno', 'Your OTP was expired.please click resend otp'));
		end if;
	 
end if;
end;
$$;


ALTER FUNCTION portal.verify_user_otp(p_data json) OWNER TO postgres;

--
-- Name: create_booking(json); Type: FUNCTION; Schema: rent; Owner: postgres
--

CREATE FUNCTION rent.create_booking(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION rent.create_booking(p_data json) OWNER TO postgres;

--
-- Name: delete_booking(json); Type: FUNCTION; Schema: rent; Owner: postgres
--

CREATE FUNCTION rent.delete_booking(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION rent.delete_booking(p_data json) OWNER TO postgres;

--
-- Name: get_booking(json); Type: FUNCTION; Schema: rent; Owner: postgres
--

CREATE FUNCTION rent.get_booking(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION rent.get_booking(p_data json) OWNER TO postgres;

--
-- Name: get_contact_carrage(json); Type: FUNCTION; Schema: rent; Owner: postgres
--

CREATE FUNCTION rent.get_contact_carrage(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION rent.get_contact_carrage(p_data json) OWNER TO postgres;

--
-- Name: get_rent_bus(json); Type: FUNCTION; Schema: rent; Owner: postgres
--

CREATE FUNCTION rent.get_rent_bus(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION rent.get_rent_bus(p_data json) OWNER TO postgres;

--
-- Name: get_vehicle_count(json); Type: FUNCTION; Schema: rent; Owner: postgres
--

CREATE FUNCTION rent.get_vehicle_count(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare
_count bigint;
begin
 
 select count(*) into _count from operator.vehicle v 
inner join operator.vehicle_detail vd on vd.vehicle_sno=v.vehicle_sno
inner join master_data.district d on d.district_sno = vd.district_sno
where ((v.vehicle_type_cd=22 and vd.district_sno = (p_data->>'districtSno')::bigint) or v.vehicle_type_cd=22 and d.district_name = (p_data->>'districtName'));				   
return (select  json_build_object('data',json_agg(json_build_object('count',_count)))); 

end;
$$;


ALTER FUNCTION rent.get_vehicle_count(p_data json) OWNER TO postgres;

--
-- Name: insert_rent_bus(json); Type: FUNCTION; Schema: rent; Owner: postgres
--

CREATE FUNCTION rent.insert_rent_bus(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION rent.insert_rent_bus(p_data json) OWNER TO postgres;

--
-- Name: update_booking(json); Type: FUNCTION; Schema: rent; Owner: postgres
--

CREATE FUNCTION rent.update_booking(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION rent.update_booking(p_data json) OWNER TO postgres;

--
-- Name: delete_tyre(json); Type: FUNCTION; Schema: tyre; Owner: postgres
--

CREATE FUNCTION tyre.delete_tyre(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
tyreSno bigint;
mediaSno bigint;
begin
 delete from tyre.tyre where tyre_sno = (p_data->>'tyreSno')::bigint
  returning invoice_media into mediaSno;
 
 raise notice 'MEDIASNO=%',mediaSno;
 if mediaSno is not null then
 perform media.delete_media(json_build_object('mediaSno',mediaSno));
  end if;
 return(json_build_object('data',json_agg(json_build_object('isdelete',true))));
end;
$$;


ALTER FUNCTION tyre.delete_tyre(p_data json) OWNER TO postgres;

--
-- Name: get_tyre(json); Type: FUNCTION; Schema: tyre; Owner: postgres
--

CREATE FUNCTION tyre.get_tyre(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
tyre_list json;
begin

select  json_agg(json_build_object(
								  'tyreSno',t.tyre_sno,
								  'tyreSerialNumber',t.tyre_serial_number,
								  'tyreSizeSno',t.tyre_size_sno,
								  'tyrePrice',t.tyre_price,
								  'tyreTypeSno',t.tyre_type_sno,
								  'tyreModel',t.tyre_model,
								  'paymentModeCd',t.payment_mode_cd,
								  'vehicleNumber',(select v.vehicle_reg_number from tyre.tyre_activity ta 
inner join operator.vehicle v on v.vehicle_sno = ta.vehicle_sno 
where  ta.tyre_sno = t.tyre_sno and ta.is_running = true),
								  'tyreTypeName',(select tyre_type from master_data.tyre_type where tyre_type_sno=t.tyre_type_sno ),
								  'tyreSizeName',(select tyre_size from master_data.tyre_size where tyre_size_sno=t.tyre_size_sno ),
-- 								  'tyreModelName',t.tyre_model,
								  'paymentMethod',(select cd.cd_value from portal.codes_dtl cd where cd.codes_dtl_sno = t.payment_mode_cd),
								  'invoiceMedia',(select media.get_media_detail(json_build_object('mediaSno',invoice_media))->0),
								  'agencyName',t.agency_name,
								  'tyreCompanySno',t.tyre_company_sno,
								  'tyreCompanyName',(select tyre_company from master_data.tyre_company where tyre_company_sno=t.tyre_company_sno ),
								  'invoiceDate',t.invoice_date,
								  'incomingDate',t.incoming_date,
						          'efficiencyValue',t.efficiency_value,
								  'isNew',t.is_new::text,
								  'isTread',t.is_tread::text,
								  'kmDrive',t.km_drive,
	 							  'noOfTread',t.no_of_tread,
								  'isRunning',t.is_running,
								  'overAllRunningKm',(case when t.is_running::boolean then 
													  (select * from tyre.get_tyre_over_all_running_km(json_build_object('tyreSno',t.tyre_sno))) else null end),
								  'stock',t.stock,
								  'activeFlag',t.active_flag,
								  'runningKm',(select sum(tatk.running_km) from tyre.tyre_activity_total_km tatk where tatk.tyre_sno = t.tyre_sno),
								  'isBursted',t.is_bursted,
								  'tyreLifeCycle',json_build_object(
									  'retreadingCount',(select count(*) from tyre.tyre_activity where tyre_activity_type_cd = 99 and tyre_sno = t.tyre_sno and vehicle_sno is not  null),
									  'rotationCount',(select count(*) from tyre.tyre_activity where tyre_activity_type_cd = 100 and tyre_sno = t.tyre_sno and vehicle_sno is not  null),
									  'puncherCount',(select count(*) from tyre.tyre_activity where tyre_activity_type_cd = 101 and tyre_sno = t.tyre_sno and vehicle_sno is not  null),
									  'powderCount',(select count(*) from tyre.tyre_activity where tyre_activity_type_cd = 103 and tyre_sno = t.tyre_sno and vehicle_sno is not  null)
								  )
								 )) into tyre_list from (select t.tyre_sno,t.tyre_serial_number,t.tyre_size_sno,t.tyre_price,t.tyre_type_sno,t.tyre_model,t.payment_mode_cd,
t.invoice_media,t.agency_name,t.tyre_company_sno,t.invoice_date,t.incoming_date,t.efficiency_value,t.is_new,t.is_tread,t.km_drive,t.no_of_tread,t.is_running,t.stock,t.active_flag,t.is_bursted
from tyre.tyre t
	   where case when (p_data->>'orgSno')::bigint is not null  then org_sno=(p_data->>'orgSno')::bigint
	   else true end and 
	   case when (p_data->>'activeFlag') is not null then active_flag = (p_data->>'activeFlag')::boolean else true end and
	  case when (p_data->>'tyreCompanySno')::bigint is not null  then t.tyre_company_sno =(p_data->>'tyreCompanySno')::bigint
      else true end and
	  case when (p_data->>'status' = 'running') then is_running = true else true end and
	  case when (p_data->>'status' = 'stock') then is_running = false and is_bursted = false else true end and
	  case when (p_data->>'status' = 'bursted') then is_running = false and is_bursted = true else true end and
	   case when (p_data->>'searchKey' is not null) then
		((agency_name::text ilike ('%' || trim((p_data->>'searchKey')::text) || '%')) or (tyre_serial_number::text ilike ('%' || trim((p_data->>'searchKey')::text) || '%')))
		else true end order by t.tyre_sno desc offset (p_data->>'skip')::bigint limit (p_data->>'limit')::bigint )t;
		
return (select json_build_object('data',tyre_list));

end;
$$;


ALTER FUNCTION tyre.get_tyre(p_data json) OWNER TO postgres;

--
-- Name: get_tyre_count(json); Type: FUNCTION; Schema: tyre; Owner: postgres
--

CREATE FUNCTION tyre.get_tyre_count(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
counts bigint;
begin

select count(*) into counts from tyre.tyre t
	   where case when (p_data->>'orgSno')::bigint is not null  then org_sno=(p_data->>'orgSno')::bigint
	   else true end and 
	   case when (p_data->>'activeFlag') is not null then active_flag = (p_data->>'activeFlag')::boolean else true end and
	   case when (p_data->>'tyreCompanySno')::bigint is not null  then tyre_company_sno =(p_data->>'tyreCompanySno')::bigint
      else true end and
	  case when (p_data->>'status' = 'running') then is_running = true else true end and
	  case when (p_data->>'status' = 'stock') then is_running = false and is_bursted = false else true end and
	  case when (p_data->>'status' = 'bursted') then is_running = false and is_bursted = true else true end and
	   case when (p_data->>'searchKey' is not null) then
		((agency_name::text ilike ('%' || trim((p_data->>'searchKey')::text) || '%')) or (tyre_serial_number::text ilike ('%' || trim((p_data->>'searchKey')::text) || '%')))
		else true end;
		
return (select json_build_object('data',(select json_agg(json_build_object('counts',counts)))));

end;
$$;


ALTER FUNCTION tyre.get_tyre_count(p_data json) OWNER TO postgres;

--
-- Name: get_tyre_life_cycle(json); Type: FUNCTION; Schema: tyre; Owner: postgres
--

CREATE FUNCTION tyre.get_tyre_life_cycle(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
tyre_life_cycle_list json;
begin

with tyre_life_cycle as(
select v.vehicle_sno,v.vehicle_name,v.vehicle_reg_number,ta.activity_date as activity_start_date,tatk.activity_end_date,tatk.running_km,ta.wheel_position,
	dtl.cd_value as status,ta.is_running,tatk.running_life from tyre.tyre_activity ta
left join tyre.tyre_activity_total_km tatk on tatk.tyre_activity_sno = ta.tyre_activity_sno
inner join operator.vehicle v on v.vehicle_sno = ta.vehicle_sno
inner join portal.codes_dtl dtl on dtl.codes_dtl_sno = ta.tyre_activity_type_cd
where 
-- 	ta.vehicle_sno = (p_data->>'vehicleSno')::bigint and 
-- 	trim(lower(ta.wheel_position)) = trim(lower(p_data->>'wheelPosition')) 
	ta.tyre_sno = (p_data->>'tyreSno')::bigint
order by ta.tyre_activity_sno)
select json_agg(json_build_object('vehicleName',tlc.vehicle_name,
								  'vehicleRegNumber',tlc.vehicle_reg_number,
								  'activityStartDate',tlc.activity_start_date,
								  'activityEndDate',tlc.activity_end_date,
								  'runningKm',tlc.running_km,
								  'wheelPosition',tlc.wheel_position,
								  'status',tlc.status,
								  'isRunning',tlc.is_running,
								  'currentOdo',case when tlc.is_running=true then (select odo_meter_value from operator.vehicle_detail where vehicle_sno=tlc.vehicle_sno) else 0 end,
								  'runningLife',tlc.running_life
								 )) into tyre_life_cycle_list from tyre_life_cycle tlc;
								 
return (select json_build_object('data',tyre_life_cycle_list));
end;
$$;


ALTER FUNCTION tyre.get_tyre_life_cycle(p_data json) OWNER TO postgres;

--
-- Name: get_tyre_over_all_running_km(json); Type: FUNCTION; Schema: tyre; Owner: postgres
--

CREATE FUNCTION tyre.get_tyre_over_all_running_km(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
overAllRunningKm bigint;
begin
raise notice'%','mthu';
select ((vd.odo_meter_value::bigint-ta.odo_meter::bigint)::bigint+
		(case when t.km_drive is not null then t.km_drive::bigint else 0 end)+
		(case when tatk.running_km is not null then tatk.running_km::bigint else 0 end)) into overAllRunningKm from tyre.tyre_activity ta
inner join operator.vehicle_detail vd on vd.vehicle_sno=ta.vehicle_sno
inner join tyre.tyre t on t.tyre_sno=ta.tyre_sno
left join tyre.tyre_activity_total_km tatk on tatk.tyre_sno=ta.tyre_sno
where ta.tyre_sno=(p_data->>'tyreSno')::bigint and ta.is_running=true;
return overAllRunningKm;
end;
$$;


ALTER FUNCTION tyre.get_tyre_over_all_running_km(p_data json) OWNER TO postgres;

--
-- Name: get_tyre_position(json); Type: FUNCTION; Schema: tyre; Owner: postgres
--

CREATE FUNCTION tyre.get_tyre_position(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
tyre_list json;
stepney_list json;
begin

raise notice '%',p_data;
with tyre as(
select ta.tyre_sno,t.is_new,t.tyre_serial_number,a::text::smallint as seq,t.tyre_type_sno,ta.odo_meter,ta.activity_date
	from generate_series(1,(p_data->>'tyreCount')::int)a
left join tyre.tyre_activity ta on ta.vehicle_sno = (p_data->>'vehicleSno')::bigint and ta.wheel_position = ('p' || a::text) and is_running = true
left join tyre.tyre t on t.tyre_sno = ta.tyre_sno
left join master_data.tyre_type tt on tt.tyre_type_sno = t.tyre_type_sno order by ta.wheel_position asc)
select json_agg(json_build_object('tyreSno',t.tyre_sno,
								'tyreSerialNumber',t.tyre_serial_number,
								  'tyreTypeCd',t.tyre_type_sno,
								  'isNew',t.is_new,
                                  'retreadingCount',(select count(*) from tyre.tyre_activity where tyre_activity_type_cd = 99 and tyre_sno = t.tyre_sno and vehicle_sno is not  null),
								  'className',(select operator.getClassName(t.seq,'M',(p_data->>'tyreCountCd')::smallint)),
								  'searchTyreList',(select operator.get_search_available_tyre(json_build_object('tyreSno',t.tyre_sno,'vehicleSno',(p_data->>'vehicleSno')::bigint))),
								  'odometer',t.odo_meter,
								  'currentOdoMeter',(select odo_meter_value from operator.vehicle_detail where vehicle_sno=(p_data->>'vehicleSno')::bigint),
								  'activityDate',t.activity_date,
								  'overAllRunningKm',(select * from tyre.get_tyre_over_all_running_km(json_build_object('tyreSno',t.tyre_sno)))
								 )) into tyre_list from tyre t;

with tyre as(
select ta.tyre_sno,t.is_new,t.tyre_serial_number,a::text::smallint as seq,t.tyre_type_sno,ta.odo_meter,ta.activity_date from generate_series(1,(p_data->>'stepnyCount')::int)a
left join tyre.tyre_activity ta on ta.vehicle_sno = (p_data->>'vehicleSno')::bigint and ta.wheel_position = ('s' || a::text) and is_running = true
left join tyre.tyre t on t.tyre_sno = ta.tyre_sno
left join master_data.tyre_type tt on tt.tyre_type_sno = t.tyre_type_sno order by ta.wheel_position asc)
select json_agg(json_build_object('tyreSno',t.tyre_sno,
								 'tyreSerialNumber',t.tyre_serial_number,
								  'tyreTypeCd',t.tyre_type_sno,
								  'isNew',t.is_new,
                                  'retreadingCount',(select count(*) from tyre.tyre_activity where tyre_activity_type_cd = 99 and tyre_sno = t.tyre_sno and vehicle_sno is not  null),
								  'className',(select operator.getClassName(t.seq,'S',(p_data->>'tyreCountCd')::smallint)),
								  'searchTyreList',(select operator.get_search_available_tyre(json_build_object('tyreSno',t.tyre_sno))),
								  'odometer',t.odo_meter,
								  'activityDate',t.activity_date,
								  'overAllRunningKm',(select * from tyre.get_tyre_over_all_running_km(json_build_object('tyreSno',t.tyre_sno)))
								 )) into stepney_list from tyre t;
raise notice '%',tyre_list;
return (select json_agg(json_build_object('tyreList',tyre_list,'stepneyList',stepney_list)));
end;
$$;


ALTER FUNCTION tyre.get_tyre_position(p_data json) OWNER TO postgres;

--
-- Name: insert_rotation_tyre_activity(json); Type: FUNCTION; Schema: tyre; Owner: postgres
--

CREATE FUNCTION tyre.insert_rotation_tyre_activity(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
v_doc json;
begin
for v_doc in SELECT * FROM json_array_elements((p_data->>'tyreList')::json) loop
	perform tyre.insert_tyre_activity(v_doc);
end loop;

return (select json_build_object('data',json_build_object('isUpdated',true)));
end;
$$;


ALTER FUNCTION tyre.insert_rotation_tyre_activity(p_data json) OWNER TO postgres;

--
-- Name: insert_tyre(json); Type: FUNCTION; Schema: tyre; Owner: postgres
--

CREATE FUNCTION tyre.insert_tyre(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
tyreSno bigint;
begin
-- raise notice '%',p_data;
if (select count(*) from tyre.tyre where tyre_serial_number=(p_data->>'tyreSerialNumber')::text)>0 then 
  return (select json_build_object('data',json_build_object('msg','This tyre serial number is already exists')));
else
insert into tyre.tyre(org_sno,
					tyre_serial_number,
					tyre_type_sno,
					tyre_model,
					tyre_size_sno,
					tyre_price,
					agency_name,
					tyre_company_sno,
					invoice_date,
					incoming_date,
					invoice_media,
					payment_mode_cd,
					is_new, 
					is_tread,
					km_drive,
					no_of_tread,  
					efficiency_value) 
   values ((p_data->>'orgSno')::bigint,
	           (p_data->>'tyreSerialNumber'),
		   (p_data->>'tyreTypeSno')::bigint,
		   (p_data->>'tyreModel'),
		   (p_data->>'tyreSizeSno')::bigint,
		   (p_data->>'tyrePrice')::double precision,
		   (p_data->>'agencyName'),
		   (p_data->>'tyreCompanySno')::bigint,
		   (p_data->>'invoiceDate')::timestamp,
		   (p_data->>'incomingDate')::timestamp,
		   (p_data->>'invoiceMedia')::bigint,
		   (p_data->>'paymentModeCd')::smallint,
		   (p_data->>'isNew')::boolean,
		   (p_data->>'isTread')::boolean,
		   (p_data->>'kmDrive'),
		   (p_data->>'noOfTread')::smallint,
		   (p_data->>'efficiencyValue')::smallint) 
  returning tyre_sno  INTO tyreSno;
  
  return (select json_build_object('data',json_build_object('tyreSno',tyreSno,'msg','success')));
  end if;
end;
$$;


ALTER FUNCTION tyre.insert_tyre(p_data json) OWNER TO postgres;

--
-- Name: insert_tyre_activity(json); Type: FUNCTION; Schema: tyre; Owner: postgres
--

CREATE FUNCTION tyre.insert_tyre_activity(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
_tyre_pre_actitvity json;
_tyre_activity_sno bigint;
_tyre_activity_type_cd smallint;
-- _activity_date timestamp := portal.get_time_with_zone(json_build_object('timeZone',p_data->>'activityDate'))::timestamp;
_tyre_sno bigint;
begin

select json_build_object(
		'tyreActivitySno',ta.tyre_activity_sno,
		'tyreSno',ta.tyre_sno,
		'tyreActivityTypeCd',(p_data->>'tyreActivityTypeCd')::smallint,
		'runningKm',((p_data->>'odoMeter')::numeric - ta.odo_meter),
		'runningLife', ((p_data->>'activityDate')::timestamp - ta.activity_date),
		'activityStartDate',ta.activity_date,
		'activityEndDate',(p_data->>'activityDate')::timestamp
	) into _tyre_pre_actitvity from tyre.tyre_activity ta where ta.vehicle_sno = (p_data->>'vehicleSno')::bigint and  ta.tyre_sno = (p_data->>'tyreSno')::bigint and trim(ta.wheel_position) = trim(p_data->>'wheelPosition')
	and case 
	when (
		((p_data->>'tyreActivityTypeCd')::smallint = 98) or 
		((p_data->>'tyreActivityTypeCd')::smallint = 99) or 
		((p_data->>'tyreActivityTypeCd')::smallint = 100) or 
		((p_data->>'tyreActivityTypeCd')::smallint = 101) or 
		((p_data->>'tyreActivityTypeCd')::smallint = 102) or 
		((p_data->>'tyreActivityTypeCd')::smallint = 103)
		 ) then 
	(ta.tyre_activity_type_cd = 97 OR ((ta.tyre_activity_type_cd = 98 OR ta.tyre_activity_type_cd = 99 OR ta.tyre_activity_type_cd = 100 OR ta.tyre_activity_type_cd = 101 OR ta.tyre_activity_type_cd = 103) and ta.is_running = true))
	else ta.tyre_activity_type_cd = (p_data->>'tyreActivityTypeCd')::smallint end 
	order by ta.tyre_activity_sno desc;
	

raise notice '_tyre_pre_actitvity %', _tyre_pre_actitvity;

if(((p_data->>'tyreActivityTypeCd')::smallint = 98) or ((p_data->>'tyreActivityTypeCd')::smallint = 99)) then
	update tyre.tyre_activity set is_running = false where tyre_sno = (p_data->>'changeTyreSno')::bigint;
end if;

if (_tyre_pre_actitvity is not null) then
	insert into tyre.tyre_activity_total_km(tyre_sno,tyre_activity_type_cd,running_km,running_life,activity_start_date,activity_end_date,tyre_activity_sno)	
		values((_tyre_pre_actitvity->>'tyreSno')::bigint,
			   (_tyre_pre_actitvity->>'tyreActivityTypeCd')::smallint,
			   (_tyre_pre_actitvity->>'runningKm')::numeric,
			   (_tyre_pre_actitvity->>'runningLife'),
			   (_tyre_pre_actitvity->>'activityStartDate')::timestamp,
			   (_tyre_pre_actitvity->>'activityEndDate')::timestamp,(_tyre_pre_actitvity->>'tyreActivitySno')::bigint);

	update tyre.tyre_activity set is_running = false where tyre_activity_sno = (_tyre_pre_actitvity->>'tyreActivitySno')::bigint;
	
	select tyre_activity_type_cd into _tyre_activity_type_cd from tyre.tyre_activity where tyre_sno = (p_data->>'changeTyreSno')::bigint and tyre_activity_type_cd = (p_data->>'tyreActivityTypeCd')::smallint;

    raise notice '_tyre_activity_type_cd %',_tyre_activity_type_cd;

		if(((p_data->>'tyreActivityTypeCd')::bigint = 98) or ((p_data->>'tyreActivityTypeCd')::bigint = 99) or ((p_data->>'tyreActivityTypeCd')::bigint = 102)) then	   

		 insert into tyre.tyre_activity(tyre_sno,vehicle_sno,tyre_activity_type_cd,description,odo_meter,is_running,activity_date,wheel_position)
		 values ((p_data->>'changeTyreSno')::bigint,(p_data->>'vehicleSno')::bigint,case when _tyre_activity_type_cd is null  then 97 else _tyre_activity_type_cd end ,p_data->>'description',
		 (p_data->>'odoMeter')::numeric,true,(p_data->>'activityDate')::timestamp,p_data->>'wheelPosition')
		  returning tyre_activity_sno,tyre_sno into _tyre_activity_sno,_tyre_sno;

		 update tyre.tyre set is_running = false where tyre_sno = (p_data->>'tyreSno')::bigint;

		end if;
	
end if;


insert into tyre.tyre_activity(tyre_sno,vehicle_sno,tyre_activity_type_cd,description,odo_meter,is_running,activity_date,wheel_position)
values ( case when (p_data->>'tyreActivityTypeCd')::smallint <> 100 then (p_data->>'tyreSno')::bigint else (p_data->>'changeTyreSno')::bigint end,
		case when (p_data->>'tyreActivityTypeCd')::smallint <> 98 and (p_data->>'tyreActivityTypeCd')::smallint <> 99 then (p_data->>'vehicleSno')::bigint else null end,
		(p_data->>'tyreActivityTypeCd')::smallint,
		p_data->>'description',
	    (p_data->>'odoMeter')::numeric,
		(p_data->>'isRunning')::boolean,
		(p_data->>'activityDate')::timestamp,
		case 
		when (p_data->>'tyreActivityTypeCd')::smallint = 98 then 'remove'
		when (p_data->>'tyreActivityTypeCd')::smallint = 99 then 'inventory'
		when (p_data->>'tyreActivityTypeCd')::smallint = 102 then 'bursted'
		else p_data->>'wheelPosition' end) 
returning tyre_activity_sno into _tyre_activity_sno;

if (p_data->>'tyreActivityTypeCd')::smallint = 102 then
	update tyre.tyre set is_bursted = true where tyre_sno = (select ta.tyre_sno from tyre.tyre_activity ta where ta.tyre_activity_sno = _tyre_activity_sno);
end if;

raise notice '%',_tyre_activity_sno;

update tyre.tyre set is_running = true where tyre_sno = case when (((p_data->>'tyreActivityTypeCd')::smallint <> 98) and ((p_data->>'tyreActivityTypeCd')::smallint <> 99) 
																   and ((p_data->>'tyreActivityTypeCd')::smallint <> 102)) then (p_data->>'tyreSno')::bigint else 
(p_data->>'changeTyreSno')::bigint end;
	   
return (select json_build_object('data',json_build_object('tyreActivitySno',_tyre_activity_sno)));
end;
$$;


ALTER FUNCTION tyre.insert_tyre_activity(p_data json) OWNER TO postgres;

--
-- Name: update_tyre(json); Type: FUNCTION; Schema: tyre; Owner: postgres
--

CREATE FUNCTION tyre.update_tyre(p_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
begin
raise notice 'update_tyre %',p_data;

update tyre.tyre set  agency_name= (p_data->>'agencyName'), tyre_company_sno= (p_data->>'tyreCompanySno')::bigint,tyre_serial_number = (p_data->>'tyreSerialNumber'),
tyre_size_sno = (p_data->>'tyreSizeSno')::bigint,tyre_price = (p_data->>'tyrePrice')::double precision,
tyre_type_sno = (p_data->>'tyreTypeSno')::bigint,tyre_model = (p_data->>'tyreModel'),invoice_date = (p_data->>'invoiceDate')::timestamp,
incoming_date = (p_data->>'incomingDate')::timestamp,invoice_media = (p_data->>'invoiceMedia')::bigint,
payment_mode_cd = (p_data->>'paymentModeCd')::smallint,is_new = (p_data->>'isNew')::boolean,is_tread = (p_data->>'isTread')::boolean,km_drive = (p_data->>'kmDrive'),
no_of_tread = (p_data->>'noOfTread')::smallint,efficiency_value = (p_data->>'efficiencyValue')::smallint
where tyre_sno = (p_data->>'tyreSno')::bigint;
return 
( json_build_object('data',json_build_object('tyreSno',(p_data->>'tyreSno')::bigint)));
end;
$$;


ALTER FUNCTION tyre.update_tyre(p_data json) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: config; Type: TABLE; Schema: config; Owner: postgres
--

CREATE TABLE config.config (
    config_sno smallint NOT NULL,
    environment_sno smallint NOT NULL,
    module_sno smallint NOT NULL,
    sub_module_sno smallint NOT NULL,
    config_value text NOT NULL,
    config_key_sno smallint NOT NULL
);


ALTER TABLE config.config OWNER TO postgres;

--
-- Name: config_config_sno_seq; Type: SEQUENCE; Schema: config; Owner: postgres
--

CREATE SEQUENCE config.config_config_sno_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE config.config_config_sno_seq OWNER TO postgres;

--
-- Name: config_config_sno_seq; Type: SEQUENCE OWNED BY; Schema: config; Owner: postgres
--

ALTER SEQUENCE config.config_config_sno_seq OWNED BY config.config.config_sno;


--
-- Name: config_key; Type: TABLE; Schema: config; Owner: postgres
--

CREATE TABLE config.config_key (
    config_key_sno smallint NOT NULL,
    config_key_attribute text,
    encrypt_type_cd smallint
);


ALTER TABLE config.config_key OWNER TO postgres;

--
-- Name: config_key_config_key_sno_seq; Type: SEQUENCE; Schema: config; Owner: postgres
--

CREATE SEQUENCE config.config_key_config_key_sno_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE config.config_key_config_key_sno_seq OWNER TO postgres;

--
-- Name: config_key_config_key_sno_seq; Type: SEQUENCE OWNED BY; Schema: config; Owner: postgres
--

ALTER SEQUENCE config.config_key_config_key_sno_seq OWNED BY config.config_key.config_key_sno;


--
-- Name: environment; Type: TABLE; Schema: config; Owner: postgres
--

CREATE TABLE config.environment (
    environment_sno smallint NOT NULL,
    environment_name text NOT NULL
);


ALTER TABLE config.environment OWNER TO postgres;

--
-- Name: environment_environment_sno_seq; Type: SEQUENCE; Schema: config; Owner: postgres
--

CREATE SEQUENCE config.environment_environment_sno_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE config.environment_environment_sno_seq OWNER TO postgres;

--
-- Name: environment_environment_sno_seq; Type: SEQUENCE OWNED BY; Schema: config; Owner: postgres
--

ALTER SEQUENCE config.environment_environment_sno_seq OWNED BY config.environment.environment_sno;


--
-- Name: module; Type: TABLE; Schema: config; Owner: postgres
--

CREATE TABLE config.module (
    module_sno smallint NOT NULL,
    environment_sno smallint NOT NULL,
    module_name text NOT NULL
);


ALTER TABLE config.module OWNER TO postgres;

--
-- Name: module_module_sno_seq; Type: SEQUENCE; Schema: config; Owner: postgres
--

CREATE SEQUENCE config.module_module_sno_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE config.module_module_sno_seq OWNER TO postgres;

--
-- Name: module_module_sno_seq; Type: SEQUENCE OWNED BY; Schema: config; Owner: postgres
--

ALTER SEQUENCE config.module_module_sno_seq OWNED BY config.module.module_sno;


--
-- Name: sub_module; Type: TABLE; Schema: config; Owner: postgres
--

CREATE TABLE config.sub_module (
    sub_module_sno smallint NOT NULL,
    module_sno smallint NOT NULL,
    sub_module_name text NOT NULL
);


ALTER TABLE config.sub_module OWNER TO postgres;

--
-- Name: sub_module_sub_module_sno_seq; Type: SEQUENCE; Schema: config; Owner: postgres
--

CREATE SEQUENCE config.sub_module_sub_module_sno_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE config.sub_module_sub_module_sno_seq OWNER TO postgres;

--
-- Name: sub_module_sub_module_sno_seq; Type: SEQUENCE OWNED BY; Schema: config; Owner: postgres
--

ALTER SEQUENCE config.sub_module_sub_module_sno_seq OWNED BY config.sub_module.sub_module_sno;


--
-- Name: driver; Type: TABLE; Schema: driver; Owner: postgres
--

CREATE TABLE driver.driver (
    driver_sno bigint NOT NULL,
    driver_name text NOT NULL,
    driver_mobile_number text NOT NULL,
    driver_whatsapp_number text,
    dob timestamp without time zone NOT NULL,
    father_name text,
    address text,
    current_address text,
    current_district text,
    blood_group_cd smallint,
    media_sno bigint,
    certificate_sno bigint,
    certificate_description text,
    licence_number public.citext NOT NULL,
    licence_expiry_date timestamp without time zone,
    transport_licence_expiry_date timestamp without time zone,
    driving_licence_type integer[],
    active_flag boolean DEFAULT true NOT NULL,
    kyc_status smallint,
    reject_reason text,
    licence_front_sno bigint,
    licence_back_sno bigint
);


ALTER TABLE driver.driver OWNER TO postgres;

--
-- Name: driver_attendance; Type: TABLE; Schema: driver; Owner: postgres
--

CREATE TABLE driver.driver_attendance (
    driver_attendance_sno bigint NOT NULL,
    driver_sno bigint NOT NULL,
    vehicle_sno bigint NOT NULL,
    start_lat_long text,
    end_lat_long text,
    start_media json,
    end_media json,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    start_value text,
    end_value text,
    attendance_status_cd smallint,
    active_flag boolean DEFAULT true,
    accept_status boolean DEFAULT false,
    is_calculated boolean DEFAULT false,
    report_id bigint
);


ALTER TABLE driver.driver_attendance OWNER TO postgres;

--
-- Name: driver_attendance_driver_attendance_sno_seq; Type: SEQUENCE; Schema: driver; Owner: postgres
--

CREATE SEQUENCE driver.driver_attendance_driver_attendance_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE driver.driver_attendance_driver_attendance_sno_seq OWNER TO postgres;

--
-- Name: driver_attendance_driver_attendance_sno_seq; Type: SEQUENCE OWNED BY; Schema: driver; Owner: postgres
--

ALTER SEQUENCE driver.driver_attendance_driver_attendance_sno_seq OWNED BY driver.driver_attendance.driver_attendance_sno;


--
-- Name: driver_driver_sno_seq; Type: SEQUENCE; Schema: driver; Owner: postgres
--

CREATE SEQUENCE driver.driver_driver_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE driver.driver_driver_sno_seq OWNER TO postgres;

--
-- Name: driver_driver_sno_seq; Type: SEQUENCE OWNED BY; Schema: driver; Owner: postgres
--

ALTER SEQUENCE driver.driver_driver_sno_seq OWNED BY driver.driver.driver_sno;


--
-- Name: driver_mileage; Type: TABLE; Schema: driver; Owner: postgres
--

CREATE TABLE driver.driver_mileage (
    driver_mileage_sno bigint NOT NULL,
    driver_sno bigint,
    driving_type_cd bigint,
    mileage text,
    kms text,
    fuel double precision,
    vehicle_sno bigint,
    active_flag boolean
);


ALTER TABLE driver.driver_mileage OWNER TO postgres;

--
-- Name: driver_mileage_driver_mileage_sno_seq; Type: SEQUENCE; Schema: driver; Owner: postgres
--

CREATE SEQUENCE driver.driver_mileage_driver_mileage_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE driver.driver_mileage_driver_mileage_sno_seq OWNER TO postgres;

--
-- Name: driver_mileage_driver_mileage_sno_seq; Type: SEQUENCE OWNED BY; Schema: driver; Owner: postgres
--

ALTER SEQUENCE driver.driver_mileage_driver_mileage_sno_seq OWNED BY driver.driver_mileage.driver_mileage_sno;


--
-- Name: driver_user; Type: TABLE; Schema: driver; Owner: postgres
--

CREATE TABLE driver.driver_user (
    driver_user_sno bigint NOT NULL,
    driver_sno bigint NOT NULL,
    app_user_sno bigint NOT NULL,
    active_flag boolean DEFAULT true NOT NULL
);


ALTER TABLE driver.driver_user OWNER TO postgres;

--
-- Name: driver_user_driver_user_sno_seq; Type: SEQUENCE; Schema: driver; Owner: postgres
--

CREATE SEQUENCE driver.driver_user_driver_user_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE driver.driver_user_driver_user_sno_seq OWNER TO postgres;

--
-- Name: driver_user_driver_user_sno_seq; Type: SEQUENCE OWNED BY; Schema: driver; Owner: postgres
--

ALTER SEQUENCE driver.driver_user_driver_user_sno_seq OWNED BY driver.driver_user.driver_user_sno;


--
-- Name: job_post; Type: TABLE; Schema: driver; Owner: postgres
--

CREATE TABLE driver.job_post (
    job_post_sno bigint NOT NULL,
    role_cd smallint NOT NULL,
    org_sno bigint,
    driver_sno bigint,
    user_lat_long json,
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    posted_on timestamp without time zone,
    contact_name text,
    contact_number text,
    drive_type_cd smallint[],
    job_type_cd smallint[],
    lat text,
    lng text,
    description text,
    active_flag boolean,
    distance numeric,
    auth_type_cd smallint,
    transmission_type_cd smallint[],
    fuel_type_cd smallint[],
    app_user_sno bigint
);


ALTER TABLE driver.job_post OWNER TO postgres;

--
-- Name: job_post_job_post_sno_seq; Type: SEQUENCE; Schema: driver; Owner: postgres
--

CREATE SEQUENCE driver.job_post_job_post_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE driver.job_post_job_post_sno_seq OWNER TO postgres;

--
-- Name: job_post_job_post_sno_seq; Type: SEQUENCE OWNED BY; Schema: driver; Owner: postgres
--

ALTER SEQUENCE driver.job_post_job_post_sno_seq OWNED BY driver.job_post.job_post_sno;


--
-- Name: city; Type: TABLE; Schema: master_data; Owner: postgres
--

CREATE TABLE master_data.city (
    city_sno bigint NOT NULL,
    city_name text,
    district_sno bigint,
    active_flag boolean DEFAULT true
);


ALTER TABLE master_data.city OWNER TO postgres;

--
-- Name: city_city_sno_seq; Type: SEQUENCE; Schema: master_data; Owner: postgres
--

CREATE SEQUENCE master_data.city_city_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE master_data.city_city_sno_seq OWNER TO postgres;

--
-- Name: city_city_sno_seq; Type: SEQUENCE OWNED BY; Schema: master_data; Owner: postgres
--

ALTER SEQUENCE master_data.city_city_sno_seq OWNED BY master_data.city.city_sno;


--
-- Name: district; Type: TABLE; Schema: master_data; Owner: postgres
--

CREATE TABLE master_data.district (
    district_sno bigint NOT NULL,
    district_name text,
    state_sno bigint,
    active_flag boolean DEFAULT true
);


ALTER TABLE master_data.district OWNER TO postgres;

--
-- Name: district_district_sno_seq; Type: SEQUENCE; Schema: master_data; Owner: postgres
--

CREATE SEQUENCE master_data.district_district_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE master_data.district_district_sno_seq OWNER TO postgres;

--
-- Name: district_district_sno_seq; Type: SEQUENCE OWNED BY; Schema: master_data; Owner: postgres
--

ALTER SEQUENCE master_data.district_district_sno_seq OWNED BY master_data.district.district_sno;


--
-- Name: route; Type: TABLE; Schema: master_data; Owner: postgres
--

CREATE TABLE master_data.route (
    route_sno bigint NOT NULL,
    source_city_sno bigint NOT NULL,
    destination_city_sno bigint NOT NULL,
    active_flag boolean DEFAULT true
);


ALTER TABLE master_data.route OWNER TO postgres;

--
-- Name: route_route_sno_seq; Type: SEQUENCE; Schema: master_data; Owner: postgres
--

CREATE SEQUENCE master_data.route_route_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE master_data.route_route_sno_seq OWNER TO postgres;

--
-- Name: route_route_sno_seq; Type: SEQUENCE OWNED BY; Schema: master_data; Owner: postgres
--

ALTER SEQUENCE master_data.route_route_sno_seq OWNED BY master_data.route.route_sno;


--
-- Name: state; Type: TABLE; Schema: master_data; Owner: postgres
--

CREATE TABLE master_data.state (
    state_sno bigint NOT NULL,
    state_name text,
    active_flag boolean DEFAULT true
);


ALTER TABLE master_data.state OWNER TO postgres;

--
-- Name: state_state_sno_seq; Type: SEQUENCE; Schema: master_data; Owner: postgres
--

CREATE SEQUENCE master_data.state_state_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE master_data.state_state_sno_seq OWNER TO postgres;

--
-- Name: state_state_sno_seq; Type: SEQUENCE OWNED BY; Schema: master_data; Owner: postgres
--

ALTER SEQUENCE master_data.state_state_sno_seq OWNED BY master_data.state.state_sno;


--
-- Name: tyre_company; Type: TABLE; Schema: master_data; Owner: postgres
--

CREATE TABLE master_data.tyre_company (
    tyre_company_sno bigint NOT NULL,
    tyre_company text,
    active_flag boolean DEFAULT true
);


ALTER TABLE master_data.tyre_company OWNER TO postgres;

--
-- Name: tyre_company_tyre_company_sno_seq; Type: SEQUENCE; Schema: master_data; Owner: postgres
--

CREATE SEQUENCE master_data.tyre_company_tyre_company_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE master_data.tyre_company_tyre_company_sno_seq OWNER TO postgres;

--
-- Name: tyre_company_tyre_company_sno_seq; Type: SEQUENCE OWNED BY; Schema: master_data; Owner: postgres
--

ALTER SEQUENCE master_data.tyre_company_tyre_company_sno_seq OWNED BY master_data.tyre_company.tyre_company_sno;


--
-- Name: tyre_size; Type: TABLE; Schema: master_data; Owner: postgres
--

CREATE TABLE master_data.tyre_size (
    tyre_size_sno bigint NOT NULL,
    tyre_type_sno bigint,
    tyre_size text NOT NULL,
    active_flag boolean DEFAULT true
);


ALTER TABLE master_data.tyre_size OWNER TO postgres;

--
-- Name: tyre_size_tyre_size_sno_seq; Type: SEQUENCE; Schema: master_data; Owner: postgres
--

CREATE SEQUENCE master_data.tyre_size_tyre_size_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE master_data.tyre_size_tyre_size_sno_seq OWNER TO postgres;

--
-- Name: tyre_size_tyre_size_sno_seq; Type: SEQUENCE OWNED BY; Schema: master_data; Owner: postgres
--

ALTER SEQUENCE master_data.tyre_size_tyre_size_sno_seq OWNED BY master_data.tyre_size.tyre_size_sno;


--
-- Name: tyre_type; Type: TABLE; Schema: master_data; Owner: postgres
--

CREATE TABLE master_data.tyre_type (
    tyre_type_sno bigint NOT NULL,
    tyre_type text NOT NULL,
    active_flag boolean DEFAULT true
);


ALTER TABLE master_data.tyre_type OWNER TO postgres;

--
-- Name: tyre_type_tyre_type_sno_seq; Type: SEQUENCE; Schema: master_data; Owner: postgres
--

CREATE SEQUENCE master_data.tyre_type_tyre_type_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE master_data.tyre_type_tyre_type_sno_seq OWNER TO postgres;

--
-- Name: tyre_type_tyre_type_sno_seq; Type: SEQUENCE OWNED BY; Schema: master_data; Owner: postgres
--

ALTER SEQUENCE master_data.tyre_type_tyre_type_sno_seq OWNED BY master_data.tyre_type.tyre_type_sno;


--
-- Name: media; Type: TABLE; Schema: media; Owner: postgres
--

CREATE TABLE media.media (
    media_sno bigint NOT NULL,
    container_name character varying(60) NOT NULL
);


ALTER TABLE media.media OWNER TO postgres;

--
-- Name: media_detail; Type: TABLE; Schema: media; Owner: postgres
--

CREATE TABLE media.media_detail (
    media_detail_sno bigint NOT NULL,
    azure_id text,
    media_sno bigint,
    media_url text,
    thumbnail_url text,
    media_type character varying(20),
    content_type character varying(20),
    media_size integer,
    media_detail_description character varying(200),
    isuploaded boolean DEFAULT true
);


ALTER TABLE media.media_detail OWNER TO postgres;

--
-- Name: media_detail_media_detail_sno_seq; Type: SEQUENCE; Schema: media; Owner: postgres
--

CREATE SEQUENCE media.media_detail_media_detail_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE media.media_detail_media_detail_sno_seq OWNER TO postgres;

--
-- Name: media_detail_media_detail_sno_seq; Type: SEQUENCE OWNED BY; Schema: media; Owner: postgres
--

ALTER SEQUENCE media.media_detail_media_detail_sno_seq OWNED BY media.media_detail.media_detail_sno;


--
-- Name: media_media_sno_seq; Type: SEQUENCE; Schema: media; Owner: postgres
--

CREATE SEQUENCE media.media_media_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE media.media_media_sno_seq OWNER TO postgres;

--
-- Name: media_media_sno_seq; Type: SEQUENCE OWNED BY; Schema: media; Owner: postgres
--

ALTER SEQUENCE media.media_media_sno_seq OWNED BY media.media.media_sno;


--
-- Name: notification; Type: TABLE; Schema: notification; Owner: postgres
--

CREATE TABLE notification.notification (
    notification_sno bigint NOT NULL,
    title text,
    message text,
    action_id bigint,
    router_link text,
    from_id bigint,
    to_id bigint,
    created_on timestamp without time zone,
    notification_status_cd smallint DEFAULT 117,
    active_flag boolean DEFAULT true NOT NULL
);


ALTER TABLE notification.notification OWNER TO postgres;

--
-- Name: notification_notification_sno_seq; Type: SEQUENCE; Schema: notification; Owner: postgres
--

CREATE SEQUENCE notification.notification_notification_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE notification.notification_notification_sno_seq OWNER TO postgres;

--
-- Name: notification_notification_sno_seq; Type: SEQUENCE OWNED BY; Schema: notification; Owner: postgres
--

ALTER SEQUENCE notification.notification_notification_sno_seq OWNED BY notification.notification.notification_sno;


--
-- Name: address; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.address (
    address_sno bigint NOT NULL,
    address_line1 text NOT NULL,
    address_line2 text,
    pincode integer NOT NULL,
    city_name text,
    state_name text,
    district_name text,
    country_name text,
    country_code smallint,
    latitude text,
    longitude text
);


ALTER TABLE operator.address OWNER TO postgres;

--
-- Name: address_address_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.address_address_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.address_address_sno_seq OWNER TO postgres;

--
-- Name: address_address_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.address_address_sno_seq OWNED BY operator.address.address_sno;


--
-- Name: bank_account_detail; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.bank_account_detail (
    bank_account_detail_sno bigint NOT NULL,
    org_sno bigint,
    bank_account_name text
);


ALTER TABLE operator.bank_account_detail OWNER TO postgres;

--
-- Name: bank_account_detail_bank_account_detail_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.bank_account_detail_bank_account_detail_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.bank_account_detail_bank_account_detail_sno_seq OWNER TO postgres;

--
-- Name: bank_account_detail_bank_account_detail_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.bank_account_detail_bank_account_detail_sno_seq OWNED BY operator.bank_account_detail.bank_account_detail_sno;


--
-- Name: bunk; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.bunk (
    bunk_sno bigint NOT NULL,
    bunk_name text NOT NULL,
    address text,
    operator_sno smallint
);


ALTER TABLE operator.bunk OWNER TO postgres;

--
-- Name: bunk_bunk_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.bunk_bunk_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.bunk_bunk_sno_seq OWNER TO postgres;

--
-- Name: bunk_bunk_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.bunk_bunk_sno_seq OWNED BY operator.bunk.bunk_sno;


--
-- Name: bus_report; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.bus_report (
    bus_report_sno bigint NOT NULL,
    org_sno bigint,
    vehicle_sno bigint,
    driver_sno bigint,
    driver_attendance_sno bigint,
    driving_type_cd smallint,
    start_km bigint,
    end_km bigint,
    drived_km numeric,
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    fuel_consumed double precision,
    mileage double precision,
    created_on timestamp without time zone
);


ALTER TABLE operator.bus_report OWNER TO postgres;

--
-- Name: bus_report_bus_report_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.bus_report_bus_report_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.bus_report_bus_report_sno_seq OWNER TO postgres;

--
-- Name: bus_report_bus_report_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.bus_report_bus_report_sno_seq OWNED BY operator.bus_report.bus_report_sno;


--
-- Name: fuel; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.fuel (
    fuel_sno bigint NOT NULL,
    vehicle_sno bigint,
    driver_sno bigint,
    driver_attendance_sno bigint,
    bunk_sno bigint,
    lat_long text,
    fuel_media json,
    odo_meter_media json,
    fuel_quantity double precision NOT NULL,
    fuel_amount double precision NOT NULL,
    odo_meter_value bigint NOT NULL,
    filled_date timestamp without time zone NOT NULL,
    price_per_ltr double precision NOT NULL,
    accept_status boolean DEFAULT false,
    active_flag boolean DEFAULT true,
    is_filled boolean NOT NULL,
    fuel_fill_type_cd smallint,
    tank_media json,
    is_calculated boolean,
    report_id bigint
);


ALTER TABLE operator.fuel OWNER TO postgres;

--
-- Name: fuel_fuel_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.fuel_fuel_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.fuel_fuel_sno_seq OWNER TO postgres;

--
-- Name: fuel_fuel_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.fuel_fuel_sno_seq OWNED BY operator.fuel.fuel_sno;


--
-- Name: operator_driver; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.operator_driver (
    operator_driver_sno bigint NOT NULL,
    org_sno bigint NOT NULL,
    driver_sno bigint NOT NULL,
    accept_status_cd smallint,
    active_flag boolean DEFAULT true NOT NULL
);


ALTER TABLE operator.operator_driver OWNER TO postgres;

--
-- Name: operator_driver_operator_driver_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.operator_driver_operator_driver_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.operator_driver_operator_driver_sno_seq OWNER TO postgres;

--
-- Name: operator_driver_operator_driver_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.operator_driver_operator_driver_sno_seq OWNED BY operator.operator_driver.operator_driver_sno;


--
-- Name: operator_route; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.operator_route (
    operator_route_sno bigint NOT NULL,
    route_sno bigint,
    operator_sno bigint,
    active_flag boolean DEFAULT true
);


ALTER TABLE operator.operator_route OWNER TO postgres;

--
-- Name: operator_route_operator_route_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.operator_route_operator_route_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.operator_route_operator_route_sno_seq OWNER TO postgres;

--
-- Name: operator_route_operator_route_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.operator_route_operator_route_sno_seq OWNED BY operator.operator_route.operator_route_sno;


--
-- Name: org; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.org (
    org_sno bigint NOT NULL,
    org_name text NOT NULL,
    owner_name text NOT NULL,
    vehicle_number text NOT NULL,
    org_status_cd smallint NOT NULL,
    active_flag boolean DEFAULT true NOT NULL
);


ALTER TABLE operator.org OWNER TO postgres;

--
-- Name: org_contact; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.org_contact (
    org_contact_sno bigint NOT NULL,
    org_sno bigint,
    contact_sno bigint,
    active_flag boolean DEFAULT true NOT NULL
);


ALTER TABLE operator.org_contact OWNER TO postgres;

--
-- Name: org_contact_org_contact_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.org_contact_org_contact_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.org_contact_org_contact_sno_seq OWNER TO postgres;

--
-- Name: org_contact_org_contact_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.org_contact_org_contact_sno_seq OWNED BY operator.org_contact.org_contact_sno;


--
-- Name: org_detail; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.org_detail (
    org_detail_sno bigint NOT NULL,
    org_sno bigint NOT NULL,
    org_logo json,
    org_banner json,
    address_sno bigint NOT NULL,
    org_website text
);


ALTER TABLE operator.org_detail OWNER TO postgres;

--
-- Name: org_detail_org_detail_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.org_detail_org_detail_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.org_detail_org_detail_sno_seq OWNER TO postgres;

--
-- Name: org_detail_org_detail_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.org_detail_org_detail_sno_seq OWNED BY operator.org_detail.org_detail_sno;


--
-- Name: org_org_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.org_org_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.org_org_sno_seq OWNER TO postgres;

--
-- Name: org_org_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.org_org_sno_seq OWNED BY operator.org.org_sno;


--
-- Name: org_owner; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.org_owner (
    org_owner_sno bigint NOT NULL,
    org_sno bigint,
    app_user_sno bigint
);


ALTER TABLE operator.org_owner OWNER TO postgres;

--
-- Name: org_owner_org_owner_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.org_owner_org_owner_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.org_owner_org_owner_sno_seq OWNER TO postgres;

--
-- Name: org_owner_org_owner_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.org_owner_org_owner_sno_seq OWNED BY operator.org_owner.org_owner_sno;


--
-- Name: org_social_link; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.org_social_link (
    org_social_link_sno bigint NOT NULL,
    org_sno bigint,
    social_link_sno bigint,
    active_flag boolean DEFAULT true NOT NULL
);


ALTER TABLE operator.org_social_link OWNER TO postgres;

--
-- Name: org_social_link_org_social_link_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.org_social_link_org_social_link_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.org_social_link_org_social_link_sno_seq OWNER TO postgres;

--
-- Name: org_social_link_org_social_link_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.org_social_link_org_social_link_sno_seq OWNED BY operator.org_social_link.org_social_link_sno;


--
-- Name: org_user; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.org_user (
    org_user_sno bigint NOT NULL,
    operator_user_sno bigint,
    role_user_sno bigint
);


ALTER TABLE operator.org_user OWNER TO postgres;

--
-- Name: org_user_org_user_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.org_user_org_user_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.org_user_org_user_sno_seq OWNER TO postgres;

--
-- Name: org_user_org_user_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.org_user_org_user_sno_seq OWNED BY operator.org_user.org_user_sno;


--
-- Name: org_vehicle; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.org_vehicle (
    org_vehicle_sno bigint NOT NULL,
    org_sno bigint NOT NULL,
    vehicle_sno bigint NOT NULL
);


ALTER TABLE operator.org_vehicle OWNER TO postgres;

--
-- Name: org_vehicle_org_vehicle_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.org_vehicle_org_vehicle_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.org_vehicle_org_vehicle_sno_seq OWNER TO postgres;

--
-- Name: org_vehicle_org_vehicle_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.org_vehicle_org_vehicle_sno_seq OWNED BY operator.org_vehicle.org_vehicle_sno;


--
-- Name: reject_reason; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.reject_reason (
    reject_reason_sno bigint NOT NULL,
    org_sno bigint,
    reason text
);


ALTER TABLE operator.reject_reason OWNER TO postgres;

--
-- Name: reject_reason_reject_reason_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.reject_reason_reject_reason_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.reject_reason_reject_reason_sno_seq OWNER TO postgres;

--
-- Name: reject_reason_reject_reason_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.reject_reason_reject_reason_sno_seq OWNED BY operator.reject_reason.reject_reason_sno;


--
-- Name: single_route; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.single_route (
    single_route_sno bigint NOT NULL,
    route_sno bigint NOT NULL,
    org_sno bigint NOT NULL,
    vehicle_sno bigint NOT NULL,
    starting_time timestamp without time zone NOT NULL,
    running_time bigint NOT NULL,
    active_flag boolean DEFAULT true
);


ALTER TABLE operator.single_route OWNER TO postgres;

--
-- Name: single_route_single_route_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.single_route_single_route_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.single_route_single_route_sno_seq OWNER TO postgres;

--
-- Name: single_route_single_route_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.single_route_single_route_sno_seq OWNED BY operator.single_route.single_route_sno;


--
-- Name: toll_pass_detail; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.toll_pass_detail (
    toll_pass_detail_sno bigint NOT NULL,
    vehicle_sno bigint,
    org_sno bigint,
    toll_id text,
    toll_name text,
    toll_amount double precision,
    pass_start_date date,
    pass_end_date date,
    active_flag boolean,
    is_paid boolean DEFAULT false
);


ALTER TABLE operator.toll_pass_detail OWNER TO postgres;

--
-- Name: toll_pass_detail_toll_pass_detail_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.toll_pass_detail_toll_pass_detail_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.toll_pass_detail_toll_pass_detail_sno_seq OWNER TO postgres;

--
-- Name: toll_pass_detail_toll_pass_detail_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.toll_pass_detail_toll_pass_detail_sno_seq OWNED BY operator.toll_pass_detail.toll_pass_detail_sno;


--
-- Name: trip; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.trip (
    trip_sno bigint NOT NULL,
    source_name text NOT NULL,
    destination text,
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    district_sno bigint NOT NULL,
    active_flag boolean DEFAULT true
);


ALTER TABLE operator.trip OWNER TO postgres;

--
-- Name: trip_route; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.trip_route (
    trip_route_sno bigint NOT NULL,
    trip_sno bigint NOT NULL,
    via_name text,
    latitude text,
    longitude text,
    active_flag boolean DEFAULT true
);


ALTER TABLE operator.trip_route OWNER TO postgres;

--
-- Name: trip_route_trip_route_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.trip_route_trip_route_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.trip_route_trip_route_sno_seq OWNER TO postgres;

--
-- Name: trip_route_trip_route_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.trip_route_trip_route_sno_seq OWNED BY operator.trip_route.trip_route_sno;


--
-- Name: trip_trip_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.trip_trip_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.trip_trip_sno_seq OWNER TO postgres;

--
-- Name: trip_trip_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.trip_trip_sno_seq OWNED BY operator.trip.trip_sno;


--
-- Name: vehicle; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.vehicle (
    vehicle_sno bigint NOT NULL,
    vehicle_reg_number text NOT NULL,
    vehicle_name text NOT NULL,
    vehicle_banner_name text NOT NULL,
    chase_number text NOT NULL,
    engine_number text,
    media_sno bigint,
    vehicle_type_cd smallint NOT NULL,
    tyre_type_cd smallint[] NOT NULL,
    tyre_size_cd smallint[] NOT NULL,
    active_flag boolean DEFAULT true NOT NULL,
    kyc_status smallint,
    reject_reason text,
    tyre_count_cd smallint
);


ALTER TABLE operator.vehicle OWNER TO postgres;

--
-- Name: vehicle_detail; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.vehicle_detail (
    vehicle_detail_sno bigint NOT NULL,
    vehicle_sno bigint,
    vehicle_logo json,
    vehicle_reg_date timestamp without time zone,
    fc_expiry_date timestamp without time zone,
    insurance_expiry_date timestamp without time zone,
    pollution_expiry_date timestamp without time zone,
    tax_expiry_date timestamp without time zone,
    permit_expiry_date timestamp without time zone,
    state_sno bigint,
    district_sno bigint,
    odo_meter_value bigint,
    fuel_capacity integer,
    fuel_type_cd smallint,
    video_types_cd integer[],
    seat_type_cd smallint,
    audio_types_cd integer[],
    cool_type_cd smallint,
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
    public_addressing_system_cd integer[],
    lighting_system_cd integer[],
    image_sno bigint,
    fc_expiry_amount double precision,
    insurance_expiry_amount double precision,
    tax_expiry_amount double precision
);


ALTER TABLE operator.vehicle_detail OWNER TO postgres;

--
-- Name: vehicle_detail_vehicle_detail_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.vehicle_detail_vehicle_detail_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.vehicle_detail_vehicle_detail_sno_seq OWNER TO postgres;

--
-- Name: vehicle_detail_vehicle_detail_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.vehicle_detail_vehicle_detail_sno_seq OWNED BY operator.vehicle_detail.vehicle_detail_sno;


--
-- Name: vehicle_driver; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.vehicle_driver (
    vehicle_driver_sno bigint NOT NULL,
    driver_sno bigint,
    vehicle_sno bigint,
    created_on timestamp without time zone
);


ALTER TABLE operator.vehicle_driver OWNER TO postgres;

--
-- Name: vehicle_driver_vehicle_driver_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.vehicle_driver_vehicle_driver_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.vehicle_driver_vehicle_driver_sno_seq OWNER TO postgres;

--
-- Name: vehicle_driver_vehicle_driver_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.vehicle_driver_vehicle_driver_sno_seq OWNED BY operator.vehicle_driver.vehicle_driver_sno;


--
-- Name: vehicle_due_fixed_pay; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.vehicle_due_fixed_pay (
    vehicle_due_sno bigint NOT NULL,
    vehicle_sno bigint,
    org_sno bigint,
    bank_account_detail_sno bigint,
    due_type_cd smallint,
    due_close_date date,
    remainder_type_cd integer[],
    due_amount double precision,
    active_flag boolean DEFAULT true,
    bank_name text,
    bank_account_number text,
    discription text
);


ALTER TABLE operator.vehicle_due_fixed_pay OWNER TO postgres;

--
-- Name: vehicle_due_fixed_pay_vehicle_due_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.vehicle_due_fixed_pay_vehicle_due_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.vehicle_due_fixed_pay_vehicle_due_sno_seq OWNER TO postgres;

--
-- Name: vehicle_due_fixed_pay_vehicle_due_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.vehicle_due_fixed_pay_vehicle_due_sno_seq OWNED BY operator.vehicle_due_fixed_pay.vehicle_due_sno;


--
-- Name: vehicle_due_variable_pay; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.vehicle_due_variable_pay (
    vehicle_due_variable_pay_sno bigint NOT NULL,
    vehicle_due_sno bigint,
    due_pay_date date,
    due_amount double precision,
    active_flag boolean DEFAULT true,
    is_pass_paid boolean DEFAULT false
);


ALTER TABLE operator.vehicle_due_variable_pay OWNER TO postgres;

--
-- Name: vehicle_due_variable_pay_vehicle_due_variable_pay_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.vehicle_due_variable_pay_vehicle_due_variable_pay_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.vehicle_due_variable_pay_vehicle_due_variable_pay_sno_seq OWNER TO postgres;

--
-- Name: vehicle_due_variable_pay_vehicle_due_variable_pay_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.vehicle_due_variable_pay_vehicle_due_variable_pay_sno_seq OWNED BY operator.vehicle_due_variable_pay.vehicle_due_variable_pay_sno;


--
-- Name: vehicle_owner; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.vehicle_owner (
    vehicle_owner_sno bigint NOT NULL,
    vehicle_sno bigint,
    owner_name text,
    owner_number text,
    current_owner boolean,
    purchase_date timestamp without time zone,
    active_flag boolean DEFAULT true NOT NULL,
    app_user_sno bigint
);


ALTER TABLE operator.vehicle_owner OWNER TO postgres;

--
-- Name: vehicle_owner_vehicle_owner_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.vehicle_owner_vehicle_owner_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.vehicle_owner_vehicle_owner_sno_seq OWNER TO postgres;

--
-- Name: vehicle_owner_vehicle_owner_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.vehicle_owner_vehicle_owner_sno_seq OWNED BY operator.vehicle_owner.vehicle_owner_sno;


--
-- Name: vehicle_route; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.vehicle_route (
    vehicle_route_sno bigint NOT NULL,
    operator_route_sno bigint,
    vehicle_sno bigint,
    active_flag boolean DEFAULT true NOT NULL
);


ALTER TABLE operator.vehicle_route OWNER TO postgres;

--
-- Name: vehicle_route_vehicle_route_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.vehicle_route_vehicle_route_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.vehicle_route_vehicle_route_sno_seq OWNER TO postgres;

--
-- Name: vehicle_route_vehicle_route_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.vehicle_route_vehicle_route_sno_seq OWNED BY operator.vehicle_route.vehicle_route_sno;


--
-- Name: vehicle_vehicle_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.vehicle_vehicle_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.vehicle_vehicle_sno_seq OWNER TO postgres;

--
-- Name: vehicle_vehicle_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.vehicle_vehicle_sno_seq OWNED BY operator.vehicle.vehicle_sno;


--
-- Name: via; Type: TABLE; Schema: operator; Owner: postgres
--

CREATE TABLE operator.via (
    via_sno integer NOT NULL,
    operator_route_sno bigint,
    city_sno bigint,
    active_flag boolean DEFAULT true
);


ALTER TABLE operator.via OWNER TO postgres;

--
-- Name: via_via_sno_seq; Type: SEQUENCE; Schema: operator; Owner: postgres
--

CREATE SEQUENCE operator.via_via_sno_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE operator.via_via_sno_seq OWNER TO postgres;

--
-- Name: via_via_sno_seq; Type: SEQUENCE OWNED BY; Schema: operator; Owner: postgres
--

ALTER SEQUENCE operator.via_via_sno_seq OWNED BY operator.via.via_sno;


--
-- Name: app_menu; Type: TABLE; Schema: portal; Owner: postgres
--

CREATE TABLE portal.app_menu (
    app_menu_sno smallint NOT NULL,
    title text NOT NULL,
    href text,
    icon text,
    has_sub_menu boolean,
    parent_menu_sno integer,
    router_link text
);


ALTER TABLE portal.app_menu OWNER TO postgres;

--
-- Name: app_menu_app_menu_sno_seq; Type: SEQUENCE; Schema: portal; Owner: postgres
--

CREATE SEQUENCE portal.app_menu_app_menu_sno_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE portal.app_menu_app_menu_sno_seq OWNER TO postgres;

--
-- Name: app_menu_app_menu_sno_seq; Type: SEQUENCE OWNED BY; Schema: portal; Owner: postgres
--

ALTER SEQUENCE portal.app_menu_app_menu_sno_seq OWNED BY portal.app_menu.app_menu_sno;


--
-- Name: app_menu_role; Type: TABLE; Schema: portal; Owner: postgres
--

CREATE TABLE portal.app_menu_role (
    app_menu_role_sno smallint NOT NULL,
    app_menu_sno integer NOT NULL,
    role_cd integer NOT NULL
);


ALTER TABLE portal.app_menu_role OWNER TO postgres;

--
-- Name: app_menu_role_app_menu_role_sno_seq; Type: SEQUENCE; Schema: portal; Owner: postgres
--

CREATE SEQUENCE portal.app_menu_role_app_menu_role_sno_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE portal.app_menu_role_app_menu_role_sno_seq OWNER TO postgres;

--
-- Name: app_menu_role_app_menu_role_sno_seq; Type: SEQUENCE OWNED BY; Schema: portal; Owner: postgres
--

ALTER SEQUENCE portal.app_menu_role_app_menu_role_sno_seq OWNED BY portal.app_menu_role.app_menu_role_sno;


--
-- Name: app_menu_user; Type: TABLE; Schema: portal; Owner: postgres
--

CREATE TABLE portal.app_menu_user (
    app_menu_user_sno smallint NOT NULL,
    app_menu_sno integer NOT NULL,
    app_user_sno bigint NOT NULL,
    is_admin boolean
);


ALTER TABLE portal.app_menu_user OWNER TO postgres;

--
-- Name: app_menu_user_app_menu_user_sno_seq; Type: SEQUENCE; Schema: portal; Owner: postgres
--

CREATE SEQUENCE portal.app_menu_user_app_menu_user_sno_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE portal.app_menu_user_app_menu_user_sno_seq OWNER TO postgres;

--
-- Name: app_menu_user_app_menu_user_sno_seq; Type: SEQUENCE OWNED BY; Schema: portal; Owner: postgres
--

ALTER SEQUENCE portal.app_menu_user_app_menu_user_sno_seq OWNED BY portal.app_menu_user.app_menu_user_sno;


--
-- Name: app_user; Type: TABLE; Schema: portal; Owner: postgres
--

CREATE TABLE portal.app_user (
    app_user_sno bigint NOT NULL,
    mobile_no text NOT NULL,
    password text,
    confirm_password text,
    user_status_cd smallint NOT NULL
);


ALTER TABLE portal.app_user OWNER TO postgres;

--
-- Name: app_user_app_user_sno_seq; Type: SEQUENCE; Schema: portal; Owner: postgres
--

CREATE SEQUENCE portal.app_user_app_user_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE portal.app_user_app_user_sno_seq OWNER TO postgres;

--
-- Name: app_user_app_user_sno_seq; Type: SEQUENCE OWNED BY; Schema: portal; Owner: postgres
--

ALTER SEQUENCE portal.app_user_app_user_sno_seq OWNED BY portal.app_user.app_user_sno;


--
-- Name: app_user_contact; Type: TABLE; Schema: portal; Owner: postgres
--

CREATE TABLE portal.app_user_contact (
    app_user_contact_sno bigint NOT NULL,
    app_user_sno bigint NOT NULL,
    user_name text,
    mobile_no text NOT NULL,
    alternative_mobile_no text,
    email text,
    user_status_cd smallint NOT NULL
);


ALTER TABLE portal.app_user_contact OWNER TO postgres;

--
-- Name: app_user_contact_app_user_contact_sno_seq; Type: SEQUENCE; Schema: portal; Owner: postgres
--

CREATE SEQUENCE portal.app_user_contact_app_user_contact_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE portal.app_user_contact_app_user_contact_sno_seq OWNER TO postgres;

--
-- Name: app_user_contact_app_user_contact_sno_seq; Type: SEQUENCE OWNED BY; Schema: portal; Owner: postgres
--

ALTER SEQUENCE portal.app_user_contact_app_user_contact_sno_seq OWNED BY portal.app_user_contact.app_user_contact_sno;


--
-- Name: app_user_role; Type: TABLE; Schema: portal; Owner: postgres
--

CREATE TABLE portal.app_user_role (
    app_user_role_sno bigint NOT NULL,
    app_user_sno bigint NOT NULL,
    role_cd smallint NOT NULL
);


ALTER TABLE portal.app_user_role OWNER TO postgres;

--
-- Name: app_user_role_app_user_role_sno_seq; Type: SEQUENCE; Schema: portal; Owner: postgres
--

CREATE SEQUENCE portal.app_user_role_app_user_role_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE portal.app_user_role_app_user_role_sno_seq OWNER TO postgres;

--
-- Name: app_user_role_app_user_role_sno_seq; Type: SEQUENCE OWNED BY; Schema: portal; Owner: postgres
--

ALTER SEQUENCE portal.app_user_role_app_user_role_sno_seq OWNED BY portal.app_user_role.app_user_role_sno;


--
-- Name: codes_dtl; Type: TABLE; Schema: portal; Owner: postgres
--

CREATE TABLE portal.codes_dtl (
    codes_dtl_sno smallint NOT NULL,
    codes_hdr_sno smallint NOT NULL,
    cd_value text NOT NULL,
    seqno integer,
    filter_1 text,
    filter_2 text,
    active_flag boolean DEFAULT true NOT NULL
);


ALTER TABLE portal.codes_dtl OWNER TO postgres;

--
-- Name: codes_dtl_codes_dtl_sno_seq; Type: SEQUENCE; Schema: portal; Owner: postgres
--

CREATE SEQUENCE portal.codes_dtl_codes_dtl_sno_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE portal.codes_dtl_codes_dtl_sno_seq OWNER TO postgres;

--
-- Name: codes_dtl_codes_dtl_sno_seq; Type: SEQUENCE OWNED BY; Schema: portal; Owner: postgres
--

ALTER SEQUENCE portal.codes_dtl_codes_dtl_sno_seq OWNED BY portal.codes_dtl.codes_dtl_sno;


--
-- Name: codes_hdr; Type: TABLE; Schema: portal; Owner: postgres
--

CREATE TABLE portal.codes_hdr (
    codes_hdr_sno smallint NOT NULL,
    code_type text NOT NULL,
    active_flag boolean DEFAULT true NOT NULL
);


ALTER TABLE portal.codes_hdr OWNER TO postgres;

--
-- Name: codes_hdr_codes_hdr_sno_seq; Type: SEQUENCE; Schema: portal; Owner: postgres
--

CREATE SEQUENCE portal.codes_hdr_codes_hdr_sno_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE portal.codes_hdr_codes_hdr_sno_seq OWNER TO postgres;

--
-- Name: codes_hdr_codes_hdr_sno_seq; Type: SEQUENCE OWNED BY; Schema: portal; Owner: postgres
--

ALTER SEQUENCE portal.codes_hdr_codes_hdr_sno_seq OWNED BY portal.codes_hdr.codes_hdr_sno;


--
-- Name: contact; Type: TABLE; Schema: portal; Owner: postgres
--

CREATE TABLE portal.contact (
    contact_sno bigint NOT NULL,
    app_user_sno bigint,
    name text,
    contact_role_cd smallint,
    mobile_number text,
    email text,
    is_show boolean,
    active_flag boolean DEFAULT true NOT NULL
);


ALTER TABLE portal.contact OWNER TO postgres;

--
-- Name: contact_contact_sno_seq; Type: SEQUENCE; Schema: portal; Owner: postgres
--

CREATE SEQUENCE portal.contact_contact_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE portal.contact_contact_sno_seq OWNER TO postgres;

--
-- Name: contact_contact_sno_seq; Type: SEQUENCE OWNED BY; Schema: portal; Owner: postgres
--

ALTER SEQUENCE portal.contact_contact_sno_seq OWNED BY portal.contact.contact_sno;


--
-- Name: otp; Type: TABLE; Schema: portal; Owner: postgres
--

CREATE TABLE portal.otp (
    otp_sno bigint NOT NULL,
    app_user_sno bigint NOT NULL,
    sim_otp character varying(6) NOT NULL,
    api_otp character varying(10) NOT NULL,
    push_otp character varying(10) NOT NULL,
    device_id text NOT NULL,
    expire_time timestamp without time zone NOT NULL,
    active_flag boolean DEFAULT true NOT NULL
);


ALTER TABLE portal.otp OWNER TO postgres;

--
-- Name: otp_otp_sno_seq; Type: SEQUENCE; Schema: portal; Owner: postgres
--

CREATE SEQUENCE portal.otp_otp_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE portal.otp_otp_sno_seq OWNER TO postgres;

--
-- Name: otp_otp_sno_seq; Type: SEQUENCE OWNED BY; Schema: portal; Owner: postgres
--

ALTER SEQUENCE portal.otp_otp_sno_seq OWNED BY portal.otp.otp_sno;


--
-- Name: signin_config; Type: TABLE; Schema: portal; Owner: postgres
--

CREATE TABLE portal.signin_config (
    signin_config_sno bigint NOT NULL,
    app_user_sno bigint NOT NULL,
    push_token_id text,
    device_type_cd smallint NOT NULL,
    device_id text NOT NULL,
    active_flag boolean DEFAULT true
);


ALTER TABLE portal.signin_config OWNER TO postgres;

--
-- Name: signin_config_signin_config_sno_seq; Type: SEQUENCE; Schema: portal; Owner: postgres
--

CREATE SEQUENCE portal.signin_config_signin_config_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE portal.signin_config_signin_config_sno_seq OWNER TO postgres;

--
-- Name: signin_config_signin_config_sno_seq; Type: SEQUENCE OWNED BY; Schema: portal; Owner: postgres
--

ALTER SEQUENCE portal.signin_config_signin_config_sno_seq OWNED BY portal.signin_config.signin_config_sno;


--
-- Name: social_link; Type: TABLE; Schema: portal; Owner: postgres
--

CREATE TABLE portal.social_link (
    social_link_sno bigint NOT NULL,
    social_url text,
    social_link_type_cd integer,
    active_flag boolean DEFAULT true NOT NULL
);


ALTER TABLE portal.social_link OWNER TO postgres;

--
-- Name: social_link_social_link_sno_seq; Type: SEQUENCE; Schema: portal; Owner: postgres
--

CREATE SEQUENCE portal.social_link_social_link_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE portal.social_link_social_link_sno_seq OWNER TO postgres;

--
-- Name: social_link_social_link_sno_seq; Type: SEQUENCE OWNED BY; Schema: portal; Owner: postgres
--

ALTER SEQUENCE portal.social_link_social_link_sno_seq OWNED BY portal.social_link.social_link_sno;


--
-- Name: user_profile; Type: TABLE; Schema: portal; Owner: postgres
--

CREATE TABLE portal.user_profile (
    user_profile_sno bigint NOT NULL,
    app_user_sno bigint,
    first_name text NOT NULL,
    last_name text NOT NULL,
    mobile text NOT NULL,
    gender_cd integer,
    photo text,
    dob timestamp without time zone
);


ALTER TABLE portal.user_profile OWNER TO postgres;

--
-- Name: user_profile_user_profile_sno_seq; Type: SEQUENCE; Schema: portal; Owner: postgres
--

CREATE SEQUENCE portal.user_profile_user_profile_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE portal.user_profile_user_profile_sno_seq OWNER TO postgres;

--
-- Name: user_profile_user_profile_sno_seq; Type: SEQUENCE OWNED BY; Schema: portal; Owner: postgres
--

ALTER SEQUENCE portal.user_profile_user_profile_sno_seq OWNED BY portal.user_profile.user_profile_sno;


--
-- Name: waiting_approval_driver; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.waiting_approval_driver AS
 SELECT d.driver_sno,
    d.driver_name,
    d.driver_mobile_number,
    d.driver_whatsapp_number,
    d.dob,
    d.father_name,
    d.address,
    d.current_address,
    d.current_district,
    d.blood_group_cd,
    d.media_sno,
    d.certificate_sno,
    d.certificate_description,
    d.licence_number,
    d.licence_expiry_date,
    d.transport_licence_expiry_date,
    d.driving_licence_type,
    d.active_flag,
    d.kyc_status,
    d.reject_reason,
    d.licence_front_sno,
    d.licence_back_sno
   FROM driver.driver d
  WHERE (d.kyc_status = 20);


ALTER TABLE public.waiting_approval_driver OWNER TO postgres;

--
-- Name: waiting_approval_org; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.waiting_approval_org AS
 SELECT o.org_sno,
    o.org_name,
    o.owner_name,
    o.vehicle_number,
    o.org_status_cd,
    o.active_flag
   FROM operator.org o
  WHERE (o.org_status_cd = 20);


ALTER TABLE public.waiting_approval_org OWNER TO postgres;

--
-- Name: waiting_approval_vehicle; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.waiting_approval_vehicle AS
 SELECT v.vehicle_sno,
    v.vehicle_reg_number,
    v.vehicle_name,
    v.vehicle_banner_name,
    v.chase_number,
    v.engine_number,
    v.media_sno,
    v.vehicle_type_cd,
    v.tyre_type_cd,
    v.tyre_size_cd,
    v.active_flag,
    v.kyc_status,
    v.reject_reason,
    v.tyre_count_cd
   FROM operator.vehicle v
  WHERE (v.kyc_status = 20);


ALTER TABLE public.waiting_approval_vehicle OWNER TO postgres;

--
-- Name: booking; Type: TABLE; Schema: rent; Owner: postgres
--

CREATE TABLE rent.booking (
    booking_sno bigint NOT NULL,
    vehicle_sno bigint NOT NULL,
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    customer_name text,
    customer_address text,
    contact_number text,
    active_flag boolean DEFAULT true,
    no_of_days_booked bigint,
    total_booking_amount double precision,
    advance_paid double precision,
    balance_amount_to_paid double precision,
    toll_parking_includes boolean,
    driver_wages_includes boolean,
    driver_wages double precision,
    description text,
    booking_id text,
    trip_plan text,
    created_on timestamp without time zone
);


ALTER TABLE rent.booking OWNER TO postgres;

--
-- Name: booking_booking_sno_seq; Type: SEQUENCE; Schema: rent; Owner: postgres
--

CREATE SEQUENCE rent.booking_booking_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE rent.booking_booking_sno_seq OWNER TO postgres;

--
-- Name: booking_booking_sno_seq; Type: SEQUENCE OWNED BY; Schema: rent; Owner: postgres
--

ALTER SEQUENCE rent.booking_booking_sno_seq OWNED BY rent.booking.booking_sno;


--
-- Name: rent_bus; Type: TABLE; Schema: rent; Owner: postgres
--

CREATE TABLE rent.rent_bus (
    rent_bus_sno bigint NOT NULL,
    customer_sno bigint,
    trip_starting_date date,
    trip_end_date date,
    trip_source json,
    trip_destination json,
    trip_via json,
    is_same_route boolean,
    return_type_cd smallint,
    return_rent_bus_sno bigint,
    total_km double precision
);


ALTER TABLE rent.rent_bus OWNER TO postgres;

--
-- Name: rent_bus_rent_bus_sno_seq; Type: SEQUENCE; Schema: rent; Owner: postgres
--

CREATE SEQUENCE rent.rent_bus_rent_bus_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE rent.rent_bus_rent_bus_sno_seq OWNER TO postgres;

--
-- Name: rent_bus_rent_bus_sno_seq; Type: SEQUENCE OWNED BY; Schema: rent; Owner: postgres
--

ALTER SEQUENCE rent.rent_bus_rent_bus_sno_seq OWNED BY rent.rent_bus.rent_bus_sno;


--
-- Name: permit_route; Type: TABLE; Schema: stage_carriage; Owner: postgres
--

CREATE TABLE stage_carriage.permit_route (
    permit_route_sno bigint NOT NULL,
    source_city_sno bigint NOT NULL,
    destination_city_sno bigint NOT NULL,
    vehicle_sno bigint NOT NULL,
    active_flag boolean DEFAULT true
);


ALTER TABLE stage_carriage.permit_route OWNER TO postgres;

--
-- Name: permit_route_permit_route_sno_seq; Type: SEQUENCE; Schema: stage_carriage; Owner: postgres
--

CREATE SEQUENCE stage_carriage.permit_route_permit_route_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE stage_carriage.permit_route_permit_route_sno_seq OWNER TO postgres;

--
-- Name: permit_route_permit_route_sno_seq; Type: SEQUENCE OWNED BY; Schema: stage_carriage; Owner: postgres
--

ALTER SEQUENCE stage_carriage.permit_route_permit_route_sno_seq OWNED BY stage_carriage.permit_route.permit_route_sno;


--
-- Name: single; Type: TABLE; Schema: stage_carriage; Owner: postgres
--

CREATE TABLE stage_carriage.single (
    single_sno bigint NOT NULL,
    route_sno bigint NOT NULL,
    start_time timestamp without time zone NOT NULL,
    vehicle_sno bigint NOT NULL,
    running_mints integer NOT NULL,
    active_flag boolean DEFAULT true
);


ALTER TABLE stage_carriage.single OWNER TO postgres;

--
-- Name: single_single_sno_seq; Type: SEQUENCE; Schema: stage_carriage; Owner: postgres
--

CREATE SEQUENCE stage_carriage.single_single_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE stage_carriage.single_single_sno_seq OWNER TO postgres;

--
-- Name: single_single_sno_seq; Type: SEQUENCE OWNED BY; Schema: stage_carriage; Owner: postgres
--

ALTER SEQUENCE stage_carriage.single_single_sno_seq OWNED BY stage_carriage.single.single_sno;


--
-- Name: via; Type: TABLE; Schema: stage_carriage; Owner: postgres
--

CREATE TABLE stage_carriage.via (
    via_sno bigint NOT NULL,
    single_sno bigint NOT NULL,
    via_city_sno bigint,
    active_flag boolean DEFAULT true
);


ALTER TABLE stage_carriage.via OWNER TO postgres;

--
-- Name: via_via_sno_seq; Type: SEQUENCE; Schema: stage_carriage; Owner: postgres
--

CREATE SEQUENCE stage_carriage.via_via_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE stage_carriage.via_via_sno_seq OWNER TO postgres;

--
-- Name: via_via_sno_seq; Type: SEQUENCE OWNED BY; Schema: stage_carriage; Owner: postgres
--

ALTER SEQUENCE stage_carriage.via_via_sno_seq OWNED BY stage_carriage.via.via_sno;


--
-- Name: tyre; Type: TABLE; Schema: tyre; Owner: postgres
--

CREATE TABLE tyre.tyre (
    tyre_sno bigint NOT NULL,
    org_sno bigint,
    tyre_serial_number public.citext NOT NULL,
    tyre_type_sno bigint,
    tyre_size_sno bigint,
    tyre_price double precision,
    agency_name character varying(60),
    invoice_date timestamp without time zone,
    incoming_date timestamp without time zone,
    invoice_media bigint,
    payment_mode_cd smallint,
    is_new boolean,
    is_tread boolean,
    km_drive text,
    no_of_tread smallint,
    stock boolean DEFAULT true,
    efficiency_value smallint,
    is_running boolean DEFAULT false,
    active_flag boolean DEFAULT true,
    is_bursted boolean DEFAULT false,
    tyre_company_sno bigint,
    tyre_model text
);


ALTER TABLE tyre.tyre OWNER TO postgres;

--
-- Name: tyre_activity; Type: TABLE; Schema: tyre; Owner: postgres
--

CREATE TABLE tyre.tyre_activity (
    tyre_activity_sno bigint NOT NULL,
    tyre_sno bigint,
    vehicle_sno bigint,
    wheel_position text,
    description text,
    tyre_activity_type_cd smallint,
    odo_meter numeric,
    activity_date timestamp without time zone,
    is_running boolean DEFAULT true
);


ALTER TABLE tyre.tyre_activity OWNER TO postgres;

--
-- Name: tyre_activity_total_km; Type: TABLE; Schema: tyre; Owner: postgres
--

CREATE TABLE tyre.tyre_activity_total_km (
    tyre_activity_total_km_sno bigint NOT NULL,
    tyre_sno bigint,
    tyre_activity_type_cd smallint,
    running_km numeric,
    running_life text,
    activity_start_date timestamp without time zone,
    activity_end_date timestamp without time zone,
    tyre_activity_sno bigint
);


ALTER TABLE tyre.tyre_activity_total_km OWNER TO postgres;

--
-- Name: tyre_activity_total_km_tyre_activity_total_km_sno_seq; Type: SEQUENCE; Schema: tyre; Owner: postgres
--

CREATE SEQUENCE tyre.tyre_activity_total_km_tyre_activity_total_km_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tyre.tyre_activity_total_km_tyre_activity_total_km_sno_seq OWNER TO postgres;

--
-- Name: tyre_activity_total_km_tyre_activity_total_km_sno_seq; Type: SEQUENCE OWNED BY; Schema: tyre; Owner: postgres
--

ALTER SEQUENCE tyre.tyre_activity_total_km_tyre_activity_total_km_sno_seq OWNED BY tyre.tyre_activity_total_km.tyre_activity_total_km_sno;


--
-- Name: tyre_activity_tyre_activity_sno_seq; Type: SEQUENCE; Schema: tyre; Owner: postgres
--

CREATE SEQUENCE tyre.tyre_activity_tyre_activity_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tyre.tyre_activity_tyre_activity_sno_seq OWNER TO postgres;

--
-- Name: tyre_activity_tyre_activity_sno_seq; Type: SEQUENCE OWNED BY; Schema: tyre; Owner: postgres
--

ALTER SEQUENCE tyre.tyre_activity_tyre_activity_sno_seq OWNED BY tyre.tyre_activity.tyre_activity_sno;


--
-- Name: tyre_invoice; Type: TABLE; Schema: tyre; Owner: postgres
--

CREATE TABLE tyre.tyre_invoice (
    tyre_invoice_sno bigint NOT NULL,
    tyre_sno bigint NOT NULL,
    tyre_activity_type_cd smallint NOT NULL,
    description text,
    invoice_date timestamp without time zone NOT NULL,
    agency_name text NOT NULL,
    amount numeric NOT NULL
);


ALTER TABLE tyre.tyre_invoice OWNER TO postgres;

--
-- Name: tyre_invoice_tyre_invoice_sno_seq; Type: SEQUENCE; Schema: tyre; Owner: postgres
--

CREATE SEQUENCE tyre.tyre_invoice_tyre_invoice_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tyre.tyre_invoice_tyre_invoice_sno_seq OWNER TO postgres;

--
-- Name: tyre_invoice_tyre_invoice_sno_seq; Type: SEQUENCE OWNED BY; Schema: tyre; Owner: postgres
--

ALTER SEQUENCE tyre.tyre_invoice_tyre_invoice_sno_seq OWNED BY tyre.tyre_invoice.tyre_invoice_sno;


--
-- Name: tyre_tyre_sno_seq; Type: SEQUENCE; Schema: tyre; Owner: postgres
--

CREATE SEQUENCE tyre.tyre_tyre_sno_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tyre.tyre_tyre_sno_seq OWNER TO postgres;

--
-- Name: tyre_tyre_sno_seq; Type: SEQUENCE OWNED BY; Schema: tyre; Owner: postgres
--

ALTER SEQUENCE tyre.tyre_tyre_sno_seq OWNED BY tyre.tyre.tyre_sno;


--
-- Name: config config_sno; Type: DEFAULT; Schema: config; Owner: postgres
--

ALTER TABLE ONLY config.config ALTER COLUMN config_sno SET DEFAULT nextval('config.config_config_sno_seq'::regclass);


--
-- Name: config_key config_key_sno; Type: DEFAULT; Schema: config; Owner: postgres
--

ALTER TABLE ONLY config.config_key ALTER COLUMN config_key_sno SET DEFAULT nextval('config.config_key_config_key_sno_seq'::regclass);


--
-- Name: environment environment_sno; Type: DEFAULT; Schema: config; Owner: postgres
--

ALTER TABLE ONLY config.environment ALTER COLUMN environment_sno SET DEFAULT nextval('config.environment_environment_sno_seq'::regclass);


--
-- Name: module module_sno; Type: DEFAULT; Schema: config; Owner: postgres
--

ALTER TABLE ONLY config.module ALTER COLUMN module_sno SET DEFAULT nextval('config.module_module_sno_seq'::regclass);


--
-- Name: sub_module sub_module_sno; Type: DEFAULT; Schema: config; Owner: postgres
--

ALTER TABLE ONLY config.sub_module ALTER COLUMN sub_module_sno SET DEFAULT nextval('config.sub_module_sub_module_sno_seq'::regclass);


--
-- Name: driver driver_sno; Type: DEFAULT; Schema: driver; Owner: postgres
--

ALTER TABLE ONLY driver.driver ALTER COLUMN driver_sno SET DEFAULT nextval('driver.driver_driver_sno_seq'::regclass);


--
-- Name: driver_attendance driver_attendance_sno; Type: DEFAULT; Schema: driver; Owner: postgres
--

ALTER TABLE ONLY driver.driver_attendance ALTER COLUMN driver_attendance_sno SET DEFAULT nextval('driver.driver_attendance_driver_attendance_sno_seq'::regclass);


--
-- Name: driver_mileage driver_mileage_sno; Type: DEFAULT; Schema: driver; Owner: postgres
--

ALTER TABLE ONLY driver.driver_mileage ALTER COLUMN driver_mileage_sno SET DEFAULT nextval('driver.driver_mileage_driver_mileage_sno_seq'::regclass);


--
-- Name: driver_user driver_user_sno; Type: DEFAULT; Schema: driver; Owner: postgres
--

ALTER TABLE ONLY driver.driver_user ALTER COLUMN driver_user_sno SET DEFAULT nextval('driver.driver_user_driver_user_sno_seq'::regclass);


--
-- Name: job_post job_post_sno; Type: DEFAULT; Schema: driver; Owner: postgres
--

ALTER TABLE ONLY driver.job_post ALTER COLUMN job_post_sno SET DEFAULT nextval('driver.job_post_job_post_sno_seq'::regclass);


--
-- Name: city city_sno; Type: DEFAULT; Schema: master_data; Owner: postgres
--

ALTER TABLE ONLY master_data.city ALTER COLUMN city_sno SET DEFAULT nextval('master_data.city_city_sno_seq'::regclass);


--
-- Name: district district_sno; Type: DEFAULT; Schema: master_data; Owner: postgres
--

ALTER TABLE ONLY master_data.district ALTER COLUMN district_sno SET DEFAULT nextval('master_data.district_district_sno_seq'::regclass);


--
-- Name: route route_sno; Type: DEFAULT; Schema: master_data; Owner: postgres
--

ALTER TABLE ONLY master_data.route ALTER COLUMN route_sno SET DEFAULT nextval('master_data.route_route_sno_seq'::regclass);


--
-- Name: state state_sno; Type: DEFAULT; Schema: master_data; Owner: postgres
--

ALTER TABLE ONLY master_data.state ALTER COLUMN state_sno SET DEFAULT nextval('master_data.state_state_sno_seq'::regclass);


--
-- Name: tyre_company tyre_company_sno; Type: DEFAULT; Schema: master_data; Owner: postgres
--

ALTER TABLE ONLY master_data.tyre_company ALTER COLUMN tyre_company_sno SET DEFAULT nextval('master_data.tyre_company_tyre_company_sno_seq'::regclass);


--
-- Name: tyre_size tyre_size_sno; Type: DEFAULT; Schema: master_data; Owner: postgres
--

ALTER TABLE ONLY master_data.tyre_size ALTER COLUMN tyre_size_sno SET DEFAULT nextval('master_data.tyre_size_tyre_size_sno_seq'::regclass);


--
-- Name: tyre_type tyre_type_sno; Type: DEFAULT; Schema: master_data; Owner: postgres
--

ALTER TABLE ONLY master_data.tyre_type ALTER COLUMN tyre_type_sno SET DEFAULT nextval('master_data.tyre_type_tyre_type_sno_seq'::regclass);


--
-- Name: media media_sno; Type: DEFAULT; Schema: media; Owner: postgres
--

ALTER TABLE ONLY media.media ALTER COLUMN media_sno SET DEFAULT nextval('media.media_media_sno_seq'::regclass);


--
-- Name: media_detail media_detail_sno; Type: DEFAULT; Schema: media; Owner: postgres
--

ALTER TABLE ONLY media.media_detail ALTER COLUMN media_detail_sno SET DEFAULT nextval('media.media_detail_media_detail_sno_seq'::regclass);


--
-- Name: notification notification_sno; Type: DEFAULT; Schema: notification; Owner: postgres
--

ALTER TABLE ONLY notification.notification ALTER COLUMN notification_sno SET DEFAULT nextval('notification.notification_notification_sno_seq'::regclass);


--
-- Name: address address_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.address ALTER COLUMN address_sno SET DEFAULT nextval('operator.address_address_sno_seq'::regclass);


--
-- Name: bank_account_detail bank_account_detail_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.bank_account_detail ALTER COLUMN bank_account_detail_sno SET DEFAULT nextval('operator.bank_account_detail_bank_account_detail_sno_seq'::regclass);


--
-- Name: bunk bunk_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.bunk ALTER COLUMN bunk_sno SET DEFAULT nextval('operator.bunk_bunk_sno_seq'::regclass);


--
-- Name: bus_report bus_report_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.bus_report ALTER COLUMN bus_report_sno SET DEFAULT nextval('operator.bus_report_bus_report_sno_seq'::regclass);


--
-- Name: fuel fuel_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.fuel ALTER COLUMN fuel_sno SET DEFAULT nextval('operator.fuel_fuel_sno_seq'::regclass);


--
-- Name: operator_driver operator_driver_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.operator_driver ALTER COLUMN operator_driver_sno SET DEFAULT nextval('operator.operator_driver_operator_driver_sno_seq'::regclass);


--
-- Name: operator_route operator_route_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.operator_route ALTER COLUMN operator_route_sno SET DEFAULT nextval('operator.operator_route_operator_route_sno_seq'::regclass);


--
-- Name: org org_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org ALTER COLUMN org_sno SET DEFAULT nextval('operator.org_org_sno_seq'::regclass);


--
-- Name: org_contact org_contact_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org_contact ALTER COLUMN org_contact_sno SET DEFAULT nextval('operator.org_contact_org_contact_sno_seq'::regclass);


--
-- Name: org_detail org_detail_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org_detail ALTER COLUMN org_detail_sno SET DEFAULT nextval('operator.org_detail_org_detail_sno_seq'::regclass);


--
-- Name: org_owner org_owner_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org_owner ALTER COLUMN org_owner_sno SET DEFAULT nextval('operator.org_owner_org_owner_sno_seq'::regclass);


--
-- Name: org_social_link org_social_link_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org_social_link ALTER COLUMN org_social_link_sno SET DEFAULT nextval('operator.org_social_link_org_social_link_sno_seq'::regclass);


--
-- Name: org_user org_user_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org_user ALTER COLUMN org_user_sno SET DEFAULT nextval('operator.org_user_org_user_sno_seq'::regclass);


--
-- Name: org_vehicle org_vehicle_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org_vehicle ALTER COLUMN org_vehicle_sno SET DEFAULT nextval('operator.org_vehicle_org_vehicle_sno_seq'::regclass);


--
-- Name: reject_reason reject_reason_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.reject_reason ALTER COLUMN reject_reason_sno SET DEFAULT nextval('operator.reject_reason_reject_reason_sno_seq'::regclass);


--
-- Name: single_route single_route_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.single_route ALTER COLUMN single_route_sno SET DEFAULT nextval('operator.single_route_single_route_sno_seq'::regclass);


--
-- Name: toll_pass_detail toll_pass_detail_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.toll_pass_detail ALTER COLUMN toll_pass_detail_sno SET DEFAULT nextval('operator.toll_pass_detail_toll_pass_detail_sno_seq'::regclass);


--
-- Name: trip trip_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.trip ALTER COLUMN trip_sno SET DEFAULT nextval('operator.trip_trip_sno_seq'::regclass);


--
-- Name: trip_route trip_route_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.trip_route ALTER COLUMN trip_route_sno SET DEFAULT nextval('operator.trip_route_trip_route_sno_seq'::regclass);


--
-- Name: vehicle vehicle_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle ALTER COLUMN vehicle_sno SET DEFAULT nextval('operator.vehicle_vehicle_sno_seq'::regclass);


--
-- Name: vehicle_detail vehicle_detail_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle_detail ALTER COLUMN vehicle_detail_sno SET DEFAULT nextval('operator.vehicle_detail_vehicle_detail_sno_seq'::regclass);


--
-- Name: vehicle_driver vehicle_driver_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle_driver ALTER COLUMN vehicle_driver_sno SET DEFAULT nextval('operator.vehicle_driver_vehicle_driver_sno_seq'::regclass);


--
-- Name: vehicle_due_fixed_pay vehicle_due_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle_due_fixed_pay ALTER COLUMN vehicle_due_sno SET DEFAULT nextval('operator.vehicle_due_fixed_pay_vehicle_due_sno_seq'::regclass);


--
-- Name: vehicle_due_variable_pay vehicle_due_variable_pay_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle_due_variable_pay ALTER COLUMN vehicle_due_variable_pay_sno SET DEFAULT nextval('operator.vehicle_due_variable_pay_vehicle_due_variable_pay_sno_seq'::regclass);


--
-- Name: vehicle_owner vehicle_owner_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle_owner ALTER COLUMN vehicle_owner_sno SET DEFAULT nextval('operator.vehicle_owner_vehicle_owner_sno_seq'::regclass);


--
-- Name: vehicle_route vehicle_route_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle_route ALTER COLUMN vehicle_route_sno SET DEFAULT nextval('operator.vehicle_route_vehicle_route_sno_seq'::regclass);


--
-- Name: via via_sno; Type: DEFAULT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.via ALTER COLUMN via_sno SET DEFAULT nextval('operator.via_via_sno_seq'::regclass);


--
-- Name: app_menu app_menu_sno; Type: DEFAULT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.app_menu ALTER COLUMN app_menu_sno SET DEFAULT nextval('portal.app_menu_app_menu_sno_seq'::regclass);


--
-- Name: app_menu_role app_menu_role_sno; Type: DEFAULT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.app_menu_role ALTER COLUMN app_menu_role_sno SET DEFAULT nextval('portal.app_menu_role_app_menu_role_sno_seq'::regclass);


--
-- Name: app_menu_user app_menu_user_sno; Type: DEFAULT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.app_menu_user ALTER COLUMN app_menu_user_sno SET DEFAULT nextval('portal.app_menu_user_app_menu_user_sno_seq'::regclass);


--
-- Name: app_user app_user_sno; Type: DEFAULT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.app_user ALTER COLUMN app_user_sno SET DEFAULT nextval('portal.app_user_app_user_sno_seq'::regclass);


--
-- Name: app_user_contact app_user_contact_sno; Type: DEFAULT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.app_user_contact ALTER COLUMN app_user_contact_sno SET DEFAULT nextval('portal.app_user_contact_app_user_contact_sno_seq'::regclass);


--
-- Name: app_user_role app_user_role_sno; Type: DEFAULT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.app_user_role ALTER COLUMN app_user_role_sno SET DEFAULT nextval('portal.app_user_role_app_user_role_sno_seq'::regclass);


--
-- Name: codes_dtl codes_dtl_sno; Type: DEFAULT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.codes_dtl ALTER COLUMN codes_dtl_sno SET DEFAULT nextval('portal.codes_dtl_codes_dtl_sno_seq'::regclass);


--
-- Name: codes_hdr codes_hdr_sno; Type: DEFAULT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.codes_hdr ALTER COLUMN codes_hdr_sno SET DEFAULT nextval('portal.codes_hdr_codes_hdr_sno_seq'::regclass);


--
-- Name: contact contact_sno; Type: DEFAULT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.contact ALTER COLUMN contact_sno SET DEFAULT nextval('portal.contact_contact_sno_seq'::regclass);


--
-- Name: otp otp_sno; Type: DEFAULT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.otp ALTER COLUMN otp_sno SET DEFAULT nextval('portal.otp_otp_sno_seq'::regclass);


--
-- Name: signin_config signin_config_sno; Type: DEFAULT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.signin_config ALTER COLUMN signin_config_sno SET DEFAULT nextval('portal.signin_config_signin_config_sno_seq'::regclass);


--
-- Name: social_link social_link_sno; Type: DEFAULT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.social_link ALTER COLUMN social_link_sno SET DEFAULT nextval('portal.social_link_social_link_sno_seq'::regclass);


--
-- Name: user_profile user_profile_sno; Type: DEFAULT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.user_profile ALTER COLUMN user_profile_sno SET DEFAULT nextval('portal.user_profile_user_profile_sno_seq'::regclass);


--
-- Name: booking booking_sno; Type: DEFAULT; Schema: rent; Owner: postgres
--

ALTER TABLE ONLY rent.booking ALTER COLUMN booking_sno SET DEFAULT nextval('rent.booking_booking_sno_seq'::regclass);


--
-- Name: rent_bus rent_bus_sno; Type: DEFAULT; Schema: rent; Owner: postgres
--

ALTER TABLE ONLY rent.rent_bus ALTER COLUMN rent_bus_sno SET DEFAULT nextval('rent.rent_bus_rent_bus_sno_seq'::regclass);


--
-- Name: permit_route permit_route_sno; Type: DEFAULT; Schema: stage_carriage; Owner: postgres
--

ALTER TABLE ONLY stage_carriage.permit_route ALTER COLUMN permit_route_sno SET DEFAULT nextval('stage_carriage.permit_route_permit_route_sno_seq'::regclass);


--
-- Name: single single_sno; Type: DEFAULT; Schema: stage_carriage; Owner: postgres
--

ALTER TABLE ONLY stage_carriage.single ALTER COLUMN single_sno SET DEFAULT nextval('stage_carriage.single_single_sno_seq'::regclass);


--
-- Name: via via_sno; Type: DEFAULT; Schema: stage_carriage; Owner: postgres
--

ALTER TABLE ONLY stage_carriage.via ALTER COLUMN via_sno SET DEFAULT nextval('stage_carriage.via_via_sno_seq'::regclass);


--
-- Name: tyre tyre_sno; Type: DEFAULT; Schema: tyre; Owner: postgres
--

ALTER TABLE ONLY tyre.tyre ALTER COLUMN tyre_sno SET DEFAULT nextval('tyre.tyre_tyre_sno_seq'::regclass);


--
-- Name: tyre_activity tyre_activity_sno; Type: DEFAULT; Schema: tyre; Owner: postgres
--

ALTER TABLE ONLY tyre.tyre_activity ALTER COLUMN tyre_activity_sno SET DEFAULT nextval('tyre.tyre_activity_tyre_activity_sno_seq'::regclass);


--
-- Name: tyre_activity_total_km tyre_activity_total_km_sno; Type: DEFAULT; Schema: tyre; Owner: postgres
--

ALTER TABLE ONLY tyre.tyre_activity_total_km ALTER COLUMN tyre_activity_total_km_sno SET DEFAULT nextval('tyre.tyre_activity_total_km_tyre_activity_total_km_sno_seq'::regclass);


--
-- Name: tyre_invoice tyre_invoice_sno; Type: DEFAULT; Schema: tyre; Owner: postgres
--

ALTER TABLE ONLY tyre.tyre_invoice ALTER COLUMN tyre_invoice_sno SET DEFAULT nextval('tyre.tyre_invoice_tyre_invoice_sno_seq'::regclass);


--
-- Data for Name: config; Type: TABLE DATA; Schema: config; Owner: postgres
--

COPY config.config (config_sno, environment_sno, module_sno, sub_module_sno, config_value, config_key_sno) FROM stdin;
1	1	1	1	portal	1
2	1	1	1	application/json;charset=utf-8	2
3	1	1	1	*	3
4	1	1	1	8080	4
5	1	1	1	8052	5
6	1	1	1	./src/main/resources/yInhUOEDMv2PZqJWc2j3id0tZVYD3vBt.key	6
7	1	1	1	EzvxzEy7/EGAEgV728ADN2le3hTuNuNSmJdnGlJMztY0pWQNb0C4pg==	7
8	1	1	1	JCEKS	8
9	1	1	1	AES	9
10	1	1	1	1maRuaJV8JApV07CyhDnbA1zpy/cQixHs91aClA1pCk0pWQNb0C4pg==	10
11	1	1	1	3xCsKXY9E/8QI1Db7z8Xrex4IMuHhvJfhfeZ+McwTSY0pWQNb0C4pg==	11
12	1	1	1	5432	12
13	1	1	1	localhost	13
14	1	1	1	bus_db	14
15	1	1	1	bus_admin	15
16	1	1	1	bus123	16
17	1	1	1	2000	17
18	1	1	1	AAAA_vArJw0:APA91bG-EhDsfDdv7m_o3RXI1-2eBegndpW1sI-OdOqULO31k7MkilW_o4DnlDfMOA3sfPMlTBvKz0Ysx6v1-_v_BQmZwQAKCO6T3ZovWVDYPdGu-59WWdHshH2VW3ADdkjnWxKb862C	18
19	1	1	2	operator	1
20	1	1	2	application/json;charset=utf-8	2
21	1	1	2	*	3
22	1	1	2	8080	4
23	1	1	2	8053	5
24	1	1	2	./src/main/resources/yInhUOEDMv2PZqJWc2j3id0tZVYD3vBt.key	6
25	1	1	2	EzvxzEy7/EGAEgV728ADN2le3hTuNuNSmJdnGlJMztY0pWQNb0C4pg==	7
26	1	1	2	JCEKS	8
27	1	1	2	AES	9
28	1	1	2	1maRuaJV8JApV07CyhDnbA1zpy/cQixHs91aClA1pCk0pWQNb0C4pg==	10
29	1	1	2	3xCsKXY9E/8QI1Db7z8Xrex4IMuHhvJfhfeZ+McwTSY0pWQNb0C4pg==	11
30	1	1	2	5432	12
31	1	1	2	localhost	13
32	1	1	2	bus_db	14
33	1	1	2	bus_admin	15
34	1	1	2	bus123	16
35	1	1	2	2000	17
36	1	1	2	AAAA_vArJw0:APA91bG-EhDsfDdv7m_o3RXI1-2eBegndpW1sI-OdOqULO31k7MkilW_o4DnlDfMOA3sfPMlTBvKz0Ysx6v1-_v_BQmZwQAKCO6T3ZovWVDYPdGu-59WWdHshH2VW3ADdkjnWxKb862C	18
37	1	1	3	master	1
38	1	1	3	application/json;charset=utf-8	2
39	1	1	3	*	3
40	1	1	3	8080	4
41	1	1	3	8054	5
42	1	1	3	./src/main/resources/yInhUOEDMv2PZqJWc2j3id0tZVYD3vBt.key	6
43	1	1	3	EzvxzEy7/EGAEgV728ADN2le3hTuNuNSmJdnGlJMztY0pWQNb0C4pg==	7
44	1	1	3	JCEKS	8
45	1	1	3	AES	9
46	1	1	3	1maRuaJV8JApV07CyhDnbA1zpy/cQixHs91aClA1pCk0pWQNb0C4pg==	10
47	1	1	3	3xCsKXY9E/8QI1Db7z8Xrex4IMuHhvJfhfeZ+McwTSY0pWQNb0C4pg==	11
48	1	1	3	5432	12
49	1	1	3	localhost	13
50	1	1	3	bus_db	14
51	1	1	3	bus_admin	15
52	1	1	3	bus123	16
53	1	1	3	2000	17
54	1	1	3	AAAA_vArJw0:APA91bG-EhDsfDdv7m_o3RXI1-2eBegndpW1sI-OdOqULO31k7MkilW_o4DnlDfMOA3sfPMlTBvKz0Ysx6v1-_v_BQmZwQAKCO6T3ZovWVDYPdGu-59WWdHshH2VW3ADdkjnWxKb862C	18
55	1	1	4	driver	1
56	1	1	4	application/json;charset=utf-8	2
57	1	1	4	*	3
58	1	1	4	8080	4
59	1	1	4	8055	5
60	1	1	4	./src/main/resources/yInhUOEDMv2PZqJWc2j3id0tZVYD3vBt.key	6
61	1	1	4	EzvxzEy7/EGAEgV728ADN2le3hTuNuNSmJdnGlJMztY0pWQNb0C4pg==	7
62	1	1	4	JCEKS	8
63	1	1	4	AES	9
64	1	1	4	1maRuaJV8JApV07CyhDnbA1zpy/cQixHs91aClA1pCk0pWQNb0C4pg==	10
65	1	1	4	3xCsKXY9E/8QI1Db7z8Xrex4IMuHhvJfhfeZ+McwTSY0pWQNb0C4pg==	11
66	1	1	4	5432	12
67	1	1	4	localhost	13
68	1	1	4	bus_db	14
69	1	1	4	bus_admin	15
70	1	1	4	bus123	16
71	1	1	4	2000	17
72	1	1	4	AAAA_vArJw0:APA91bG-EhDsfDdv7m_o3RXI1-2eBegndpW1sI-OdOqULO31k7MkilW_o4DnlDfMOA3sfPMlTBvKz0Ysx6v1-_v_BQmZwQAKCO6T3ZovWVDYPdGu-59WWdHshH2VW3ADdkjnWxKb862C	18
73	1	1	5	notification	1
74	1	1	5	application/json;charset=utf-8	2
75	1	1	5	*	3
76	1	1	5	8080	4
77	1	1	5	8056	5
78	1	1	5	./src/main/resources/yInhUOEDMv2PZqJWc2j3id0tZVYD3vBt.key	6
79	1	1	5	EzvxzEy7/EGAEgV728ADN2le3hTuNuNSmJdnGlJMztY0pWQNb0C4pg==	7
80	1	1	5	JCEKS	8
81	1	1	5	AES	9
82	1	1	5	1maRuaJV8JApV07CyhDnbA1zpy/cQixHs91aClA1pCk0pWQNb0C4pg==	10
83	1	1	5	3xCsKXY9E/8QI1Db7z8Xrex4IMuHhvJfhfeZ+McwTSY0pWQNb0C4pg==	11
84	1	1	5	5432	12
85	1	1	5	localhost	13
86	1	1	5	bus_db	14
87	1	1	5	bus_admin	15
88	1	1	5	bus123	16
89	1	1	5	2000	17
90	1	1	5	AAAA_vArJw0:APA91bG-EhDsfDdv7m_o3RXI1-2eBegndpW1sI-OdOqULO31k7MkilW_o4DnlDfMOA3sfPMlTBvKz0Ysx6v1-_v_BQmZwQAKCO6T3ZovWVDYPdGu-59WWdHshH2VW3ADdkjnWxKb862C	18
91	1	1	6	cron	1
92	1	1	6	application/json;charset=utf-8	2
93	1	1	6	*	3
94	1	1	6	8080	4
95	1	1	6	8057	5
96	1	1	6	./src/main/resources/yInhUOEDMv2PZqJWc2j3id0tZVYD3vBt.key	6
97	1	1	6	EzvxzEy7/EGAEgV728ADN2le3hTuNuNSmJdnGlJMztY0pWQNb0C4pg==	7
98	1	1	6	JCEKS	8
99	1	1	6	AES	9
100	1	1	6	1maRuaJV8JApV07CyhDnbA1zpy/cQixHs91aClA1pCk0pWQNb0C4pg==	10
101	1	1	6	3xCsKXY9E/8QI1Db7z8Xrex4IMuHhvJfhfeZ+McwTSY0pWQNb0C4pg==	11
102	1	1	6	5432	12
103	1	1	6	localhost	13
104	1	1	6	bus_db	14
105	1	1	6	bus_admin	15
106	1	1	6	bus123	16
107	1	1	6	2000	17
108	1	1	6	AAAA_vArJw0:APA91bG-EhDsfDdv7m_o3RXI1-2eBegndpW1sI-OdOqULO31k7MkilW_o4DnlDfMOA3sfPMlTBvKz0Ysx6v1-_v_BQmZwQAKCO6T3ZovWVDYPdGu-59WWdHshH2VW3ADdkjnWxKb862C	18
109	1	1	7	rent	1
110	1	1	7	application/json;charset=utf-8	2
111	1	1	7	*	3
112	1	1	7	8080	4
113	1	1	7	8058	5
114	1	1	7	./src/main/resources/yInhUOEDMv2PZqJWc2j3id0tZVYD3vBt.key	6
115	1	1	7	EzvxzEy7/EGAEgV728ADN2le3hTuNuNSmJdnGlJMztY0pWQNb0C4pg==	7
116	1	1	7	JCEKS	8
117	1	1	7	AES	9
118	1	1	7	1maRuaJV8JApV07CyhDnbA1zpy/cQixHs91aClA1pCk0pWQNb0C4pg==	10
119	1	1	7	3xCsKXY9E/8QI1Db7z8Xrex4IMuHhvJfhfeZ+McwTSY0pWQNb0C4pg==	11
120	1	1	7	5432	12
121	1	1	7	localhost	13
122	1	1	7	bus_db	14
123	1	1	7	bus_admin	15
124	1	1	7	bus123	16
125	1	1	7	2000	17
126	1	1	7	AAAA_vArJw0:APA91bG-EhDsfDdv7m_o3RXI1-2eBegndpW1sI-OdOqULO31k7MkilW_o4DnlDfMOA3sfPMlTBvKz0Ysx6v1-_v_BQmZwQAKCO6T3ZovWVDYPdGu-59WWdHshH2VW3ADdkjnWxKb862C	18
127	1	1	8	media	1
128	1	1	8	application/json;charset=utf-8	2
129	1	1	8	*	3
130	1	1	8	8080	4
131	1	1	8	8059	5
132	1	1	8	./src/main/resources/yInhUOEDMv2PZqJWc2j3id0tZVYD3vBt.key	6
133	1	1	8	EzvxzEy7/EGAEgV728ADN2le3hTuNuNSmJdnGlJMztY0pWQNb0C4pg==	7
134	1	1	8	JCEKS	8
135	1	1	8	AES	9
136	1	1	8	1maRuaJV8JApV07CyhDnbA1zpy/cQixHs91aClA1pCk0pWQNb0C4pg==	10
137	1	1	8	3xCsKXY9E/8QI1Db7z8Xrex4IMuHhvJfhfeZ+McwTSY0pWQNb0C4pg==	11
138	1	1	8	5432	12
139	1	1	8	localhost	13
140	1	1	8	bus_db	14
141	1	1	8	bus_admin	15
142	1	1	8	bus123	16
143	1	1	8	2000	17
144	1	1	8	AAAA_vArJw0:APA91bG-EhDsfDdv7m_o3RXI1-2eBegndpW1sI-OdOqULO31k7MkilW_o4DnlDfMOA3sfPMlTBvKz0Ysx6v1-_v_BQmZwQAKCO6T3ZovWVDYPdGu-59WWdHshH2VW3ADdkjnWxKb862C	18
145	1	1	9	tyre	1
146	1	1	9	application/json;charset=utf-8	2
147	1	1	9	*	3
148	1	1	9	8080	4
149	1	1	9	8060	5
150	1	1	9	./src/main/resources/yInhUOEDMv2PZqJWc2j3id0tZVYD3vBt.key	6
151	1	1	9	EzvxzEy7/EGAEgV728ADN2le3hTuNuNSmJdnGlJMztY0pWQNb0C4pg==	7
152	1	1	9	JCEKS	8
153	1	1	9	AES	9
154	1	1	9	1maRuaJV8JApV07CyhDnbA1zpy/cQixHs91aClA1pCk0pWQNb0C4pg==	10
155	1	1	9	3xCsKXY9E/8QI1Db7z8Xrex4IMuHhvJfhfeZ+McwTSY0pWQNb0C4pg==	11
156	1	1	9	5432	12
157	1	1	9	localhost	13
158	1	1	9	bus_db	14
159	1	1	9	bus_admin	15
160	1	1	9	bus123	16
161	1	1	9	2000	17
162	1	1	9	AAAA_vArJw0:APA91bG-EhDsfDdv7m_o3RXI1-2eBegndpW1sI-OdOqULO31k7MkilW_o4DnlDfMOA3sfPMlTBvKz0Ysx6v1-_v_BQmZwQAKCO6T3ZovWVDYPdGu-59WWdHshH2VW3ADdkjnWxKb862C	18
\.


--
-- Data for Name: config_key; Type: TABLE DATA; Schema: config; Owner: postgres
--

COPY config.config_key (config_key_sno, config_key_attribute, encrypt_type_cd) FROM stdin;
1	db.schema.key	\N
2	content.type	\N
3	access.control.allow.origin	\N
4	server.port	\N
5	http.port.no	\N
6	master.key.file.name	\N
7	keystore.file.name	\N
8	keystore.type	\N
9	cryptography.algorithm	\N
10	file.key.password	\N
11	file.key.alias.name	\N
12	db.port.no	\N
13	db.host	\N
14	database.name	\N
15	db.user.name	\N
16	db.password	\N
17	db.conn.pool.size	\N
18	push.server.key	\N
\.


--
-- Data for Name: environment; Type: TABLE DATA; Schema: config; Owner: postgres
--

COPY config.environment (environment_sno, environment_name) FROM stdin;
1	local
2	development
3	testing
4	staging
5	production
\.


--
-- Data for Name: module; Type: TABLE DATA; Schema: config; Owner: postgres
--

COPY config.module (module_sno, environment_sno, module_name) FROM stdin;
1	1	bustoday
\.


--
-- Data for Name: sub_module; Type: TABLE DATA; Schema: config; Owner: postgres
--

COPY config.sub_module (sub_module_sno, module_sno, sub_module_name) FROM stdin;
1	1	portal
2	1	operator
3	1	master
4	1	driver
5	1	notification
6	1	cron
7	1	rent
8	1	media
9	1	tyre
\.


--
-- Data for Name: driver; Type: TABLE DATA; Schema: driver; Owner: postgres
--

COPY driver.driver (driver_sno, driver_name, driver_mobile_number, driver_whatsapp_number, dob, father_name, address, current_address, current_district, blood_group_cd, media_sno, certificate_sno, certificate_description, licence_number, licence_expiry_date, transport_licence_expiry_date, driving_licence_type, active_flag, kyc_status, reject_reason, licence_front_sno, licence_back_sno) FROM stdin;
11	RAMESH  M	9486761731	9486761731	1976-03-23 00:00:00	MARIAPPAN	Four Roads, Salem - 63604		23	\N	54	\N	\N	TN27 19950000461	2025-05-23 00:00:00	2025-09-18 00:00:00	{52,51,53,54,55}	t	19	\N	55	56
3	SIVAKUMAR V	9751257799	9751257799	1979-07-16 00:00:00	VELUSAMY C			8	84	10	\N	\N	TN57Z20090000848	2029-04-15 00:00:00	2025-01-29 00:00:00	{52,51}	t	19	\N	8	9
12	CHINNADURAI T	9940837464	9940837464	1984-08-19 00:00:00	THANGARAJU	Sankari, Salem - 637102	\N	23	84	57	\N	\N	TN27V20060001088	2026-06-18 00:00:00	2026-10-05 00:00:00	{51,52,53,54,55}	t	19	\N	58	59
4	RAJENDRAN  K	9442308634		1965-04-06 00:00:00	KARUPPAIAH			23	88	14	\N	\N	TN27 19850005345	2025-10-29 00:00:00	2026-10-21 00:00:00	{51,52,53,54,55}	t	19	\N	12	13
13	DHANASEKAR L	9345473146	9345473146	2000-07-14 00:00:00	\N	Muthunaickenpatti, Omalur TK, SALEM - 636304	\N	23	84	60	\N	\N	TN30W20210003464	2040-07-13 00:00:00	2026-10-24 00:00:00	{52,51,53,54,55}	t	19	\N	61	62
5	SENTHILKUMAR K	7373352522	7373352522	1985-07-24 00:00:00	A KANDASWAMY	Erode	Erode	8	88	18	\N	\N	TN33 20030005140	2033-12-07 00:00:00	2025-02-18 00:00:00	{51,52,53,54,55}	t	19	\N	16	17
6	SENTHILPRABHU  G	8508665808	8508665808	1980-07-28 00:00:00	B GOVINDHAN			23	84	19	\N	\N	TN33 19990003528	2030-07-27 00:00:00	2026-09-27 00:00:00	{52,51,53,54,55}	t	19	\N	20	21
7	DINESH V	9080483332	9080483332	1993-07-05 00:00:00	VADIVEL			23	86	22	\N	\N	TN52 20110003227	2031-10-17 00:00:00	2025-06-09 00:00:00	{52,53,54,55}	t	19	\N	23	24
14	SARAVANAKUMAR  K	9865952527	9865952527	1976-07-22 00:00:00	KANDASAMY S P	Bhavani Road, Anthiyur TK, ERODE - 638501		8	84	63	\N	\N	TN36 19970002099	2026-07-21 00:00:00	2025-08-30 00:00:00	{52,51,53,54,55}	t	19	\N	64	65
15	SURESH  P	6379090633	6379090633	1990-06-06 00:00:00	PERUMAL	1/67 Godalpatti Vil Kalappampadi PO Pennagaram TK Dharmapuri DT - 636811		6	84	66	\N	\N	TN29 20080003967	2034-03-09 00:00:00	2024-09-23 00:00:00	{52,53,54,55}	t	19	\N	67	68
9	PRAKASH  T	9080111923	9080111923	1993-01-09 00:00:00	THANGAVEL			23	84	29	\N	\N	TN52 20120002057	2032-05-24 00:00:00	2027-09-06 00:00:00	{52,51,53,54,55}	t	19	\N	30	31
2	SRIRAM JAWAHAR A	6383864180	6383864180	1998-05-01 00:00:00			Sholinganallur, Chennai, Tamil Nadu 600119, India	\N	\N	43	\N	\N	TN84 20210003389	2038-04-30 00:00:00	\N	{51}	t	19	\N	44	45
8	BOOPATHIRAJA  A	8248323364	8248323364	1993-06-10 00:00:00	ALAGESAN P			8	84	50	\N	\N	TN28 20130002567	2033-04-09 00:00:00	2025-03-02 00:00:00	{52,53,54,51,55}	t	19	\N	26	27
1	subash	9788404744	\N	1993-08-09 00:00:00	saravanan	\N	\N	28	84	\N	\N	\N	TN602012343545435	2026-06-01 00:00:00	2025-11-18 00:00:00	{51,53,54}	t	58	Test	\N	\N
10	THANGAVEL S	7598735439	7598735439	1964-07-10 00:00:00	Sanjeevan	Edappadi	\N	23	88	51	\N	\N	TN27V19840001432	2024-11-23 00:00:00	2025-11-23 00:00:00	{51,52,53,54,55}	t	19	\N	52	53
\.


--
-- Data for Name: driver_attendance; Type: TABLE DATA; Schema: driver; Owner: postgres
--

COPY driver.driver_attendance (driver_attendance_sno, driver_sno, vehicle_sno, start_lat_long, end_lat_long, start_media, end_media, start_time, end_time, start_value, end_value, attendance_status_cd, active_flag, accept_status, is_calculated, report_id) FROM stdin;
1	2	2	\N	\N	\N	\N	2024-04-08 11:19:16	\N	3200	\N	28	t	f	f	\N
2	9	4	\N	\N	\N	\N	2024-04-27 14:22:04	2024-04-27 14:22:20	300000	300450	29	t	t	f	\N
3	10	7	\N	\N	\N	\N	2024-05-31 09:30:00	2024-06-01 10:30:00	34067	34627	29	t	t	t	3
28	14	4	\N	\N	\N	\N	2024-06-01 13:05:00	2024-06-02 13:05:00	563152	563578	29	t	t	t	3
8	9	7	\N	\N	\N	\N	2024-06-01 10:30:00	2024-06-02 10:30:00	34627	35327	29	t	t	t	4
9	8	7	\N	\N	\N	\N	2024-06-02 10:30:00	2024-06-03 10:30:00	35327	36032	29	t	t	t	5
43	14	4	\N	\N	\N	\N	2024-06-18 13:05:00	2024-06-19 13:05:00	570325	570748	29	t	t	t	18
10	10	7	\N	\N	\N	\N	2024-06-03 10:30:00	2024-06-04 10:30:00	36032	36739	29	t	t	t	6
29	11	4	\N	\N	\N	\N	2024-06-02 13:05:00	2024-06-03 13:05:00	563578	564138	29	t	t	t	4
11	9	7	\N	\N	\N	\N	2024-06-04 10:30:00	2024-06-05 10:30:00	36739	37448	29	t	t	t	7
12	10	7	\N	\N	\N	\N	2024-06-05 10:30:00	2024-06-06 10:30:00	36739	37448	29	t	t	t	8
13	8	7	\N	\N	\N	\N	2024-06-06 10:30:00	2024-06-07 10:30:00	37448	38170	29	t	t	t	9
30	12	4	\N	\N	\N	\N	2024-06-03 13:05:00	2024-06-04 13:05:00	564138	564564	29	t	t	t	5
14	10	7	\N	\N	\N	\N	2024-06-07 10:30:00	2024-06-07 10:30:00	38870	39578	29	t	t	t	10
15	9	7	\N	\N	\N	\N	2024-06-08 10:30:00	2024-06-09 10:30:00	39578	40283	29	t	t	t	11
16	8	7	\N	\N	\N	\N	2024-06-09 10:30:00	2024-06-10 10:30:00	40283	40990	29	t	t	t	12
31	6	4	\N	\N	\N	\N	2024-06-04 13:05:00	2024-06-05 13:05:00	564564	564990	29	t	t	t	6
17	9	7	\N	\N	\N	\N	2024-06-10 10:30:00	2024-06-11 10:30:00	40950	41689	29	t	t	t	13
18	10	7	\N	\N	\N	\N	2024-06-11 10:30:00	2024-06-12 10:30:00	41689	42395	29	t	t	t	14
44	11	4	\N	\N	\N	\N	2024-06-19 13:05:00	2024-06-20 13:05:00	570748	571171	29	t	t	t	19
19	9	7	\N	\N	\N	\N	2024-06-12 10:30:00	2024-06-13 10:30:00	42395	43102	29	t	t	t	15
32	12	4	\N	\N	\N	\N	2024-06-05 13:05:00	2024-06-06 13:05:00	564990	565427	29	t	t	t	7
20	10	7	\N	\N	\N	\N	2024-06-13 10:30:00	2024-06-14 10:30:00	43102	43691	29	t	t	t	16
21	9	7	\N	\N	\N	\N	2024-06-14 10:30:00	2024-06-15 10:30:00	43691	44402	29	t	t	t	17
22	10	7	\N	\N	\N	\N	2024-06-15 10:30:00	2024-06-16 10:30:00	44402	45107	29	t	t	t	18
33	6	4	\N	\N	\N	\N	2024-06-06 13:05:00	2024-06-07 13:05:00	565427	565853	29	t	t	t	8
23	9	7	\N	\N	\N	\N	2024-06-16 10:30:00	2024-06-17 10:30:00	45107	45817	29	t	t	t	19
24	10	7	\N	\N	\N	\N	2024-06-17 10:30:00	2024-06-18 10:30:00	45817	46523	29	t	t	t	20
53	11	5	\N	\N	\N	\N	2024-06-08 11:30:00	2024-06-09 11:30:00	611525	611945	29	t	t	t	32
25	9	7	\N	\N	\N	\N	2024-06-18 10:30:00	2024-06-19 10:30:00	46523	47232	29	t	t	t	21
34	12	4	\N	\N	\N	\N	2024-06-07 13:05:00	2024-06-08 13:05:00	565853	566279	29	t	t	t	9
26	10	7	\N	\N	\N	\N	2024-06-19 10:30:00	2024-06-20 10:30:00	47232	47939	29	t	t	t	22
27	12	4	\N	\N	\N	\N	2024-05-31 13:05:00	2024-06-01 13:05:00	562717	563152	29	t	t	t	2
45	4	5	\N	\N	\N	\N	2024-05-31 11:30:00	2024-06-01 11:30:00	608259	608683	29	t	t	t	24
35	14	4	\N	\N	\N	\N	2024-06-08 13:05:00	2024-06-09 13:05:00	566279	566716	29	t	t	t	10
36	13	4	\N	\N	\N	\N	2024-06-09 13:05:00	2024-06-10 13:05:00	566716	567407	29	t	t	t	11
37	14	4	\N	\N	\N	\N	2024-06-10 13:05:00	2024-06-11 13:05:00	567407	567756	29	t	t	t	12
46	7	5	\N	\N	\N	\N	2024-06-01 10:30:00	2024-06-02 11:30:00	608683	609108	29	t	t	t	25
38	13	4	\N	\N	\N	\N	2024-06-11 13:05:00	2024-06-12 13:05:00	567756	568057	29	t	t	t	13
39	11	4	\N	\N	\N	\N	2024-06-12 13:05:00	2024-06-13 13:05:00	568057	568480	29	t	t	t	14
59	4	5	\N	\N	\N	\N	2024-06-14 11:30:00	2024-06-15 11:30:00	614073	614499	29	t	t	t	38
40	7	4	\N	\N	\N	\N	2024-06-13 13:05:00	2024-06-14 13:06:00	568480	568903	29	t	t	t	15
47	4	5	\N	\N	\N	\N	2024-06-02 11:30:00	2024-06-03 11:30:00	609108	609532	29	t	t	t	26
41	14	4	\N	\N	\N	\N	2024-06-14 13:05:00	2024-06-15 13:05:00	568903	569327	29	t	t	t	16
42	14	4	\N	\N	\N	\N	2024-06-15 13:05:00	2024-06-16 13:05:00	569327	569748	29	t	t	t	17
54	5	5	\N	\N	\N	\N	2024-06-09 11:30:00	2024-06-10 11:30:00	611945	612369	29	t	t	t	33
48	7	5	\N	\N	\N	\N	2024-06-03 11:30:00	2024-06-04 11:30:00	609532	609957	29	t	t	t	27
49	14	5	\N	\N	\N	\N	2024-06-04 11:30:00	2024-06-05 11:30:00	609957	610382	29	t	t	t	28
50	11	5	\N	\N	\N	\N	2024-06-05 11:30:00	2024-06-06 11:30:00	610382	610806	29	t	t	t	29
55	5	5	\N	\N	\N	\N	2024-06-10 11:30:00	2024-06-11 11:30:00	612369	612793	29	t	t	t	34
51	4	5	\N	\N	\N	\N	2024-06-06 11:30:00	2024-06-07 11:30:00	610806	611100	29	t	t	t	30
52	13	5	\N	\N	\N	\N	2024-06-07 11:30:00	2024-06-08 11:30:00	611100	611525	29	t	t	t	31
56	7	5	\N	\N	\N	\N	2024-06-11 11:30:00	2024-06-12 11:30:00	612793	613215	29	t	t	t	35
60	12	5	\N	\N	\N	\N	2024-06-15 11:30:00	2024-06-16 11:30:00	614499	614925	29	t	t	t	39
57	4	5	\N	\N	\N	\N	2024-06-12 11:30:00	2024-06-13 11:30:00	613218	613648	29	t	t	t	36
58	5	5	\N	\N	\N	\N	2024-06-13 11:30:00	2024-06-14 11:30:00	613648	614073	29	t	t	t	37
61	9	7	\N	\N	\N	\N	2024-06-24 17:12:49	2024-06-24 17:16:29	47232	47939	29	t	f	f	23
\.


--
-- Data for Name: driver_mileage; Type: TABLE DATA; Schema: driver; Owner: postgres
--

COPY driver.driver_mileage (driver_mileage_sno, driver_sno, driving_type_cd, mileage, kms, fuel, vehicle_sno, active_flag) FROM stdin;
1	10	55	3.8298454383805227	560	146.22	7	t
2	9	55	3.6601307189542482	700	191.25	7	t
3	8	55	3.7952196382428944	705	185.76	7	t
4	10	55	3.708755180191995	707	190.63	7	t
5	9	55	3.8879140162316292	709	182.36	7	t
6	10	55	3.8322252851197236	709	185.01	7	t
7	8	55	3.9003835557236237	722	185.11	7	t
8	10	55	3.8688524590163933	708	183	7	t
9	9	55	3.650958052822372	705	193.1	7	t
10	8	55	3.7167490274419093	707	190.22	7	t
11	9	55	3.6766169154228856	739	201	7	t
12	10	55	3.729529846804015	706	189.3	7	t
13	9	55	3.8216216216216217	707	185	7	t
14	10	55	3.7924151696606785	589	155.31	7	t
15	9	55	3.864130434782609	711	184	7	t
16	10	55	3.7017589918613814	705	190.45	7	t
17	9	55	3.9043167445697002	710	181.85	7	t
18	10	55	3.786741042694701	706	186.44	7	t
19	9	55	3.858293426208098	709	183.76	7	t
20	10	55	3.8600131032976632	707	183.16	7	t
21	12	55	3.925992779783394	435	110.8	4	t
22	14	55	3.778270509977827	426	112.75	4	t
23	11	55	3.888888888888889	560	144	4	t
24	12	55	3.704025736892444	426	115.01	4	t
25	6	55	3.610169491525424	426	118	4	t
26	12	55	3.611271795719362	437	121.01	4	t
27	6	55	3.328125	426	128	4	t
28	12	55	3.941524796447076	426	108.08	4	t
29	14	55	3.7239028547081383	437	117.35	4	t
30	13	55	3.80905132021388	691	181.41	4	t
31	14	55	2.9742628259757966	349	117.34	4	t
32	13	55	3.909090909090909	301	77	4	t
33	11	55	3.455882352941176	423	122.4	4	t
34	7	55	3.7121544537077664	423	113.95	4	t
35	14	55	3.8061041292639137	424	111.4	4	t
36	14	55	3.692982456140351	421	114	4	t
37	14	55	3.6946458205956856	423	114.49	4	t
38	11	55	3.631212979654906	423	116.49	4	t
39	4	55	3.9626168224299065	424	107	5	t
40	7	55	3.950181243610001	425	107.59	5	t
41	4	55	4.141433873803478	424	102.37999999999998	5	t
42	7	55	3.9715914400523316	425	107.01	5	t
43	14	55	4.170755642787046	425	101.90000000000002	5	t
44	11	55	4.018957345971564	424	105.5	5	t
45	4	55	3.7088431941465876	294	79.27	5	t
46	13	55	4.0971753591053695	425	103.73	5	t
47	11	55	3.8809831824062098	420	108.22	5	t
48	5	55	4.037710694219598	424	105.01	5	t
49	5	55	3.923746066999815	424	108.06	5	t
50	7	55	3.9661654135338344	422	106.4	5	t
51	4	55	3.893516841724013	430	110.44	5	t
52	5	55	4	425	106.25	5	t
53	4	55	4.131510037823683	426	103.11	5	t
54	12	55	3.908256880733945	426	109	5	t
\.


--
-- Data for Name: driver_user; Type: TABLE DATA; Schema: driver; Owner: postgres
--

COPY driver.driver_user (driver_user_sno, driver_sno, app_user_sno, active_flag) FROM stdin;
1	1	5	t
2	2	6	t
3	3	7	t
4	4	10	t
5	5	11	t
6	6	12	t
7	7	13	t
8	8	15	t
9	9	16	t
10	10	20	t
11	11	22	t
12	12	21	t
13	13	23	t
14	14	24	t
15	15	25	t
\.


--
-- Data for Name: job_post; Type: TABLE DATA; Schema: driver; Owner: postgres
--

COPY driver.job_post (job_post_sno, role_cd, org_sno, driver_sno, user_lat_long, start_date, end_date, posted_on, contact_name, contact_number, drive_type_cd, job_type_cd, lat, lng, description, active_flag, distance, auth_type_cd, transmission_type_cd, fuel_type_cd, app_user_sno) FROM stdin;
1	2	1	\N	{"lat":10.0103852,"lang":77.4949531,"place":"Unnamed Road, Sidco Thoz, NRT Nagar, Theni Allinagaram, Vadaveeranaickenpatty, Tamil Nadu 625531, India"}	2024-03-16 00:00:00	2024-03-17 00:00:00	2024-03-16 15:21:48.939189	vinoth	7890322312	{136}	{139}	10.0103852	77.4949531	\N	t	\N	\N	\N	\N	\N
3	6	\N	2	{"lat":12.9190519,"lang":80.2300343,"place":"Karapakkam, Chennai, Tamil Nadu, India"}	2024-03-18 08:00:00	2024-03-30 00:00:00	2024-03-18 16:16:06.101732	\N	\N	{136}	{140,141}	12.9190519	80.2300343		t	\N	\N	\N	\N	\N
4	6	\N	9	{"lat":12.889158,"lang":80.2292866,"place":"Sholinganallur, Chennai"}	2024-05-13 00:00:00	2024-05-15 00:00:00	2024-05-12 19:57:58.676469	\N	\N	{136}	{139,138}	12.889158	80.2292866	\N	t	\N	\N	\N	\N	\N
5	6	\N	8	{"lat":12.8891374,"lang":80.22935,"place":"Sholinganallur, Chennai"}	2024-05-14 08:00:00	2024-05-15 08:00:00	2024-05-13 16:55:53.453685	\N	\N	{136}	{139,140}	12.8891374	80.22935	2 days	t	\N	\N	\N	\N	\N
7	2	3	\N	{"lat":11.3513514,"lang":77.7262872,"place":"KNK Road, Thiru Nagar Colony, 9P2G+GGV, Erode, Tamil Nadu 638003, India"}	2024-05-25 13:00:00	2024-05-27 17:05:00	2024-05-24 12:02:14.500309	Karthikeyan Bus Transport	9585177077	{136}	{139}	11.3513514	77.7262872	Regular Route Bus from Erode to Salem	t	\N	\N	\N	\N	\N
6	6	\N	8	{"lat":11.350835182423513,"lang":77.7308189123869,"place":" Poungondenar 1st Street,  Karungalpalayam,  Tamil Nadu 638003,  India"}	2024-05-25 08:00:00	2024-05-27 19:00:00	2024-05-24 09:36:58.985464	\N	\N	{136}	{140,139,138}	11.350835182423513	77.7308189123869	With in 25 kms radius	t	25	\N	\N	\N	\N
8	6	\N	\N	{"lat":11.3516391,"lang":77.7381096,"place":"Karungalpalayam, Tamil Nadu, India"}	2024-05-27 08:00:00	2024-05-31 21:00:00	2024-05-26 16:16:15.609307	\N	\N	{136}	{139,138}	11.3516391	77.7381096	Free to drive car	t	\N	\N	\N	\N	\N
9	6	\N	\N	{"lat":11.350347692817241,"lang":77.73119609802961,"place":"5/a,  Poongundranar Street,  Karungalpalayam,  Tamil Nadu 638001,  India"}	2024-06-06 08:00:00	2024-06-06 20:00:00	2024-06-05 09:35:25.582978	Raja	97860377	{151}	{155}	11.350347692817241	77.73119609802961	Need driver to drive a innova car	t	25	167	{164}	{27}	19
\.


--
-- Data for Name: city; Type: TABLE DATA; Schema: master_data; Owner: postgres
--

COPY master_data.city (city_sno, city_name, district_sno, active_flag) FROM stdin;
1	Theni	28	t
2	kanavillaku	28	t
3	Aundipatti	28	t
4	usilampatti	28	t
5	chellampatti	28	t
6	karumathur	28	t
7	chekanurani	28	t
8	MKuniversity	28	t
9	kochadai	28	t
10	Arapalliyam	14	t
11	Erode	8	t
12	Bhavani	8	t
13	Perundurai	8	t
14	Kodumudi	8	t
15	Anthiyur	8	t
16	Gobichettipalayam	8	t
17	Sathyamangalam	8	t
18	Chithode	8	t
19	Nasiyanur	8	t
20	Thalavadi	8	t
21	Thindal	8	t
22	Avalpoondurai	8	t
23	Arachalur	8	t
24	Nathakkadaiyur	8	t
25	Chennimalai	8	t
26	Salem	23	t
27	Omalur	23	t
28	Sankari	23	t
29	Mettur	23	t
30	Edappadi	23	t
31	Tharamangalam	23	t
32	Yercaud	23	t
33	Kondalampatti	23	t
34	Konganapuram	23	t
35	Mallur	23	t
36	Attayampatti	23	t
37	Namakkal	18	t
38	Pallipalayam	18	t
39	Kumarapalayam	18	t
40	Tiruchengode	18	t
41	Veppadai	18	t
\.


--
-- Data for Name: district; Type: TABLE DATA; Schema: master_data; Owner: postgres
--

COPY master_data.district (district_sno, district_name, state_sno, active_flag) FROM stdin;
1	Ariyalur	1	t
2	Chengalpattu	1	t
3	Chennai	1	t
4	Coimbatore	1	t
5	Cuddalore	1	t
6	Dharmapuri	1	t
7	Dindigul	1	t
8	Erode	1	t
9	Kallakurichi	1	t
10	Kanchipuram	1	t
11	Kanyakumari	1	t
12	Karur	1	t
13	Krishnagiri	1	t
14	Madurai	1	t
15	Mayiladuthurai	1	t
16	Nagapattinam	1	t
17	Nilgiris	1	t
18	Namakkal	1	t
19	Perambalur	1	t
20	Pudukkottai	1	t
21	Ramanathapuram	1	t
22	Ranipet	1	t
23	Salem	1	t
24	Sivaganga	1	t
25	Tenkasi	1	t
26	Tirupur	1	t
27	Tiruchirappalli	1	t
28	Theni	1	t
29	Tirunelveli	1	t
30	Thanjavur	1	t
31	Thoothukudi	1	t
32	Tirupattur	1	t
33	Tiruvallur	1	t
34	Tiruvarur	1	t
35	Tiruvannamalai	1	t
36	Vellore	1	t
37	Viluppuram	1	t
38	Virudhunagar	1	t
\.


--
-- Data for Name: route; Type: TABLE DATA; Schema: master_data; Owner: postgres
--

COPY master_data.route (route_sno, source_city_sno, destination_city_sno, active_flag) FROM stdin;
1	1	10	t
2	10	1	t
3	5	4	t
4	4	5	t
5	11	26	t
6	26	11	t
7	11	26	t
8	26	11	t
9	12	26	t
10	26	12	t
11	11	26	t
12	26	11	t
13	26	11	t
14	11	26	t
\.


--
-- Data for Name: state; Type: TABLE DATA; Schema: master_data; Owner: postgres
--

COPY master_data.state (state_sno, state_name, active_flag) FROM stdin;
1	Tamil Nadu	t
2	Andhra Pradesh	t
3	Arunachal Pradesh	t
4	Assam	t
5	Bihar	t
6	Chhattisgarh	t
7	Goa	t
8	Gujarat	t
9	Haryana	t
10	Himachal Pradesh	t
11	Jharkhand	t
12	Karnataka	t
13	Kerala	t
14	Madhya Pradesh	t
15	Maharashtra	t
16	Manipur	t
17	Meghalaya	t
18	Mizoram	t
19	Nagaland	t
20	Odisha	t
21	Punjab	t
22	Rajasthan	t
23	Sikkim	t
24	Telangana	t
25	Tripura	t
26	Uttar Pradesh	t
27	Uttarakhand	t
28	West Bengal	t
\.


--
-- Data for Name: tyre_company; Type: TABLE DATA; Schema: master_data; Owner: postgres
--

COPY master_data.tyre_company (tyre_company_sno, tyre_company, active_flag) FROM stdin;
1	MRF	t
2	Apollo	t
3	CEAT	t
4	JK	t
5	Michelin	t
6	Bridgestone	t
7	Dunlop	t
8	Continental	t
9	Good Year	t
10	Others	t
\.


--
-- Data for Name: tyre_size; Type: TABLE DATA; Schema: master_data; Owner: postgres
--

COPY master_data.tyre_size (tyre_size_sno, tyre_type_sno, tyre_size, active_flag) FROM stdin;
1	1	7.50 / 16	t
2	1	8.25 / 16	t
3	1	8.25 / 20	t
4	1	9.00 / 20	t
5	1	10.00 / 20	t
6	1	11.00 / 20	t
7	1	12.00 / 20	t
8	1	14.00 / 20	t
9	1	12.00 / 24	t
10	2	7.50 R 16	t
11	2	8.25 R 16	t
12	2	8.25 R 20	t
13	2	9.00 R 20	t
14	2	10.00 R 20	t
15	2	11.00 R 20	t
16	2	12.00 R 20	t
17	2	295/90 R 20	t
18	3	235/75 R 17.5	t
19	3	295/80 R 22.5	t
20	3	11.00 R 22.5	t
21	3	315/80 R 22.5	t
22	3	385/65 R 22.5	t
23	3	245/75 R 19.5	t
\.


--
-- Data for Name: tyre_type; Type: TABLE DATA; Schema: master_data; Owner: postgres
--

COPY master_data.tyre_type (tyre_type_sno, tyre_type, active_flag) FROM stdin;
1	Nylon Tube Tyre	t
2	Radial Tube Tyre	t
3	Radial Tubeless Tyre	t
\.


--
-- Data for Name: media; Type: TABLE DATA; Schema: media; Owner: postgres
--

COPY media.media (media_sno, container_name) FROM stdin;
1	media
2	media
3	media
4	media
5	media
6	media
7	Profile
8	LicenceFrontPage
9	LicenceBackPage
10	Profile
11	Profile
12	LicenceFrontPage
13	LicenceBackPage
14	Profile
15	Profile
16	LicenceFrontPage
17	LicenceBackPage
18	Profile
19	Profile
20	LicenceFrontPage
21	LicenceBackPage
22	Profile
23	LicenceFrontPage
24	LicenceBackPage
25	Profile
26	LicenceFrontPage
27	LicenceBackPage
28	Profile
29	Profile
30	LicenceFrontPage
31	LicenceBackPage
32	media
33	media
34	Profile
35	LicenceFrontPage
36	LicenceBackPage
37	Profile
38	LicenceFrontPage
39	LicenceBackPage
40	Profile
41	LicenceFrontPage
42	LicenceBackPage
43	Profile
44	LicenceFrontPage
45	LicenceBackPage
46	media
47	media
48	media
49	media
50	Profile
51	Profile
52	LicenceFrontPage
53	LicenceBackPage
54	Profile
55	LicenceFrontPage
56	LicenceBackPage
57	Profile
58	LicenceFrontPage
59	LicenceBackPage
60	Profile
61	LicenceFrontPage
62	LicenceBackPage
63	Profile
64	LicenceFrontPage
65	LicenceBackPage
66	Profile
67	LicenceFrontPage
68	LicenceBackPage
69	media
70	media
71	media
72	media
73	media
74	media
\.


--
-- Data for Name: media_detail; Type: TABLE DATA; Schema: media; Owner: postgres
--

COPY media.media_detail (media_detail_sno, azure_id, media_sno, media_url, thumbnail_url, media_type, content_type, media_size, media_detail_description, isuploaded) FROM stdin;
3	\N	10	https://swombclientblob.blob.core.windows.net/myjob/6c4a4de2-824e-4704-9137-59387a9431denull	https://swombclientblob.blob.core.windows.net/myjob/ea800b66-7599-4866-a5d6-96fd2e9a252anull	.jpg	image/jpeg	\N	\N	t
1	\N	8	https://swombclientblob.blob.core.windows.net/myjob/1de4988d-31e5-4bef-aea8-8c3ae53e1d0cnull	https://swombclientblob.blob.core.windows.net/myjob/c2a1ccb2-243b-4737-897a-b91a3df48c9bnull	.jpg	image/jpeg	\N	\N	t
2	\N	9	https://swombclientblob.blob.core.windows.net/myjob/b6da4709-b58e-4984-a62e-9e09243957abnull	https://swombclientblob.blob.core.windows.net/myjob/abe8d4bc-983e-42f4-9301-75e6b0d85566null	.jpg	image/jpeg	\N	\N	t
6	\N	14	https://swombclientblob.blob.core.windows.net/myjob/d503b394-7701-43b4-b67e-d3546287ce90null	https://swombclientblob.blob.core.windows.net/myjob/84415b4d-2d74-47d7-b0ef-208e886c777enull	.jpg	image/jpeg	\N	\N	t
4	\N	12	https://swombclientblob.blob.core.windows.net/myjob/7e610183-f1c2-4c76-8524-fc77a5f54b69null	https://swombclientblob.blob.core.windows.net/myjob/2567d9dd-4ee9-420b-bf0d-bed14f111c02null	.jpg	image/jpeg	\N	\N	t
5	\N	13	https://swombclientblob.blob.core.windows.net/myjob/49d663f8-a7cf-4e56-8a6c-5681b5521b47null	https://swombclientblob.blob.core.windows.net/myjob/3adfd4ed-60d0-4b2c-b60a-ae773150d204null	.jpg	image/jpeg	\N	\N	t
9	\N	18	https://swombclientblob.blob.core.windows.net/myjob/8471bb51-4781-4abe-9aa4-36d50c3ba20fnull	https://swombclientblob.blob.core.windows.net/myjob/f2963cb4-0cad-4bed-9d50-9230d1d88d98null	.jpg	image/jpeg	\N	\N	t
7	\N	16	https://swombclientblob.blob.core.windows.net/myjob/97b46b58-9b37-4f36-9fa6-2cc2d8fdfa10null	https://swombclientblob.blob.core.windows.net/myjob/59ce5f1c-c7b9-4891-96b2-7faa5ce69e05null	.jpg	image/jpeg	\N	\N	t
8	\N	17	https://swombclientblob.blob.core.windows.net/myjob/163ed0eb-fed5-4169-96da-1e3cf142bfa8null	https://swombclientblob.blob.core.windows.net/myjob/3b864545-43fc-4286-9bfa-528afb065dacnull	.jpg	image/jpeg	\N	\N	t
10	\N	20	https://swombclientblob.blob.core.windows.net/myjob/5734796a-9e52-4045-b06c-78c75ea1bfffnull	https://swombclientblob.blob.core.windows.net/myjob/983c9a41-c0e2-42c2-b301-a6f9672e69f8null	.jpg	image/jpeg	\N	\N	t
11	\N	21	https://swombclientblob.blob.core.windows.net/myjob/3992b8d5-a676-4f62-9bbb-ecd4c4166443null	https://swombclientblob.blob.core.windows.net/myjob/52eaffd3-a055-45af-b0aa-87fb8c9272fcnull	.jpg	image/jpeg	\N	\N	t
12	\N	23	https://swombclientblob.blob.core.windows.net/myjob/ce9ba819-e371-4d8a-9b34-d7ad1d0d3b2dnull	https://swombclientblob.blob.core.windows.net/myjob/c4a7ce35-7d9d-47ae-9b0a-41014607574anull	.jpg	image/jpeg	\N	\N	t
13	\N	24	https://swombclientblob.blob.core.windows.net/myjob/784e40d9-8d1c-4c19-aa0e-7454b92de441null	https://swombclientblob.blob.core.windows.net/myjob/420ae799-3452-416d-ae7b-9bff78f8a46bnull	.jpg	image/jpeg	\N	\N	t
16	\N	28	https://swombclientblob.blob.core.windows.net/myjob/4c7ae232-69ac-4c70-b237-9bbcf5194071null	https://swombclientblob.blob.core.windows.net/myjob/c767e2df-f8c0-490c-95cc-c7150a016d7cnull	.jpg	image/jpeg	\N	\N	t
17	\N	30	https://swombclientblob.blob.core.windows.net/myjob/cf58822a-018c-40ec-ac1b-dee508f3b230null	https://swombclientblob.blob.core.windows.net/myjob/755811b0-1269-4e45-bc13-ae842f68221enull	.jpg	image/jpeg	\N	\N	t
18	\N	31	https://swombclientblob.blob.core.windows.net/myjob/9b878857-c331-4bc0-ab07-04213e3a784cnull	https://swombclientblob.blob.core.windows.net/myjob/e4e84718-9be0-48af-9b1c-267728e840f3null	.jpg	image/jpeg	\N	\N	t
19	\N	43	https://svpou.blob.core.windows.net/myjob/20b91a8b-0d45-4aa0-b350-410145a38d43null	https://svpou.blob.core.windows.net/myjob/caac1585-929c-45fd-9e0c-4313ec00fd99null	.jpg	image/jpeg	\N	\N	t
20	\N	50	https://svpou.blob.core.windows.net/myjob/29adb743-7753-4bca-ab83-a396eb2d25f9null	https://svpou.blob.core.windows.net/myjob/e27f1ff2-bbe2-4862-8c96-a8d93739cf87null	.jpg	image/jpeg	\N	\N	t
14	\N	26	https://swombclientblob.blob.core.windows.net/myjob/51bdd873-d6dc-4327-873d-a1ad7a35501fnull	https://swombclientblob.blob.core.windows.net/myjob/96fbf2da-d327-45c1-be26-a69d67c417cdnull	.jpg	image/jpeg	\N	\N	t
15	\N	27	https://swombclientblob.blob.core.windows.net/myjob/0bcbc488-fe6d-4bc7-89f5-a1a84fa4ddb2null	https://swombclientblob.blob.core.windows.net/myjob/8bbb3c57-cbb3-4a60-9ab7-cc446dde0559null	.jpg	image/jpeg	\N	\N	t
\.


--
-- Data for Name: notification; Type: TABLE DATA; Schema: notification; Owner: postgres
--

COPY notification.notification (notification_sno, title, message, action_id, router_link, from_id, to_id, created_on, notification_status_cd, active_flag) FROM stdin;
1	Expiry Message	Your vehicle fc is expire on 23/03/2024	\N	registervehicle	\N	\N	2024-03-16 15:00:21.282074	117	t
2	Expiry Message	Your vehicle pollution is expire on 23/03/2024	\N	registervehicle	\N	\N	2024-03-16 15:00:21.287522	117	t
3	Expiry Message	Your vehicle tax is expire on 23/03/2024	\N	registervehicle	\N	\N	2024-03-16 15:00:21.287929	117	t
4	Expiry Message	Your vehicle insurance is expire on 23/03/2024	\N	registervehicle	\N	\N	2024-03-16 15:00:21.290487	117	t
5	Expiry Message	Your vehicle permit is expire on 23/03/2024	\N	registervehicle	\N	\N	2024-03-16 15:00:21.2891	117	t
6	Welcome 	welcome to Bus Today	\N	bus-dashboard	3	3	2024-03-16 15:02:06.092776	117	t
7	Welcome 	welcome to Bus Today	\N	bus-dashboard	4	4	2024-03-16 15:02:33.812081	117	t
10	Drive Request	SRI RAM JAWAHAR A you got drive request from  Saara	\N	/driver	4	6	2024-03-16 16:14:24.843481	117	f
11	Accepted	SRI RAM JAWAHAR A accept your request	\N	/driver	6	4	2024-03-16 13:15:41.762564	117	t
12	Welcome 	welcome to Bus Today	\N	bus-dashboard	7	7	\N	117	t
13	Welcome 	welcome to Bus Today	\N	bus-dashboard	8	8	\N	117	t
15	Welcome 	welcome to Bus Today	\N	bus-dashboard	9	9	2024-03-18 12:32:32.600943	116	t
16	Verified 	Dear operator kyc of your vehicle successfully verified 	\N	registervehicle	2	9	2024-03-18 19:23:06.865325	116	t
17	Verified 	Dear operator kyc of your vehicle successfully verified 	\N	registervehicle	2	9	2024-03-18 19:31:29.021196	116	t
18	Verified 	Dear operator kyc of your vehicle successfully verified 	\N	registervehicle	2	9	2024-03-18 19:37:36.313191	116	t
34	Accepted	SENTHILPRABHU  G accept your request	\N	/driver	12	9	2024-03-20 07:57:45.895406	116	t
19	Verified 	Dear operator kyc of your vehicle successfully verified 	\N	registervehicle	2	9	2024-03-18 19:44:07.642309	116	t
20	Verified 	Dear Driver your KYC is Successfully verified 	\N	driver	\N	7	2024-03-19 12:17:59.0803	117	t
21	Drive Request	SIVAKUMAR V you got drive request from  Karthikeyan Bus Transport	\N	/driver	9	7	2024-03-19 12:43:03.706117	117	f
22	Accepted	SIVAKUMAR V accept your request	\N	/driver	7	9	2024-03-19 09:13:14.561025	116	t
23	Welcome 	welcome to Bus Today	\N	bus-dashboard	10	10	\N	117	t
24	Verified 	Dear Driver your KYC is Successfully verified 	\N	driver	\N	10	2024-03-19 12:56:03.045498	117	t
25	Drive Request	RAJENDRAN  K you got drive request from  Karthikeyan Bus Transport	\N	/driver	9	10	2024-03-19 12:56:30.199827	117	f
26	Accepted	RAJENDRAN  K accept your request	\N	/driver	10	9	2024-03-19 09:26:36.195668	116	t
27	Welcome 	welcome to Bus Today	\N	bus-dashboard	11	11	\N	117	t
28	Verified 	Dear Driver your KYC is Successfully verified 	\N	driver	\N	11	2024-03-19 18:39:42.759329	117	t
29	Drive Request	SENTHILKUMAR K you got drive request from  Karthikeyan Bus Transport	\N	/driver	9	11	2024-03-19 18:40:20.767094	117	f
30	Accepted	SENTHILKUMAR K accept your request	\N	/driver	11	9	2024-03-19 15:10:37.519737	116	t
31	Welcome 	welcome to Bus Today	\N	bus-dashboard	12	12	\N	117	t
32	Verified 	Dear Driver your KYC is Successfully verified 	\N	driver	\N	12	2024-03-20 11:26:31.89118	117	t
33	Drive Request	SENTHILPRABHU  G you got drive request from  Karthikeyan Bus Transport	\N	/driver	9	12	2024-03-20 11:27:35.368402	117	f
35	Welcome 	welcome to Bus Today	\N	bus-dashboard	13	13	\N	117	t
36	Verified 	Dear Driver your KYC is Successfully verified 	\N	driver	\N	13	2024-03-20 12:11:00.146575	117	t
37	Drive Request	DINESH V you got drive request from  Karthikeyan Bus Transport	\N	/driver	9	13	2024-03-20 12:11:16.193853	117	f
38	Accepted	DINESH V accept your request	\N	/driver	13	9	2024-03-20 08:41:21.440742	116	t
41	Drive Request	BOOPATHIRAJA  A you got drive request from  Karthikeyan Bus Transport	\N	/driver	9	15	2024-03-20 14:03:18.219963	117	f
42	Accepted	BOOPATHIRAJA  A accept your request	\N	/driver	15	9	2024-03-20 10:33:22.883967	116	t
8	Welcome 	welcome to Bus Today	\N	bus-dashboard	6	6	\N	116	t
9	Verified 	Dear Driver your KYC is Successfully verified 	\N	driver	\N	6	2024-03-16 16:12:19.333998	116	t
39	Welcome 	welcome to Bus Today	\N	bus-dashboard	15	15	\N	116	t
48	Verified 	Dear operator kyc of your vehicle successfully verified 	\N	registervehicle	2	9	2024-05-24 12:32:12.695884	116	t
14	Welcome 	welcome to Bus Today	\N	bus-dashboard	5	5	\N	116	t
45	Drive Request	PRAKASH  T you got drive request from  Karthikeyan Bus Transport	\N	/driver	9	16	2024-03-22 12:03:11.346244	117	f
43	Welcome 	welcome to Drver Today	\N	bus-dashboard	16	16	\N	116	t
46	Accepted	PRAKASH  T accept your request	\N	/driver	16	9	2024-03-22 08:33:35.602939	116	t
47	Welcome 	welcome to Bus Today	\N	bus-dashboard	17	17	2024-05-10 15:47:43.498561	117	t
40	Verified 	Dear Driver your KYC is Successfully verified 	\N	driver	\N	15	2024-03-20 14:02:53.001267	116	t
50	Welcome 	welcome to Driver Today	\N	bus-dashboard	19	19	\N	116	t
49	Welcome 	welcome to Bus Today	\N	bus-dashboard	18	18	2024-05-24 17:52:01.890915	116	t
51	Welcome 	Welcome to Driver Today	\N	bus-dashboard	20	20	\N	116	t
55	Verified 	Dear THANGAVEL S your KYC is Successfully verified 	\N	driver	\N	20	2024-06-20 12:21:28.604764	116	t
52	Rejected 	Dear operator kyc of your vehicle rejected due to  Test	\N	registervehicle	2	4	2024-06-18 11:18:22.825503	117	t
53	Rejected 	Dear operator kyc of your vehicle rejected due to  Test	\N	registervehicle	2	3	2024-06-18 11:18:36.248437	117	t
54	Rejected 	Dear subash Your Kyc is rejected due to  Test	\N	driver	\N	5	2024-06-18 11:18:41.557057	117	t
56	Drive Request	THANGAVEL S you got drive request from  Karthikeyan Bus Transport	\N	/driver	9	20	2024-06-20 12:22:11.602998	117	f
57	Accepted	THANGAVEL S accept your request	\N	/driver	20	9	2024-06-20 12:22:20.151537	116	t
59	Verified 	Dear RAMESH  M your KYC is Successfully verified 	\N	driver	\N	22	2024-06-20 15:23:50.004789	117	t
58	Welcome 	Welcome to Driver Today	\N	bus-dashboard	22	22	\N	116	t
60	Drive Request	RAMESH  M you got drive request from  Karthikeyan Bus Transport	\N	/driver	9	22	2024-06-20 15:24:03.006984	117	f
61	Accepted	RAMESH  M accept your request	\N	/driver	22	9	2024-06-20 15:24:12.64211	116	t
62	Welcome 	Welcome to Driver Today	\N	bus-dashboard	21	21	\N	116	t
64	Drive Request	CHINNADURAI T you got drive request from  Karthikeyan Bus Transport	\N	/driver	9	21	2024-06-20 16:09:42.662048	117	f
63	Verified 	Dear CHINNADURAI T your KYC is Successfully verified 	\N	driver	\N	21	2024-06-20 16:09:12.232005	116	t
68	Drive Request	DHANASEKAR L you got drive request from  Karthikeyan Bus Transport	\N	/driver	9	23	2024-06-20 16:16:46.525016	117	f
67	Verified 	Dear DHANASEKAR L your KYC is Successfully verified 	\N	driver	\N	23	2024-06-20 16:16:14.17941	116	t
66	Welcome 	Welcome to Driver Today	\N	bus-dashboard	23	23	\N	116	t
70	Welcome 	Welcome to Driver Today	\N	bus-dashboard	24	24	\N	116	t
72	Drive Request	SARAVANAKUMAR  K you got drive request from  Karthikeyan Bus Transport	\N	/driver	9	24	2024-06-20 16:25:21.87826	117	f
71	Verified 	Dear SARAVANAKUMAR  K your KYC is Successfully verified 	\N	driver	\N	24	2024-06-20 16:24:58.50761	116	t
65	Accepted	CHINNADURAI T accept your request	\N	/driver	21	9	2024-06-20 16:09:47.325515	116	t
69	Accepted	DHANASEKAR L accept your request	\N	/driver	23	9	2024-06-20 16:17:24.99668	116	t
73	Accepted	SARAVANAKUMAR  K accept your request	\N	/driver	24	9	2024-06-20 16:25:26.345612	116	t
74	Welcome 	Welcome to Driver Today	\N	bus-dashboard	25	25	\N	116	t
75	Verified 	Dear SURESH  P your KYC is Successfully verified 	\N	driver	\N	25	2024-06-22 13:29:05.518334	116	t
76	Drive Request	SURESH  P you got drive request from  Karthikeyan Bus Transport	\N	/driver	9	25	2024-06-22 13:29:31.59109	117	f
77	Accepted	SURESH  P accept your request	\N	/driver	25	9	2024-06-22 13:29:37.0496	116	t
44	Verified 	Dear Driver your KYC is Successfully verified 	\N	driver	\N	16	2024-03-22 12:02:55.849218	116	t
78	Welcome 	welcome to Bus Today	\N	bus-dashboard	27	27	\N	117	t
\.


--
-- Data for Name: address; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.address (address_sno, address_line1, address_line2, pincode, city_name, state_name, district_name, country_name, country_code, latitude, longitude) FROM stdin;
1	No 8, BALAJI NAGAR	\N	600119	Sholinganallur	Tamil Nadu	Kanchipuram	India	91	\N	\N
2	1/14A,Krishnan Kovil Street	\N	626111	Meenakshipuram	Tamil Nadu	Virudhunagar	India	91	\N	\N
3	13, KNK Road		638003	Karungalpalayam	Tamil Nadu	Erode	India	91	\N	\N
\.


--
-- Data for Name: bank_account_detail; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.bank_account_detail (bank_account_detail_sno, org_sno, bank_account_name) FROM stdin;
1	1	subash
2	2	SBI
3	3	IOB 3939
4	3	IOB 2619
5	3	HDFC 3456
\.


--
-- Data for Name: bunk; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.bunk (bunk_sno, bunk_name, address, operator_sno) FROM stdin;
\.


--
-- Data for Name: bus_report; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.bus_report (bus_report_sno, org_sno, vehicle_sno, driver_sno, driver_attendance_sno, driving_type_cd, start_km, end_km, drived_km, start_date, end_date, fuel_consumed, mileage, created_on) FROM stdin;
1	3	7	10	3	55	34067	34627	560	2024-05-31 09:30:00	2024-06-01 10:30:00	146.22	3.8298454383805227	2024-06-20 07:09:33.172693
2	3	7	9	8	55	34627	35327	700	2024-06-01 10:30:00	2024-06-02 10:30:00	191.25	3.6601307189542482	2024-06-20 07:15:44.608588
3	3	7	8	9	55	35327	36032	705	2024-06-02 10:30:00	2024-06-03 10:30:00	185.76	3.7952196382428944	2024-06-20 07:18:51.3388
4	3	7	10	10	55	36032	36739	707	2024-06-03 10:30:00	2024-06-04 10:30:00	190.63	3.708755180191995	2024-06-20 07:20:43.083097
5	3	7	9	11	55	36739	37448	709	2024-06-04 10:30:00	2024-06-05 10:30:00	182.36	3.8879140162316292	2024-06-20 07:22:07.611721
6	3	7	10	12	55	36739	37448	709	2024-06-05 10:30:00	2024-06-06 10:30:00	185.01	3.8322252851197236	2024-06-20 07:24:46.133809
7	3	7	8	13	55	37448	38170	722	2024-06-06 10:30:00	2024-06-07 10:30:00	185.11	3.9003835557236237	2024-06-20 07:26:32.678217
8	3	7	10	14	55	38870	39578	708	2024-06-07 10:30:00	2024-06-07 10:30:00	183	3.8688524590163933	2024-06-20 07:29:18.160497
9	3	7	9	15	55	39578	40283	705	2024-06-08 10:30:00	2024-06-09 10:30:00	193.1	3.650958052822372	2024-06-20 07:31:04.805824
10	3	7	8	16	55	40283	40990	707	2024-06-09 10:30:00	2024-06-10 10:30:00	190.22	3.7167490274419093	2024-06-20 07:32:36.674726
11	3	7	9	17	55	40950	41689	739	2024-06-10 10:30:00	2024-06-11 10:30:00	201	3.6766169154228856	2024-06-20 07:34:06.586669
12	3	7	10	18	55	41689	42395	706	2024-06-11 10:30:00	2024-06-12 10:30:00	189.3	3.729529846804015	2024-06-20 07:36:55.050469
13	3	7	9	19	55	42395	43102	707	2024-06-12 10:30:00	2024-06-13 10:30:00	185	3.8216216216216217	2024-06-20 07:38:12.574989
14	3	7	10	20	55	43102	43691	589	2024-06-13 10:30:00	2024-06-14 10:30:00	155.31	3.7924151696606785	2024-06-20 07:40:33.635627
15	3	7	9	21	55	43691	44402	711	2024-06-14 10:30:00	2024-06-15 10:30:00	184	3.864130434782609	2024-06-20 07:42:39.661195
16	3	7	10	22	55	44402	45107	705	2024-06-15 10:30:00	2024-06-16 10:30:00	190.45	3.7017589918613814	2024-06-20 07:43:59.643765
17	3	7	9	23	55	45107	45817	710	2024-06-16 10:30:00	2024-06-17 10:30:00	181.85	3.9043167445697002	2024-06-20 07:45:22.972905
18	3	7	10	24	55	45817	46523	706	2024-06-17 10:30:00	2024-06-18 10:30:00	186.44	3.786741042694701	2024-06-20 07:47:00.255419
19	3	7	9	25	55	46523	47232	709	2024-06-18 10:30:00	2024-06-19 10:30:00	183.76	3.858293426208098	2024-06-20 07:48:13.956178
20	3	7	10	26	55	47232	47939	707	2024-06-19 10:30:00	2024-06-20 10:30:00	183.16	3.8600131032976632	2024-06-20 07:50:21.090926
21	3	4	12	27	55	562717	563152	435	2024-05-31 13:05:00	2024-06-01 13:05:00	110.8	3.925992779783394	2024-06-20 10:58:13.675554
22	3	4	14	28	55	563152	563578	426	2024-06-01 13:05:00	2024-06-02 13:05:00	112.75	3.778270509977827	2024-06-20 10:59:54.171419
23	3	4	11	29	55	563578	564138	560	2024-06-02 13:05:00	2024-06-03 13:05:00	144	3.888888888888889	2024-06-20 11:02:50.094819
24	3	4	12	30	55	564138	564564	426	2024-06-03 13:05:00	2024-06-04 13:05:00	115.01	3.704025736892444	2024-06-20 11:05:23.300925
25	3	4	6	31	55	564564	564990	426	2024-06-04 13:05:00	2024-06-05 13:05:00	118	3.610169491525424	2024-06-20 11:07:03.227627
26	3	4	12	32	55	564990	565427	437	2024-06-05 13:05:00	2024-06-06 13:05:00	121.01	3.611271795719362	2024-06-20 11:08:36.136809
27	3	4	6	33	55	565427	565853	426	2024-06-06 13:05:00	2024-06-07 13:05:00	128	3.328125	2024-06-20 11:09:55.966962
28	3	4	12	34	55	565853	566279	426	2024-06-07 13:05:00	2024-06-08 13:05:00	108.08	3.941524796447076	2024-06-20 11:11:22.330225
29	3	4	14	35	55	566279	566716	437	2024-06-08 13:05:00	2024-06-09 13:05:00	117.35	3.7239028547081383	2024-06-20 11:13:09.172954
30	3	4	13	36	55	566716	567407	691	2024-06-09 13:05:00	2024-06-10 13:05:00	181.41	3.80905132021388	2024-06-20 11:14:35.444411
31	3	4	14	37	55	567407	567756	349	2024-06-10 13:05:00	2024-06-11 13:05:00	117.34	2.9742628259757966	2024-06-20 11:16:07.028622
32	3	4	13	38	55	567756	568057	301	2024-06-11 13:05:00	2024-06-12 13:05:00	77	3.909090909090909	2024-06-20 11:19:13.385582
33	3	4	11	39	55	568057	568480	423	2024-06-12 13:05:00	2024-06-13 13:05:00	122.4	3.455882352941176	2024-06-20 11:20:33.427982
34	3	4	7	40	55	568480	568903	423	2024-06-13 13:05:00	2024-06-14 13:06:00	113.95	3.7121544537077664	2024-06-20 11:21:52.992066
35	3	4	14	41	55	568903	569327	424	2024-06-14 13:05:00	2024-06-15 13:05:00	111.4	3.8061041292639137	2024-06-20 11:23:10.406565
36	3	4	14	42	55	569327	569748	421	2024-06-15 13:05:00	2024-06-16 13:05:00	114	3.692982456140351	2024-06-20 11:26:02.62454
37	3	4	14	43	55	570325	570748	423	2024-06-18 13:05:00	2024-06-19 13:05:00	114.49	3.6946458205956856	2024-06-20 11:28:42.887529
38	3	4	11	44	55	570748	571171	423	2024-06-19 13:05:00	2024-06-20 13:05:00	116.49	3.631212979654906	2024-06-20 11:29:51.63319
39	3	5	4	45	55	608259	608683	424	2024-05-31 11:30:00	2024-06-01 11:30:00	107	3.9626168224299065	2024-06-20 11:36:14.03019
40	3	5	7	46	55	608683	609108	425	2024-06-01 10:30:00	2024-06-02 11:30:00	107.59	3.950181243610001	2024-06-20 11:37:37.691246
41	3	5	4	47	55	609108	609532	424	2024-06-02 11:30:00	2024-06-03 11:30:00	102.38	4.141433873803478	2024-06-20 11:39:24.685358
42	3	5	7	48	55	609532	609957	425	2024-06-03 11:30:00	2024-06-04 11:30:00	107.01	3.9715914400523316	2024-06-20 11:40:42.866397
43	3	5	14	49	55	609957	610382	425	2024-06-04 11:30:00	2024-06-05 11:30:00	101.9	4.170755642787046	2024-06-20 11:42:22.926046
44	3	5	11	50	55	610382	610806	424	2024-06-05 11:30:00	2024-06-06 11:30:00	105.5	4.018957345971564	2024-06-20 11:44:21.34599
45	3	5	4	51	55	610806	611100	294	2024-06-06 11:30:00	2024-06-07 11:30:00	79.27	3.7088431941465876	2024-06-20 11:45:39.861807
46	3	5	13	52	55	611100	611525	425	2024-06-07 11:30:00	2024-06-08 11:30:00	103.73	4.0971753591053695	2024-06-20 11:47:02.839714
47	3	5	11	53	55	611525	611945	420	2024-06-08 11:30:00	2024-06-09 11:30:00	108.22	3.8809831824062098	2024-06-20 11:48:24.879361
48	3	5	5	54	55	611945	612369	424	2024-06-09 11:30:00	2024-06-10 11:30:00	105.01	4.037710694219598	2024-06-20 11:49:42.096826
49	3	5	5	55	55	612369	612793	424	2024-06-10 11:30:00	2024-06-11 11:30:00	108.06	3.923746066999815	2024-06-20 11:51:13.874781
50	3	5	7	56	55	612793	613215	422	2024-06-11 11:30:00	2024-06-12 11:30:00	106.4	3.9661654135338344	2024-06-20 11:52:26.62343
51	3	5	4	57	55	613218	613648	430	2024-06-12 11:30:00	2024-06-13 11:30:00	110.44	3.893516841724013	2024-06-20 11:53:39.15301
52	3	5	5	58	55	613648	614073	425	2024-06-13 11:30:00	2024-06-14 11:30:00	106.25	4	2024-06-20 11:54:56.475791
53	3	5	4	59	55	614073	614499	426	2024-06-14 11:30:00	2024-06-15 11:30:00	103.11	4.131510037823683	2024-06-20 11:56:45.917237
54	3	5	12	60	55	614499	614925	426	2024-06-15 11:30:00	2024-06-16 11:30:00	109	3.908256880733945	2024-06-20 11:58:48.036412
\.


--
-- Data for Name: fuel; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.fuel (fuel_sno, vehicle_sno, driver_sno, driver_attendance_sno, bunk_sno, lat_long, fuel_media, odo_meter_media, fuel_quantity, fuel_amount, odo_meter_value, filled_date, price_per_ltr, accept_status, active_flag, is_filled, fuel_fill_type_cd, tank_media, is_calculated, report_id) FROM stdin;
1	2	2	1	\N	\N	\N	\N	450	44649.5355	3200	2024-04-08 11:19:16	99.22119	\N	t	t	\N	\N	t	0
2	4	9	2	\N	\N	\N	\N	240	23813.0856	500000	2024-04-27 14:22:04	99.22119	\N	t	t	\N	\N	t	1
3	7	10	3	\N	\N	\N	\N	320	31750.7808	34067	2024-05-31 09:30:00	99.22119	\N	t	t	\N	\N	t	2
4	7	10	3	\N	\N	\N	\N	146.22	13472.7108	34067	2024-06-01 10:30:00	92.14	t	t	t	133	\N	t	3
9	7	9	8	\N	\N	\N	\N	191.25	17621.775	34627	2024-06-02 10:30:00	92.14	t	t	t	133	\N	t	4
10	7	8	9	\N	\N	\N	\N	185.76	17115.9264	35327	2024-06-03 10:30:00	92.14	t	t	t	133	\N	t	5
11	7	10	10	\N	\N	\N	\N	190.63	17564.6482	36032	2024-06-04 10:30:00	92.14	t	t	t	133	\N	t	6
12	7	9	11	\N	\N	\N	\N	182.36	16802.650400000002	36739	2024-06-05 10:30:00	92.14	t	t	t	133	\N	t	7
13	7	10	12	\N	\N	\N	\N	185.01	17046.8214	36739	2024-06-06 10:30:00	92.14	t	t	t	133	\N	t	8
14	7	8	13	\N	\N	\N	\N	185.11	17056.0354	37448	2024-06-07 10:30:00	92.14	t	t	t	133	\N	t	9
15	7	10	14	\N	\N	\N	\N	183	16861.62	38870	2024-06-07 10:30:00	92.14	t	t	t	133	\N	t	10
16	7	9	15	\N	\N	\N	\N	193.1	17792.234	39578	2024-06-09 10:30:00	92.14	t	t	t	133	\N	t	11
17	7	8	16	\N	\N	\N	\N	190.22	17526.8708	40283	2024-06-10 10:30:00	92.14	t	t	t	133	\N	t	12
18	7	9	17	\N	\N	\N	\N	201	18520.14	40950	2024-06-11 10:30:00	92.14	t	t	t	133	\N	t	13
19	7	10	18	\N	\N	\N	\N	189.3	17442.102000000003	41689	2024-06-12 10:30:00	92.14	t	t	t	133	\N	t	14
20	7	9	19	\N	\N	\N	\N	185	17045.9	42395	2024-06-13 10:30:00	92.14	t	t	t	133	\N	t	15
21	7	10	20	\N	\N	\N	\N	155.31	14310.2634	43102	2024-06-14 10:30:00	92.14	t	t	t	133	\N	t	16
22	7	9	21	\N	\N	\N	\N	184	16953.76	43691	2024-06-15 10:30:00	92.14	t	t	t	133	\N	t	17
23	7	10	22	\N	\N	\N	\N	190.45	17548.063	44402	2024-06-16 10:30:00	92.14	t	t	t	133	\N	t	18
24	7	9	23	\N	\N	\N	\N	181.85	16755.659	45107	2024-06-17 10:30:00	92.14	t	t	t	133	\N	t	19
25	7	10	24	\N	\N	\N	\N	186.44	17178.5816	45817	2024-06-18 10:30:00	92.14	t	t	t	133	\N	t	20
26	7	9	25	\N	\N	\N	\N	183.76	16931.646399999998	46523	2024-06-19 10:30:00	92.14	t	t	t	133	\N	t	21
27	7	10	26	\N	\N	\N	\N	183.16	16876.362399999998	47232	2024-06-20 10:30:00	92.14	t	t	t	133	\N	t	22
28	4	12	27	\N	\N	\N	\N	110.8	10216.867999999999	562717	2024-06-01 13:05:00	92.21	t	t	t	133	\N	t	2
29	4	14	28	\N	\N	\N	\N	112.75	10396.6775	563152	2024-06-02 13:05:00	92.21	t	t	t	133	\N	t	3
30	4	11	29	\N	\N	\N	\N	144	13278.24	563578	2024-06-03 13:05:00	92.21	t	t	t	133	\N	t	4
31	4	12	30	\N	\N	\N	\N	115.01	10605.0721	564138	2024-06-04 13:05:00	92.21	t	t	t	133	\N	t	5
32	4	6	31	\N	\N	\N	\N	118	10880.779999999999	564564	2024-06-05 13:05:00	92.21	t	t	t	133	\N	t	6
33	4	12	32	\N	\N	\N	\N	121.01	11158.3321	564990	2024-06-06 13:05:00	92.21	t	t	t	133	\N	t	7
34	4	6	33	\N	\N	\N	\N	128	11802.88	565427	2024-06-07 13:05:00	92.21	t	t	t	133	\N	t	8
35	4	12	34	\N	\N	\N	\N	108.08	9966.056799999998	565853	2024-06-08 13:05:00	92.21	t	t	t	133	\N	t	9
36	4	14	35	\N	\N	\N	\N	117.35	10820.843499999999	566279	2024-06-09 13:05:00	92.21	t	t	t	133	\N	t	10
37	4	13	36	\N	\N	\N	\N	181.41	16727.8161	566716	2024-06-10 13:05:00	92.21	t	t	t	133	\N	t	11
38	4	14	37	\N	\N	\N	\N	117.34	10819.9214	567407	2024-06-11 13:05:00	92.21	t	t	t	133	\N	t	12
39	4	13	38	\N	\N	\N	\N	77	7100.169999999999	567756	2024-06-12 13:05:00	92.21	t	t	t	133	\N	t	13
40	4	11	39	\N	\N	\N	\N	122.4	11286.503999999999	568057	2024-06-13 13:05:00	92.21	t	t	t	133	\N	t	14
41	4	7	40	\N	\N	\N	\N	113.95	10507.3295	568480	2024-06-14 13:06:00	92.21	t	t	t	133	\N	t	15
42	4	14	41	\N	\N	\N	\N	111.4	10272.194	568903	2024-06-15 13:05:00	92.21	t	t	t	133	\N	t	16
43	4	14	42	\N	\N	\N	\N	114	10511.939999999999	569327	2024-06-16 13:05:00	92.21	t	t	t	133	\N	t	17
44	4	14	43	\N	\N	\N	\N	114.49	10557.122899999998	570325	2024-06-19 13:05:00	92.21	t	t	t	133	\N	t	18
45	4	11	44	\N	\N	\N	\N	116.49	10741.542899999999	570748	2024-06-20 13:05:00	92.21	t	t	t	133	\N	t	19
46	5	4	45	\N	\N	\N	\N	240	23813.0856	608259	2024-05-31 11:30:00	99.22119	\N	t	t	\N	\N	t	23
47	5	4	45	\N	\N	\N	\N	107	9858.98	608259	2024-06-01 11:30:00	92.14	t	t	t	133	\N	t	24
48	5	7	46	\N	\N	\N	\N	107.59	9913.3426	608683	2024-06-02 11:30:00	92.14	t	t	t	133	\N	t	25
49	5	4	47	\N	\N	\N	\N	102.38	9433.2932	609108	2024-06-03 11:30:00	92.14	t	t	t	133	\N	t	26
50	5	7	48	\N	\N	\N	\N	107.01	9859.9014	609532	2024-06-04 11:30:00	92.14	t	t	t	133	\N	t	27
51	5	14	49	\N	\N	\N	\N	101.9	9389.066	609957	2024-06-05 11:30:00	92.14	t	t	t	133	\N	t	28
52	5	11	50	\N	\N	\N	\N	105.5	9720.77	610382	2024-06-06 11:30:00	92.14	t	t	t	133	\N	t	29
53	5	4	51	\N	\N	\N	\N	79.27	7303.9378	610806	2024-06-07 11:30:00	92.14	t	t	t	133	\N	t	30
54	5	13	52	\N	\N	\N	\N	103.73	9557.682200000001	611100	2024-06-08 11:30:00	92.14	t	t	t	133	\N	t	31
55	5	11	53	\N	\N	\N	\N	108.22	9971.3908	611525	2024-06-09 11:30:00	92.14	t	t	t	133	\N	t	32
56	5	5	54	\N	\N	\N	\N	105.01	9675.6214	611945	2024-06-10 11:30:00	92.14	t	t	t	133	\N	t	33
57	5	5	55	\N	\N	\N	\N	108.06	9956.6484	612369	2024-06-11 11:30:00	92.14	t	t	t	133	\N	t	34
58	5	7	56	\N	\N	\N	\N	106.4	9803.696	612793	2024-06-12 11:30:00	92.14	t	t	t	133	\N	t	35
59	5	4	57	\N	\N	\N	\N	110.44	10175.9416	613218	2024-06-13 11:30:00	92.14	t	t	t	133	\N	t	36
60	5	5	58	\N	\N	\N	\N	106.25	9789.875	613648	2024-06-14 11:30:00	92.14	t	t	t	133	\N	t	37
61	5	4	59	\N	\N	\N	\N	103.11	9500.5554	614073	2024-06-15 11:30:00	92.14	t	t	t	133	\N	t	38
62	5	12	60	\N	\N	\N	\N	109	10043.26	614499	2024-06-16 11:30:00	92.14	t	t	t	133	\N	t	39
63	7	9	61	\N	\N	\N	\N	183.16	16876.362399999998	47232	2024-06-24 17:16:03	92.14	f	t	t	\N	\N	f	23
\.


--
-- Data for Name: operator_driver; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.operator_driver (operator_driver_sno, org_sno, driver_sno, accept_status_cd, active_flag) FROM stdin;
1	2	2	122	t
2	3	3	122	t
3	3	4	122	t
4	3	5	122	t
5	3	6	122	t
6	3	7	122	t
7	3	8	122	t
8	3	9	122	t
9	3	10	122	t
10	3	11	122	t
11	3	12	122	t
12	3	13	122	t
13	3	14	122	t
14	3	15	122	t
\.


--
-- Data for Name: operator_route; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.operator_route (operator_route_sno, route_sno, operator_sno, active_flag) FROM stdin;
1	1	1	t
2	2	1	t
3	3	2	t
4	4	2	t
6	6	3	t
8	8	3	t
9	9	3	t
10	10	3	t
12	12	3	t
14	14	3	t
13	6	3	t
11	5	3	t
7	5	3	t
5	5	3	t
\.


--
-- Data for Name: org; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.org (org_sno, org_name, owner_name, vehicle_number, org_status_cd, active_flag) FROM stdin;
1	SAI	Test	TN60AL1708	19	t
2	Saara	Jawahar	TN01AS7484	19	t
3	Karthikeyan Bus Transport	Jayaraman A M V	TN86F5335	19	t
\.


--
-- Data for Name: org_contact; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.org_contact (org_contact_sno, org_sno, contact_sno, active_flag) FROM stdin;
1	1	1	t
2	2	2	t
3	3	3	t
4	3	4	t
\.


--
-- Data for Name: org_detail; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.org_detail (org_detail_sno, org_sno, org_logo, org_banner, address_sno, org_website) FROM stdin;
1	1	{}	{}	1	\N
2	2	{}	{}	2	\N
3	3	{}	{}	3	\N
\.


--
-- Data for Name: org_owner; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.org_owner (org_owner_sno, org_sno, app_user_sno) FROM stdin;
1	1	3
2	2	4
3	3	9
\.


--
-- Data for Name: org_social_link; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.org_social_link (org_social_link_sno, org_sno, social_link_sno, active_flag) FROM stdin;
1	1	1	t
2	1	2	t
3	1	3	t
4	2	4	t
5	2	5	t
6	2	6	t
7	3	7	t
8	3	8	t
9	3	9	t
\.


--
-- Data for Name: org_user; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.org_user (org_user_sno, operator_user_sno, role_user_sno) FROM stdin;
1	9	18
\.


--
-- Data for Name: org_vehicle; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.org_vehicle (org_vehicle_sno, org_sno, vehicle_sno) FROM stdin;
1	1	1
2	2	2
3	3	3
4	3	4
5	3	5
6	3	6
7	3	7
\.


--
-- Data for Name: reject_reason; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.reject_reason (reject_reason_sno, org_sno, reason) FROM stdin;
\.


--
-- Data for Name: single_route; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.single_route (single_route_sno, route_sno, org_sno, vehicle_sno, starting_time, running_time, active_flag) FROM stdin;
1	1	1	1	2024-03-16 05:00:00	480	t
2	11	3	5	2024-03-19 05:57:00	90	t
3	11	3	5	2024-03-19 16:00:00	95	t
4	11	3	5	2024-03-19 11:44:00	100	t
5	11	3	5	2024-03-19 19:48:00	95	t
6	12	3	5	2024-03-19 17:57:00	100	t
7	12	3	5	2024-03-19 22:05:00	85	t
8	12	3	5	2024-03-19 09:30:00	100	t
9	12	3	5	2024-03-19 13:41:00	95	t
10	10	3	4	2024-03-19 07:10:00	105	t
11	9	3	4	2024-03-19 09:20:00	105	t
12	7	3	4	2024-03-19 13:20:00	95	t
13	7	3	4	2024-03-19 18:22:00	100	t
14	7	3	4	2024-03-19 22:19:00	90	t
15	7	3	4	2024-03-19 03:35:00	85	t
16	8	3	4	2024-03-19 16:22:00	100	t
17	8	3	4	2024-03-19 11:25:00	95	t
18	8	3	4	2024-03-19 20:06:00	95	t
19	8	3	4	2024-03-19 23:55:00	85	t
20	5	3	3	2024-03-19 00:05:00	80	t
21	5	3	3	2024-03-19 08:58:00	95	t
22	5	3	3	2024-03-19 16:17:00	95	t
23	5	3	3	2024-03-19 04:23:00	85	t
24	5	3	3	2024-03-19 20:06:00	95	t
25	6	3	3	2024-03-19 02:05:00	80	t
26	6	3	3	2024-03-19 06:49:00	95	t
27	6	3	3	2024-03-19 11:10:00	95	t
28	6	3	3	2024-03-19 18:09:00	100	t
29	6	3	3	2024-03-19 22:15:00	90	t
30	14	3	7	2024-05-24 01:42:00	75	t
31	14	3	7	2024-05-24 06:50:00	90	t
32	14	3	7	2024-05-24 10:55:00	95	t
33	14	3	7	2024-05-24 15:21:00	95	t
34	14	3	7	2024-05-24 19:25:00	60	t
35	13	3	7	2024-05-24 04:30:00	90	t
36	13	3	7	2024-05-24 08:45:00	95	t
37	13	3	7	2024-05-24 12:50:00	95	t
38	13	3	7	2024-05-24 17:30:00	95	t
39	13	3	7	2024-05-24 21:25:00	90	t
\.


--
-- Data for Name: toll_pass_detail; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.toll_pass_detail (toll_pass_detail_sno, vehicle_sno, org_sno, toll_id, toll_name, toll_amount, pass_start_date, pass_end_date, active_flag, is_paid) FROM stdin;
1	1	1	THJe34	checkanu	20000	2024-03-01	2024-03-31	\N	f
2	2	2	\N	SAAS	3200	2024-03-20	2024-04-04	\N	f
5	7	3	043001	Vaiguntham	7940	2024-06-04	2024-07-03	\N	t
3	5	3	043001	Vaiguntham	7940	2024-06-08	2024-07-07	\N	t
4	3	3	043001	Vaiguntham	7940	2024-06-08	2024-07-07	\N	t
6	4	3	043001	Vaiguntham	7940	2024-06-24	2024-07-23	\N	t
\.


--
-- Data for Name: trip; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.trip (trip_sno, source_name, destination, start_date, end_date, district_sno, active_flag) FROM stdin;
\.


--
-- Data for Name: trip_route; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.trip_route (trip_route_sno, trip_sno, via_name, latitude, longitude, active_flag) FROM stdin;
\.


--
-- Data for Name: vehicle; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.vehicle (vehicle_sno, vehicle_reg_number, vehicle_name, vehicle_banner_name, chase_number, engine_number, media_sno, vehicle_type_cd, tyre_type_cd, tyre_size_cd, active_flag, kyc_status, reject_reason, tyre_count_cd) FROM stdin;
2	TN01AS7484	Sri Travels	SRI 	GFHTY7585	FHFJDI7589	\N	21	{1,2}	{2,3}	t	58	Test	113
1	TN60AL1708	SMS	SMS	ADS466SDHHAS	HJDSJDSA67778	\N	21	{3}	{19}	t	58	Test	113
7	TN86J5799	AMVJ Bus Transports	AMVJ	MB1PREHD3REPM7075	RPEZ400737	\N	21	{3}	{19}	t	19	\N	113
6	TN86D0790	Karthikeyan Bus Transport	AMVJ	MB1PBEHD2JEDA7257	JEEZ414336	\N	22	{3}	{19}	t	19	\N	113
5	TN86E2299	Karthikeyan Bus Transport	AMVJ	MB1PBEHD7KEDE0983	KDEZ417201	\N	21	{3}	{19}	t	19	\N	113
4	TN86E5699	Karthikeyan Bus Transport	AMVJ	MB1PBEHD6LEKF0982	LKEZ400817	\N	21	{2}	{14}	t	19	\N	113
3	TN86F5335	Karthikeyan Bus Transport	AMVJ	MB1PBEHD0MEJG1765	MKEZ404989	\N	21	{3}	{19}	t	19	\N	113
\.


--
-- Data for Name: vehicle_detail; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.vehicle_detail (vehicle_detail_sno, vehicle_sno, vehicle_logo, vehicle_reg_date, fc_expiry_date, insurance_expiry_date, pollution_expiry_date, tax_expiry_date, permit_expiry_date, state_sno, district_sno, odo_meter_value, fuel_capacity, fuel_type_cd, video_types_cd, seat_type_cd, audio_types_cd, cool_type_cd, suspension_type, driving_type_cd, wheelbase_type_cd, vehicle_make_cd, vehicle_model, wheels_cd, stepny_cd, fuel_norms_cd, seat_capacity_cd, price_perday, otherslist, seat_capacity, luckage_count, top_luckage_carrier, public_addressing_system_cd, lighting_system_cd, image_sno, fc_expiry_amount, insurance_expiry_amount, tax_expiry_amount) FROM stdin;
1	1	\N	2022-01-04 00:00:00	2024-03-19 00:00:00	2024-03-21 00:00:00	2024-03-08 00:00:00	2024-03-07 00:00:00	2024-03-23 00:00:00	1	28	80000	40	27	\N	\N	\N	\N	\N	53	49	64	2022	\N	1	71	\N	\N	[]	50	\N	\N	\N	\N	\N	600000	80000	4000
2	2	\N	2024-03-09 00:00:00	2026-06-06 00:00:00	2025-06-05 00:00:00	2025-11-22 00:00:00	2025-11-28 00:00:00	2025-06-20 00:00:00	1	16	3200	450	26	\N	\N	\N	\N	\N	53	49	65	\N	\N	\N	70	\N	\N	[]	\N	\N	\N	\N	\N	\N	\N	\N	\N
7	7	\N	2024-03-28 00:00:00	2026-03-27 00:00:00	2025-02-08 00:00:00	2025-03-27 00:00:00	2024-09-30 00:00:00	2024-08-20 00:00:00	1	23	47939	320	27	\N	\N	\N	\N	\N	55	50	62	TF2012.0T6R	\N	1	71	\N	\N	[]	62	\N	\N	\N	\N	\N	150000	99000	35805
6	6	\N	2018-08-21 00:00:00	2024-11-22 00:00:00	2024-12-01 00:00:00	2024-11-29 00:00:00	2024-09-30 00:00:00	2028-08-07 00:00:00	1	8	310000	240	27	{30}	42	{35}	40	44	55	49	62	VK1611.0D4R	\N	1	71	\N	18000	[]	52	2	f	{110}	{112}	71	125000	80000	29553
5	5	\N	2019-08-20 00:00:00	2025-09-12 00:00:00	2024-12-05 00:00:00	2024-10-08 00:00:00	2024-09-30 00:00:00	2026-10-08 00:00:00	1	18	614925	240	27	\N	\N	\N	\N	\N	55	49	62	VK1611.0D4R	\N	1	70	\N	\N	[]	54	\N	\N	\N	\N	\N	125000	80000	30689
4	4	\N	2020-02-26 00:00:00	2026-02-18 00:00:00	2025-06-26 00:00:00	2024-10-08 00:00:00	2024-09-30 00:00:00	2027-10-23 00:00:00	1	8	570748	240	27	\N	\N	\N	\N	\N	55	49	62	VK1611.0D4R	\N	1	70	\N	\N	[]	54	\N	\N	\N	\N	\N	120000	82261	30689
3	3	\N	2021-07-09 00:00:00	2025-06-29 00:00:00	2025-04-12 00:00:00	2025-01-18 00:00:00	2024-09-30 00:00:00	2029-02-28 00:00:00	1	8	350000	240	27	\N	\N	\N	\N	\N	55	49	62	VK2011.4T6R	\N	1	71	\N	\N	[]	54	\N	\N	\N	\N	\N	120000	85000	29553
\.


--
-- Data for Name: vehicle_driver; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.vehicle_driver (vehicle_driver_sno, driver_sno, vehicle_sno, created_on) FROM stdin;
\.


--
-- Data for Name: vehicle_due_fixed_pay; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.vehicle_due_fixed_pay (vehicle_due_sno, vehicle_sno, org_sno, bank_account_detail_sno, due_type_cd, due_close_date, remainder_type_cd, due_amount, active_flag, bank_name, bank_account_number, discription) FROM stdin;
1	1	1	1	129	2024-11-21	\N	20000	t	KVB	11100023432323244343	\N
2	2	2	2	130	2024-11-22	\N	\N	t	SBI	SBI747586	\N
3	3	3	\N	130	2025-04-01	\N	\N	t	ICICI Bank	LVERO00043503989	RTGS Chasis
4	3	3	3	129	2025-07-22	\N	19340	t	ICICI Bank	LVERO00044047804	RTGS Body
5	7	3	4	130	2027-03-05	\N	\N	t	HDFC Bank	89613882	ECS Chasis
6	7	3	4	129	2027-03-10	\N	26265	t	HDFC Bank	99540178	ECS Body
7	6	3	5	129	2025-08-01	\N	46542	t	ICICI Bank	UVERO00048444483	Refinance
9	5	3	3	130	2024-12-15	\N	\N	t	ICICI Bank	UVERO00046971315	RTGS Refinance
10	4	3	3	129	2027-12-05	\N	37870	t	HDFC Bank	89170603	Chq Refinance
\.


--
-- Data for Name: vehicle_due_variable_pay; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.vehicle_due_variable_pay (vehicle_due_variable_pay_sno, vehicle_due_sno, due_pay_date, due_amount, active_flag, is_pass_paid) FROM stdin;
1	1	2024-03-21	20000	t	f
2	1	2024-04-21	20000	t	f
3	1	2024-05-21	20000	t	f
4	1	2024-06-21	20000	t	f
5	1	2024-07-21	20000	t	f
6	1	2024-08-21	20000	t	f
7	1	2024-09-21	20000	t	f
8	1	2024-10-21	20000	t	f
9	1	2024-11-21	20000	t	f
10	2	2024-03-22	4300	t	f
11	2	2024-04-22	2000	t	f
12	2	2024-05-22	6500	t	f
13	2	2024-06-22	2100	t	f
14	2	2024-07-22	1500	t	f
15	2	2024-08-22	2300	t	f
16	2	2024-09-22	3100	t	f
17	2	2024-10-22	2100	t	f
18	2	2024-11-22	3000	t	f
22	3	2024-09-01	46813	t	f
23	3	2024-10-01	46534	t	f
24	3	2024-11-01	46255	t	f
25	3	2024-12-01	45977	t	f
26	3	2025-01-01	45698	t	f
27	3	2025-02-01	45419	t	f
28	3	2025-03-01	45141	t	f
29	3	2025-04-01	44856	t	f
32	4	2024-08-22	19340	t	f
33	4	2024-09-22	19340	t	f
34	4	2024-10-22	19340	t	f
35	4	2024-11-22	19340	t	f
36	4	2024-12-22	19340	t	f
37	4	2025-01-22	19340	t	f
38	4	2025-02-22	19340	t	f
39	4	2025-03-22	19340	t	f
40	4	2025-04-22	19340	t	f
41	4	2025-05-22	19340	t	f
42	4	2025-06-22	19340	t	f
43	4	2025-07-22	19340	t	f
47	5	2024-09-05	101086	t	f
48	5	2024-10-05	100471	t	f
49	5	2024-11-05	99855	t	f
50	5	2024-12-05	99239	t	f
51	5	2025-01-05	98623	t	f
52	5	2025-02-05	98008	t	f
53	5	2025-03-05	97392	t	f
54	5	2025-04-05	96776	t	f
55	5	2025-05-05	96161	t	f
56	5	2025-06-05	95545	t	f
57	5	2025-07-05	94929	t	f
58	5	2025-08-05	94314	t	f
59	5	2025-09-05	93698	t	f
60	5	2025-10-05	93082	t	f
61	5	2025-11-05	92467	t	f
62	5	2025-12-05	91851	t	f
63	5	2026-01-05	91235	t	f
64	5	2026-02-05	90620	t	f
65	5	2026-03-05	90004	t	f
66	5	2026-04-05	89388	t	f
67	5	2026-05-05	88773	t	f
68	5	2026-06-05	88157	t	f
69	5	2026-07-05	87541	t	f
70	5	2026-08-05	86925	t	f
71	5	2026-09-05	86310	t	f
72	5	2026-10-05	85694	t	f
73	5	2026-11-05	85078	t	f
74	5	2026-12-05	84463	t	f
75	5	2027-01-05	83847	t	f
76	5	2027-02-05	83231	t	f
77	5	2027-03-05	82500	t	f
81	6	2024-09-10	26265	t	f
82	6	2024-10-10	26265	t	f
83	6	2024-11-10	26265	t	f
84	6	2024-12-10	26265	t	f
85	6	2025-01-10	26265	t	f
86	6	2025-02-10	26265	t	f
87	6	2025-03-10	26265	t	f
88	6	2025-04-10	26265	t	f
89	6	2025-05-10	26265	t	f
90	6	2025-06-10	26265	t	f
91	6	2025-07-10	26265	t	f
92	6	2025-08-10	26265	t	f
93	6	2025-09-10	26265	t	f
94	6	2025-10-10	26265	t	f
95	6	2025-11-10	26265	t	f
96	6	2025-12-10	26265	t	f
97	6	2026-01-10	26265	t	f
98	6	2026-02-10	26265	t	f
99	6	2026-03-10	26265	t	f
100	6	2026-04-10	26265	t	f
101	6	2026-05-10	26265	t	f
102	6	2026-06-10	26265	t	f
103	6	2026-07-10	26265	t	f
104	6	2026-08-10	26265	t	f
105	6	2026-09-10	26265	t	f
106	6	2026-10-10	26265	t	f
107	6	2026-11-10	26265	t	f
108	6	2026-12-10	26265	t	f
109	6	2027-01-10	26265	t	f
110	6	2027-02-10	26265	t	f
111	6	2027-03-10	26265	t	f
115	7	2024-09-01	46542	t	f
116	7	2024-10-01	46542	t	f
117	7	2024-11-01	46542	t	f
118	7	2024-12-01	46542	t	f
119	7	2025-01-01	46542	t	f
120	7	2025-02-01	46542	t	f
112	7	2024-06-01	46542	t	t
78	6	2024-06-10	26265	t	t
30	4	2024-06-22	19340	t	t
20	3	2024-07-01	47370	t	t
113	7	2024-07-01	46542	t	t
45	5	2024-07-05	102318	t	t
79	6	2024-07-10	26265	t	t
31	4	2024-07-22	19340	t	t
21	3	2024-08-01	47091	t	t
114	7	2024-08-01	46542	t	t
46	5	2024-08-05	101702	t	t
80	6	2024-08-10	26265	t	t
121	7	2025-03-01	46542	t	f
122	7	2025-04-01	46542	t	f
123	7	2025-05-01	46542	t	f
124	7	2025-06-01	46542	t	f
125	7	2025-07-01	46542	t	f
126	7	2025-08-01	46542	t	f
136	9	2024-08-15	43448	t	f
137	9	2024-09-15	43092	t	f
138	9	2024-10-15	42735	t	f
139	9	2024-11-15	42379	t	f
140	9	2024-12-15	41216	t	f
144	10	2024-09-05	37870	t	f
145	10	2024-10-05	37870	t	f
146	10	2024-11-05	37870	t	f
147	10	2024-12-05	37870	t	f
148	10	2025-01-05	37870	t	f
149	10	2025-02-05	37870	t	f
150	10	2025-03-05	37870	t	f
151	10	2025-04-05	37870	t	f
152	10	2025-05-05	37870	t	f
153	10	2025-06-05	37870	t	f
154	10	2025-07-05	37870	t	f
155	10	2025-08-05	37870	t	f
156	10	2025-09-05	37870	t	f
157	10	2025-10-05	37870	t	f
158	10	2025-11-05	37870	t	f
159	10	2025-12-05	37870	t	f
160	10	2026-01-05	37870	t	f
161	10	2026-02-05	37870	t	f
162	10	2026-03-05	37870	t	f
163	10	2026-04-05	37870	t	f
164	10	2026-05-05	37870	t	f
165	10	2026-06-05	37870	t	f
166	10	2026-07-05	37870	t	f
167	10	2026-08-05	37870	t	f
168	10	2026-09-05	37870	t	f
169	10	2026-10-05	37870	t	f
170	10	2026-11-05	37870	t	f
171	10	2026-12-05	37870	t	f
172	10	2027-01-05	37870	t	f
173	10	2027-02-05	37870	t	f
174	10	2027-03-05	37870	t	f
175	10	2027-04-05	37870	t	f
176	10	2027-05-05	37870	t	f
177	10	2027-06-05	37870	t	f
178	10	2027-07-05	37870	t	f
179	10	2027-08-05	37870	t	f
180	10	2027-09-05	37870	t	f
181	10	2027-10-05	37870	t	f
182	10	2027-11-05	37870	t	f
183	10	2027-12-05	37870	t	f
19	3	2024-06-01	47648	t	t
141	10	2024-06-05	37870	t	t
44	5	2024-06-05	102933	t	t
134	9	2024-06-15	44160	t	t
142	10	2024-07-05	37870	t	t
135	9	2024-07-15	43804	t	t
143	10	2024-08-05	37870	t	t
\.


--
-- Data for Name: vehicle_owner; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.vehicle_owner (vehicle_owner_sno, vehicle_sno, owner_name, owner_number, current_owner, purchase_date, active_flag, app_user_sno) FROM stdin;
1	1	subash	9751773508	f	\N	t	\N
2	2	Arun	1234567890	f	\N	t	\N
7	7	AMVJ Bus Transports	9442233456	f	\N	t	\N
6	6	Jayaraman A M V	9442233456	f	\N	t	\N
5	5	Jayaraman A M V	9442233456	f	\N	t	\N
4	4	Jayaraman A M V	9442233456	f	\N	t	\N
3	3	Jayaraman A M V	9442233456	f	\N	t	\N
\.


--
-- Data for Name: vehicle_route; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.vehicle_route (vehicle_route_sno, operator_route_sno, vehicle_sno, active_flag) FROM stdin;
1	1	1	t
2	2	1	t
3	3	2	t
4	4	2	t
5	5	3	t
6	6	3	t
7	7	4	t
8	8	4	t
9	9	4	t
10	10	4	t
11	11	5	t
12	12	5	t
13	\N	\N	t
14	\N	\N	t
15	\N	\N	t
16	\N	\N	t
17	\N	\N	t
18	13	7	t
19	14	7	t
20	\N	\N	t
21	\N	\N	t
22	\N	\N	t
23	\N	\N	t
24	\N	\N	t
25	\N	\N	t
26	\N	\N	t
27	\N	\N	t
28	\N	\N	t
\.


--
-- Data for Name: via; Type: TABLE DATA; Schema: operator; Owner: postgres
--

COPY operator.via (via_sno, operator_route_sno, city_sno, active_flag) FROM stdin;
1	1	2	t
2	2	2	t
3	1	3	t
4	2	3	t
5	1	4	t
6	2	4	t
7	1	5	t
8	2	5	t
9	1	6	t
10	2	6	t
11	1	7	t
12	2	7	t
13	1	8	t
14	2	8	t
15	1	9	t
16	2	9	t
17	3	1	t
18	4	1	t
20	6	28	t
22	8	28	t
24	8	38	t
25	9	28	t
26	10	28	t
28	12	38	t
30	12	28	t
32	14	28	t
31	13	28	t
27	11	38	t
29	11	28	t
21	7	28	t
23	7	38	t
19	5	28	t
\.


--
-- Data for Name: app_menu; Type: TABLE DATA; Schema: portal; Owner: postgres
--

COPY portal.app_menu (app_menu_sno, title, href, icon, has_sub_menu, parent_menu_sno, router_link) FROM stdin;
1	Dashboard		tachometer	f	0	/bus-dashboard
2	Operator		user	f	0	/operator
3	Vehicle		bus	f	0	/registervehicle
4	Approval		check	f	0	/approval
5	Operators		user	f	0	/operatorlist
6	Route		route	t	0	\N
7	Location		map-marker	f	6	/location
8	Single		route	f	6	/single
9	Driver Activity		bars	t	0	\N
10	Driver		user-circle-o	f	9	/driver
11	Attendance		id-card-o	f	9	/busAttendance
12	Fuel		tachometer	f	9	/busFuel
13	Booking		money	t	0	\N
14	View-booking		user	f	13	/view-booking
15	Booking calendar		calendar	f	13	/reminder
16	Tyre		dot-circle-o	t	0	\N
17	Tyres		life-ring	f	16	/tyre
18	Manage Tyre		file-text-o	f	16	/managetyre
19	Report		clock-o	t	0	\N
20	Bus Report		bus	f	19	/bus-report
21	Fuel Report		tachometer	f	19	/fuel-report
22	Driver Report		users	f	19	/driver-report
23	Vehicles		bus	f	0	/vehiclelist
24	Drivers		user-circle-o	f	0	/driverlist
25	Notification		bell	f	0	/notification
26	Assign driver vehicle		address-card	f	9	/assign-driver
27	Menu Permission		key	f	0	/menu-permission
28	User		user	t	0	\N
29	Find Bus		bus	f	28	/find-bus
30	Rent Bus		user	f	28	/rent-bus
31	Trip Calculate		route	f	28	/trip-calculate
32	Find Bus		bus	f	0	/find-bus
33	Rent Bus		user	f	0	/rent-bus
34	Trip Calculate		route	f	0	/trip-calculate
35	Jobs		briefcase	t	0	\N
36	Job Search		search-plus	f	35	/job-search
37	Job Post		user-plus	f	35	/job-post
\.


--
-- Data for Name: app_menu_role; Type: TABLE DATA; Schema: portal; Owner: postgres
--

COPY portal.app_menu_role (app_menu_role_sno, app_menu_sno, role_cd) FROM stdin;
1	1	1
2	1	2
3	1	3
4	1	4
5	1	5
6	1	127
7	1	128
8	2	2
9	2	5
10	3	2
11	4	1
12	5	1
13	6	2
14	7	1
15	7	2
16	8	2
17	9	2
18	10	2
19	11	2
20	12	2
21	13	2
22	14	2
23	15	2
24	16	2
25	17	2
26	18	2
27	19	2
28	20	2
29	21	2
30	22	2
31	23	1
32	24	1
33	25	1
34	25	2
35	26	2
36	27	2
37	28	1
38	28	2
39	28	3
40	28	4
41	28	127
42	28	128
43	29	1
44	29	2
45	29	3
46	29	4
47	29	127
48	29	128
49	30	1
50	30	2
51	30	3
52	30	4
53	30	127
54	30	128
55	31	1
56	31	2
57	31	3
58	31	4
59	31	127
60	31	128
61	32	5
62	33	5
63	34	5
64	35	2
65	36	2
66	37	2
67	2	128
68	3	128
69	6	128
70	8	128
71	11	128
72	13	128
73	7	128
74	9	128
75	10	128
76	12	128
77	14	128
78	15	128
79	16	128
80	17	128
81	18	128
82	19	128
\.


--
-- Data for Name: app_menu_user; Type: TABLE DATA; Schema: portal; Owner: postgres
--

COPY portal.app_menu_user (app_menu_user_sno, app_menu_sno, app_user_sno, is_admin) FROM stdin;
1	2	18	t
2	3	18	t
3	6	18	t
7	7	18	t
4	8	18	t
8	9	18	t
9	10	18	t
5	11	18	t
10	12	18	t
6	13	18	t
11	14	18	t
12	15	18	t
13	16	18	t
14	17	18	t
15	18	18	t
16	19	18	t
\.


--
-- Data for Name: app_user; Type: TABLE DATA; Schema: portal; Owner: postgres
--

COPY portal.app_user (app_user_sno, mobile_no, password, confirm_password, user_status_cd) FROM stdin;
1	9790300667	Apple123	Apple123	7
2	9385940104	Apple123	Apple123	7
3	9751773508	Apple@123	Apple@123	7
4	8220686438	Apple123	Apple123	7
22	9486761731	abcd1234	abcd1234	7
21	9940837464	abcd1234	abcd1234	7
23	9345473146	abcd1234	abcd1234	7
5	9788404744	Apple@123	Apple@123	7
9	9442233456	abcd1234	abcd1234	7
24	9865952527	abcd1234	abcd1234	7
7	9751257799	abcd1234	abcd1234	7
10	9442308634	abcd1234	abcd1234	7
25	6379090633	abcd1234	abcd1234	7
26	6478383268	\N	\N	8
11	7373352522	abcd1234	abcd1234	7
12	8508665808	abcd1234	abcd1234	7
27	9945698496	Raaj@20244	Raaj@20244	7
13	9080483332	abcd1234	abcd1234	7
14	8248823364	\N	\N	8
16	9080111923	abcd1234	abcd1234	7
17	9585177077	abcd1234	abcd1234	7
6	6383864180	Apple123	Apple123	7
18	9159956799	abcd1234	abcd1234	7
15	8248323364	abcd1234	abcd1234	7
19	9786770377	abcd1234	abcd1234	7
20	7598735439	abcd1234	abcd1234	7
\.


--
-- Data for Name: app_user_contact; Type: TABLE DATA; Schema: portal; Owner: postgres
--

COPY portal.app_user_contact (app_user_contact_sno, app_user_sno, user_name, mobile_no, alternative_mobile_no, email, user_status_cd) FROM stdin;
\.


--
-- Data for Name: app_user_role; Type: TABLE DATA; Schema: portal; Owner: postgres
--

COPY portal.app_user_role (app_user_role_sno, app_user_sno, role_cd) FROM stdin;
1	1	1
2	2	1
3	3	2
4	4	2
5	5	6
6	6	6
7	7	6
10	10	6
11	11	6
12	12	6
13	13	6
14	14	6
15	15	6
16	16	6
17	17	5
9	9	2
18	18	128
19	19	6
20	20	6
21	21	6
22	22	6
23	23	6
24	24	6
25	25	6
26	26	5
27	27	5
\.


--
-- Data for Name: codes_dtl; Type: TABLE DATA; Schema: portal; Owner: postgres
--

COPY portal.codes_dtl (codes_dtl_sno, codes_hdr_sno, cd_value, seqno, filter_1, filter_2, active_flag) FROM stdin;
1	1	Admin	1	\N	\N	t
2	1	Operator	2	2	\N	t
3	1	Sales/E-Commerce	3	\N	\N	t
4	1	Service Provider	4	\N	\N	t
5	1	User	5	\N	\N	t
6	1	Driver	6	\N	\N	t
127	1	Operator Admin	7	7	\N	t
128	1	Manager	8	8	\N	t
7	2	Active	1	\N	\N	t
8	2	InActive	2	\N	\N	t
9	2	Blocked	3	\N	\N	t
10	3	5	1	true	\N	t
11	3	10	2	false	\N	t
12	3	15	3	false	\N	t
13	4	Male	1	\N	\N	t
14	4	Female	2	\N	\N	t
15	4	Third Gender	3	\N	\N	t
16	5	Android	1	\N	\N	t
17	5	Ios	2	\N	\N	t
18	5	Web	3	\N	\N	t
72	22	One Way Trip	1	\N	\N	t
73	22	Rounded Trip	2	\N	\N	t
19	6	KYC Verified	1	\N	\N	t
20	6	KYC Not Verified	2	\N	\N	t
58	6	KYC Rejected	3	\N	\N	t
21	7	Stage Carriage	1	\N	\N	t
22	7	Contract Carriage	2	\N	\N	t
92	7	Mini stage carriage	3	\N	\N	t
93	7	Mini contract carriage	4	\N	\N	t
94	7	School / College bus	5	\N	\N	t
95	7	Staff bus	6	\N	\N	t
96	7	Omni	7	\N	\N	t
23	8	Facebook	1	\N	\N	t
24	8	Twitter	2	\N	\N	t
25	8	Google	3	\N	\N	t
26	9	Petrol	1	\N	\N	t
27	9	Diesel	2	\N	\N	t
30	11	MP4	1	\N	\N	t
31	11	MKV	2	\N	\N	t
32	11	4K	3	\N	\N	t
33	11	AVI	4	\N	\N	t
34	11	WMV	5	\N	\N	t
35	12	MP3	1	\N	\N	t
36	12	DolByAudio	2	\N	\N	t
37	12	WAV	3	\N	\N	t
38	12	AIFF	4	\N	\N	t
39	13	Ac	1	\N	\N	t
40	13	Non Ac	2	\N	\N	t
41	14	Pushback	1	\N	\N	t
42	14	Normal	2	\N	\N	t
43	15	Airbus	1	\N	\N	t
44	15	Non Airbus	2	\N	\N	t
45	16	HMV	1	\N	\N	t
46	16	HGMV	2	\N	\N	t
47	16	HPMV	3	\N	\N	t
48	17	210 Inches	1	\N	\N	t
49	17	222 Inches	2	\N	\N	t
50	17	244 Inches	3	\N	\N	t
59	19	Owner	1	\N	\N	t
60	19	Manager	2	\N	\N	t
61	19	Admin	3	\N	\N	t
62	20	Ashok Leyland	1	\N	\N	t
63	20	TATA	2	\N	\N	t
64	20	Bharat Benz	3	\N	\N	t
65	20	Mahindra	4	\N	\N	t
66	20	Eicher	5	\N	\N	t
67	20	SML  Isuzu	6	\N	\N	t
68	20	Volvo	7	\N	\N	t
126	20	Scania	8	\N	\N	t
69	21	BS III	1	\N	\N	t
70	21	BS IV	2	\N	\N	t
71	21	BS VI	3	\N	\N	t
109	30	Yes	1	\N	\N	t
110	30	No	2	\N	\N	t
111	31	LED reading lights	1	\N	\N	t
112	31	LED spots	2	\N	\N	t
113	32	6 Tyres	1	6	\N	t
114	32	8 Tyres	2	8	\N	t
115	32	10 Tyres	3	10	\N	t
28	10	open	1	\N	\N	t
29	10	close	2	\N	\N	t
51	18	LMV	1	\N	\N	t
52	18	LMV-TR	2	\N	\N	t
53	18	HMV	3	\N	\N	t
54	18	HGMV	4	\N	\N	t
55	18	HPTV	5	\N	\N	t
56	18	HPMY	6	\N	\N	t
57	18	TRAILER	7	\N	\N	t
84	26	O+	1	\N	\N	t
85	26	O-	2	\N	\N	t
86	26	A+	3	\N	\N	t
87	26	A-	4	\N	\N	t
88	26	B+	5	\N	\N	t
89	26	B-	6	\N	\N	t
90	26	AB+	7	\N	\N	t
91	26	AB-	8	\N	\N	t
122	35	Accept	1	\N	\N	t
123	35	Reject	2	\N	\N	t
124	35	Not Accept	3	\N	\N	t
125	35	Requested	4	\N	\N	t
129	36	Fixed	1	\N	\N	t
130	36	Variable	2	\N	\N	t
131	37	1 day	1	\N	\N	t
132	37	7 days	2	\N	\N	t
133	38	Fuel Filled	1	\N	\N	t
134	38	Partially Filled	2	\N	\N	t
135	38	No Filled	3	\N	\N	t
136	39	Passenger Vehicle	1	\N	\N	t
137	39	Goods Vehicle	2	\N	\N	t
138	40	City / town bus	1	136	\N	t
139	40	Mofussil bus	2	136	\N	t
140	40	Omni bus	3	136	\N	t
141	40	Mini bus	4	136	\N	t
142	40	School / college bus	5	136	\N	t
143	40	Staff bus	6	136	\N	t
144	40	Normal truck	7	137	\N	t
146	40	Trailer	9	137	\N	t
147	40	Tanker	10	137	\N	t
148	40	Container	11	137	\N	t
149	40	Tripper	12	137	\N	t
150	40	Special Vehicle	13	137	\N	t
74	23	Tube Tyre	1	\N	\N	t
75	23	Tubeless Tyre	2	\N	\N	t
76	23	Cross Ply Tyre	3	\N	\N	t
77	23	Radial Ply Tyre	4	\N	\N	t
78	23	Bias Ply Tyre	5	\N	\N	t
79	24	New Tyre	1	\N	\N	t
80	24	Regrooving	2	\N	\N	t
81	24	Repair	3	\N	\N	t
82	25	puncher	1	\N	\N	t
83	25	damaged	2	\N	\N	t
105	28	Online	1	\N	\N	t
106	28	Offline	2	\N	\N	t
97	27	Insert	1	\N	\N	t
98	27	Remove	2	\N	\N	t
99	27	Retired	3	\N	\N	t
100	27	Rotation	4	\N	\N	t
101	27	Pucher	5	\N	\N	t
102	27	Busted	6	\N	\N	t
103	27	Powder	7	\N	\N	t
104	27	Stepny	8	\N	\N	t
107	29	385/65R22.5	1	\N	\N	t
108	29	315/80R22.5	2	\N	\N	t
118	34	CDTire	1	\N	\N	t
119	34	Dtire	2	\N	\N	t
120	34	FTire	3	\N	\N	t
121	34	SWIFT	4	\N	\N	t
116	33	read	1	\N	\N	t
117	33	unread	2	\N	\N	t
145	40	Taurus truck	8	137	\N	t
151	39	Light Passenger Vehicle	3	\N	\N	t
152	39	Light Goods Vehicle	4	\N	\N	t
153	39	Special Vehicle	5	\N	\N	t
154	40	Van	14	151	\N	t
155	40	Car	15	151	\N	t
156	40	Mini truck	16	152	\N	t
157	40	Tata ace	17	152	\N	t
158	40	Harvester	18	153	\N	t
159	40	Construction vehicles	19	153	\N	t
160	40	Crane	20	153	\N	t
161	40	Ambulance	21	153	\N	t
162	9	Electric vehicle	3	\N	\N	t
163	9	Gas	4	\N	\N	t
164	41	Manual	1	\N	\N	t
165	41	Automatic	2	\N	\N	t
166	42	Organisation	1	\N	\N	t
167	42	End user	2	\N	\N	t
\.


--
-- Data for Name: codes_hdr; Type: TABLE DATA; Schema: portal; Owner: postgres
--

COPY portal.codes_hdr (codes_hdr_sno, code_type, active_flag) FROM stdin;
1	role_cd	t
2	user_status_cd	t
3	otp_expire_time	t
4	gender_cd	t
5	device_type_cd	t
22	return_type_cd	t
6	organization_status_cd	t
7	vehicle_type_cd	t
8	social_type_cd	t
9	fuel_type_cd	t
11	video_types_cd	t
12	Audio_types_cd	t
13	Cool_type_cd	t
14	seat_Type_cd	t
15	bus_type_cd	t
16	class_type_cd	t
17	wheel_type_cd	t
19	contact_role_cd	t
20	vehicleMakeCd	t
21	fuelNormsCd	t
30	public_addressing_system_cd	t
31	lighting_system_cd	t
32	tyre_count_cd	t
10	attendance_status_cd	t
18	driving_type_cd	t
26	blood_group_cd	t
35	accept_status_cd	t
36	due_type_cd	t
37	remainder_type_cd	t
38	fuel_fill_type_cd	t
39	drive_type_cd	t
40	job_type_cd	t
23	tyre_type_cd	t
24	tyre_usage_cd	t
25	reason_status_cd	t
28	payment_mode_cd	t
27	tyre_activity_type_cd	t
29	tyre_size_cd	t
34	tyre_model	t
33	notification_status_cd	t
41	transmission_type_cd	t
42	auth_type_cd	t
\.


--
-- Data for Name: contact; Type: TABLE DATA; Schema: portal; Owner: postgres
--

COPY portal.contact (contact_sno, app_user_sno, name, contact_role_cd, mobile_number, email, is_show, active_flag) FROM stdin;
1	3	subash	2	9751773508	\N	\N	t
2	4	Arun	2	1234567890	\N	\N	t
3	9	Jayaraman A M V	2	9442233456	amvjtravels@gmail.com	\N	t
4	18	Sivakumar	128	9159956799		\N	t
\.


--
-- Data for Name: otp; Type: TABLE DATA; Schema: portal; Owner: postgres
--

COPY portal.otp (otp_sno, app_user_sno, sim_otp, api_otp, push_otp, device_id, expire_time, active_flag) FROM stdin;
1	1	258345	72910607	467438719	12345	2024-03-16 14:36:42.187054	t
2	2	425439	879351493	147900653	12345	2024-03-16 14:36:42.20646	t
3	3	684985	773524406	956671571	12345	2024-03-16 15:06:43.706023	t
4	4	722482	838558739	384247485	12345	2024-03-16 15:07:13.269563	t
5	6	929133	63478499	728988264	12345	2024-03-16 16:02:05.533337	t
6	7	171780	372400283	540815921	12345	2024-03-18 09:46:35.192778	t
10	10	676007	349055137	423505217	12345	2024-03-19 12:53:50.433844	t
11	11	690664	628294068	802710651	12345	2024-03-19 18:27:14.650656	t
12	12	689124	27470605	29450373	12345	2024-03-20 11:27:14.240513	t
13	13	502355	597278019	68721635	12345	2024-03-20 12:11:05.531769	t
14	14	481390	313644724	19027039	12345	2024-03-20 14:02:00.174876	t
15	15	360461	222188890	957915272	12345	2024-03-20 14:03:43.983347	t
16	16	284154	241692137	86703384	12345	2024-03-22 11:59:06.011167	t
17	17	111002	912764271	757266781	12345	2024-05-10 15:52:29.238082	t
18	18	401389	823803050	901200133	12345	2024-05-24 17:56:41.531165	t
19	19	434967	901267204	792431724	12345	2024-05-26 16:17:52.965769	t
20	20	859463	290412845	201933135	12345	2024-06-12 11:23:32.935486	t
22	22	686574	969268914	987855951	12345	2024-06-20 15:22:23.717318	t
21	21	952509	463606785	826950146	12345	2024-06-20 15:39:22.6243	t
23	23	173739	325434339	236083812	12345	2024-06-20 16:16:37.0258	t
24	24	212066	121189193	778893251	12345	2024-06-20 16:26:56.19169	t
25	25	211948	723054437	675858495	12345	2024-06-20 22:09:49.326423	t
9	9	510726	274616772	560582255	12345	2024-07-05 21:19:38.721279	t
26	26	897580	468356950	571183427	12345	2024-08-04 11:06:17.040164	t
27	27	944206	101520977	817896596	12345	2024-08-11 12:24:24.797114	t
8	5	361946	494574824	189014331	12345	2024-08-14 08:41:19.485438	t
\.


--
-- Data for Name: signin_config; Type: TABLE DATA; Schema: portal; Owner: postgres
--

COPY portal.signin_config (signin_config_sno, app_user_sno, push_token_id, device_type_cd, device_id, active_flag) FROM stdin;
7	5	dfjFDlFfT_OdRs5dR-USCW:APA91bHpghk5W0l0SMmh-aEghqsmaQY-zLSfU1ufkIMERfBNrsymUmpl9dyjAaoPOJ071UMV25F1qDBTDzqzdjswHezVPzik2XWMfAaV-x6vfBlbSo7HQW3BZeDAoojVOvv3yCAb9DGQ	16	12345	t
5	7	dfjFDlFfT_OdRs5dR-USCW:APA91bHpghk5W0l0SMmh-aEghqsmaQY-zLSfU1ufkIMERfBNrsymUmpl9dyjAaoPOJ071UMV25F1qDBTDzqzdjswHezVPzik2XWMfAaV-x6vfBlbSo7HQW3BZeDAoojVOvv3yCAb9DGQ	16	12345	t
18	19	e9I4nWWOQLu-ole_j93ZaY:APA91bFPcBDR4J3fDTJg0vSd_qVifHY9RpJmge3zMrsKwzcPOXdt9zQMQF_9BZpX3WgAQKmevH5QQFY2DK6kCj_Cfsc3P8-PUljxgng1ZD5ZOxkL-QLdze0KSQM5uocx578jfpJ-W1jv	16	12345	t
10	10	\N	16	12345	t
12	12	\N	16	12345	t
13	13	\N	16	12345	t
19	20	\N	16	12345	t
1	3	\N	18	12345	t
20	22	\N	16	12345	t
21	21	\N	16	12345	t
22	23	\N	16	12345	t
23	24	\N	16	12345	t
24	25	\N	16	12345	t
15	16	fOw06azOTKSN0sdOkUuGgN:APA91bGeI77AWrNyajJkVc1V9QQCcSeJvhUCqGjH_9rmiCowflAzkEodGwkE9XWMG8JDTFS6EkLkvM2jvxCE7zBvNOTnfpre6iVUolx9E-JHaMV_Q1bneu-Lw2N5fNvSDPR4lCpbQVM5	16	12345	t
8	2	\N	18	12345	t
17	18	fOw06azOTKSN0sdOkUuGgN:APA91bGeI77AWrNyajJkVc1V9QQCcSeJvhUCqGjH_9rmiCowflAzkEodGwkE9XWMG8JDTFS6EkLkvM2jvxCE7zBvNOTnfpre6iVUolx9E-JHaMV_Q1bneu-Lw2N5fNvSDPR4lCpbQVM5	18	12345	t
14	15	fOw06azOTKSN0sdOkUuGgN:APA91bGeI77AWrNyajJkVc1V9QQCcSeJvhUCqGjH_9rmiCowflAzkEodGwkE9XWMG8JDTFS6EkLkvM2jvxCE7zBvNOTnfpre6iVUolx9E-JHaMV_Q1bneu-Lw2N5fNvSDPR4lCpbQVM5	16	12345	t
16	17	\N	18	12345	t
11	11	c2tIU7X2RCWH9jKeGKYhub:APA91bEKU6_BvqhW0bLQxmHXS1PPb3ppbUqJwLgAVeJbMaErHbvWZCNNOzwphu-ZuNk3rQEwqGK0yffnw_pCgRRYq535Xnwkwbj0nGIOM3nLhGPwJgOt58meIyPVqR-L4JeXEjYqi9Ce	16	12345	t
25	27	\N	16	12345	t
4	6	eRANs3x1SXKrBX4iTFos20:APA91bGH4_Ez-YTbXpI4bf2KyXzZKT0T1tXyWeHHgOA1UPNq2JVns2KK4FIJcZeQtT4xZ3IIuhmYYaQ_Ito_tM2gE7FgHYk1Qoh85MmjCzVK16ylugWgrtwqSdGhDsNYf64M22mBDh6h	16	12345	t
9	9	\N	18	12345	t
3	1	\N	18	12345	t
2	4	\N	18	12345	t
\.


--
-- Data for Name: social_link; Type: TABLE DATA; Schema: portal; Owner: postgres
--

COPY portal.social_link (social_link_sno, social_url, social_link_type_cd, active_flag) FROM stdin;
1		23	t
2		24	t
3		25	t
4		23	t
5		24	t
6		25	t
7		23	t
8		24	t
9		25	t
\.


--
-- Data for Name: user_profile; Type: TABLE DATA; Schema: portal; Owner: postgres
--

COPY portal.user_profile (user_profile_sno, app_user_sno, first_name, last_name, mobile, gender_cd, photo, dob) FROM stdin;
1	1	Admin	Admin	9790300667	13	\N	\N
2	2	Admin	Admin	9385940104	13	\N	\N
\.


--
-- Data for Name: booking; Type: TABLE DATA; Schema: rent; Owner: postgres
--

COPY rent.booking (booking_sno, vehicle_sno, start_date, end_date, customer_name, customer_address, contact_number, active_flag, no_of_days_booked, total_booking_amount, advance_paid, balance_amount_to_paid, toll_parking_includes, driver_wages_includes, driver_wages, description, booking_id, trip_plan, created_on) FROM stdin;
1	6	2024-03-22 10:30:00	2024-03-22 22:30:00	ErodeAssociation	Bus Mahal, Erode	8610096004	t	1	15000	0	15000	\N	f	\N	\N	FT032224B1	Erode, Kulithalai, Siruganur, Erode	\N
2	6	2024-03-24 18:06:00	2024-03-25 18:06:00	SelvanM	Kollampalayam	9843172917	t	2	45600	10000	35600	t	f	\N	\N	FT032424B2	Erode, Vellore, Sriperumpudur, Nemam, Tiruvallur, Uthukottai, Sathiyavedu, Bathalavallam, Egam Temple, Return to Erode	\N
3	6	2024-05-28 05:00:00	2024-05-29 23:10:00	Naidu Sangam	Bhavani	9087122889	t	2	4000	4000	0	t	t	1200	\N	FT052424B3	Erode, Bhavani, Dindigul, Suruli Falls, Kumuli, Vagamon and return to Bhavani, Erode.	2024-05-24 12:12:23.885567
4	6	2024-06-08 10:00:00	2024-06-08 23:30:00	V S Senthilkumar	Veerappanchatram	9944268717	t	1	13000	4000	9000	t	t	400	\N	FT052524B4	Erode, Coimbatore SNR College and back to Erode	2024-05-25 18:30:17.834548
5	6	2024-06-05 15:30:00	2024-06-06 23:59:00	M Selvam	Kollampalayam, Erode	9843172917	t	2	40600	10000	30600	\N	\N	\N	All inclusive	FT060324B5	Erode, Krishnagiri, Vellore, Sriperumpudur, Thirumalisai, Nemam and return to Erode	2024-06-03 12:53:18.285037
\.


--
-- Data for Name: rent_bus; Type: TABLE DATA; Schema: rent; Owner: postgres
--

COPY rent.rent_bus (rent_bus_sno, customer_sno, trip_starting_date, trip_end_date, trip_source, trip_destination, trip_via, is_same_route, return_type_cd, return_rent_bus_sno, total_km) FROM stdin;
1	4	2024-04-08	2024-04-19	{"lat":13.0826802,"lang":80.2707184,"place":"Chennai, Tamil Nadu, India"}	{"lat":10.0079322,"lang":77.4735441,"place":"Theni, Tamil Nadu, India"}	[{"lat":9.9252007,"lang":78.1197754,"place":"Madurai, Tamil Nadu, India"}]	f	72	\N	641.5288873271347
2	\N	2024-05-18	2024-05-22	{"lat":13.0827989,"lang":80.2754246,"place":"Puratchi Thalaivar, Dr MGR Central, railway station, Kannappar Thidal, Periyamet, Chennai, Tamil Nadu 600003, India"}	{"lat":9.172669599999999,"lang":77.8714879,"place":"Kovilpatti, Tamil Nadu, India"}	[{"lat":9.9252007,"lang":78.1197754,"place":"Madurai, Tamil Nadu, India"}]	f	72	\N	663.5281833158152
3	\N	2024-05-18	2024-05-22	{"lat":13.0827989,"lang":80.2754246,"place":"Puratchi Thalaivar, Dr MGR Central, railway station, Kannappar Thidal, Periyamet, Chennai, Tamil Nadu 600003, India"}	{"lat":9.172669599999999,"lang":77.8714879,"place":"Kovilpatti, Tamil Nadu, India"}	[{"lat":9.9252007,"lang":78.1197754,"place":"Madurai, Tamil Nadu, India"}]	f	72	2	663.5281833158152
4	4	2024-05-15	2024-05-21	{"lat":13.0843007,"lang":80.2704622,"place":"Chennai, Tamil Nadu, India"}	{"lat":10.1631526,"lang":76.64127119999999,"place":"Kerala, India"}	[{"lat":12.9715987,"lang":77.5945627,"place":"Bengaluru, Karnataka, India"}]	f	72	\N	805.0284129690626
5	4	2024-05-17	2024-05-20	{"lat":9.451484299999999,"lang":77.55434249999999,"place":"Rajapalayam, Tamil Nadu, India"}	{"lat":9.9252007,"lang":78.1197754,"place":"Madurai, Tamil Nadu, India"}	[{"lat":10.0079322,"lang":77.4735441,"place":"Theni, Tamil Nadu, India"}]	f	72	\N	174.0351696510164
6	7	2024-05-13	2024-05-13	{"lat":11.3410364,"lang":77.7171642,"place":"Erode, Tamil Nadu, India"}	{"lat":11.3410364,"lang":77.7171642,"place":"Erode, Tamil Nadu, India"}	[{"lat":10.4500374,"lang":77.5161356,"place":"Palani, Tamil Nadu, India"}]	f	72	\N	263.84017579016074
7	7	2024-05-13	2024-05-14	{"lat":10.4500374,"lang":77.5161356,"place":"பழனி, Tamil Nadu, India"}	{"lat":9.9252007,"lang":78.1197754,"place":"மதுரை, Tamil Nadu, India"}	[{"lat":10.3623794,"lang":77.9694579,"place":"திண்டுக்கல், Tamil Nadu, India"}]	f	72	\N	132.40246798002426
8	7	2024-05-14	2024-05-15	{"lat":11.3410364,"lang":77.7171642,"place":"Erode, Tamil Nadu, India"}	{"lat":10.4500374,"lang":77.5161356,"place":"Palani, Tamil Nadu, India"}	[{"lat":10.9600778,"lang":78.07660360000001,"place":"Karur, Tamil Nadu, India"}]	f	72	\N	183.54583322197806
9	7	2024-05-14	2024-05-15	{"lat":11.3410364,"lang":77.7171642,"place":"Erode, Tamil Nadu, India"}	{"lat":10.4500374,"lang":77.5161356,"place":"Palani, Tamil Nadu, India"}	[{"lat":10.9600778,"lang":78.07660360000001,"place":"Karur, Tamil Nadu, India"},{"lat":10.3623794,"lang":77.9694579,"place":"Dindigul, Tamil Nadu, India"}]	f	72	\N	228.45674516949953
10	\N	2024-05-27	2024-05-29	{"lat":11.3410364,"lang":77.7171642,"place":"Erode, Tamil Nadu, India"}	{}	[{"lat":10.3623794,"lang":77.9694579,"place":"Dindigul, Tamil Nadu 624001, India"},{"lat":9.655222199999999,"lang":77.309054,"place":"Near Cumbum, M845+3JM, Suruli R.F., Tamil Nadu 625516, India"},{"lat":9.686181399999999,"lang":76.9052294,"place":"Vagamon, Kerala, India"},{"lat":10.3623794,"lang":77.9694579,"place":"Dindigul, Tamil Nadu 624001, India"}]	f	73	\N	668.7470732052238
11	\N	2024-05-27	2024-05-29	{}	{"lat":11.3410364,"lang":77.7171642,"place":"Erode, Tamil Nadu, India"}	[{"lat":10.3623794,"lang":77.9694579,"place":"Dindigul, Tamil Nadu 624001, India"},{"lat":9.655222199999999,"lang":77.309054,"place":"Near Cumbum, M845+3JM, Suruli R.F., Tamil Nadu 625516, India"},{"lat":9.686181399999999,"lang":76.9052294,"place":"Vagamon, Kerala, India"},{"lat":10.3623794,"lang":77.9694579,"place":"Dindigul, Tamil Nadu 624001, India"}]	f	73	10	668.7470732052238
12	7	2024-05-25	2024-05-26	{"lat":9.9252007,"lang":78.1197754,"place":"Madurai, Tamil Nadu, India"}	{"lat":11.0168445,"lang":76.9558321,"place":"Coimbatore, Tamil Nadu, India"}	[{"lat":10.3623794,"lang":77.9694579,"place":"Dindigul, Tamil Nadu, India"}]	f	72	\N	238.99670601301892
13	7	2024-07-10	2024-07-30	{"lat":11.3499616,"lang":77.7310758,"place":"Amvj Travels, KNK Road, Janakiammal Layout, Karungalpalayam, Tamil Nadu, India"}	{"lat":34.2268475,"lang":77.5619419,"place":"Ladakh, India"}	[{"lat":33.277839,"lang":75.34121789999999,"place":"Jammu and Kashmir"}]	f	72	\N	3485.6085634194333
14	7	2024-07-10	2024-07-11	{"lat":11.3499616,"lang":77.7310758,"place":"Amvj Travels, KNK Road, Janakiammal Layout, Karungalpalayam, Tamil Nadu, India"}	{"lat":11.664325,"lang":78.1460142,"place":"Salem, Tamil Nadu, India"}	[]	f	72	\N	74.29339697634568
\.


--
-- Data for Name: permit_route; Type: TABLE DATA; Schema: stage_carriage; Owner: postgres
--

COPY stage_carriage.permit_route (permit_route_sno, source_city_sno, destination_city_sno, vehicle_sno, active_flag) FROM stdin;
\.


--
-- Data for Name: single; Type: TABLE DATA; Schema: stage_carriage; Owner: postgres
--

COPY stage_carriage.single (single_sno, route_sno, start_time, vehicle_sno, running_mints, active_flag) FROM stdin;
\.


--
-- Data for Name: via; Type: TABLE DATA; Schema: stage_carriage; Owner: postgres
--

COPY stage_carriage.via (via_sno, single_sno, via_city_sno, active_flag) FROM stdin;
\.


--
-- Data for Name: tyre; Type: TABLE DATA; Schema: tyre; Owner: postgres
--

COPY tyre.tyre (tyre_sno, org_sno, tyre_serial_number, tyre_type_sno, tyre_size_sno, tyre_price, agency_name, invoice_date, incoming_date, invoice_media, payment_mode_cd, is_new, is_tread, km_drive, no_of_tread, stock, efficiency_value, is_running, active_flag, is_bursted, tyre_company_sno, tyre_model) FROM stdin;
\.


--
-- Data for Name: tyre_activity; Type: TABLE DATA; Schema: tyre; Owner: postgres
--

COPY tyre.tyre_activity (tyre_activity_sno, tyre_sno, vehicle_sno, wheel_position, description, tyre_activity_type_cd, odo_meter, activity_date, is_running) FROM stdin;
\.


--
-- Data for Name: tyre_activity_total_km; Type: TABLE DATA; Schema: tyre; Owner: postgres
--

COPY tyre.tyre_activity_total_km (tyre_activity_total_km_sno, tyre_sno, tyre_activity_type_cd, running_km, running_life, activity_start_date, activity_end_date, tyre_activity_sno) FROM stdin;
\.


--
-- Data for Name: tyre_invoice; Type: TABLE DATA; Schema: tyre; Owner: postgres
--

COPY tyre.tyre_invoice (tyre_invoice_sno, tyre_sno, tyre_activity_type_cd, description, invoice_date, agency_name, amount) FROM stdin;
\.


--
-- Name: config_config_sno_seq; Type: SEQUENCE SET; Schema: config; Owner: postgres
--

SELECT pg_catalog.setval('config.config_config_sno_seq', 1, false);


--
-- Name: config_key_config_key_sno_seq; Type: SEQUENCE SET; Schema: config; Owner: postgres
--

SELECT pg_catalog.setval('config.config_key_config_key_sno_seq', 1, false);


--
-- Name: environment_environment_sno_seq; Type: SEQUENCE SET; Schema: config; Owner: postgres
--

SELECT pg_catalog.setval('config.environment_environment_sno_seq', 1, false);


--
-- Name: module_module_sno_seq; Type: SEQUENCE SET; Schema: config; Owner: postgres
--

SELECT pg_catalog.setval('config.module_module_sno_seq', 1, false);


--
-- Name: sub_module_sub_module_sno_seq; Type: SEQUENCE SET; Schema: config; Owner: postgres
--

SELECT pg_catalog.setval('config.sub_module_sub_module_sno_seq', 1, false);


--
-- Name: driver_attendance_driver_attendance_sno_seq; Type: SEQUENCE SET; Schema: driver; Owner: postgres
--

SELECT pg_catalog.setval('driver.driver_attendance_driver_attendance_sno_seq', 61, true);


--
-- Name: driver_driver_sno_seq; Type: SEQUENCE SET; Schema: driver; Owner: postgres
--

SELECT pg_catalog.setval('driver.driver_driver_sno_seq', 15, true);


--
-- Name: driver_mileage_driver_mileage_sno_seq; Type: SEQUENCE SET; Schema: driver; Owner: postgres
--

SELECT pg_catalog.setval('driver.driver_mileage_driver_mileage_sno_seq', 54, true);


--
-- Name: driver_user_driver_user_sno_seq; Type: SEQUENCE SET; Schema: driver; Owner: postgres
--

SELECT pg_catalog.setval('driver.driver_user_driver_user_sno_seq', 15, true);


--
-- Name: job_post_job_post_sno_seq; Type: SEQUENCE SET; Schema: driver; Owner: postgres
--

SELECT pg_catalog.setval('driver.job_post_job_post_sno_seq', 9, true);


--
-- Name: city_city_sno_seq; Type: SEQUENCE SET; Schema: master_data; Owner: postgres
--

SELECT pg_catalog.setval('master_data.city_city_sno_seq', 41, true);


--
-- Name: district_district_sno_seq; Type: SEQUENCE SET; Schema: master_data; Owner: postgres
--

SELECT pg_catalog.setval('master_data.district_district_sno_seq', 38, true);


--
-- Name: route_route_sno_seq; Type: SEQUENCE SET; Schema: master_data; Owner: postgres
--

SELECT pg_catalog.setval('master_data.route_route_sno_seq', 14, true);


--
-- Name: state_state_sno_seq; Type: SEQUENCE SET; Schema: master_data; Owner: postgres
--

SELECT pg_catalog.setval('master_data.state_state_sno_seq', 28, true);


--
-- Name: tyre_company_tyre_company_sno_seq; Type: SEQUENCE SET; Schema: master_data; Owner: postgres
--

SELECT pg_catalog.setval('master_data.tyre_company_tyre_company_sno_seq', 10, true);


--
-- Name: tyre_size_tyre_size_sno_seq; Type: SEQUENCE SET; Schema: master_data; Owner: postgres
--

SELECT pg_catalog.setval('master_data.tyre_size_tyre_size_sno_seq', 23, true);


--
-- Name: tyre_type_tyre_type_sno_seq; Type: SEQUENCE SET; Schema: master_data; Owner: postgres
--

SELECT pg_catalog.setval('master_data.tyre_type_tyre_type_sno_seq', 3, true);


--
-- Name: media_detail_media_detail_sno_seq; Type: SEQUENCE SET; Schema: media; Owner: postgres
--

SELECT pg_catalog.setval('media.media_detail_media_detail_sno_seq', 20, true);


--
-- Name: media_media_sno_seq; Type: SEQUENCE SET; Schema: media; Owner: postgres
--

SELECT pg_catalog.setval('media.media_media_sno_seq', 74, true);


--
-- Name: notification_notification_sno_seq; Type: SEQUENCE SET; Schema: notification; Owner: postgres
--

SELECT pg_catalog.setval('notification.notification_notification_sno_seq', 83, true);


--
-- Name: address_address_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.address_address_sno_seq', 3, true);


--
-- Name: bank_account_detail_bank_account_detail_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.bank_account_detail_bank_account_detail_sno_seq', 5, true);


--
-- Name: bunk_bunk_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.bunk_bunk_sno_seq', 1, false);


--
-- Name: bus_report_bus_report_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.bus_report_bus_report_sno_seq', 54, true);


--
-- Name: fuel_fuel_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.fuel_fuel_sno_seq', 63, true);


--
-- Name: operator_driver_operator_driver_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.operator_driver_operator_driver_sno_seq', 14, true);


--
-- Name: operator_route_operator_route_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.operator_route_operator_route_sno_seq', 14, true);


--
-- Name: org_contact_org_contact_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.org_contact_org_contact_sno_seq', 4, true);


--
-- Name: org_detail_org_detail_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.org_detail_org_detail_sno_seq', 3, true);


--
-- Name: org_org_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.org_org_sno_seq', 3, true);


--
-- Name: org_owner_org_owner_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.org_owner_org_owner_sno_seq', 3, true);


--
-- Name: org_social_link_org_social_link_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.org_social_link_org_social_link_sno_seq', 9, true);


--
-- Name: org_user_org_user_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.org_user_org_user_sno_seq', 1, true);


--
-- Name: org_vehicle_org_vehicle_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.org_vehicle_org_vehicle_sno_seq', 7, true);


--
-- Name: reject_reason_reject_reason_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.reject_reason_reject_reason_sno_seq', 1, false);


--
-- Name: single_route_single_route_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.single_route_single_route_sno_seq', 39, true);


--
-- Name: toll_pass_detail_toll_pass_detail_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.toll_pass_detail_toll_pass_detail_sno_seq', 6, true);


--
-- Name: trip_route_trip_route_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.trip_route_trip_route_sno_seq', 1, false);


--
-- Name: trip_trip_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.trip_trip_sno_seq', 1, false);


--
-- Name: vehicle_detail_vehicle_detail_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.vehicle_detail_vehicle_detail_sno_seq', 7, true);


--
-- Name: vehicle_driver_vehicle_driver_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.vehicle_driver_vehicle_driver_sno_seq', 1, false);


--
-- Name: vehicle_due_fixed_pay_vehicle_due_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.vehicle_due_fixed_pay_vehicle_due_sno_seq', 10, true);


--
-- Name: vehicle_due_variable_pay_vehicle_due_variable_pay_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.vehicle_due_variable_pay_vehicle_due_variable_pay_sno_seq', 183, true);


--
-- Name: vehicle_owner_vehicle_owner_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.vehicle_owner_vehicle_owner_sno_seq', 7, true);


--
-- Name: vehicle_route_vehicle_route_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.vehicle_route_vehicle_route_sno_seq', 28, true);


--
-- Name: vehicle_vehicle_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.vehicle_vehicle_sno_seq', 7, true);


--
-- Name: via_via_sno_seq; Type: SEQUENCE SET; Schema: operator; Owner: postgres
--

SELECT pg_catalog.setval('operator.via_via_sno_seq', 32, true);


--
-- Name: app_menu_app_menu_sno_seq; Type: SEQUENCE SET; Schema: portal; Owner: postgres
--

SELECT pg_catalog.setval('portal.app_menu_app_menu_sno_seq', 37, true);


--
-- Name: app_menu_role_app_menu_role_sno_seq; Type: SEQUENCE SET; Schema: portal; Owner: postgres
--

SELECT pg_catalog.setval('portal.app_menu_role_app_menu_role_sno_seq', 82, true);


--
-- Name: app_menu_user_app_menu_user_sno_seq; Type: SEQUENCE SET; Schema: portal; Owner: postgres
--

SELECT pg_catalog.setval('portal.app_menu_user_app_menu_user_sno_seq', 16, true);


--
-- Name: app_user_app_user_sno_seq; Type: SEQUENCE SET; Schema: portal; Owner: postgres
--

SELECT pg_catalog.setval('portal.app_user_app_user_sno_seq', 27, true);


--
-- Name: app_user_contact_app_user_contact_sno_seq; Type: SEQUENCE SET; Schema: portal; Owner: postgres
--

SELECT pg_catalog.setval('portal.app_user_contact_app_user_contact_sno_seq', 1, false);


--
-- Name: app_user_role_app_user_role_sno_seq; Type: SEQUENCE SET; Schema: portal; Owner: postgres
--

SELECT pg_catalog.setval('portal.app_user_role_app_user_role_sno_seq', 27, true);


--
-- Name: codes_dtl_codes_dtl_sno_seq; Type: SEQUENCE SET; Schema: portal; Owner: postgres
--

SELECT pg_catalog.setval('portal.codes_dtl_codes_dtl_sno_seq', 1, false);


--
-- Name: codes_hdr_codes_hdr_sno_seq; Type: SEQUENCE SET; Schema: portal; Owner: postgres
--

SELECT pg_catalog.setval('portal.codes_hdr_codes_hdr_sno_seq', 1, false);


--
-- Name: contact_contact_sno_seq; Type: SEQUENCE SET; Schema: portal; Owner: postgres
--

SELECT pg_catalog.setval('portal.contact_contact_sno_seq', 4, true);


--
-- Name: otp_otp_sno_seq; Type: SEQUENCE SET; Schema: portal; Owner: postgres
--

SELECT pg_catalog.setval('portal.otp_otp_sno_seq', 27, true);


--
-- Name: signin_config_signin_config_sno_seq; Type: SEQUENCE SET; Schema: portal; Owner: postgres
--

SELECT pg_catalog.setval('portal.signin_config_signin_config_sno_seq', 25, true);


--
-- Name: social_link_social_link_sno_seq; Type: SEQUENCE SET; Schema: portal; Owner: postgres
--

SELECT pg_catalog.setval('portal.social_link_social_link_sno_seq', 9, true);


--
-- Name: user_profile_user_profile_sno_seq; Type: SEQUENCE SET; Schema: portal; Owner: postgres
--

SELECT pg_catalog.setval('portal.user_profile_user_profile_sno_seq', 2, true);


--
-- Name: booking_booking_sno_seq; Type: SEQUENCE SET; Schema: rent; Owner: postgres
--

SELECT pg_catalog.setval('rent.booking_booking_sno_seq', 5, true);


--
-- Name: rent_bus_rent_bus_sno_seq; Type: SEQUENCE SET; Schema: rent; Owner: postgres
--

SELECT pg_catalog.setval('rent.rent_bus_rent_bus_sno_seq', 14, true);


--
-- Name: permit_route_permit_route_sno_seq; Type: SEQUENCE SET; Schema: stage_carriage; Owner: postgres
--

SELECT pg_catalog.setval('stage_carriage.permit_route_permit_route_sno_seq', 1, false);


--
-- Name: single_single_sno_seq; Type: SEQUENCE SET; Schema: stage_carriage; Owner: postgres
--

SELECT pg_catalog.setval('stage_carriage.single_single_sno_seq', 1, false);


--
-- Name: via_via_sno_seq; Type: SEQUENCE SET; Schema: stage_carriage; Owner: postgres
--

SELECT pg_catalog.setval('stage_carriage.via_via_sno_seq', 1, false);


--
-- Name: tyre_activity_total_km_tyre_activity_total_km_sno_seq; Type: SEQUENCE SET; Schema: tyre; Owner: postgres
--

SELECT pg_catalog.setval('tyre.tyre_activity_total_km_tyre_activity_total_km_sno_seq', 1, false);


--
-- Name: tyre_activity_tyre_activity_sno_seq; Type: SEQUENCE SET; Schema: tyre; Owner: postgres
--

SELECT pg_catalog.setval('tyre.tyre_activity_tyre_activity_sno_seq', 1, false);


--
-- Name: tyre_invoice_tyre_invoice_sno_seq; Type: SEQUENCE SET; Schema: tyre; Owner: postgres
--

SELECT pg_catalog.setval('tyre.tyre_invoice_tyre_invoice_sno_seq', 1, false);


--
-- Name: tyre_tyre_sno_seq; Type: SEQUENCE SET; Schema: tyre; Owner: postgres
--

SELECT pg_catalog.setval('tyre.tyre_tyre_sno_seq', 1, false);


--
-- Name: config_key config_key_config_key_attribute_key; Type: CONSTRAINT; Schema: config; Owner: postgres
--

ALTER TABLE ONLY config.config_key
    ADD CONSTRAINT config_key_config_key_attribute_key UNIQUE (config_key_attribute);


--
-- Name: config_key config_key_pkey; Type: CONSTRAINT; Schema: config; Owner: postgres
--

ALTER TABLE ONLY config.config_key
    ADD CONSTRAINT config_key_pkey PRIMARY KEY (config_key_sno);


--
-- Name: config config_pkey; Type: CONSTRAINT; Schema: config; Owner: postgres
--

ALTER TABLE ONLY config.config
    ADD CONSTRAINT config_pkey PRIMARY KEY (config_sno);


--
-- Name: environment environment_pkey; Type: CONSTRAINT; Schema: config; Owner: postgres
--

ALTER TABLE ONLY config.environment
    ADD CONSTRAINT environment_pkey PRIMARY KEY (environment_sno);


--
-- Name: module module_pkey; Type: CONSTRAINT; Schema: config; Owner: postgres
--

ALTER TABLE ONLY config.module
    ADD CONSTRAINT module_pkey PRIMARY KEY (module_sno);


--
-- Name: sub_module sub_module_pkey; Type: CONSTRAINT; Schema: config; Owner: postgres
--

ALTER TABLE ONLY config.sub_module
    ADD CONSTRAINT sub_module_pkey PRIMARY KEY (sub_module_sno);


--
-- Name: driver_attendance driver_attendance_pkey; Type: CONSTRAINT; Schema: driver; Owner: postgres
--

ALTER TABLE ONLY driver.driver_attendance
    ADD CONSTRAINT driver_attendance_pkey PRIMARY KEY (driver_attendance_sno);


--
-- Name: driver driver_licence_number_key; Type: CONSTRAINT; Schema: driver; Owner: postgres
--

ALTER TABLE ONLY driver.driver
    ADD CONSTRAINT driver_licence_number_key UNIQUE (licence_number);


--
-- Name: driver_mileage driver_mileage_pkey; Type: CONSTRAINT; Schema: driver; Owner: postgres
--

ALTER TABLE ONLY driver.driver_mileage
    ADD CONSTRAINT driver_mileage_pkey PRIMARY KEY (driver_mileage_sno);


--
-- Name: driver driver_pkey; Type: CONSTRAINT; Schema: driver; Owner: postgres
--

ALTER TABLE ONLY driver.driver
    ADD CONSTRAINT driver_pkey PRIMARY KEY (driver_sno);


--
-- Name: driver_user driver_user_pkey; Type: CONSTRAINT; Schema: driver; Owner: postgres
--

ALTER TABLE ONLY driver.driver_user
    ADD CONSTRAINT driver_user_pkey PRIMARY KEY (driver_user_sno);


--
-- Name: job_post job_post_pkey; Type: CONSTRAINT; Schema: driver; Owner: postgres
--

ALTER TABLE ONLY driver.job_post
    ADD CONSTRAINT job_post_pkey PRIMARY KEY (job_post_sno);


--
-- Name: city city_pkey; Type: CONSTRAINT; Schema: master_data; Owner: postgres
--

ALTER TABLE ONLY master_data.city
    ADD CONSTRAINT city_pkey PRIMARY KEY (city_sno);


--
-- Name: district district_pkey; Type: CONSTRAINT; Schema: master_data; Owner: postgres
--

ALTER TABLE ONLY master_data.district
    ADD CONSTRAINT district_pkey PRIMARY KEY (district_sno);


--
-- Name: route route_pkey; Type: CONSTRAINT; Schema: master_data; Owner: postgres
--

ALTER TABLE ONLY master_data.route
    ADD CONSTRAINT route_pkey PRIMARY KEY (route_sno);


--
-- Name: state state_pkey; Type: CONSTRAINT; Schema: master_data; Owner: postgres
--

ALTER TABLE ONLY master_data.state
    ADD CONSTRAINT state_pkey PRIMARY KEY (state_sno);


--
-- Name: tyre_company tyre_company_pkey; Type: CONSTRAINT; Schema: master_data; Owner: postgres
--

ALTER TABLE ONLY master_data.tyre_company
    ADD CONSTRAINT tyre_company_pkey PRIMARY KEY (tyre_company_sno);


--
-- Name: tyre_size tyre_size_pkey; Type: CONSTRAINT; Schema: master_data; Owner: postgres
--

ALTER TABLE ONLY master_data.tyre_size
    ADD CONSTRAINT tyre_size_pkey PRIMARY KEY (tyre_size_sno);


--
-- Name: tyre_type tyre_type_pkey; Type: CONSTRAINT; Schema: master_data; Owner: postgres
--

ALTER TABLE ONLY master_data.tyre_type
    ADD CONSTRAINT tyre_type_pkey PRIMARY KEY (tyre_type_sno);


--
-- Name: media_detail media_detail_pkey; Type: CONSTRAINT; Schema: media; Owner: postgres
--

ALTER TABLE ONLY media.media_detail
    ADD CONSTRAINT media_detail_pkey PRIMARY KEY (media_detail_sno);


--
-- Name: media media_pkey; Type: CONSTRAINT; Schema: media; Owner: postgres
--

ALTER TABLE ONLY media.media
    ADD CONSTRAINT media_pkey PRIMARY KEY (media_sno);


--
-- Name: notification notification_pkey; Type: CONSTRAINT; Schema: notification; Owner: postgres
--

ALTER TABLE ONLY notification.notification
    ADD CONSTRAINT notification_pkey PRIMARY KEY (notification_sno);


--
-- Name: address address_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.address
    ADD CONSTRAINT address_pkey PRIMARY KEY (address_sno);


--
-- Name: bank_account_detail bank_account_detail_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.bank_account_detail
    ADD CONSTRAINT bank_account_detail_pkey PRIMARY KEY (bank_account_detail_sno);


--
-- Name: bunk bunk_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.bunk
    ADD CONSTRAINT bunk_pkey PRIMARY KEY (bunk_sno);


--
-- Name: bus_report bus_report_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.bus_report
    ADD CONSTRAINT bus_report_pkey PRIMARY KEY (bus_report_sno);


--
-- Name: fuel fuel_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.fuel
    ADD CONSTRAINT fuel_pkey PRIMARY KEY (fuel_sno);


--
-- Name: operator_driver operator_driver_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.operator_driver
    ADD CONSTRAINT operator_driver_pkey PRIMARY KEY (operator_driver_sno);


--
-- Name: operator_route operator_route_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.operator_route
    ADD CONSTRAINT operator_route_pkey PRIMARY KEY (operator_route_sno);


--
-- Name: org_contact org_contact_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org_contact
    ADD CONSTRAINT org_contact_pkey PRIMARY KEY (org_contact_sno);


--
-- Name: org_detail org_detail_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org_detail
    ADD CONSTRAINT org_detail_pkey PRIMARY KEY (org_detail_sno);


--
-- Name: org_owner org_owner_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org_owner
    ADD CONSTRAINT org_owner_pkey PRIMARY KEY (org_owner_sno);


--
-- Name: org org_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org
    ADD CONSTRAINT org_pkey PRIMARY KEY (org_sno);


--
-- Name: org_social_link org_social_link_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org_social_link
    ADD CONSTRAINT org_social_link_pkey PRIMARY KEY (org_social_link_sno);


--
-- Name: org_user org_user_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org_user
    ADD CONSTRAINT org_user_pkey PRIMARY KEY (org_user_sno);


--
-- Name: org_vehicle org_vehicle_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org_vehicle
    ADD CONSTRAINT org_vehicle_pkey PRIMARY KEY (org_vehicle_sno);


--
-- Name: reject_reason reject_reason_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.reject_reason
    ADD CONSTRAINT reject_reason_pkey PRIMARY KEY (reject_reason_sno);


--
-- Name: single_route single_route_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.single_route
    ADD CONSTRAINT single_route_pkey PRIMARY KEY (single_route_sno);


--
-- Name: toll_pass_detail toll_pass_detail_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.toll_pass_detail
    ADD CONSTRAINT toll_pass_detail_pkey PRIMARY KEY (toll_pass_detail_sno);


--
-- Name: trip trip_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.trip
    ADD CONSTRAINT trip_pkey PRIMARY KEY (trip_sno);


--
-- Name: trip_route trip_route_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.trip_route
    ADD CONSTRAINT trip_route_pkey PRIMARY KEY (trip_route_sno);


--
-- Name: vehicle_detail vehicle_detail_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle_detail
    ADD CONSTRAINT vehicle_detail_pkey PRIMARY KEY (vehicle_detail_sno);


--
-- Name: vehicle_driver vehicle_driver_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle_driver
    ADD CONSTRAINT vehicle_driver_pkey PRIMARY KEY (vehicle_driver_sno);


--
-- Name: vehicle_due_fixed_pay vehicle_due_fixed_pay_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle_due_fixed_pay
    ADD CONSTRAINT vehicle_due_fixed_pay_pkey PRIMARY KEY (vehicle_due_sno);


--
-- Name: vehicle_due_variable_pay vehicle_due_variable_pay_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle_due_variable_pay
    ADD CONSTRAINT vehicle_due_variable_pay_pkey PRIMARY KEY (vehicle_due_variable_pay_sno);


--
-- Name: vehicle_owner vehicle_owner_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle_owner
    ADD CONSTRAINT vehicle_owner_pkey PRIMARY KEY (vehicle_owner_sno);


--
-- Name: vehicle vehicle_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle
    ADD CONSTRAINT vehicle_pkey PRIMARY KEY (vehicle_sno);


--
-- Name: vehicle_route vehicle_route_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle_route
    ADD CONSTRAINT vehicle_route_pkey PRIMARY KEY (vehicle_route_sno);


--
-- Name: via via_pkey; Type: CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.via
    ADD CONSTRAINT via_pkey PRIMARY KEY (via_sno);


--
-- Name: app_menu app_menu_pkey; Type: CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.app_menu
    ADD CONSTRAINT app_menu_pkey PRIMARY KEY (app_menu_sno);


--
-- Name: app_menu_role app_menu_role_pkey; Type: CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.app_menu_role
    ADD CONSTRAINT app_menu_role_pkey PRIMARY KEY (app_menu_role_sno);


--
-- Name: app_menu_user app_menu_user_pkey; Type: CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.app_menu_user
    ADD CONSTRAINT app_menu_user_pkey PRIMARY KEY (app_menu_user_sno);


--
-- Name: app_user_contact app_user_contact_mobile_no_key; Type: CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.app_user_contact
    ADD CONSTRAINT app_user_contact_mobile_no_key UNIQUE (mobile_no);


--
-- Name: app_user_contact app_user_contact_pkey; Type: CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.app_user_contact
    ADD CONSTRAINT app_user_contact_pkey PRIMARY KEY (app_user_contact_sno);


--
-- Name: app_user app_user_mobile_no_key; Type: CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.app_user
    ADD CONSTRAINT app_user_mobile_no_key UNIQUE (mobile_no);


--
-- Name: app_user app_user_pkey; Type: CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.app_user
    ADD CONSTRAINT app_user_pkey PRIMARY KEY (app_user_sno);


--
-- Name: app_user_role app_user_role_pkey; Type: CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.app_user_role
    ADD CONSTRAINT app_user_role_pkey PRIMARY KEY (app_user_role_sno);


--
-- Name: codes_dtl codes_dtl_pkey; Type: CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.codes_dtl
    ADD CONSTRAINT codes_dtl_pkey PRIMARY KEY (codes_dtl_sno);


--
-- Name: codes_hdr codes_hdr_pkey; Type: CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.codes_hdr
    ADD CONSTRAINT codes_hdr_pkey PRIMARY KEY (codes_hdr_sno);


--
-- Name: contact contact_pkey; Type: CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.contact
    ADD CONSTRAINT contact_pkey PRIMARY KEY (contact_sno);


--
-- Name: otp otp_pkey; Type: CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.otp
    ADD CONSTRAINT otp_pkey PRIMARY KEY (otp_sno);


--
-- Name: signin_config signin_config_pkey; Type: CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.signin_config
    ADD CONSTRAINT signin_config_pkey PRIMARY KEY (signin_config_sno);


--
-- Name: social_link social_link_pkey; Type: CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.social_link
    ADD CONSTRAINT social_link_pkey PRIMARY KEY (social_link_sno);


--
-- Name: user_profile user_profile_pkey; Type: CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.user_profile
    ADD CONSTRAINT user_profile_pkey PRIMARY KEY (user_profile_sno);


--
-- Name: booking booking_booking_id_key; Type: CONSTRAINT; Schema: rent; Owner: postgres
--

ALTER TABLE ONLY rent.booking
    ADD CONSTRAINT booking_booking_id_key UNIQUE (booking_id);


--
-- Name: booking booking_pkey; Type: CONSTRAINT; Schema: rent; Owner: postgres
--

ALTER TABLE ONLY rent.booking
    ADD CONSTRAINT booking_pkey PRIMARY KEY (booking_sno);


--
-- Name: rent_bus rent_bus_pkey; Type: CONSTRAINT; Schema: rent; Owner: postgres
--

ALTER TABLE ONLY rent.rent_bus
    ADD CONSTRAINT rent_bus_pkey PRIMARY KEY (rent_bus_sno);


--
-- Name: permit_route permit_route_pkey; Type: CONSTRAINT; Schema: stage_carriage; Owner: postgres
--

ALTER TABLE ONLY stage_carriage.permit_route
    ADD CONSTRAINT permit_route_pkey PRIMARY KEY (permit_route_sno);


--
-- Name: single single_pkey; Type: CONSTRAINT; Schema: stage_carriage; Owner: postgres
--

ALTER TABLE ONLY stage_carriage.single
    ADD CONSTRAINT single_pkey PRIMARY KEY (single_sno);


--
-- Name: via via_pkey; Type: CONSTRAINT; Schema: stage_carriage; Owner: postgres
--

ALTER TABLE ONLY stage_carriage.via
    ADD CONSTRAINT via_pkey PRIMARY KEY (via_sno);


--
-- Name: tyre_activity tyre_activity_pkey; Type: CONSTRAINT; Schema: tyre; Owner: postgres
--

ALTER TABLE ONLY tyre.tyre_activity
    ADD CONSTRAINT tyre_activity_pkey PRIMARY KEY (tyre_activity_sno);


--
-- Name: tyre_activity_total_km tyre_activity_total_km_pkey; Type: CONSTRAINT; Schema: tyre; Owner: postgres
--

ALTER TABLE ONLY tyre.tyre_activity_total_km
    ADD CONSTRAINT tyre_activity_total_km_pkey PRIMARY KEY (tyre_activity_total_km_sno);


--
-- Name: tyre_invoice tyre_invoice_pkey; Type: CONSTRAINT; Schema: tyre; Owner: postgres
--

ALTER TABLE ONLY tyre.tyre_invoice
    ADD CONSTRAINT tyre_invoice_pkey PRIMARY KEY (tyre_invoice_sno);


--
-- Name: tyre tyre_pkey; Type: CONSTRAINT; Schema: tyre; Owner: postgres
--

ALTER TABLE ONLY tyre.tyre
    ADD CONSTRAINT tyre_pkey PRIMARY KEY (tyre_sno);


--
-- Name: tyre tyre_tyre_serial_number_key; Type: CONSTRAINT; Schema: tyre; Owner: postgres
--

ALTER TABLE ONLY tyre.tyre
    ADD CONSTRAINT tyre_tyre_serial_number_key UNIQUE (tyre_serial_number);


--
-- Name: config config_config_key_sno_fkey; Type: FK CONSTRAINT; Schema: config; Owner: postgres
--

ALTER TABLE ONLY config.config
    ADD CONSTRAINT config_config_key_sno_fkey FOREIGN KEY (config_key_sno) REFERENCES config.config_key(config_key_sno);


--
-- Name: config config_environment_sno_fkey; Type: FK CONSTRAINT; Schema: config; Owner: postgres
--

ALTER TABLE ONLY config.config
    ADD CONSTRAINT config_environment_sno_fkey FOREIGN KEY (environment_sno) REFERENCES config.environment(environment_sno);


--
-- Name: config_key config_key_encrypt_type_cd_fkey; Type: FK CONSTRAINT; Schema: config; Owner: postgres
--

ALTER TABLE ONLY config.config_key
    ADD CONSTRAINT config_key_encrypt_type_cd_fkey FOREIGN KEY (encrypt_type_cd) REFERENCES portal.codes_dtl(codes_dtl_sno);


--
-- Name: config config_module_sno_fkey; Type: FK CONSTRAINT; Schema: config; Owner: postgres
--

ALTER TABLE ONLY config.config
    ADD CONSTRAINT config_module_sno_fkey FOREIGN KEY (module_sno) REFERENCES config.module(module_sno);


--
-- Name: config config_sub_module_sno_fkey; Type: FK CONSTRAINT; Schema: config; Owner: postgres
--

ALTER TABLE ONLY config.config
    ADD CONSTRAINT config_sub_module_sno_fkey FOREIGN KEY (sub_module_sno) REFERENCES config.sub_module(sub_module_sno);


--
-- Name: module module_environment_sno_fkey; Type: FK CONSTRAINT; Schema: config; Owner: postgres
--

ALTER TABLE ONLY config.module
    ADD CONSTRAINT module_environment_sno_fkey FOREIGN KEY (environment_sno) REFERENCES config.environment(environment_sno);


--
-- Name: sub_module sub_module_module_sno_fkey; Type: FK CONSTRAINT; Schema: config; Owner: postgres
--

ALTER TABLE ONLY config.sub_module
    ADD CONSTRAINT sub_module_module_sno_fkey FOREIGN KEY (module_sno) REFERENCES config.module(module_sno);


--
-- Name: driver_attendance driver_attendance_attendance_status_cd_fkey; Type: FK CONSTRAINT; Schema: driver; Owner: postgres
--

ALTER TABLE ONLY driver.driver_attendance
    ADD CONSTRAINT driver_attendance_attendance_status_cd_fkey FOREIGN KEY (attendance_status_cd) REFERENCES portal.codes_dtl(codes_dtl_sno);


--
-- Name: driver_attendance driver_attendance_driver_sno_fkey; Type: FK CONSTRAINT; Schema: driver; Owner: postgres
--

ALTER TABLE ONLY driver.driver_attendance
    ADD CONSTRAINT driver_attendance_driver_sno_fkey FOREIGN KEY (driver_sno) REFERENCES driver.driver(driver_sno);


--
-- Name: driver_attendance driver_attendance_vehicle_sno_fkey; Type: FK CONSTRAINT; Schema: driver; Owner: postgres
--

ALTER TABLE ONLY driver.driver_attendance
    ADD CONSTRAINT driver_attendance_vehicle_sno_fkey FOREIGN KEY (vehicle_sno) REFERENCES operator.vehicle(vehicle_sno);


--
-- Name: driver driver_blood_group_cd_fkey; Type: FK CONSTRAINT; Schema: driver; Owner: postgres
--

ALTER TABLE ONLY driver.driver
    ADD CONSTRAINT driver_blood_group_cd_fkey FOREIGN KEY (blood_group_cd) REFERENCES portal.codes_dtl(codes_dtl_sno);


--
-- Name: driver driver_kyc_status_fkey; Type: FK CONSTRAINT; Schema: driver; Owner: postgres
--

ALTER TABLE ONLY driver.driver
    ADD CONSTRAINT driver_kyc_status_fkey FOREIGN KEY (kyc_status) REFERENCES portal.codes_dtl(codes_dtl_sno);


--
-- Name: driver_mileage driver_mileage_driver_sno_fkey; Type: FK CONSTRAINT; Schema: driver; Owner: postgres
--

ALTER TABLE ONLY driver.driver_mileage
    ADD CONSTRAINT driver_mileage_driver_sno_fkey FOREIGN KEY (driver_sno) REFERENCES driver.driver(driver_sno);


--
-- Name: driver_mileage driver_mileage_vehicle_sno_fkey; Type: FK CONSTRAINT; Schema: driver; Owner: postgres
--

ALTER TABLE ONLY driver.driver_mileage
    ADD CONSTRAINT driver_mileage_vehicle_sno_fkey FOREIGN KEY (vehicle_sno) REFERENCES operator.vehicle(vehicle_sno);


--
-- Name: driver_user driver_user_app_user_sno_fkey; Type: FK CONSTRAINT; Schema: driver; Owner: postgres
--

ALTER TABLE ONLY driver.driver_user
    ADD CONSTRAINT driver_user_app_user_sno_fkey FOREIGN KEY (app_user_sno) REFERENCES portal.app_user(app_user_sno);


--
-- Name: driver_user driver_user_driver_sno_fkey; Type: FK CONSTRAINT; Schema: driver; Owner: postgres
--

ALTER TABLE ONLY driver.driver_user
    ADD CONSTRAINT driver_user_driver_sno_fkey FOREIGN KEY (driver_sno) REFERENCES driver.driver(driver_sno);


--
-- Name: job_post job_post_app_user_sno_fkey; Type: FK CONSTRAINT; Schema: driver; Owner: postgres
--

ALTER TABLE ONLY driver.job_post
    ADD CONSTRAINT job_post_app_user_sno_fkey FOREIGN KEY (app_user_sno) REFERENCES portal.app_user(app_user_sno);


--
-- Name: job_post job_post_driver_sno_fkey; Type: FK CONSTRAINT; Schema: driver; Owner: postgres
--

ALTER TABLE ONLY driver.job_post
    ADD CONSTRAINT job_post_driver_sno_fkey FOREIGN KEY (driver_sno) REFERENCES driver.driver(driver_sno);


--
-- Name: job_post job_post_org_sno_fkey; Type: FK CONSTRAINT; Schema: driver; Owner: postgres
--

ALTER TABLE ONLY driver.job_post
    ADD CONSTRAINT job_post_org_sno_fkey FOREIGN KEY (org_sno) REFERENCES operator.org(org_sno);


--
-- Name: job_post job_post_role_cd_fkey; Type: FK CONSTRAINT; Schema: driver; Owner: postgres
--

ALTER TABLE ONLY driver.job_post
    ADD CONSTRAINT job_post_role_cd_fkey FOREIGN KEY (role_cd) REFERENCES portal.codes_dtl(codes_dtl_sno);


--
-- Name: city city_district_sno_fkey; Type: FK CONSTRAINT; Schema: master_data; Owner: postgres
--

ALTER TABLE ONLY master_data.city
    ADD CONSTRAINT city_district_sno_fkey FOREIGN KEY (district_sno) REFERENCES master_data.district(district_sno);


--
-- Name: district district_state_sno_fkey; Type: FK CONSTRAINT; Schema: master_data; Owner: postgres
--

ALTER TABLE ONLY master_data.district
    ADD CONSTRAINT district_state_sno_fkey FOREIGN KEY (state_sno) REFERENCES master_data.state(state_sno);


--
-- Name: route route_destination_city_sno_fkey; Type: FK CONSTRAINT; Schema: master_data; Owner: postgres
--

ALTER TABLE ONLY master_data.route
    ADD CONSTRAINT route_destination_city_sno_fkey FOREIGN KEY (destination_city_sno) REFERENCES master_data.city(city_sno);


--
-- Name: route route_source_city_sno_fkey; Type: FK CONSTRAINT; Schema: master_data; Owner: postgres
--

ALTER TABLE ONLY master_data.route
    ADD CONSTRAINT route_source_city_sno_fkey FOREIGN KEY (source_city_sno) REFERENCES master_data.city(city_sno);


--
-- Name: tyre_size tyre_size_tyre_type_sno_fkey; Type: FK CONSTRAINT; Schema: master_data; Owner: postgres
--

ALTER TABLE ONLY master_data.tyre_size
    ADD CONSTRAINT tyre_size_tyre_type_sno_fkey FOREIGN KEY (tyre_type_sno) REFERENCES master_data.tyre_type(tyre_type_sno);


--
-- Name: media_detail media_detail_media_sno_fkey; Type: FK CONSTRAINT; Schema: media; Owner: postgres
--

ALTER TABLE ONLY media.media_detail
    ADD CONSTRAINT media_detail_media_sno_fkey FOREIGN KEY (media_sno) REFERENCES media.media(media_sno);


--
-- Name: notification notification_notification_status_cd_fkey; Type: FK CONSTRAINT; Schema: notification; Owner: postgres
--

ALTER TABLE ONLY notification.notification
    ADD CONSTRAINT notification_notification_status_cd_fkey FOREIGN KEY (notification_status_cd) REFERENCES portal.codes_dtl(codes_dtl_sno);


--
-- Name: bank_account_detail bank_account_detail_org_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.bank_account_detail
    ADD CONSTRAINT bank_account_detail_org_sno_fkey FOREIGN KEY (org_sno) REFERENCES operator.org(org_sno);


--
-- Name: bunk bunk_operator_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.bunk
    ADD CONSTRAINT bunk_operator_sno_fkey FOREIGN KEY (operator_sno) REFERENCES operator.org(org_sno);


--
-- Name: bus_report bus_report_driver_attendance_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.bus_report
    ADD CONSTRAINT bus_report_driver_attendance_sno_fkey FOREIGN KEY (driver_attendance_sno) REFERENCES driver.driver_attendance(driver_attendance_sno);


--
-- Name: bus_report bus_report_driver_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.bus_report
    ADD CONSTRAINT bus_report_driver_sno_fkey FOREIGN KEY (driver_sno) REFERENCES driver.driver(driver_sno);


--
-- Name: bus_report bus_report_driving_type_cd_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.bus_report
    ADD CONSTRAINT bus_report_driving_type_cd_fkey FOREIGN KEY (driving_type_cd) REFERENCES portal.codes_dtl(codes_dtl_sno);


--
-- Name: bus_report bus_report_org_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.bus_report
    ADD CONSTRAINT bus_report_org_sno_fkey FOREIGN KEY (org_sno) REFERENCES operator.org(org_sno);


--
-- Name: bus_report bus_report_vehicle_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.bus_report
    ADD CONSTRAINT bus_report_vehicle_sno_fkey FOREIGN KEY (vehicle_sno) REFERENCES operator.vehicle(vehicle_sno);


--
-- Name: fuel fuel_bunk_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.fuel
    ADD CONSTRAINT fuel_bunk_sno_fkey FOREIGN KEY (bunk_sno) REFERENCES operator.bunk(bunk_sno);


--
-- Name: fuel fuel_driver_attendance_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.fuel
    ADD CONSTRAINT fuel_driver_attendance_sno_fkey FOREIGN KEY (driver_attendance_sno) REFERENCES driver.driver_attendance(driver_attendance_sno);


--
-- Name: fuel fuel_driver_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.fuel
    ADD CONSTRAINT fuel_driver_sno_fkey FOREIGN KEY (driver_sno) REFERENCES driver.driver(driver_sno);


--
-- Name: fuel fuel_fuel_fill_type_cd_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.fuel
    ADD CONSTRAINT fuel_fuel_fill_type_cd_fkey FOREIGN KEY (fuel_fill_type_cd) REFERENCES portal.codes_dtl(codes_dtl_sno);


--
-- Name: fuel fuel_vehicle_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.fuel
    ADD CONSTRAINT fuel_vehicle_sno_fkey FOREIGN KEY (vehicle_sno) REFERENCES operator.vehicle(vehicle_sno);


--
-- Name: operator_driver operator_driver_driver_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.operator_driver
    ADD CONSTRAINT operator_driver_driver_sno_fkey FOREIGN KEY (driver_sno) REFERENCES driver.driver(driver_sno);


--
-- Name: operator_driver operator_driver_org_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.operator_driver
    ADD CONSTRAINT operator_driver_org_sno_fkey FOREIGN KEY (org_sno) REFERENCES operator.org(org_sno);


--
-- Name: operator_route operator_route_operator_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.operator_route
    ADD CONSTRAINT operator_route_operator_sno_fkey FOREIGN KEY (operator_sno) REFERENCES operator.org(org_sno);


--
-- Name: operator_route operator_route_route_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.operator_route
    ADD CONSTRAINT operator_route_route_sno_fkey FOREIGN KEY (route_sno) REFERENCES master_data.route(route_sno);


--
-- Name: org_contact org_contact_contact_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org_contact
    ADD CONSTRAINT org_contact_contact_sno_fkey FOREIGN KEY (contact_sno) REFERENCES portal.contact(contact_sno);


--
-- Name: org_contact org_contact_org_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org_contact
    ADD CONSTRAINT org_contact_org_sno_fkey FOREIGN KEY (org_sno) REFERENCES operator.org(org_sno);


--
-- Name: org_detail org_detail_address_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org_detail
    ADD CONSTRAINT org_detail_address_sno_fkey FOREIGN KEY (address_sno) REFERENCES operator.address(address_sno);


--
-- Name: org_detail org_detail_org_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org_detail
    ADD CONSTRAINT org_detail_org_sno_fkey FOREIGN KEY (org_sno) REFERENCES operator.org(org_sno);


--
-- Name: org org_org_status_cd_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org
    ADD CONSTRAINT org_org_status_cd_fkey FOREIGN KEY (org_status_cd) REFERENCES portal.codes_dtl(codes_dtl_sno);


--
-- Name: org_owner org_owner_app_user_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org_owner
    ADD CONSTRAINT org_owner_app_user_sno_fkey FOREIGN KEY (app_user_sno) REFERENCES portal.app_user(app_user_sno);


--
-- Name: org_owner org_owner_org_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org_owner
    ADD CONSTRAINT org_owner_org_sno_fkey FOREIGN KEY (org_sno) REFERENCES operator.org(org_sno);


--
-- Name: org_social_link org_social_link_org_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org_social_link
    ADD CONSTRAINT org_social_link_org_sno_fkey FOREIGN KEY (org_sno) REFERENCES operator.org(org_sno);


--
-- Name: org_social_link org_social_link_social_link_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org_social_link
    ADD CONSTRAINT org_social_link_social_link_sno_fkey FOREIGN KEY (social_link_sno) REFERENCES portal.social_link(social_link_sno);


--
-- Name: org_user org_user_operator_user_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org_user
    ADD CONSTRAINT org_user_operator_user_sno_fkey FOREIGN KEY (operator_user_sno) REFERENCES portal.app_user(app_user_sno);


--
-- Name: org_user org_user_operator_user_sno_fkey1; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org_user
    ADD CONSTRAINT org_user_operator_user_sno_fkey1 FOREIGN KEY (operator_user_sno) REFERENCES portal.app_user(app_user_sno);


--
-- Name: org_vehicle org_vehicle_org_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org_vehicle
    ADD CONSTRAINT org_vehicle_org_sno_fkey FOREIGN KEY (org_sno) REFERENCES operator.org(org_sno);


--
-- Name: org_vehicle org_vehicle_vehicle_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.org_vehicle
    ADD CONSTRAINT org_vehicle_vehicle_sno_fkey FOREIGN KEY (vehicle_sno) REFERENCES operator.vehicle(vehicle_sno);


--
-- Name: reject_reason reject_reason_org_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.reject_reason
    ADD CONSTRAINT reject_reason_org_sno_fkey FOREIGN KEY (org_sno) REFERENCES operator.org(org_sno);


--
-- Name: single_route single_route_org_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.single_route
    ADD CONSTRAINT single_route_org_sno_fkey FOREIGN KEY (org_sno) REFERENCES operator.org(org_sno);


--
-- Name: single_route single_route_route_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.single_route
    ADD CONSTRAINT single_route_route_sno_fkey FOREIGN KEY (route_sno) REFERENCES master_data.route(route_sno);


--
-- Name: single_route single_route_vehicle_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.single_route
    ADD CONSTRAINT single_route_vehicle_sno_fkey FOREIGN KEY (vehicle_sno) REFERENCES operator.vehicle(vehicle_sno);


--
-- Name: toll_pass_detail toll_pass_detail_org_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.toll_pass_detail
    ADD CONSTRAINT toll_pass_detail_org_sno_fkey FOREIGN KEY (org_sno) REFERENCES operator.org(org_sno);


--
-- Name: toll_pass_detail toll_pass_detail_vehicle_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.toll_pass_detail
    ADD CONSTRAINT toll_pass_detail_vehicle_sno_fkey FOREIGN KEY (vehicle_sno) REFERENCES operator.vehicle(vehicle_sno);


--
-- Name: trip trip_district_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.trip
    ADD CONSTRAINT trip_district_sno_fkey FOREIGN KEY (district_sno) REFERENCES master_data.district(district_sno);


--
-- Name: trip_route trip_route_trip_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.trip_route
    ADD CONSTRAINT trip_route_trip_sno_fkey FOREIGN KEY (trip_sno) REFERENCES operator.trip(trip_sno);


--
-- Name: vehicle_detail vehicle_detail_vehicle_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle_detail
    ADD CONSTRAINT vehicle_detail_vehicle_sno_fkey FOREIGN KEY (vehicle_sno) REFERENCES operator.vehicle(vehicle_sno);


--
-- Name: vehicle_driver vehicle_driver_driver_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle_driver
    ADD CONSTRAINT vehicle_driver_driver_sno_fkey FOREIGN KEY (driver_sno) REFERENCES driver.driver(driver_sno);


--
-- Name: vehicle_driver vehicle_driver_vehicle_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle_driver
    ADD CONSTRAINT vehicle_driver_vehicle_sno_fkey FOREIGN KEY (vehicle_sno) REFERENCES operator.vehicle(vehicle_sno);


--
-- Name: vehicle_due_fixed_pay vehicle_due_fixed_pay_bank_account_detail_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle_due_fixed_pay
    ADD CONSTRAINT vehicle_due_fixed_pay_bank_account_detail_sno_fkey FOREIGN KEY (bank_account_detail_sno) REFERENCES operator.bank_account_detail(bank_account_detail_sno);


--
-- Name: vehicle_due_fixed_pay vehicle_due_fixed_pay_org_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle_due_fixed_pay
    ADD CONSTRAINT vehicle_due_fixed_pay_org_sno_fkey FOREIGN KEY (org_sno) REFERENCES operator.org(org_sno);


--
-- Name: vehicle_due_fixed_pay vehicle_due_fixed_pay_vehicle_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle_due_fixed_pay
    ADD CONSTRAINT vehicle_due_fixed_pay_vehicle_sno_fkey FOREIGN KEY (vehicle_sno) REFERENCES operator.vehicle(vehicle_sno);


--
-- Name: vehicle_due_variable_pay vehicle_due_variable_pay_vehicle_due_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle_due_variable_pay
    ADD CONSTRAINT vehicle_due_variable_pay_vehicle_due_sno_fkey FOREIGN KEY (vehicle_due_sno) REFERENCES operator.vehicle_due_fixed_pay(vehicle_due_sno);


--
-- Name: vehicle vehicle_kyc_status_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle
    ADD CONSTRAINT vehicle_kyc_status_fkey FOREIGN KEY (kyc_status) REFERENCES portal.codes_dtl(codes_dtl_sno);


--
-- Name: vehicle vehicle_media_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle
    ADD CONSTRAINT vehicle_media_sno_fkey FOREIGN KEY (media_sno) REFERENCES media.media(media_sno);


--
-- Name: vehicle_owner vehicle_owner_app_user_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle_owner
    ADD CONSTRAINT vehicle_owner_app_user_sno_fkey FOREIGN KEY (app_user_sno) REFERENCES portal.app_user(app_user_sno);


--
-- Name: vehicle_owner vehicle_owner_vehicle_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle_owner
    ADD CONSTRAINT vehicle_owner_vehicle_sno_fkey FOREIGN KEY (vehicle_sno) REFERENCES operator.vehicle(vehicle_sno);


--
-- Name: vehicle_route vehicle_route_operator_route_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle_route
    ADD CONSTRAINT vehicle_route_operator_route_sno_fkey FOREIGN KEY (operator_route_sno) REFERENCES operator.operator_route(operator_route_sno);


--
-- Name: vehicle_route vehicle_route_vehicle_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle_route
    ADD CONSTRAINT vehicle_route_vehicle_sno_fkey FOREIGN KEY (vehicle_sno) REFERENCES operator.vehicle(vehicle_sno);


--
-- Name: vehicle vehicle_tyre_count_cd_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle
    ADD CONSTRAINT vehicle_tyre_count_cd_fkey FOREIGN KEY (tyre_count_cd) REFERENCES portal.codes_dtl(codes_dtl_sno);


--
-- Name: vehicle vehicle_vehicle_type_cd_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.vehicle
    ADD CONSTRAINT vehicle_vehicle_type_cd_fkey FOREIGN KEY (vehicle_type_cd) REFERENCES portal.codes_dtl(codes_dtl_sno);


--
-- Name: via via_city_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.via
    ADD CONSTRAINT via_city_sno_fkey FOREIGN KEY (city_sno) REFERENCES master_data.city(city_sno);


--
-- Name: via via_operator_route_sno_fkey; Type: FK CONSTRAINT; Schema: operator; Owner: postgres
--

ALTER TABLE ONLY operator.via
    ADD CONSTRAINT via_operator_route_sno_fkey FOREIGN KEY (operator_route_sno) REFERENCES operator.operator_route(operator_route_sno);


--
-- Name: app_menu_role app_menu_role_app_menu_sno_fkey; Type: FK CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.app_menu_role
    ADD CONSTRAINT app_menu_role_app_menu_sno_fkey FOREIGN KEY (app_menu_sno) REFERENCES portal.app_menu(app_menu_sno);


--
-- Name: app_menu_user app_menu_user_app_menu_sno_fkey; Type: FK CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.app_menu_user
    ADD CONSTRAINT app_menu_user_app_menu_sno_fkey FOREIGN KEY (app_menu_sno) REFERENCES portal.app_menu(app_menu_sno);


--
-- Name: app_menu_user app_menu_user_app_user_sno_fkey; Type: FK CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.app_menu_user
    ADD CONSTRAINT app_menu_user_app_user_sno_fkey FOREIGN KEY (app_user_sno) REFERENCES portal.app_user(app_user_sno);


--
-- Name: app_user_contact app_user_contact_app_user_sno_fkey; Type: FK CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.app_user_contact
    ADD CONSTRAINT app_user_contact_app_user_sno_fkey FOREIGN KEY (app_user_sno) REFERENCES portal.app_user(app_user_sno);


--
-- Name: app_user_contact app_user_contact_user_status_cd_fkey; Type: FK CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.app_user_contact
    ADD CONSTRAINT app_user_contact_user_status_cd_fkey FOREIGN KEY (user_status_cd) REFERENCES portal.codes_dtl(codes_dtl_sno);


--
-- Name: app_user_role app_user_role_app_user_sno_fkey; Type: FK CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.app_user_role
    ADD CONSTRAINT app_user_role_app_user_sno_fkey FOREIGN KEY (app_user_sno) REFERENCES portal.app_user(app_user_sno);


--
-- Name: app_user_role app_user_role_role_cd_fkey; Type: FK CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.app_user_role
    ADD CONSTRAINT app_user_role_role_cd_fkey FOREIGN KEY (role_cd) REFERENCES portal.codes_dtl(codes_dtl_sno);


--
-- Name: app_user app_user_user_status_cd_fkey; Type: FK CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.app_user
    ADD CONSTRAINT app_user_user_status_cd_fkey FOREIGN KEY (user_status_cd) REFERENCES portal.codes_dtl(codes_dtl_sno);


--
-- Name: codes_dtl codes_dtl_codes_hdr_sno_fkey; Type: FK CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.codes_dtl
    ADD CONSTRAINT codes_dtl_codes_hdr_sno_fkey FOREIGN KEY (codes_hdr_sno) REFERENCES portal.codes_hdr(codes_hdr_sno);


--
-- Name: contact contact_app_user_sno_fkey; Type: FK CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.contact
    ADD CONSTRAINT contact_app_user_sno_fkey FOREIGN KEY (app_user_sno) REFERENCES portal.app_user(app_user_sno);


--
-- Name: contact contact_contact_role_cd_fkey; Type: FK CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.contact
    ADD CONSTRAINT contact_contact_role_cd_fkey FOREIGN KEY (contact_role_cd) REFERENCES portal.codes_dtl(codes_dtl_sno);


--
-- Name: otp otp_app_user_sno_fkey; Type: FK CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.otp
    ADD CONSTRAINT otp_app_user_sno_fkey FOREIGN KEY (app_user_sno) REFERENCES portal.app_user(app_user_sno);


--
-- Name: signin_config signin_config_app_user_sno_fkey; Type: FK CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.signin_config
    ADD CONSTRAINT signin_config_app_user_sno_fkey FOREIGN KEY (app_user_sno) REFERENCES portal.app_user(app_user_sno);


--
-- Name: signin_config signin_config_device_type_cd_fkey; Type: FK CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.signin_config
    ADD CONSTRAINT signin_config_device_type_cd_fkey FOREIGN KEY (device_type_cd) REFERENCES portal.codes_dtl(codes_dtl_sno);


--
-- Name: social_link social_link_social_link_type_cd_fkey; Type: FK CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.social_link
    ADD CONSTRAINT social_link_social_link_type_cd_fkey FOREIGN KEY (social_link_type_cd) REFERENCES portal.codes_dtl(codes_dtl_sno);


--
-- Name: user_profile user_profile_app_user_sno_fkey; Type: FK CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.user_profile
    ADD CONSTRAINT user_profile_app_user_sno_fkey FOREIGN KEY (app_user_sno) REFERENCES portal.app_user(app_user_sno);


--
-- Name: user_profile user_profile_gender_cd_fkey; Type: FK CONSTRAINT; Schema: portal; Owner: postgres
--

ALTER TABLE ONLY portal.user_profile
    ADD CONSTRAINT user_profile_gender_cd_fkey FOREIGN KEY (gender_cd) REFERENCES portal.codes_dtl(codes_dtl_sno);


--
-- Name: booking booking_vehicle_sno_fkey; Type: FK CONSTRAINT; Schema: rent; Owner: postgres
--

ALTER TABLE ONLY rent.booking
    ADD CONSTRAINT booking_vehicle_sno_fkey FOREIGN KEY (vehicle_sno) REFERENCES operator.vehicle(vehicle_sno);


--
-- Name: rent_bus rent_bus_return_type_cd_fkey; Type: FK CONSTRAINT; Schema: rent; Owner: postgres
--

ALTER TABLE ONLY rent.rent_bus
    ADD CONSTRAINT rent_bus_return_type_cd_fkey FOREIGN KEY (return_type_cd) REFERENCES portal.codes_dtl(codes_dtl_sno);


--
-- Name: permit_route permit_route_destination_city_sno_fkey; Type: FK CONSTRAINT; Schema: stage_carriage; Owner: postgres
--

ALTER TABLE ONLY stage_carriage.permit_route
    ADD CONSTRAINT permit_route_destination_city_sno_fkey FOREIGN KEY (destination_city_sno) REFERENCES master_data.city(city_sno);


--
-- Name: permit_route permit_route_source_city_sno_fkey; Type: FK CONSTRAINT; Schema: stage_carriage; Owner: postgres
--

ALTER TABLE ONLY stage_carriage.permit_route
    ADD CONSTRAINT permit_route_source_city_sno_fkey FOREIGN KEY (source_city_sno) REFERENCES master_data.city(city_sno);


--
-- Name: permit_route permit_route_vehicle_sno_fkey; Type: FK CONSTRAINT; Schema: stage_carriage; Owner: postgres
--

ALTER TABLE ONLY stage_carriage.permit_route
    ADD CONSTRAINT permit_route_vehicle_sno_fkey FOREIGN KEY (vehicle_sno) REFERENCES operator.vehicle(vehicle_sno);


--
-- Name: single single_route_sno_fkey; Type: FK CONSTRAINT; Schema: stage_carriage; Owner: postgres
--

ALTER TABLE ONLY stage_carriage.single
    ADD CONSTRAINT single_route_sno_fkey FOREIGN KEY (route_sno) REFERENCES master_data.route(route_sno);


--
-- Name: single single_vehicle_sno_fkey; Type: FK CONSTRAINT; Schema: stage_carriage; Owner: postgres
--

ALTER TABLE ONLY stage_carriage.single
    ADD CONSTRAINT single_vehicle_sno_fkey FOREIGN KEY (vehicle_sno) REFERENCES operator.vehicle(vehicle_sno);


--
-- Name: via via_single_sno_fkey; Type: FK CONSTRAINT; Schema: stage_carriage; Owner: postgres
--

ALTER TABLE ONLY stage_carriage.via
    ADD CONSTRAINT via_single_sno_fkey FOREIGN KEY (single_sno) REFERENCES stage_carriage.single(single_sno);


--
-- Name: via via_via_city_sno_fkey; Type: FK CONSTRAINT; Schema: stage_carriage; Owner: postgres
--

ALTER TABLE ONLY stage_carriage.via
    ADD CONSTRAINT via_via_city_sno_fkey FOREIGN KEY (via_city_sno) REFERENCES master_data.city(city_sno);


--
-- Name: tyre_activity_total_km tyre_activity_total_km_tyre_activity_sno_fkey; Type: FK CONSTRAINT; Schema: tyre; Owner: postgres
--

ALTER TABLE ONLY tyre.tyre_activity_total_km
    ADD CONSTRAINT tyre_activity_total_km_tyre_activity_sno_fkey FOREIGN KEY (tyre_activity_sno) REFERENCES tyre.tyre_activity(tyre_activity_sno);


--
-- Name: tyre_activity_total_km tyre_activity_total_km_tyre_activity_type_cd_fkey; Type: FK CONSTRAINT; Schema: tyre; Owner: postgres
--

ALTER TABLE ONLY tyre.tyre_activity_total_km
    ADD CONSTRAINT tyre_activity_total_km_tyre_activity_type_cd_fkey FOREIGN KEY (tyre_activity_type_cd) REFERENCES portal.codes_dtl(codes_dtl_sno);


--
-- Name: tyre_activity tyre_activity_tyre_activity_type_cd_fkey; Type: FK CONSTRAINT; Schema: tyre; Owner: postgres
--

ALTER TABLE ONLY tyre.tyre_activity
    ADD CONSTRAINT tyre_activity_tyre_activity_type_cd_fkey FOREIGN KEY (tyre_activity_type_cd) REFERENCES portal.codes_dtl(codes_dtl_sno);


--
-- Name: tyre_activity tyre_activity_tyre_sno_fkey; Type: FK CONSTRAINT; Schema: tyre; Owner: postgres
--

ALTER TABLE ONLY tyre.tyre_activity
    ADD CONSTRAINT tyre_activity_tyre_sno_fkey FOREIGN KEY (tyre_sno) REFERENCES tyre.tyre(tyre_sno);


--
-- Name: tyre_activity tyre_activity_vehicle_sno_fkey; Type: FK CONSTRAINT; Schema: tyre; Owner: postgres
--

ALTER TABLE ONLY tyre.tyre_activity
    ADD CONSTRAINT tyre_activity_vehicle_sno_fkey FOREIGN KEY (vehicle_sno) REFERENCES operator.vehicle(vehicle_sno);


--
-- Name: tyre tyre_invoice_media_fkey; Type: FK CONSTRAINT; Schema: tyre; Owner: postgres
--

ALTER TABLE ONLY tyre.tyre
    ADD CONSTRAINT tyre_invoice_media_fkey FOREIGN KEY (invoice_media) REFERENCES media.media(media_sno);


--
-- Name: tyre_invoice tyre_invoice_tyre_activity_type_cd_fkey; Type: FK CONSTRAINT; Schema: tyre; Owner: postgres
--

ALTER TABLE ONLY tyre.tyre_invoice
    ADD CONSTRAINT tyre_invoice_tyre_activity_type_cd_fkey FOREIGN KEY (tyre_activity_type_cd) REFERENCES portal.codes_dtl(codes_dtl_sno);


--
-- Name: tyre_invoice tyre_invoice_tyre_sno_fkey; Type: FK CONSTRAINT; Schema: tyre; Owner: postgres
--

ALTER TABLE ONLY tyre.tyre_invoice
    ADD CONSTRAINT tyre_invoice_tyre_sno_fkey FOREIGN KEY (tyre_sno) REFERENCES tyre.tyre(tyre_sno);


--
-- Name: tyre tyre_org_sno_fkey; Type: FK CONSTRAINT; Schema: tyre; Owner: postgres
--

ALTER TABLE ONLY tyre.tyre
    ADD CONSTRAINT tyre_org_sno_fkey FOREIGN KEY (org_sno) REFERENCES operator.org(org_sno);


--
-- Name: tyre tyre_payment_mode_cd_fkey; Type: FK CONSTRAINT; Schema: tyre; Owner: postgres
--

ALTER TABLE ONLY tyre.tyre
    ADD CONSTRAINT tyre_payment_mode_cd_fkey FOREIGN KEY (payment_mode_cd) REFERENCES portal.codes_dtl(codes_dtl_sno);


--
-- Name: tyre tyre_tyre_company_sno_fkey; Type: FK CONSTRAINT; Schema: tyre; Owner: postgres
--

ALTER TABLE ONLY tyre.tyre
    ADD CONSTRAINT tyre_tyre_company_sno_fkey FOREIGN KEY (tyre_company_sno) REFERENCES master_data.tyre_company(tyre_company_sno);


--
-- Name: tyre tyre_tyre_size_sno_fkey; Type: FK CONSTRAINT; Schema: tyre; Owner: postgres
--

ALTER TABLE ONLY tyre.tyre
    ADD CONSTRAINT tyre_tyre_size_sno_fkey FOREIGN KEY (tyre_size_sno) REFERENCES master_data.tyre_size(tyre_size_sno);


--
-- Name: tyre tyre_tyre_type_sno_fkey; Type: FK CONSTRAINT; Schema: tyre; Owner: postgres
--

ALTER TABLE ONLY tyre.tyre
    ADD CONSTRAINT tyre_tyre_type_sno_fkey FOREIGN KEY (tyre_type_sno) REFERENCES master_data.tyre_type(tyre_type_sno);


--
-- PostgreSQL database dump complete
--

