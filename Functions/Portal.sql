
--get_enum_sno
------------------

create or replace function portal.get_enum_sno(IN p_data json )
returns int
as $BODY$
declare 
  cd_sno smallint;
begin
   select d.codes_dtl_sno into cd_sno from portal.codes_dtl d 
   inner join portal.codes_hdr h on d.codes_hdr_sno = h.codes_hdr_sno 
   where UPPER(d.cd_value)=UPPER(p_data->>'cd_value') and UPPER(h.code_type) = UPPER(p_data->>'cd_type') ;
   
   return cd_sno;
end;
$BODY$
language plpgsql;

--createMenuByRole
-------------------

CREATE OR REPLACE FUNCTION portal.createMenuByRole(p_app_menu int,
	role_cd int[])
    RETURNS void
    LANGUAGE 'plpgsql'

AS $BODY$
declare 
 id int;
 begin
       delete from portal.app_menu_role where app_menu_sno = p_app_menu; 
		    foreach  id in  array role_cd loop
		       INSERT INTO portal.app_menu_role(app_menu_sno,role_cd) 
	           VALUES (p_app_menu,(id)::integer);
		    end loop;
 end;
$BODY$;


--create_menu
----------------
CREATE OR REPLACE FUNCTION portal.create_menu(
	p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--get_menu
--------------
																											
	CREATE OR REPLACE FUNCTION portal.get_menu(p_data json)
	RETURNS json
	AS $BODY$
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
	$BODY$
	LANGUAGE plpgsql;


--select * from portal.get_menu('{"appMenuSno":1}')	


--create_app_menu_role
-------------------------

CREATE OR REPLACE FUNCTION portal.create_app_menu_role(IN p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--get_menu_role
----------------
CREATE OR REPLACE FUNCTION portal.get_menu_role(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
AS $BODY$
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
$BODY$;

/*
select * from portal.get_enum_sno('{"cd_value":"Non Reg User","cd_type":"role_cd"}')
*/



--get_time_with_zone
--------------------
CREATE OR REPLACE FUNCTION portal.get_time_with_zone(p_data json)
  RETURNS text
 LANGUAGE plpgsql AS
$$
BEGIN

return (select (select now() AT TIME ZONE (p_data->>'timeZone')::text)::text);

END;
$$;

/*
select * from portal.get_time_with_zone(json_build_object('timeZone','Asia/Calcutta'));
*/


--verify_user
---------------

CREATE OR REPLACE FUNCTION portal.verify_user(
	IN p_data json)
    RETURNS JSON
    LANGUAGE 'plpgsql'
AS $BODY$

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
$BODY$;
/*
 select * from portal.verify_user('{"mobileNumber":"8072852116","deviceId":"12345","timeZone":"Asia/Calcutta"}')
*/ 


--get_user_push_tokens
----------------------
CREATE OR REPLACE FUNCTION portal.get_user_push_tokens(
	IN p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
AS $BODY$

declare 

_push_tokens json;

begin

select json_agg(push_token_id) into _push_tokens from portal.signin_config where active_flag = true 
and app_user_sno = (p_data->>'app_user_sno')::int;

return (select(json_build_object('pushTokens',_push_tokens)));

end;
$BODY$;

/*
select * from portal.get_user_push_tokens('{"app_user_sno":"1"}')
*/


--create_app_user
------------------

CREATE OR REPLACE FUNCTION portal.create_app_user(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'

AS $BODY$
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
$BODY$;



--create_app_user_role
----------------------
CREATE OR REPLACE FUNCTION portal.create_app_user_role(
	p_data json)
    RETURNS json
AS $BODY$
declare 
appUserRoleSno bigint;
begin

insert into portal.app_user_role(app_user_sno,
				role_cd) values 
((p_data->>'appUserSno')::bigint,
 (p_data->>'roleCd')::smallint) returning app_user_role_sno  INTO appUserRoleSno;
  return (select json_build_object('appUserRoleSno',appUserRoleSno));

end;
$BODY$
LANGUAGE plpgsql;
 

--get_enum_names
----------------

CREATE OR REPLACE FUNCTION portal.get_enum_names(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare 
begin

return (select(json_build_object('data', (select json_agg(json_build_object('codesDtlSno',d.codes_dtl_sno,'cdValue',d.cd_value,'filter1',d.filter_1,'filter2',d.filter_2,'activeFlag',d.active_flag))
										  from (select * from portal.codes_dtl cdl where  
cdl.codes_hdr_sno = (select hdr.codes_hdr_sno from portal.codes_hdr hdr where hdr.code_type = p_data->>'codeType') and 
	case when p_data->>'filter1' is not null then ('{' || cdl.filter_1 ||'}')::text[] &&   (p_data->>'filter1')::text[]  else true end  order by cdl.seqno asc)d
))));
end;
$BODY$;




/*select * from  portal.get_enum_names('{"codeType":"role_cd"}'); */

--login_user
------------
/*CREATE OR REPLACE FUNCTION portal.login_user(
	IN p_data json)
    RETURNS  json
    LANGUAGE 'plpgsql'
AS $BODY$

declare 

_app_user_sno bigint;
_sigin_config_sno int;
isMailcount int := 0;

begin

 
select au.app_user_sno into _app_user_sno  from portal.app_user au
where lower(au.mobile_number) = lower(p_data->>'mobileNumber') ;

 
 if (_app_user_sno is not null) then
 
 		if (select count(*) from portal.signin_config where device_id = p_data->>'deviceId' and app_user_sno = _app_user_sno ) = 0 then
 
	    	INSERT INTO portal.signin_config(app_user_sno, push_token_id,device_type_cd, device_id)
	    	VALUES ( _app_user_sno, p_data->>'pushToken',portal.get_enum_sno((json_build_object('cd_value',p_data->>'deviceTypeName','cd_type','device_type_cd'))),		
			p_data->>'deviceId') returning signin_config_sno into _sigin_config_sno;
 		else
 			update portal.signin_config set push_token_id = p_data->>'pushToken', active_flag = true where app_user_sno = _app_user_sno and device_id = p_data->>'deviceId' returning signin_config_sno into _sigin_config_sno;
 
 		end if;
  
  return (select json_build_object('isLogin',true,'appUserSno',_app_user_sno,
										  'siginConfigSno',_sigin_config_sno
										 ));
 
 else
	return (select json_build_object('isLogin',false,
										  'msg','This mobile number is not registered us'
										 ));
			
end if;	
end;
$BODY$;*/



 /*select * from portal.login_user('{
								"mobileNumber":"8072852115",
						  "deviceId":"sdfsdfs",
						  "pushToken":"sada",
						   "deviceTypeName":"Web"
						  }')  */

----otp_verify
----------------
CREATE OR REPLACE FUNCTION portal.otp_verify(
	IN p_data json)
    RETURNS  json
    LANGUAGE 'plpgsql'
AS $BODY$

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
$BODY$;

/*
select portal.otp_verify('{"appUserSno" : 4, "simOtp" : "514443", "pushOtp" : "265267350", "apiOtp" : "801597591","deviceId":"12345","pushToken":"12345"}')
*/


--resend_otp
------------

CREATE OR REPLACE FUNCTION portal.resend_otp(IN p_data json)
RETURNS json
LANGUAGE 'plpgsql'
AS $BODY$
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
$BODY$;


--select * from portal.resend_otp('{"deviceId":"12345","appUserSno":2}');


--generate_otp
---------------

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


-- select  * from portal.generate_otp('{
-- 							"appUserSno":1,
-- 							"deviceId":"3"
-- 							}');


-- resetPassword
------------------

CREATE OR REPLACE FUNCTION portal.reset_password(p_reset_password json)
returns json
as $$
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
$$
language plpgsql;

/* select * from  portal.reset_password('{"password":"bharathi123","appUserSno":1 }'); */






--getVerifyEmail
-------------------

create or replace function portal.getVerifyEmail(IN p_email text) 
	returns json
as $BODY$
declare _app_user_sno int;
begin
 	  select app_user_sno into _app_user_sno from portal.app_user where email =  p_email;
	  
	  return (select json_agg(json_build_object('appUserSno',_app_user_sno
										 )));
end;
 $BODY$
language plpgsql;

/* select * from portal.getVerifyEmail('bharathirajas1995@gmail.com'); */


--- getVerifyEmailAndPassword
-----------------------------

create or replace function portal.getVerifyEmailAndPassword(IN p_email text, p_password text) 
	returns json
	
as $BODY$
declare _app_user_sno int;
begin
   select app_user_sno into _app_user_sno from portal.app_user  
  where email = p_email and password = p_password;
  
  return  (select json_agg(json_build_object('appUserSno',_app_user_sno
										 )));
end;
 $BODY$
language plpgsql;

/* select * from portal.getVerifyEmailAndPassword('bharathirajas1995@gmail.com','bharathi123'); */


--get_address
-------------

CREATE OR REPLACE FUNCTION portal.get_address(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;

/*

select * from portal.address
select * from portal.get_address('{"addressSno":4}');
*/


-- get_verify_email
------------------------
CREATE OR REPLACE FUNCTION portal.get_verify_email(
	p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE 'plpgsql';

--verify_user_otp 
-----------------

CREATE OR REPLACE FUNCTION portal.verify_user_otp(
	IN p_data json)
    RETURNS  json
    LANGUAGE 'plpgsql'
AS $BODY$

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
$BODY$;

-- select * from portal.verify_user_otp('{"appUserSno":3,"pushOtp":"718072142","apiOtp":"107572628","deviceId":"122.165.102.60","emailOtp":"34926","pushToken":"c-ZYbhN_L0yKnIwjYi9kXl:APA91bERFNbGMCapkQcePyZlCWk-PeY8SlqhGh6HYjX64fLyFhFyaaDflEKdNHWIuoxu6OGJU6BLgu53J4oiX7GSMVAyma5z3BEAEWGpXCBV8K-pxOhxhShGyOoa9QpeyOm9dyTVKlK3","timeZone":"Asia/Kolkata","deviceTypeName":"Web"}')


--update_signin_config
----------------------


CREATE OR REPLACE FUNCTION portal.logout(
	p_data json)
    RETURNS json
AS $BODY$
declare 
signinConfigSno bigint;
begin
-- raise notice '%',p_data;

update portal.signin_config set active_flag = false
								where signin_config_sno = (p_data->>'signinConfigSno')::bigint 
								returning signin_config_sno into signinConfigSno;

  return (select json_build_object('signinConfigSno',signinConfigSno));

end;
$BODY$
LANGUAGE plpgsql;


---insert_user_profile
----------------------

CREATE OR REPLACE FUNCTION portal.insert_user_profile(
	in_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
   
AS $BODY$
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
$BODY$;


--get_time_with_zone
----------------------

CREATE OR REPLACE FUNCTION portal.get_time_with_zone(
	p_data json)
    RETURNS text
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN

return (select (select now() AT TIME ZONE (p_data->>'timeZone')::text)::text);

END;
$BODY$;

CREATE OR REPLACE FUNCTION portal.get_user_contact(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare 
begin
return ( select json_build_object('email',email,'phone',phone,'address',address) from portal.user_contact where app_user_sno = (p_data->>'appUserSno')::bigint);
end;
$BODY$;


-- portal.signin
-------------------
--drop function if exists portal.signin;
CREATE OR REPLACE FUNCTION portal.signin(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
AS $BODY$
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
$BODY$;

--portal.verify_otp;
-----------------------
drop function if exists portal.verify_otp;
CREATE OR REPLACE FUNCTION portal.verify_otp(
	p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE 'plpgsql';




--select * from portal.verify_otp('{"appUserSno":3,"pushOtp":"108040479","apiOtp":"918922192","deviceId":"12345","simOtp":"860998","pushToken":"12345","timeZone":"Asia/Calcutta","deviceTypeName":"Web"}')



--get_enum_name
---------------

CREATE OR REPLACE FUNCTION portal.get_enum_name(
	p_cd_sno integer,
	p_cd_type text)
    RETURNS text
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare 
  cd_value text;
begin

   select d.cd_value into cd_value from portal.codes_dtl d 
   inner join portal.codes_hdr h on d.codes_hdr_sno = h.codes_hdr_sno 
   where d.codes_dtl_sno = p_cd_sno and UPPER(h.code_type) = UPPER(p_cd_type) ;
   
   return cd_value;
end;
$BODY$;


--create_contact
----------------
CREATE FUNCTION portal.create_contact(p_data json) 
RETURNS json
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
$$
LANGUAGE plpgsql;

--create_social_link
--------------------

CREATE OR REPLACE FUNCTION portal.create_social_link(
	p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;

--get_contact
-------------

CREATE OR REPLACE FUNCTION portal.get_contact(p_data json)
    RETURNS json
AS $BODY$
declare 
begin
raise notice '%',p_data;
return (select json_agg(json_build_object('contactSno',contact_sno,
										   'mobileNumber',mobile_number,
										   'email',email,
										   'activeFlag',active_flag
										  ))from portal.contact);
end;
$BODY$
LANGUAGE plpgsql;
		
		
--get_social_link
-----------------

CREATE OR REPLACE FUNCTION portal.get_social_link(p_data json)
    RETURNS json
AS $BODY$
declare 
begin
raise notice '%',p_data;
return ( select json_agg(json_build_object('socialLinkSno',social_link_sno,
	                                       'socialUrl',social_url,
										   'socialLinkTypeCd',social_link_type_cd,
										   'activeFlag',active_flag
										  ))from portal.social_link);
end;
$BODY$
LANGUAGE plpgsql;

--update_app_user_role
-----------------------

CREATE OR REPLACE FUNCTION portal.update_app_user_role(
	p_data json)
    RETURNS json
AS $BODY$
declare 
appUserRoleSno bigint;
begin		
raise notice '%',p_data;

update  portal.app_user_role set role_cd = (p_data->>'roleCd')::smallint where app_user_sno = (p_data->>'appUserSno')::bigint  returning app_user_role_sno  INTO appUserRoleSno;

return (select json_build_object('appUserRoleSno',appUserRoleSno));

end;
$BODY$
LANGUAGE plpgsql;


--update_app_user
-------------------
CREATE OR REPLACE FUNCTION portal.update_app_user(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--get_verify_mobile_number
---------------------------
CREATE OR REPLACE FUNCTION portal.get_verify_mobile_number(p_data json)
RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;

--login
--------

CREATE OR REPLACE FUNCTION portal.login(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;

--get_code_type
----------------
 CREATE OR REPLACE FUNCTION portal.get_code_type(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
	declare 
	begin
 return (select(json_build_object('data', (select json_agg(json_build_object(
'codesHdrSno',ch.codes_hdr_sno,
'codeType',ch.code_type																				 
))  from portal.codes_hdr ch ))));
 
	end;
$BODY$;

--get_codes_dtl
----------------

CREATE OR REPLACE FUNCTION portal.get_codes_dtl(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;


--create_codes_dtl
-------------------

CREATE OR REPLACE FUNCTION portal.create_codes_dtl(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;



--update_codes_dtl
-------------------

CREATE OR REPLACE FUNCTION portal.update_codes_dtl(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;

---get_all_app_user
-------------------


CREATE OR REPLACE FUNCTION portal.get_all_app_user(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare 
begin	
return (select(json_build_object('data', (select json_agg(json_build_object('appUserSno',app_user_sno,
										  'mobileNo',mobile_no,
										  'Password',password,
										  'conformPassword',confirm_password,
										  'userStatusCd',user_status_cd
										  ))from portal.app_user))));
end;
$BODY$;



--get_app_user
---------------


CREATE OR REPLACE FUNCTION portal.get_app_user(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;



--tnbus_verify_mobilenumber_change_otp

CREATE OR REPLACE FUNCTION portal.tnbus_verify_mobilenumber_change_otp(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;

--get_mobile_verification

CREATE OR REPLACE FUNCTION portal.get_mobile_verification(p_data json)
RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;




--change_mobile_number
----------------------


CREATE OR REPLACE FUNCTION portal.change_mobile_number(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;



--check_mobile_number
---------------------

CREATE OR REPLACE FUNCTION portal.check_mobile_number(p_data json)
RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;

--get_assign_un_assigin_user
----------------------------

CREATE OR REPLACE FUNCTION operator.get_assign_un_assigin_user(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--insert_app_menu_user
-----------------------
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

--delete_menu_user_and_role
----------------------------
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

--update_app_menu_user
-----------------------

CREATE OR REPLACE FUNCTION portal.update_app_menu_user(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare 
appMenuUserSno bigint;
begin		
raise notice '%',p_data;

update  portal.app_menu_user set is_admin = (p_data->>'isAdmin')::boolean 
where app_menu_sno=(p_data->>'appMenuSno')::bigint and app_user_sno=(p_data->>'appUserSno')::bigint

returning app_menu_user_sno  INTO appMenuUserSno;

return (select json_build_object('appMenuUserSno',appMenuUserSno));

end;
$BODY$;


--check_role_mobile_number
--------------------------

CREATE OR REPLACE FUNCTION portal.check_role_mobile_number(p_data json)
RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;

--insert_app_user_contact
-------------------------

CREATE OR REPLACE FUNCTION portal.insert_app_user_contact(
	p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--get_app_user_contact
----------------------
CREATE OR REPLACE FUNCTION portal.get_app_user_contact(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--update_app_user_contact
-------------------------

CREATE OR REPLACE FUNCTION portal.update_app_user_contact(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;



