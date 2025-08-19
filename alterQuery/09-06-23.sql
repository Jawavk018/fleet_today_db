
update portal.app_menu set title = 'Approval', icon = 'check', has_sub_menu = 'false', parent_menu_sno = 0,
                           router_link = '/approval' where app_menu_sno = 4;
						   
update portal.app_menu set title = 'Operators', icon = 'user', has_sub_menu = 'false', parent_menu_sno = 0,
                           router_link = '/operatorlist' where app_menu_sno = 5;
						   
						   
update portal.app_menu set title = 'Vehicles', icon = 'bus', has_sub_menu = 'false', parent_menu_sno = 0,
                           router_link = '/vehiclelist' where app_menu_sno = 25;
						   
update portal.app_menu set title = 'Drivers', icon = 'user-circle-o', has_sub_menu = 'false', parent_menu_sno = 0,
                           router_link = '/driverlist' where app_menu_sno = 26;

alter table tyre.tyre add column is_bursted bool default false;

update portal.app_menu set title = 'Tyres',icon = 'life-ring' where app_menu_sno = 17;


CREATE OR REPLACE FUNCTION driver.get_current_district(p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
AS $BODY$
declare 
begin

return (select json_build_object('data',(select json_agg(json_build_object(
	'districtSno',md.district_sno,
	'districtName',md.district_name,
	'activeFlag',md.active_flag
))))from (select dd.active_flag,dd.district_sno,dd.district_name 
		  from master_data.district dd
		  inner join driver.driver d on cast(d.current_district as int) = dd.district_sno  
		 )md);
	   

end;
$BODY$;


CREATE OR REPLACE FUNCTION operator.get_search_operator_vehicle(p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
AS $BODY$
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
$BODY$;


CREATE OR REPLACE FUNCTION tyre.get_tyre_position(p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
AS $BODY$
declare 
tyre_list json;
stepney_list json;
begin

raise notice '%',p_data;
with tyre as(
select ta.tyre_sno,t.tyre_serial_number,a::text::smallint as seq,t.tyre_type_cd,ta.odo_meter,ta.activity_date from generate_series(1,(p_data->>'tyreCount')::int)a
left join tyre.tyre_activity ta on ta.vehicle_sno = (p_data->>'vehicleSno')::bigint and ta.wheel_position = ('p' || a::text) and is_running = true
left join tyre.tyre t on t.tyre_sno = ta.tyre_sno
left join portal.codes_dtl dtl on dtl.codes_dtl_sno = t.tyre_type_cd order by ta.wheel_position asc)
select json_agg(json_build_object('tyreSno',t.tyre_sno,
								'tyreSerialNumber',t.tyre_serial_number,
								  'tyreTypeCd',t.tyre_type_cd,
                                  'retreadingCount',(select count(*) from tyre.tyre_activity where tyre_activity_type_cd = 99 and tyre_sno = t.tyre_sno and vehicle_sno is not  null),
								  'className',(select operator.getClassName(t.seq,'M',(p_data->>'tyreCountCd')::smallint)),
								  'searchTyreList',(select operator.get_search_available_tyre(json_build_object('tyreSno',t.tyre_sno))),
								  'odometer',t.odo_meter,
								  'activityDate',t.activity_date
								 )) into tyre_list from tyre t;

with tyre as(
select ta.tyre_sno,t.tyre_serial_number,a::text::smallint as seq,t.tyre_type_cd,ta.odo_meter,ta.activity_date from generate_series(1,(p_data->>'stepnyCount')::int)a
left join tyre.tyre_activity ta on ta.vehicle_sno = (p_data->>'vehicleSno')::bigint and ta.wheel_position = ('s' || a::text) and is_running = true
left join tyre.tyre t on t.tyre_sno = ta.tyre_sno
left join portal.codes_dtl dtl on dtl.codes_dtl_sno = t.tyre_type_cd order by ta.wheel_position asc)
select json_agg(json_build_object('tyreSno',t.tyre_sno,
								 'tyreSerialNumber',t.tyre_serial_number,
								  'tyreTypeCd',t.tyre_type_cd,
                                  'retreadingCount',(select count(*) from tyre.tyre_activity where tyre_activity_type_cd = 99 and tyre_sno = t.tyre_sno and vehicle_sno is not  null),
								  'className',(select operator.getClassName(t.seq,'S',(p_data->>'tyreCountCd')::smallint)),
								  'searchTyreList',(select operator.get_search_available_tyre(json_build_object('tyreSno',t.tyre_sno))),
								  'odometer',t.odo_meter,
								  'activityDate',t.activity_date
								 )) into stepney_list from tyre t;
raise notice '%',tyre_list;
return (select json_agg(json_build_object('tyreList',tyre_list,'stepneyList',stepney_list)));
end;
$BODY$;


CREATE OR REPLACE FUNCTION tyre.get_tyre_life_cycle(p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
AS $BODY$
declare 
tyre_life_cycle_list json;
begin

with tyre_life_cycle as(
select v.vehicle_name,v.vehicle_reg_number,ta.activity_date as activity_start_date,tatk.activity_end_date,tatk.running_km,ta.wheel_position,
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
								  'runningLife',tlc.running_life
								 )) into tyre_life_cycle_list from tyre_life_cycle tlc;
								 
return (select json_build_object('data',tyre_life_cycle_list));
end;
$BODY$;


CREATE OR REPLACE FUNCTION tyre.insert_tyre_activity(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--get_operator_vehicle
----------------------

CREATE OR REPLACE FUNCTION operator.get_operator_vehicle(p_data json)
    RETURNS json
AS $BODY$
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
'tyreTypeName',(select portal.get_enum_name(obj.tyre_type_cd,'tyre_type_cd')),
'tyreSizeCd',obj.tyre_size_cd,
'tyreSizeName',(select portal.get_enum_name(obj.tyre_size_cd,'tyre_size_cd')),
'routeList',(select * from master_data.get_route(json_build_object('orgSno',obj.org_sno,'roleCd',6,'vehicleSno',obj.vehicle_sno))),
'vehicleDetails',(select operator.get_operator_vehicle_dtl(json_build_object('vehicleSno',obj.vehicle_sno))),
'ownerList',(select operator.get_operator_vehicle_owner(json_build_object('vehicleSno',obj.vehicle_sno))),
'kycStatus',( select portal.get_enum_name(obj.kyc_status,'organization_status_cd')),
'rejectReason',obj.reject_reason,
'activeFlag',obj.active_flag::text,
'tyreCountCd',obj.tyre_count_cd,
'tyreCountName',(select portal.get_enum_name(obj.tyre_count_cd,'tyre_count_cd'))	 	 
 )))from (select ov.org_sno,o.org_Name,v.vehicle_sno,v.vehicle_reg_number,v.vehicle_name,v.vehicle_banner_name,
		  v.chase_number,v.engine_number,v.media_sno,v.vehicle_type_cd,v.tyre_type_cd,v.tyre_size_cd,v.kyc_status,
		  v.reject_reason,v.active_flag::text,v.tyre_count_cd
		  from operator.org_vehicle ov inner join  operator.vehicle v on v.vehicle_sno=ov.vehicle_sno
 inner join operator.org o on o.org_sno=ov.org_sno
 left join operator.vehicle_detail vd on vd.vehicle_sno = v.vehicle_sno where 		  
case when (p_data->>'orgSno')::bigint is not null  then ov.org_sno=(p_data->>'orgSno')::bigint
else true end and
case when (p_data->>'selecteDate' = 'FC Expiry') then vd.fc_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and	
case when (p_data->>'selecteDate' = 'Insurance Expiry') then vd.insurance_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and	
case when (p_data->>'selecteDate'  = 'Pollution Expiry') then vd.pollution_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and	
case when (p_data->>'selecteDate'  = 'Tax Expiry')  then vd.tax_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and	
case when (p_data->>'selecteDate' = 'Permit Expiry')  then vd.permit_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and	
		  
		  
case when (p_data->>'vehicleTypeCd')::smallint is not null  then v.vehicle_type_cd =(p_data->>'vehicleTypeCd')::smallint
else true end and
case when (p_data->>'activeFlag') is not null then v.active_flag = (p_data->>'activeFlag')::boolean else v.kyc_status = 19 end and
case when (p_data->>'searchKey' is not null) then
		((v.vehicle_name ilike ('%' || trim((p_data->>'searchKey')::text) || '%')) or (v.vehicle_reg_number::text ilike ('%' || trim((p_data->>'searchKey')::text) || '%')))
		else true end and
case when (p_data->>'vehicleSno' is not null) then ov.vehicle_sno = (p_data->>'vehicleSno')::bigint else true end and 		
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
		  vd.vehicle_sno desc offset (p_data->>'skip')::bigint limit (p_data->>'limit')::bigint
		 )obj); 
end;
$BODY$
LANGUAGE plpgsql;


--get_dashboard_count
---------------------


CREATE OR REPLACE FUNCTION operator.get_dashboard_count(p_data json)
    RETURNS json
AS $BODY$
declare 
fc_expiry_count bigint;
insurance_expiry_count bigint;
pollution_expiry_count bigint;
tax_expiry_count bigint;
permit_expiry_count bigint;
vehicle_count bigint;
driver_count bigint;
route_count bigint;
booking_count bigint;
notification_count bigint;
begin
select count(*) into fc_expiry_count from operator.vehicle_detail vd inner join operator.org_vehicle ov on ov.vehicle_sno= vd.vehicle_sno where fc_expiry_date::date < (SELECT CURRENT_DATE + INTERVAL '10 days') and ov.org_sno=(p_data->>'orgSno')::bigint;
select count(*) into insurance_expiry_count from operator.vehicle_detail vd inner join operator.org_vehicle ov on ov.vehicle_sno= vd.vehicle_sno where insurance_expiry_date::date < (SELECT CURRENT_DATE + INTERVAL '10 days') and ov.org_sno=(p_data->>'orgSno')::bigint;
select count(*) into pollution_expiry_count from operator.vehicle_detail vd inner join operator.org_vehicle ov on ov.vehicle_sno= vd.vehicle_sno where pollution_expiry_date::date < (SELECT CURRENT_DATE + INTERVAL '10 days') and ov.org_sno=(p_data->>'orgSno')::bigint;
select count(*) into tax_expiry_count from operator.vehicle_detail vd inner join operator.org_vehicle ov on ov.vehicle_sno= vd.vehicle_sno where tax_expiry_date::date < (SELECT CURRENT_DATE + INTERVAL '10 days') and ov.org_sno=(p_data->>'orgSno')::bigint;
select count(*) into permit_expiry_count from operator.vehicle_detail vd inner join operator.org_vehicle ov on ov.vehicle_sno= vd.vehicle_sno where permit_expiry_date::date < (SELECT CURRENT_DATE + INTERVAL '10 days') and ov.org_sno=(p_data->>'orgSno')::bigint;
select count(*) into vehicle_count from operator.org_vehicle ov inner join operator.vehicle v on v.vehicle_sno=ov.vehicle_sno where org_sno=(p_data->>'orgSno')::bigint and v.active_flag=true;
select count(*) into driver_count from operator.operator_driver where org_sno=(p_data->>'orgSno')::bigint and active_flag=true;
select count(distinct route_sno) into route_count from operator.single_route where org_sno=(p_data->>'orgSno')::bigint;
select count(*) into booking_count from rent.booking b inner join operator.org_vehicle ov on b.vehicle_sno = ov.vehicle_sno where org_sno=(p_data->>'orgSno')::bigint;
select count(*) into notification_count from notification.notification where notification_status_cd = 117 and to_id=(select app_user_sno from operator.org_owner where org_sno=(p_data->>'orgSno')::bigint);

  return (select json_build_object('data',json_agg(json_build_object(
  'dashboard',(select  
		  json_agg(json_build_object('title','Total Vehicles','count',vehicle_count,'class','text-warning','icon','fa fa-bus','path','registervehicle'))::jsonb ||
		  json_agg(json_build_object('title','Total Bookings','count',booking_count,'class','text-success','icon','fa fa-user','path','view-booking'))::jsonb ||
		  json_agg(json_build_object('title','Total Drivers','count',driver_count,'class','text-info','icon','fa fa-ticket','path','driver'))::jsonb || 
		  json_agg(json_build_object('title','Running Routes','count',route_count,'class','text-danger','icon','fa fa-route','path','single'))::jsonb || 
		  json_agg(json_build_object('title','Notification','count',notification_count,'class','text-primary','icon','fa fa-bell','path','notification'))::jsonb 
			  ),
	  'expiryList',(select
		  json_agg(json_build_object('title','FC Expiry','count',fc_expiry_count,'class','bg-primary','icon','fa fa-bus','path','registervehicle'))::jsonb ||
		  json_agg(json_build_object('title','Insurance Expiry','count',insurance_expiry_count,'class','bg-danger','icon','fa fa-truck','path','registervehicle'))::jsonb ||
		  json_agg(json_build_object('title','Pollution Expiry','count',pollution_expiry_count,'class','bg-success','icon','fa fa-sun','path','registervehicle'))::jsonb ||
		  json_agg(json_build_object('title','Tax Expiry','count',tax_expiry_count,'class','bg-info','icon','fa fa-bus','path','registervehicle'))::jsonb ||
		  json_agg(json_build_object('title','Permit Expiry','count',permit_expiry_count,'class','bg-secondary','icon','fa fa-route','path','registervehicle'))::jsonb 
          )
  )))
		 );

end;
$BODY$
LANGUAGE plpgsql;



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
where 
	case when (p_data->>'orgSno')::bigint is not null then od.org_sno=(p_data->>'orgSno')::bigint else true end and
	case when (p_data->>'driverSno') is not null then d.driver_sno=(p_data->>'driverSno')::bigint else true end and
	case when (p_data->>'activeFlag') is not null then d.active_flag=(p_data->>'activeFlag')::boolean else true end and
	case when (p_data->>'searchKey') is not null then ((trim(d.driver_name) ilike ('%' || trim(p_data->>'searchKey') || '%')) or
				(trim(d.licence_number) ilike ('%' || trim(p_data->>'searchKey') || '%')))
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

CREATE OR REPLACE FUNCTION operator.get_search_available_tyre(p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
AS $BODY$
declare 
tyre_list json;
begin

select json_agg(json_build_object('tyreSno',t.tyre_sno,
								  'tyreSerialNumber',t.tyre_serial_number,
								  'typeTypeValue',dtl.cd_value,
								  'retreadingCount',(select count(*) from tyre.tyre_activity where tyre_activity_type_cd = 99 and tyre_sno = t.tyre_sno and vehicle_sno is not  null )
								 )) into tyre_list from tyre.tyre t 
inner join portal.codes_dtl dtl on dtl.codes_dtl_sno = t.tyre_type_cd
where t.active_flag = true and t.is_bursted = false and
case when p_data->>'orgSno' is not null then
t.org_sno = (p_data->>'orgSno')::bigint and t.is_running = false
when p_data->>'tyreSno' is not null then 
t.tyre_sno =  (p_data->>'tyreSno')::bigint
else false end;
return tyre_list;
end;
$BODY$;

CREATE OR REPLACE FUNCTION tyre.get_tyre(p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
AS $BODY$
declare 
tyre_list json;
begin

select  json_agg(json_build_object(
								  'tyreSno',t.tyre_sno,
								  'tyreSerialNumber',t.tyre_serial_number,
								  'tyreSize',t.tyre_size,
								  'tyrePrice',t.tyre_price,
								  'tyreTypeCd',t.tyre_type_cd,
								  'paymentModeCd',t.payment_mode_cd,
								  'tyreTypeName',(select cd.cd_value from portal.codes_dtl cd where cd.codes_dtl_sno = t.tyre_type_cd),
								  'paymentMethod',(select cd.cd_value from portal.codes_dtl cd where cd.codes_dtl_sno = t.payment_mode_cd),
								  'invoiceMedia',(select media.get_media_detail(json_build_object('mediaSno',invoice_media))->0),
								  'agencyName',t.agency_name,
								  'invoiceDate',t.invoice_date,
								  'incomingDate',t.incoming_date,
						          'efficiencyValue',t.efficiency_value,
								  'isNew',t.is_new,
								  'isRunning',t.is_running,
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
								 )) into tyre_list from (select t.tyre_sno,t.tyre_serial_number,t.tyre_size,t.tyre_price,t.tyre_type_cd,t.payment_mode_cd,
t.invoice_media,t.agency_name,t.invoice_date,t.incoming_date,t.efficiency_value,t.is_new,t.is_running,t.stock,t.active_flag,t.is_bursted
from tyre.tyre t
	   where case when (p_data->>'orgSno')::bigint is not null  then org_sno=(p_data->>'orgSno')::bigint
	   else true end and 
	   case when (p_data->>'activeFlag') is not null then active_flag = (p_data->>'activeFlag')::boolean else true end and
	   case when (p_data->>'searchKey' is not null) then
		((agency_name::text ilike ('%' || trim((p_data->>'searchKey')::text) || '%')) or (tyre_serial_number::text ilike ('%' || trim((p_data->>'searchKey')::text) || '%')))
		else true end order by t.tyre_sno desc offset (p_data->>'skip')::bigint limit (p_data->>'limit')::bigint )t;
		
return (select json_build_object('data',tyre_list));

end;
$BODY$;

CREATE OR REPLACE FUNCTION tyre.get_tyre_count(p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
AS $BODY$
declare 
counts bigint;
begin

select count(*) into counts from tyre.tyre t
	   where case when (p_data->>'orgSno')::bigint is not null  then org_sno=(p_data->>'orgSno')::bigint
	   else true end and 
	   case when (p_data->>'activeFlag') is not null then active_flag = (p_data->>'activeFlag')::boolean else true end and
	   case when (p_data->>'searchKey' is not null) then
		((agency_name::text ilike ('%' || trim((p_data->>'searchKey')::text) || '%')) or (tyre_serial_number::text ilike ('%' || trim((p_data->>'searchKey')::text) || '%')))
		else true end;
		
return (select json_build_object('data',(select json_agg(json_build_object('counts',counts)))));

end;
$BODY$;