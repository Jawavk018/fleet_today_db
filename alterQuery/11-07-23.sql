

--get_driver
-----------

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
	case when (p_data->>'selecteDate' = 'Transport License Expiry') then d.transport_licence_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and	
case when (p_data->>'selecteDate' = 'Driver License Expiry') then d.licence_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and				
	case when (p_data->>'driverSno') is not null then d.driver_sno=(p_data->>'driverSno')::bigint else true end and
	case when (p_data->>'activeFlag') is not null then d.active_flag=(p_data->>'activeFlag')::boolean else true end and
	case when (p_data->>'searchKey') is not null then ((trim(d.driver_name) ilike ('%' || trim(p_data->>'searchKey') || '%')) or
				(trim(d.licence_number) ilike ('%' || trim(p_data->>'searchKey') || '%')))
				else true end order by
		  case when (p_data->>'expiryType' = 'Transport License Expiry') and d.transport_licence_expiry_date is null then 1 end desc,
		  case when (p_data->>'expiryType' = 'Transport License Expiryy') and (d.transport_licence_expiry_date < (p_data->>'today')::date) then d.transport_licence_expiry_date end asc,
		  case when (p_data->>'expiryType' = 'Transport License Expiry') and ((d.transport_licence_expiry_date::date = (p_data->>'today')::date) or (d.transport_licence_expiry_date >= (p_data->>'today')::date)) then d.transport_licence_expiry_date end asc,  
		  case when (p_data->>'expiryType' = 'Transport License Expiry') then d.transport_licence_expiry_date end desc,
			
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




--get_all_driver_count
---------------------


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
	inner join driver.driver d on d.driver_sno = od.driver_sno and d.kyc_status = 19 and d.active_flag=(p_data->>'activeFlag')::boolean where 
	od.org_sno=(p_data->>'orgSno')::bigint and
	case when (p_data->>'selecteDate'  = 'Driver License Expiry')  then d.licence_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and	
	
	case when (p_data->>'selecteDate'  = 'Transport License Expiry')  then d.transport_licence_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and	
	
	case when (p_data->>'district' is not null and trim(p_data->>'district') <> '') then
	lower(trim(current_district)) in (select lower(trim(a::text)) from json_array_elements_text((p_data->>'district')::json)a)
	else true end and
		case when (p_data->>'searchKey') is not null then ((trim(d.driver_name) ilike ('%' || trim(p_data->>'searchKey') || '%')) or
				(trim(d.licence_number) ilike ('%' || trim(p_data->>'searchKey') || '%')))
				else true end;
	return (select  json_build_object('data',json_agg(json_build_object('count',_count))));
else
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
driver_license_count bigint;
driver_transport_license_count bigint;
active_vehicle_count bigint;
inactive_vehicle_count bigint;
begin
if (p_data->>'roleCd')::int =2 then 
select count(*) into fc_expiry_count from operator.vehicle_detail vd inner join operator.vehicle v on v.vehicle_sno = vd.vehicle_sno inner join operator.org_vehicle ov on ov.vehicle_sno= vd.vehicle_sno where fc_expiry_date::date < (SELECT CURRENT_DATE + INTERVAL '10 days') and ov.org_sno=(p_data->>'orgSno')::bigint 
and case when (p_data->>'selecteDate' = 'FC Expiry') then vd.fc_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and v.active_flag=true ;

select count(*) into insurance_expiry_count from operator.vehicle_detail vd inner join operator.vehicle v on v.vehicle_sno = vd.vehicle_sno inner join operator.org_vehicle ov on ov.vehicle_sno= vd.vehicle_sno where insurance_expiry_date::date < (SELECT CURRENT_DATE + INTERVAL '10 days') and ov.org_sno=(p_data->>'orgSno')::bigint
and case when (p_data->>'selecteDate' = 'Insurance Expiry') then vd.insurance_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and v.active_flag=true ;

select count(*) into pollution_expiry_count from operator.vehicle_detail vd inner join operator.vehicle v on v.vehicle_sno = vd.vehicle_sno inner join operator.org_vehicle ov on ov.vehicle_sno= vd.vehicle_sno where pollution_expiry_date::date < (SELECT CURRENT_DATE + INTERVAL '10 days') and ov.org_sno=(p_data->>'orgSno')::bigint
and case when (p_data->>'selecteDate'  = 'Pollution Expiry') then vd.pollution_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and v.active_flag=true ;

select count(*) into tax_expiry_count from operator.vehicle_detail vd inner join operator.vehicle v on v.vehicle_sno = vd.vehicle_sno inner join operator.org_vehicle ov on ov.vehicle_sno= vd.vehicle_sno where tax_expiry_date::date < (SELECT CURRENT_DATE + INTERVAL '10 days') and ov.org_sno=(p_data->>'orgSno')::bigint 
and case when (p_data->>'selecteDate'  = 'Tax Expiry')  then vd.tax_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and v.active_flag=true ;

select count(*) into permit_expiry_count from operator.vehicle_detail vd inner join operator.vehicle v on v.vehicle_sno = vd.vehicle_sno inner join operator.org_vehicle ov on ov.vehicle_sno= vd.vehicle_sno where permit_expiry_date::date < (SELECT CURRENT_DATE + INTERVAL '10 days') and ov.org_sno=(p_data->>'orgSno')::bigint
and case when (p_data->>'selecteDate' = 'Permit Expiry')  then vd.permit_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days') else true end and v.active_flag=true ;


select count(*) into vehicle_count from operator.org_vehicle ov inner join operator.vehicle v on v.vehicle_sno=ov.vehicle_sno where org_sno=(p_data->>'orgSno')::bigint and v.active_flag=true;
select count(*) into driver_count from operator.operator_driver od
inner join driver.driver d on d.driver_sno=od.driver_sno where od.org_sno=(p_data->>'orgSno')::bigint and d.active_flag=true;
select count(distinct route_sno) into route_count from operator.single_route where org_sno=(p_data->>'orgSno')::bigint;
select count(*) into booking_count from rent.booking b inner join operator.org_vehicle ov on b.vehicle_sno = ov.vehicle_sno where ov.org_sno=(p_data->>'orgSno')::bigint and b.active_flag=true;
select count(*) into notification_count from notification.notification where notification_status_cd = 117 and to_id=(select app_user_sno from operator.org_owner where org_sno=(p_data->>'orgSno')::bigint);
select count(*) into driver_license_count from operator.operator_driver od
inner join driver.driver d on d.driver_sno=od.driver_sno
where od.org_sno=(p_data->>'orgSno')::bigint and d.active_flag=true and d.licence_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days');

select count(*) into driver_transport_license_count from operator.operator_driver od
inner join driver.driver d on d.driver_sno=od.driver_sno
where od.org_sno=(p_data->>'orgSno')::bigint and d.active_flag=true and d.transport_licence_expiry_date::date < (SELECT CURRENT_DATE +  INTERVAL '10 days');

  return (select json_build_object('data',json_agg(json_build_object(
  'dashboard',(select  
		  json_agg(json_build_object('title','Total Vehicles','count',vehicle_count,'class','text-warning','icon','fa fa-bus','path','registervehicle'))::jsonb ||
		  json_agg(json_build_object('title','Total Bookings','count',booking_count,'class','text-success','icon','fa fa-user','path','view-booking'))::jsonb ||
		  json_agg(json_build_object('title','Total Drivers','count',driver_count,'class','text-info','icon','fa fa-ticket','path','driver'))::jsonb || 
		  json_agg(json_build_object('title','Driver License Expiry','count',driver_license_count,'class','text-secondary','icon','fa fa-user-circle-o','path','driver'))::jsonb || 
		  json_agg(json_build_object('title','Running Routes','count',route_count,'class','text-danger','icon','fa fa-route','path','single'))::jsonb || 
		  json_agg(json_build_object('title','Notification','count',notification_count,'class','text-primary','icon','fa fa-bell','path','notification'))::jsonb 
			  ),
	  'expiryList',(select
		  json_agg(json_build_object('title','FC Expiry','count',fc_expiry_count,'class','bg-primary','icon','fa fa-bus','path','registervehicle'))::jsonb ||
		  json_agg(json_build_object('title','Insurance Expiry','count',insurance_expiry_count,'class','bg-danger','icon','fa fa-truck','path','registervehicle'))::jsonb ||
		  json_agg(json_build_object('title','Pollution Expiry','count',pollution_expiry_count,'class','bg-success','icon','fa fa-sun','path','registervehicle'))::jsonb ||
		  json_agg(json_build_object('title','Tax Expiry','count',tax_expiry_count,'class','bg-info','icon','fa fa-bus','path','registervehicle'))::jsonb ||
		  json_agg(json_build_object('title','Permit Expiry','count',permit_expiry_count,'class','bg-secondary','icon','fa fa-route','path','registervehicle'))::jsonb ||
		  json_agg(json_build_object('title','Transport License Expiry','count',driver_transport_license_count,'class','bg-warning','icon','fa fa-user-circle-o','path','driver'))::jsonb 
          )
  )))
		 );
else

select count(*) into active_vehicle_count from operator.vehicle v where active_flag = true;
select count(*) into inactive_vehicle_count from operator.vehicle v where active_flag = false;
select count(*) into org_app_count from operator.org where org_status_cd = 20;
select count(*) into vehi_app_count from operator.vehicle where kyc_status = 20;
select count(*) into driver_app_count from driver.driver where kyc_status = 20;
select count(*) into org_count from operator.org  where org_status_cd = 19;
select count(*) into vehicle_count from operator.vehicle where kyc_status = 19 ;
select count(*) into driver_count from driver.driver where kyc_status = 19 ;
-- select count(*) into driver_count from operator.driver where kyc_status = 19;
select count(*) into notification_count from notification.notification where notification_status_cd = 117 and to_id=1;

return (select json_build_object('data',json_agg(json_build_object(
  'dashboard',(select  
		  json_agg(json_build_object('title','Total Operators','count',org_count,'class','text-danger','icon','fa fa-user','path','operatorlist'))::jsonb ||
		  json_agg(json_build_object('title','Total Vehicles','count',vehicle_count,'class','text-warning','icon','fa fa-bus','path','vehiclelist'))::jsonb ||
		  json_agg(json_build_object('title','Total Drivers','count',driver_count,'class','text-success','icon','fa fa-user-circle-o','path','driverlist'))::jsonb || 
		  json_agg(json_build_object('title','Waiting Approvals','count',(org_app_count+vehi_app_count+driver_app_count),'class','text-info','icon','fa fa-ticket','path','approval'))::jsonb || 
		  json_agg(json_build_object('title','Notification','count',notification_count,'class','text-primary','icon','fa fa-bell','path','notification'))::jsonb ||
	      json_agg(json_build_object('title','Active Vehicle','count',active_vehicle_count,'class','text-dark','icon','fa fa-bus','path','vehiclelist'))::jsonb ||
		  json_agg(json_build_object('title','Inactive Vehicle','count',inactive_vehicle_count,'class','text-secondary','icon','fa fa-truck','path','vehiclelist'))::jsonb 	   
			  )
  )))
		 );
end if;
end;
$BODY$
LANGUAGE plpgsql;



--get_operator_vehicle
-----------------------

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
		  vd.vehicle_sno desc offset (p_data->>'skip')::bigint limit (p_data->>'limit')::bigint
		 )obj); 
end;
$BODY$
LANGUAGE plpgsql;


--get_all_vehicle_count
-----------------------


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
$BODY$;

		  