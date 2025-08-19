--create_state
--------------

CREATE OR REPLACE FUNCTION master_data.create_state(p_data json)
RETURNS json
AS $BODY$
declare 
stateSno bigint;
begin
insert into master_data.state(state_name) values ((p_data->>'stateName')) returning state_sno into stateSno;

return (select json_build_object('stateSno',stateSno));
end;
$BODY$
LANGUAGE plpgsql;

/*
select * from master_data.state
select * from master_data.create_state('{"stateName":"tamilnadu"}')
*/



--get_state
-----------


CREATE OR REPLACE FUNCTION master_data.get_state(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare 
begin

return (select  json_build_object('data',json_agg(json_build_object(
	'stateSno',ms.state_sno,
	'stateName',ms.state_name,
	'activeFlag',ms.active_flag)))from (select * from master_data.state s
 order by s.state_sno asc 
 offset (p_data->>'skip')::bigint limit (p_data->>'limit')::bigint)ms);	
end;
$BODY$;

/*
select * from master_data.get_state('{}')
*/

--update_state
--------------

CREATE OR REPLACE FUNCTION master_data.update_state(
	p_data json)
    RETURNS json
AS $BODY$
declare 
stateSno bigint;
begin
-- raise notice '%',p_data;
update master_data.state set state_name = (p_data->>'stateName')
								where state_sno = (p_data->>'stateSno')::bigint 
								returning state_sno into stateSno;

  return (select json_build_object('stateSno',stateSno));

end;
$BODY$
LANGUAGE plpgsql;

/*
select * from master_data.update_state('{"stateSno":1,"stateName":"vhgfu"}')
*/

--delete_state
--------------

CREATE OR REPLACE FUNCTION master_data.delete_state(p_data json)
RETURNS json
AS $BODY$
declare 
stateSno bigint;
begin
   
   delete from master_data.state where state_sno = (p_data->>'stateSno')::bigint returning state_sno into stateSno;

return (select json_build_object('stateSno',stateSno));

end;
$BODY$
LANGUAGE plpgsql;

/*
select * from master_data.delete_state('{"stateSno":3}')
*/

--create_district
-----------------


CREATE OR REPLACE FUNCTION master_data.create_district(p_data json)
RETURNS json
AS $BODY$
declare 
districtSno bigint;
begin

insert into master_data.district(district_name,state_sno) values ((p_data->>'districtName'),(p_data->>'stateSno')::bigint) 
returning district_sno into districtSno;

return (select json_build_object('districtSno',districtSno));
end;
$BODY$
LANGUAGE plpgsql;

/*
select * from master_data.district
select * from master_data.create_district('{"districtName":"madurai","stateSno":1}')
*/

-- --get_district
-- --------------
-- CREATE OR REPLACE FUNCTION master_data.get_district(
-- 	p_data json)
--     RETURNS json
-- AS $BODY$
-- declare 
-- begin

-- return (select json_build_object('data',(select json_agg(json_build_object(
-- 	'districtSno',district_sno,
-- 	'districtName',district_name,
-- 	'activeFlag',active_flag
-- ))) )from master_data.district where 
-- 	   case when (p_data->>'stateSno') is not null then state_sno = (p_data->>'stateSno')::bigint else true end);
   
-- end;
-- $BODY$
-- LANGUAGE plpgsql;

/*
select * from master_data.get_district('{"stateSno":1}')
*/

--get_district
------------------
CREATE OR REPLACE FUNCTION master_data.get_district(
	p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;





--update_district
-----------------

CREATE OR REPLACE FUNCTION master_data.update_district(
	p_data json)
    RETURNS json
AS $BODY$
declare 
districtSno bigint;
begin
-- raise notice '%',p_data;
update master_data.district set district_name = (p_data->>'districtName'),state_sno = (p_data->>'stateSno')::bigint
								where district_sno = (p_data->>'districtSno')::bigint 
								returning district_sno into districtSno;

  return (select json_build_object('districtSno',districtSno));

end;
$BODY$
LANGUAGE plpgsql;

/*
select * from master_data.update_district('{"districtSno":3,"stateSno":2,"districtName":"vhgfu"}')
*/


--delete_district
-----------------


CREATE OR REPLACE FUNCTION master_data.delete_district(p_data json)
RETURNS json
AS $BODY$
declare 
districtSno bigint;
begin
   
   delete from master_data.district where district_sno = (p_data->>'districtSno')::bigint returning district_sno into districtSno;

return (select json_build_object('districtSno',districtSno));

end;
$BODY$
LANGUAGE plpgsql;

/*
select * from master_data.delete_district('{"districtSno":3}')
*/

--create_city
-------------



CREATE OR REPLACE FUNCTION master_data.create_city(p_data json)
RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;

/*
select * from master_data.create_city('{"cityName":"dindigal","districtSno":1}')
*/

-- --get_city
-- ----------

-- CREATE OR REPLACE FUNCTION master_data.get_city(p_data json)
--     RETURNS json
-- AS $BODY$
-- declare 
-- begin

-- return ( select json_build_object('data', json_agg(json_build_object(
-- 	'citySno',d.city_sno,
-- 	'cityName',d.city_name,
-- 	'activeFlag',d.active_flag
-- ))) from (select c.city_sno,c.city_name,c.active_flag from master_data.city c where case when (p_data->>'districtSno')::bigint is not null then  district_sno = (p_data->>'districtSno')::bigint
-- 	   else true end order by city_name asc )d)   ;
   
-- end;
-- $BODY$
-- LANGUAGE plpgsql;


/*
select * from master_data.get_city('{"districtSno":1}')
*/

--get_city
------------
CREATE OR REPLACE FUNCTION master_data.get_city(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;



--update_city
-------------

CREATE OR REPLACE FUNCTION master_data.update_city(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare 
citySno bigint;
begin
-- raise notice '%',p_data;
update master_data.city set active_flag = (p_data->>'activeFlag')::boolean, city_name = (p_data->>'cityName'),district_sno = (p_data->>'districtSno')::bigint
								where city_sno = (p_data->>'citySno')::bigint 
								returning city_sno into citySno;

  return (select json_build_object('citySno',citySno));

end;
$BODY$;


/*
select * from master_data.update_city('{"citySno":2,"districtSno":1,"cityName":"vhgfu"}')
*/

--delete_city
-------------

CREATE OR REPLACE FUNCTION master_data.delete_city(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare 
citySno bigint;
begin
   
--    delete from master_data.city where  city_sno = (p_data->>'citySno')::bigint returning city_sno into citySno;
	
	update master_data.city set active_flag = false where city_sno = (p_data->>'citySno')::bigint returning city_sno into citySno;

return (select json_build_object('citySno',citySno));

end;
$BODY$;

/*
select * from master_data.delete_city('{"citySno":2}')
*/

--create_route
--------------

CREATE OR REPLACE FUNCTION master_data.create_route(p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
AS $BODY$
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
$BODY$;
/*
select * from master_data.create_route('{"sourceCitySno":1,"destinationCitySno":5}')
*/


--get_route
-----------

CREATE OR REPLACE FUNCTION master_data.get_route(
	p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE 'plpgsql';




/*
select * from master_data.get_route('{}')
*/

--update_route
--------------

CREATE OR REPLACE FUNCTION master_data.update_route(
p_data json)
RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


/*
select * from master_data.update_route('{"routeSno":1,"sourceCitySno":1,"destinationCitySno":6}')
*/

--delete_route
--------------

CREATE OR REPLACE FUNCTION master_data.delete_route(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare 
routeSno bigint;
begin
   
   delete from master_data.route where route_sno = (p_data->>'routeSno')::bigint returning route_sno into routeSno;

return (select json_build_object('routeSno',routeSno));

end;
$BODY$;

/*
select * from master_data.delete_route('{"routeSno":1}')
*/


--insert_route
---------------

CREATE OR REPLACE FUNCTION master_data.insert_route(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--get_city_bus
--------------

CREATE OR REPLACE FUNCTION master_data.get_city_bus(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE 'plpgsql';



--get_state_count
------------------


CREATE OR REPLACE FUNCTION master_data.get_state_count(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
_count bigint;
begin
select count(*) into _count from master_data.state;
return (select  json_build_object('data',json_agg(json_build_object('count',_count))));

end;
$BODY$;


--get_city_count
-----------------


CREATE OR REPLACE FUNCTION master_data.get_city_count(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
_count bigint;
begin
select count(*) into _count from master_data.city;
return (select  json_build_object('data',json_agg(json_build_object('count',_count))));

end;
$BODY$;


--get_district_count
---------------------


CREATE OR REPLACE FUNCTION master_data.get_district_count(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
_count bigint;
begin
select count(*) into _count from master_data.district;
return (select  json_build_object('data',json_agg(json_build_object('count',_count))));

end;
$BODY$;

--get_tyre_type
----------------
CREATE OR REPLACE FUNCTION master_data.get_tyre_type(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--get_city_bus_count
--------------------

CREATE OR REPLACE FUNCTION master_data.get_city_bus_count(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE 'plpgsql';


--get_via_route
----------------

CREATE OR REPLACE FUNCTION master_data.get_via_route(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE 'plpgsql';