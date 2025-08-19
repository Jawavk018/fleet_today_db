

--get_all_driver_count
----------------------


CREATE OR REPLACE FUNCTION driver.get_all_driver_count(p_data json)
RETURNS json
LANGUAGE 'plpgsql'
AS $BODY$
declare
_count bigint;
begin
raise notice 'count%',(p_data);

if(p_data->>'orgSno')::bigint is not null then
	with op_driver as (select * from operator.operator_driver od where od.org_Sno = (p_data->>'orgSno')::bigint and od.active_flag = true) 
	
	select count(*) into _count from op_driver od
	inner join driver.driver d on d.driver_sno = od.driver_sno and d.kyc_status = 19 where 
	case when (p_data->>'district' is not null and trim(p_data->>'district') <> '') then
	lower(trim(current_district)) in (select lower(trim(a::text)) from json_array_elements_text((p_data->>'district')::json)a)
	else true end and
		case when (p_data->>'searchKey') is not null then ((trim(d.driver_name) ilike ('%' || trim(p_data->>'searchKey') || '%')) or
				(trim(d.licence_number) ilike ('%' || trim(p_data->>'searchKey') || '%')))
				else true end;
	return (select  json_build_object('data',json_agg(json_build_object('count',_count))));
else
	select count(*) into _count from driver.driver d where d.kyc_status = 19 and case when (p_data->>'district' is not null and trim(p_data->>'district') <> '') then
	lower(trim(current_district)) in (select lower(trim(a::text)) from json_array_elements_text((p_data->>'district')::json)a)
	else true end and case when (p_data->>'searchKey') is not null then ((trim(d.driver_name) ilike ('%' || trim(p_data->>'searchKey') || '%')) or
				(trim(d.licence_number) ilike ('%' || trim(p_data->>'searchKey') || '%')))
				else true end;
	return (select  json_build_object('data',json_agg(json_build_object('count',_count))));
end if;

end;
$BODY$;


--get_bus_report_count
----------------------

CREATE OR REPLACE FUNCTION operator.get_bus_report_count(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;


--get_fuel_report_count
-----------------------


CREATE OR REPLACE FUNCTION operator.get_fuel_report_count(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
case when (p_data->>'filledDate')::timestamp is not null then f.filled_date::date=(p_data->>'filledDate')::date else true end;

return (select  json_build_object('data',json_agg(json_build_object('count',_count))));

end;
$BODY$;





--get_all_vehicle_count
----------------------

CREATE OR REPLACE FUNCTION operator.get_all_vehicle_count(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
_count bigint;
begin
raise notice 'count%',(p_data);

if(p_data->>'orgSno')::bigint is not null then
raise notice 'jawa%',p_data;
select count(*) into _count from operator.vehicle v
inner join operator.org_vehicle ov on ov.vehicle_sno = v.vehicle_sno
 left join operator.vehicle_detail vd on vd.vehicle_sno = v.vehicle_sno where 		  
 ov.org_Sno = (p_data->>'orgSno')::bigint and case when (p_data->>'selecteDate' = 'FC Expiry') then vd.fc_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and	
case when (p_data->>'selecteDate' = 'Insurance Expiry') then vd.insurance_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and	
case when (p_data->>'selecteDate'  = 'Pollution Expiry') then vd.pollution_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and	
case when (p_data->>'selecteDate'  = 'Tax Expiry')  then vd.tax_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and	
case when (p_data->>'selecteDate' = 'Permit Expiry')  then vd.permit_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and case when (p_data->>'vehicleTypeCd')::smallint is not null  then v.vehicle_type_cd =(p_data->>'vehicleTypeCd')::smallint
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
case when (p_data->>'activeFlag') is not null then v.active_flag = (p_data->>'activeFlag')::boolean else v.kyc_status = 19 end and case when (p_data->>'searchKey' is not null) then
		((v.vehicle_name ilike ('%' || trim((p_data->>'searchKey')::text) || '%')) or (v.vehicle_reg_number::text ilike ('%' || trim((p_data->>'searchKey')::text) || '%')))
		else true end and
case when (p_data->>'vehicleSno' is not null) then ov.vehicle_sno = (p_data->>'vehicleSno')::bigint else true end and 		
case when (p_data->>'vehicleTypes' is not null) then v.vehicle_type_cd in (select json_array_elements((p_data->>'vehicleTypes')::json)::text::smallint)  else true end;
return (select  json_build_object('data',json_agg(json_build_object('count',_count))));

end if;

end;
$BODY$;




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
org_app_count int;
vehi_app_count int;
driver_app_count int;
org_count bigint;
begin
if (p_data->>'roleCd')::int =2 then 
select count(*) into fc_expiry_count from operator.vehicle_detail vd inner join operator.org_vehicle ov on ov.vehicle_sno= vd.vehicle_sno where fc_expiry_date::date < (SELECT CURRENT_DATE + INTERVAL '10 days') and ov.org_sno=(p_data->>'orgSno')::bigint 
and case when (p_data->>'selecteDate' = 'FC Expiry') then vd.fc_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end ;

select count(*) into insurance_expiry_count from operator.vehicle_detail vd inner join operator.org_vehicle ov on ov.vehicle_sno= vd.vehicle_sno where insurance_expiry_date::date < (SELECT CURRENT_DATE + INTERVAL '10 days') and ov.org_sno=(p_data->>'orgSno')::bigint
and case when (p_data->>'selecteDate' = 'Insurance Expiry') then vd.insurance_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end ;

select count(*) into pollution_expiry_count from operator.vehicle_detail vd inner join operator.org_vehicle ov on ov.vehicle_sno= vd.vehicle_sno where pollution_expiry_date::date < (SELECT CURRENT_DATE + INTERVAL '10 days') and ov.org_sno=(p_data->>'orgSno')::bigint
and case when (p_data->>'selecteDate'  = 'Pollution Expiry') then vd.pollution_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end ;

select count(*) into tax_expiry_count from operator.vehicle_detail vd inner join operator.org_vehicle ov on ov.vehicle_sno= vd.vehicle_sno where tax_expiry_date::date < (SELECT CURRENT_DATE + INTERVAL '10 days') and ov.org_sno=(p_data->>'orgSno')::bigint 
and case when (p_data->>'selecteDate'  = 'Tax Expiry')  then vd.tax_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end ;

select count(*) into permit_expiry_count from operator.vehicle_detail vd inner join operator.org_vehicle ov on ov.vehicle_sno= vd.vehicle_sno where permit_expiry_date::date < (SELECT CURRENT_DATE + INTERVAL '10 days') and ov.org_sno=(p_data->>'orgSno')::bigint
and case when (p_data->>'selecteDate' = 'Permit Expiry')  then vd.permit_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end ;


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
else
select count(*) into org_app_count from operator.org where org_status_cd = 20;
select count(*) into vehi_app_count from operator.vehicle where kyc_status = 20;
select count(*) into driver_app_count from driver.driver where kyc_status = 20;
select count(*) into org_count from operator.org  where org_status_cd = 19;
select count(*) into vehicle_count from operator.vehicle where kyc_status = 19;
select count(*) into driver_count from driver.driver where kyc_status = 19;
-- select count(*) into driver_count from operator.driver where kyc_status = 19;
select count(*) into notification_count from notification.notification where notification_status_cd = 117 and to_id=1;

return (select json_build_object('data',json_agg(json_build_object(
  'dashboard',(select  
		  json_agg(json_build_object('title','Total Operators','count',org_count,'class','text-danger','icon','fa fa-user','path','operatorlist'))::jsonb ||
		  json_agg(json_build_object('title','Total Vehicles','count',vehicle_count,'class','text-warning','icon','fa fa-bus','path','vehiclelist'))::jsonb ||
		  json_agg(json_build_object('title','Total Drivers','count',driver_count,'class','text-success','icon','fa fa-user-circle-o','path','driverlist'))::jsonb || 
		  json_agg(json_build_object('title','Waiting Approvals','count',(org_app_count+vehi_app_count+driver_app_count),'class','text-info','icon','fa fa-ticket','path','approval'))::jsonb || 
		  json_agg(json_build_object('title','Notification','count',notification_count,'class','text-primary','icon','fa fa-bell','path','notification'))::jsonb 
			  )
	 
  )))
		 );
end if;
end;
$BODY$
LANGUAGE plpgsql;

