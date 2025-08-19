--Alter Query
-------------


update portal.app_menu set title = 'Drivers', icon = 'user-circle-o', has_sub_menu = 'false', parent_menu_sno = 0,
                           router_link = '/driverlist' where app_menu_sno = 25;

update portal.app_menu set title = 'Vehicles', icon = 'bus', has_sub_menu = 'false', parent_menu_sno = 0,
                           router_link = '/vehiclelist' where app_menu_sno = 24;

update portal.app_menu set title = 'Notification', icon = 'bell', has_sub_menu = 'false', parent_menu_sno = 0,
                           router_link = '/notification' where app_menu_sno = 26;

delete from portal.app_menu_role where app_menu_role_sno = 31

select * from portal.create_app_menu_role('{"appMenuSno":26,"roleCd":2}');	





--get_verify_mobile_number
--------------------------


CREATE OR REPLACE FUNCTION portal.get_verify_mobile_number(p_data json)
RETURNS json
AS $BODY$
declare 
-- existUser smallint;
-- _sim_otp text:= (SELECT LEFT(CAST(random()*1000000000+999999 AS INT)::text,6)::int as INT);
_app_user_sno bigint;
begin
select au.app_user_sno into _app_user_sno from portal.app_user au 
inner join portal.app_user_role ar on ar.app_user_sno=au.app_user_sno
where mobile_no=p_data->>'mobileNumber';
raise notice'%',_app_user_sno;
if _app_user_sno is not null then

return ( select json_build_object('data',(select json_agg(json_build_object(
		'appUserSno',app_user_sno,
		'isMobileNumber',true,
			'password',password,
	'otp',case when (p_data->>'pageName' is not null) then (select * from portal.generate_otp(json_build_object('appUserSno',_app_user_sno,'deviceId',(p_data->>'deviceId'),'timeZone',(p_data->>'timeZone')))) else null end
))from portal.app_user where mobile_no=(p_data->>'mobileNumber'))
));
else
return (select json_build_object('data',(
	select json_agg(json_build_object('isMobileNumber',false,'msg','New User')))
));
end if;
end;
$BODY$
LANGUAGE plpgsql;





--generate_otp
--------------



CREATE OR REPLACE FUNCTION portal.generate_otp(
	IN p_data json)
    RETURNS  json
    LANGUAGE 'plpgsql'
AS $BODY$

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
		  inner join driver.driver d on cast(d.current_district as int) = dd.district_sno  
		 )md);
	   

end;
$BODY$;


--insert_notification
----------------------

CREATE OR REPLACE FUNCTION notification.insert_notification(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;






