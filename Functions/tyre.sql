

--get_tyre
----------

CREATE OR REPLACE FUNCTION tyre.get_tyre(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;

--get_tyre_company
------------------


CREATE OR REPLACE FUNCTION master_data.get_tyre_company(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare 
begin

return (select  json_build_object('data',json_agg(json_build_object(
	'tyreCompanySno',tc.tyre_company_sno,
	'tyreCompany',tc.tyre_company,
	'activeFlag',tc.active_flag)))from master_data.tyre_company tc where tc.active_flag=true);	
		
end;
$BODY$;



--insert_tyre
-------------
CREATE OR REPLACE FUNCTION tyre.insert_tyre(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
AS $BODY$
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
$BODY$;



--update_tyre
-------------

CREATE OR REPLACE FUNCTION tyre.update_tyre(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--insert_tyre_activity

-- CREATE OR REPLACE FUNCTION tyre.insert_tyre_activity(p_data json)
--     RETURNS json
-- AS $BODY$
-- declare 
-- _tyre_pre_actitvity json;
-- _tyre_activity_sno bigint;
-- _tyre_activity_type_cd smallint;
-- begin

-- if ((p_data->>'tyreActivityTypeCd')::smallint = 89 OR (p_data->>'tyreActivityTypeCd')::smallint = 92) then 
-- select json_build_object(
-- 		'tyreActivitySno',ta.tyre_activity_sno,
-- 		'tyreSno',ta.tyre_sno,
-- 		'tyreActivityTypeCd',86,
-- 		'runningKm',((p_data->>'odoMeter')::numeric - ta.odo_meter),
-- 		'runningLife', (p_data->>'activityDate')::timestamp - ta.activity_date,
-- 		'activityStartDate',ta.activity_date,
-- 		'activityEndDate',(p_data->>'activityDate')::timestamp
-- 	) into _tyre_pre_actitvity from tyre.tyre_activity ta
-- 	where ta.vehicle_sno = (p_data->>'vehicleSno')::bigint and ta.tyre_sno = (p_data->>'tyreSno')::bigint and 
-- 	ta.tyre_activity_type_cd = 86 and is_running = true; 
	
-- 	if ( _tyre_pre_actitvity is  null) then
-- 	select json_build_object(
-- 		'tyreActivitySno',ta.tyre_activity_sno,
-- 		'tyreSno',ta.tyre_sno,
-- 		'tyreActivityTypeCd',88,
-- 		'runningKm',((p_data->>'odoMeter')::numeric - ta.odo_meter),
-- 		'runningLife', (p_data->>'activityDate')::timestamp - ta.activity_date,
-- 		'activityStartDate',ta.activity_date,
-- 		'activityEndDate',(p_data->>'activityDate')::timestamp
-- 	) into _tyre_pre_actitvity from tyre.tyre_activity ta
-- 	where ta.vehicle_sno = (p_data->>'vehicleSno')::bigint and ta.tyre_sno = (p_data->>'tyreSno')::bigint and 
-- 	ta.tyre_activity_type_cd = 88 and is_running = true; 
-- 	end if;
-- 	if ( _tyre_pre_actitvity is null) then
-- 	select json_build_object(
-- 		'tyreActivitySno',ta.tyre_activity_sno,
-- 		'tyreSno',ta.tyre_sno,
-- 		'tyreActivityTypeCd',(p_data->>'tyreActivityTypeCd')::smallint,
-- 		'runningKm',((p_data->>'odoMeter')::numeric - ta.odo_meter),
-- 		'runningLife', (p_data->>'activityDate')::timestamp - ta.activity_date,
-- 		'activityStartDate',ta.activity_date,
-- 		'activityEndDate',(p_data->>'activityDate')::timestamp
-- 	) into _tyre_pre_actitvity from tyre.tyre_activity ta
-- 	where ta.vehicle_sno = (p_data->>'vehicleSno')::bigint and ta.tyre_sno = (p_data->>'tyreSno')::bigint and 
-- 	ta.tyre_activity_type_cd = (p_data->>'tyreActivityTypeCd')::smallint ; 
-- 	end if;
	
-- 	if ( _tyre_pre_actitvity is null) then
-- 	select json_build_object(
-- 		'tyreActivitySno',ta.tyre_activity_sno,
-- 		'tyreSno',ta.tyre_sno,
-- 		'tyreActivityTypeCd',86,
-- 		'runningKm',((p_data->>'odoMeter')::numeric - ta.odo_meter),
-- 		'runningLife', (p_data->>'activityDate')::timestamp - ta.activity_date,
-- 		'activityStartDate',ta.activity_date,
-- 		'activityEndDate',(p_data->>'activityDate')::timestamp
-- 	) into _tyre_pre_actitvity from tyre.tyre_activity ta
-- 	where ta.vehicle_sno = (p_data->>'vehicleSno')::bigint and ta.tyre_sno = (p_data->>'tyreSno')::bigint and 
-- 	ta.tyre_activity_type_cd = 86;
-- 	end if;
	
-- 	if ( _tyre_pre_actitvity is not null) then
-- 	update tyre.tyre_activity set is_running = false where tyre_activity_sno = (_tyre_pre_actitvity->>'tyreActivitySno')::bigint;
-- 	end if;
	
-- elseif((p_data->>'tyreActivityTypeCd')::smallint = 88) then 
-- 	select json_build_object(
-- 		'tyreActivitySno',ta.tyre_activity_sno,
-- 		'tyreSno',ta.tyre_sno,
-- 		'tyreActivityTypeCd',(p_data->>'tyreActivityTypeCd')::smallint,
-- 		'runningKm',((p_data->>'odoMeter')::numeric - ta.odo_meter),
-- 		'runningLife', (p_data->>'activityDate')::timestamp - ta.activity_date,
-- 		'activityStartDate',ta.activity_date,
-- 		'activityEndDate',(p_data->>'activityDate')::timestamp
-- 	) into _tyre_pre_actitvity from tyre.tyre_activity ta
-- 	where ta.vehicle_sno = (p_data->>'vehicleSno')::bigint and ta.tyre_sno = (p_data->>'tyreSno')::bigint and 
-- 	ta.tyre_activity_type_cd = (p_data->>'tyreActivityTypeCd')::smallint order by ta.tyre_activity_sno desc limit 1; 
	
-- 	if ( _tyre_pre_actitvity is null) then
-- 	select json_build_object(
-- 		'tyreActivitySno',ta.tyre_activity_sno,
-- 		'tyreSno',ta.tyre_sno,
-- 		'tyreActivityTypeCd',86,
-- 		'runningKm',((p_data->>'odoMeter')::numeric - ta.odo_meter),
-- 		'runningLife', (p_data->>'activityDate')::timestamp - ta.activity_date,
-- 		'activityStartDate',ta.activity_date,
-- 		'activityEndDate',(p_data->>'activityDate')::timestamp
-- 	) into _tyre_pre_actitvity from tyre.tyre_activity ta
-- 	where ta.vehicle_sno = (p_data->>'vehicleSno')::bigint and ta.tyre_sno = (p_data->>'tyreSno')::bigint and 
-- 	ta.tyre_activity_type_cd = 86 ; 
-- 	end if;
-- 	if ( _tyre_pre_actitvity is not null) then
-- 	update tyre.tyre_activity set is_running = false where vehicle_sno = (p_data->>'vehicleSno')::bigint and tyre_sno = (p_data->>'tyreSno')::bigint;
-- 	end if;
-- end if;

-- raise notice '_tyre_pre_actitvity%', _tyre_pre_actitvity;
-- if (_tyre_pre_actitvity is not null) then
-- 	insert into tyre.tyre_activity_total_km(tyre_sno,tyre_activity_type_cd,running_km,running_life,activity_start_date,activity_end_date,tyre_activity_sno)	
-- 		values((_tyre_pre_actitvity->>'tyreSno')::bigint,
-- 			   (_tyre_pre_actitvity->>'tyreActivityTypeCd')::smallint,
-- 			   (_tyre_pre_actitvity->>'runningKm')::numeric,
-- 			   (_tyre_pre_actitvity->>'runningLife'),
-- 			   (_tyre_pre_actitvity->>'activityStartDate')::timestamp,
-- 			   (_tyre_pre_actitvity->>'activityEndDate')::timestamp,(_tyre_pre_actitvity->>'tyreActivitySno')::bigint);

	
	
-- 	select tyre_activity_type_cd into _tyre_activity_type_cd from tyre.tyre_activity where tyre_sno = (p_data->>'changeTyreSno')::bigint and tyre_activity_type_cd = (p_data->>'tyreActivityTypeCd')::smallint;

-- 	if((p_data->>'tyreActivityTypeCd')::bigint = 88) then	   

-- 	 insert into tyre.tyre_activity(tyre_sno,vehicle_sno,tyre_activity_type_cd,description,odo_meter,is_running,activity_date,wheel_position)
-- 	 values ((p_data->>'changeTyreSno')::bigint,(p_data->>'vehicleSno')::bigint,case when _tyre_activity_type_cd is null  then 86 else _tyre_activity_type_cd end ,p_data->>'description',
-- 	 (p_data->>'odoMeter')::numeric,true,(p_data->>'activityDate')::timestamp,p_data->>'wheelPosition')
-- 	  returning tyre_activity_sno into _tyre_activity_sno;

-- 	end if;
	
-- end if;


-- insert into tyre.tyre_activity(tyre_sno,vehicle_sno,tyre_activity_type_cd,description,odo_meter,is_running,activity_date,wheel_position)
-- values ( case when (p_data->>'tyreActivityTypeCd')::smallint <> 89 then (p_data->>'tyreSno')::bigint else (p_data->>'changeTyreSno')::bigint end,
-- case when (p_data->>'tyreActivityTypeCd')::smallint <> 88 then (p_data->>'vehicleSno')::bigint else null end,
-- (p_data->>'tyreActivityTypeCd')::smallint,
-- p_data->>'description',
-- (p_data->>'odoMeter')::numeric,
-- (p_data->>'isRunning')::boolean,
-- (p_data->>'activityDate')::timestamp,
-- case when (p_data->>'tyreActivityTypeCd')::smallint = 88 then 'inventory' else p_data->>'wheelPosition' end
-- ) returning tyre_activity_sno into _tyre_activity_sno;
	   
-- return (select json_build_object('data',json_build_object('tyreActivitySno',_tyre_activity_sno)));
-- end;
-- $BODY$
-- LANGUAGE plpgsql;


--insert_tyre_activity
----------------------

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

-- --insert_tyre
-- ---------------
-- CREATE OR REPLACE FUNCTION tyre.insert_tyre(
-- 	p_data json)
--     RETURNS json
--     LANGUAGE 'plpgsql'
--     COST 100
--     VOLATILE PARALLEL UNSAFE
-- AS $BODY$
-- declare 
-- tyreSno bigint;
-- begin
-- -- raise notice '%',p_data;
-- insert into tyre.tyre(org_sno,tyre_company,manufacture_date,tyre_size,serial_number,tyre_type_cd,tyre_usage_cd,usage_count,media_sno,description,created_on,is_assigned,active_flag) 
--    values ((p_data->>'orgSno')::bigint,p_data->>'tyreCompany',(p_data->>'manufactureDate')::timestamp,p_data->>'tyreSize',p_data->>'serialNumber',(p_data->>'tyreTypeCd')::smallint,
-- 		   (p_data->>'tyreUsageCd')::smallint,(p_data->>'usageCount')::smallint,
-- 		   (p_data->>'mediaSno')::bigint,p_data->>'description',portal.get_time_with_zone(json_build_object('timeZone',p_data->>'createdOn'))::timestamp,(p_data->>'isAssigned')::boolean,(p_data->>'activeFlag')::boolean
--           ) returning tyre_sno  INTO tyreSno;
--   return (select json_build_object('data',json_build_object('tyreSno',tyreSno)));
-- end;
-- $BODY$;


-- --get_tyre
-- -----------
-- CREATE OR REPLACE FUNCTION tyre.get_tyre(
-- 	p_data json)
--     RETURNS json
--     LANGUAGE 'plpgsql'
--     COST 100
--     VOLATILE PARALLEL UNSAFE
-- AS $BODY$
-- declare 
-- begin
-- raise notice 'Padhu%',p_data;
-- return ( select  json_build_object('data',json_agg(json_build_object(
-- 								  'tyreSno',tyre_sno,
-- 								  'tyreCompany',t.tyre_company,
-- 								  'manufactureDate',t.manufacture_date,
-- 								  'tyreSize',t.tyre_size,
-- 								  'serialNumber',t.serial_number,
-- 								  'tyreTypeCd',t.tyre_type_cd,
-- 								  'tyreUsageCd',t.tyre_usage_cd,
-- 								  'tyreTypeName',(select cd.cd_value from portal.codes_dtl cd where cd.codes_dtl_sno = t.tyre_type_cd),
-- 								  'tyreUsageName',(select cd.cd_value from portal.codes_dtl cd where cd.codes_dtl_sno = t.tyre_usage_cd),
-- 								  'usageCount',t.usage_count,
-- 								  'mediaSno',(select media.get_media_detail(json_build_object('mediaSno',media_sno))->0),
-- 								  'createdOn',t.created_on,
-- 								  'description',t.description,
-- 								  'activeFlag',t.active_flag,
-- 								  'isAssigned',t.is_assigned
-- 								 )))from tyre.tyre t
-- 	   where case when (p_data->>'orgSno')::bigint is not null  then org_sno=(p_data->>'orgSno')::bigint
-- 	   else true end and 
-- 	   case when (p_data->>'activeFlag') is not null then active_flag = (p_data->>'activeFlag')::boolean else true end and
-- 	   case when (p_data->>'searchKey' is not null) then
-- 		((tyre_sno::text ilike ('%' || trim((p_data->>'searchKey')::text) || '%')) or (tyre_company::text ilike ('%' || trim((p_data->>'searchKey')::text) || '%')))
-- 		else true end	
-- );

-- end;
-- $BODY$;



-- --update_tyre
-- --------------

-- CREATE OR REPLACE FUNCTION tyre.update_tyre(
-- 	p_data json)
--     RETURNS json
--     LANGUAGE 'plpgsql'
--     COST 100
--     VOLATILE PARALLEL UNSAFE
-- AS $BODY$
-- declare 
-- begin
-- raise notice 'update_tyre %',p_data;

-- update tyre.tyre set tyre_company = (p_data->>'tyreCompany'),
-- tyre_size = (p_data->>'tyreSize'),serial_number = (p_data->>'serialNumber'),
-- tyre_type_cd = (p_data->>'tyreTypeCd')::smallint,tyre_usage_cd = (p_data->>'tyreUsageCd')::smallint,
-- usage_count = (p_data->>'usageCount')::smallint,media_sno = (p_data->>'mediaSno')::bigint,
-- created_on = (p_data->>'createdOn')::timestamp,active_flag = (p_data->>'activeFlag')::boolean
-- where tyre_sno = (p_data->>'tyreSno')::bigint;
-- return 
-- ( json_build_object('data',json_build_object('tyreSno',(p_data->>'tyreSno')::bigint)));
-- end;
-- $BODY$;


-- --delete_tyre
-- --------------

CREATE OR REPLACE FUNCTION tyre.delete_tyre(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;


-- --insert_vehicle_tyre
-- ---------------------

-- CREATE OR REPLACE FUNCTION tyre.insert_vehicle_tyre(
-- 	p_data json)
--     RETURNS json
--     LANGUAGE 'plpgsql'
--     COST 100
--     VOLATILE PARALLEL UNSAFE
-- AS $BODY$
-- declare 
-- vehicleTyreSno bigint;
-- begin
-- raise notice '%',p_data;

-- insert into tyre.vehicle_tyre(tyre_sno,vehicle_sno,position,created_on,active_flag) 
--    values ((p_data->>'tyreSno')::bigint,(p_data->>'vehicleSno')::bigint,
-- 		   (p_data->>'position')::smallint,portal.get_time_with_zone(json_build_object('timeZone',p_data->>'createdOn'))::timestamp,true
--           ) returning vehicle_tyre_sno  INTO vehicleTyreSno;
--   return (select json_build_object('data',json_build_object('vehicleTyreSno',vehicleTyreSno)));
-- end;
-- $BODY$;


-- --insert_tyre_change
-- --------------------

-- CREATE OR REPLACE FUNCTION tyre.insert_tyre_change(
-- 	p_data json)
--     RETURNS json
--     LANGUAGE 'plpgsql'
--     COST 100
--     VOLATILE PARALLEL UNSAFE
-- AS $BODY$
-- declare 
-- tyreChangeSno bigint;
-- begin
-- raise notice '%',p_data;

-- insert into tyre.tyre_change(vehicle_tyre_sno,in_odo_meter_reading,out_odo_meter_reading,reason_status_cd,in_status,out_status,in_time,out_time,active_flag) 
--    values ((p_data->>'vehicleTyreSno')::bigint,p_data->>'inOdometerReading',p_data->>'outOdometerReading',
-- 		   (p_data->>'reasonStatusCd')::smallint,(p_data->>'inStatus')::boolean,(p_data->>'outStatus')::boolean,portal.get_time_with_zone(json_build_object('timeZone',p_data->>'inTime'))::timestamp,(p_data->>'outTime')::timestamp,(p_data->>'activeFlag')::boolean
--           ) returning tyre_change_sno  INTO tyreChangeSno;
--   return (select json_build_object('data',json_build_object('tyreChangeSno',tyreChangeSno)));
-- end;
-- $BODY$;

-- --insert_tyre_manage
-- --------------------
-- CREATE OR REPLACE FUNCTION tyre.insert_tyre_manage(
-- 	p_data json)
--     RETURNS json
--     LANGUAGE 'plpgsql'
--     COST 100
--     VOLATILE PARALLEL UNSAFE
-- AS $BODY$
-- declare 
-- tyreSno bigint;
-- vehicleSno bigint;
-- vehicleTyreSno bigint;
-- isAlreadyExists bigint;
-- begin
-- raise notice '%',p_data->>'vehicleSno';
-- raise notice 'tyre%',p_data->>'tyreSno';

-- select count(*) into isAlreadyExists from tyre.vehicle_tyre v where v.vehicle_sno = (p_data->>'vehicleSno')::bigint and v.tyre_sno =(p_data->>'tyreSno')::bigint  and v.active_flag = true;
-- if isAlreadyExists=0 then

-- select (select tyre.insert_vehicle_tyre(p_data)->>'data')::json->>'vehicleTyreSno' into vehicleTyreSno;

-- raise notice 'vehicleTyreSno%',p_data->>'vehicleTyreSno';

-- -- perform tyre.insert_vehicle_tyre(p_data);

-- perform tyre.insert_tyre_change((select (p_data)::jsonb || ('{"vehicleTyreSno": ' || vehicleTyreSno ||' }')::jsonb )::json);

-- return (select json_build_object('data',json_build_object('vehicleTyreSno',vehicleTyreSno)));
-- else
-- return (select json_build_object('data',json_build_object('msg','This Tyre is Already Exists')));
-- end if;
-- end;
-- $BODY$;


-- --get_tyre_manage
-- -----------------

-- CREATE OR REPLACE FUNCTION tyre.get_tyre_manage(p_data json)
--     RETURNS json
--     LANGUAGE 'plpgsql'
-- AS $BODY$
-- declare
-- begin

-- return (select json_build_object('data',json_agg(json_build_object(
-- 	'vehicleTyreSno',d.vehicle_tyre_sno,
-- 	'vehicle', json_build_object('vehicleSno',d.vehicle_sno,'vehicleRegNumber',d.vehicle_reg_sno),
-- 	'tyre', json_build_object('tyreSno',d.tyre_sno,'serialNumber',d._serial_no),
-- 	'position',d.position,
-- 	'createdOn',d.created_on,
-- 	'activeFlag',d.active_flag,
-- 	'tyreChangeSno',d.tyre_change_sno,
-- 	'inOdometerReading',d.in_odo_meter_reading,
-- 	'outOdometerReading',d.out_odo_meter_reading,
-- 	'reasonStatusCd',d.reason_status_cd,
-- 	'inStatus',d.in_status,
-- 	'outStatus',d.out_status,
-- 	'inTime',d.in_time,
-- 	'outTime',d.out_time
-- -- 	'activeFlag',d.active_flag
-- )))from  (select * from (select v.vehicle_tyre_sno,(select serial_number as _serial_no from tyre.tyre tc where tc.tyre_sno = v.tyre_sno), 
-- 		  (select vehicle_reg_number as vehicle_reg_sno from operator.vehicle vh where vh.vehicle_sno = v.vehicle_sno) ,
-- 		  v.tyre_sno,v.vehicle_sno,v.position,v.created_on,v.active_flag,
-- 			  vc.tyre_change_sno,vc.in_odo_meter_reading,vc.out_odo_meter_reading,vc.reason_status_cd,
-- 			   vc.in_status,vc.out_status,vc.in_time,vc.out_time from tyre.vehicle_tyre v 
-- 			   inner join tyre.tyre_change vc on vc.vehicle_tyre_sno = v.vehicle_tyre_sno
-- -- 		  	   inner join operator.org_vehicle ov on ov.vehicle_sno = v.vehicle_sno
-- 		  	   inner join tyre.tyre tc on tc.tyre_sno = v.tyre_sno
-- 		       where case when (p_data->>'orgSno')::bigint is not null  then org_sno=(p_data->>'orgSno')::bigint else true end and 
-- 	  		   case when (p_data->>'activeFlag') is not null then v.active_flag = (p_data->>'activeFlag')::boolean else true end )eu 
-- 		  where case when (p_data->>'searchKey' is not null) then
-- 		((eu._serial_no ilike ('%' || trim((p_data->>'searchKey')::text) || '%')) or (eu.vehicle_reg_sno ilike ('%' || trim((p_data->>'searchKey')::text) || '%')))
-- 		else true end)d);

-- end;
-- $BODY$;


-- --get_tyre_details_by_vehicle
-- ------------------------------
-- CREATE OR REPLACE FUNCTION tyre.get_tyre_details_by_vehicle(
-- 	p_data json)
--     RETURNS json
--     LANGUAGE 'plpgsql'
--     COST 100
--     VOLATILE PARALLEL UNSAFE
-- AS $BODY$
-- declare
-- begin

-- return (select json_build_object('data',json_agg(json_build_object(
-- 	'vehicleSno',d.vehicle_sno,
-- 	'tyreSno',d.tyre_sno,
-- 	'tyreCompany',d.tyre_company,
-- 	'manufactureDate',d.manufacture_date,
-- 	'position',d.position,
-- 	'inOdometerReading',d.in_odo_meter_reading,
-- 	'outOdometerReading',d.out_odo_meter_reading
-- )))from (select t.tyre_company,t.manufacture_date,t.tyre_sno,tc.in_odo_meter_reading,tc.out_odo_meter_reading,vt.position,
-- 		 vt.vehicle_sno
-- 		 from tyre.vehicle_tyre vt
-- 		 inner join tyre.tyre_change tc on tc.vehicle_tyre_sno = vt.vehicle_tyre_sno
--          inner join tyre.tyre t on t.tyre_sno = vt.tyre_sno
-- 		 where vt.vehicle_sno=(p_data->>'vehicleSno')::bigint)d);

-- end;
-- $BODY$;


-- --update_vehicle_tyre
-- ---------------------

-- CREATE OR REPLACE FUNCTION tyre.update_vehicle_tyre(
-- 	p_data json)
--     RETURNS json
--     LANGUAGE 'plpgsql'
--     COST 100
--     VOLATILE PARALLEL UNSAFE
-- AS $BODY$
-- declare 

-- begin
-- raise notice 'update_tyre %',p_data;
-- update tyre.vehicle_tyre set tyre_sno = ((p_data->>'tyre')::json->>'tyreSno')::bigint,
-- vehicle_sno = ((p_data->>'vehicle')::json->>'vehicleSno')::bigint,position = (p_data->>'position')::smallint
-- where vehicle_tyre_sno = (p_data->>'vehicleTyreSno')::bigint;
-- return 
-- ( json_build_object('data',json_build_object('vehicleTyreSno',(p_data->>'vehicleTyreSno')::bigint)));
-- end;
-- $BODY$;


-- --update_tyre_change
-- --------------------


-- CREATE OR REPLACE FUNCTION tyre.update_tyre_change(
-- 	p_data json)
--     RETURNS json
--     LANGUAGE 'plpgsql'
--     COST 100
--     VOLATILE PARALLEL UNSAFE
-- AS $BODY$
-- declare 
-- begin

-- raise notice 'update_tyre %',p_data;

-- update tyre.tyre_change set vehicle_tyre_sno = (p_data->>'vehicleTyreSno')::bigint,
-- in_odo_meter_reading = (p_data->>'inOdometerReading'),out_odo_meter_reading = (p_data->>'outOdometerReading'),
-- reason_status_cd = (p_data->>'reasonStatusCd')::smallint,active_flag = (p_data->>'activeFlag')::boolean
-- where tyre_change_sno = (p_data->>'tyreChangeSno')::bigint;
-- return 
-- ( json_build_object('data',json_build_object('tyreChangeSno',(p_data->>'tyreChangeSno')::bigint)));
-- end;
-- $BODY$;


-- --update_tyre_manage
-- --------------------


-- CREATE OR REPLACE FUNCTION tyre.update_tyre_manage(
-- 	p_data json)
--     RETURNS json
--     LANGUAGE 'plpgsql'
--     COST 100
--     VOLATILE PARALLEL UNSAFE
-- AS $BODY$
-- declare 
-- tyreSno bigint;
-- vehicleSno bigint;
-- begin
-- raise notice '%',p_data;
-- raise notice '%',p_data->>'vehicleSno';
-- raise notice 'tyre%',p_data->>'tyreSno';

-- perform tyre.update_vehicle_tyre(p_data);

-- raise notice 'vehicleTyreSno%',p_data->>'vehicleTyreSno';

-- perform tyre.update_tyre_change(p_data);

-- return (select json_build_object('isUpdated',true));
-- end;
-- $BODY$;

-- --delete_tyre_manage
-- --------------------

-- CREATE OR REPLACE FUNCTION tyre.delete_tyre_manage(p_data json)
-- RETURNS json
-- LANGUAGE 'plpgsql'
-- COST 100
-- VOLATILE PARALLEL UNSAFE
-- AS $BODY$
-- declare 
-- begin
	
-- 	delete from tyre.tyre_change where tyre_change_sno = (p_data->>'tyreChangeSno')::bigint; 
-- 	delete from tyre.vehicle_tyre where vehicle_tyre_sno = (p_data->>'vehicleTyreSno')::bigint;  
	
	
-- return (select json_build_object('isDeleted',true));

-- end;
-- $BODY$;




--get_search_operator_vehicle
------------------------------

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


--get_tyre_position
---------------------
CREATE OR REPLACE FUNCTION tyre.get_tyre_position(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--get_search_available_tyre
---------------------------
CREATE OR REPLACE FUNCTION operator.get_search_available_tyre(p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
AS $BODY$
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
$BODY$;
--getClassName
--------------

CREATE OR REPLACE FUNCTION operator.getClassName(position_no smallint,type text,tyre_count_cd smallint)
    RETURNS text
    LANGUAGE 'plpgsql'
AS $BODY$
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
$BODY$;

--insert_rotation_tyre_activity
-------------------------------

CREATE OR REPLACE FUNCTION tyre.insert_rotation_tyre_activity(p_data json)
    RETURNS json
AS $BODY$
declare 
v_doc json;
begin
for v_doc in SELECT * FROM json_array_elements((p_data->>'tyreList')::json) loop
	perform tyre.insert_tyre_activity(v_doc);
end loop;

return (select json_build_object('data',json_build_object('isUpdated',true)));
end;
$BODY$
LANGUAGE plpgsql;


--get_tyre_life_cycle
---------------------
CREATE OR REPLACE FUNCTION tyre.get_tyre_life_cycle(p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
AS $BODY$
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
$BODY$;

--get_tyre_count
-------------------
CREATE OR REPLACE FUNCTION tyre.get_tyre_count(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;

--get_tyre_over_all_running_km
-------------------------------
CREATE OR REPLACE FUNCTION tyre.get_tyre_over_all_running_km(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;