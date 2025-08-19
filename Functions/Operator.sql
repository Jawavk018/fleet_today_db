
--insert_org
------------


CREATE OR REPLACE FUNCTION operator.insert_org(
	p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;

--insert_org_detail
-------------------


CREATE OR REPLACE FUNCTION operator.insert_org_detail(
	p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--insert_org_owner
------------------

CREATE OR REPLACE FUNCTION operator.insert_org_owner(
	p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--insert_org_contact
--------------------
CREATE OR REPLACE FUNCTION operator.insert_org_contact(
	p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--insert_org_social_link
------------------------

CREATE OR REPLACE FUNCTION operator.insert_org_social_link(
	p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;

--insert_address
----------------

CREATE OR REPLACE FUNCTION operator.insert_address(
	p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--create_org
---------------

CREATE OR REPLACE FUNCTION operator.create_org(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;




/*
select * from operator.create_org('{"orgSno":null,
                                    "orgName":"cxzz",
									"orgStatusCd":18,
									"orgDetails":{"regNumber":"3443","website":"www"},
									"contactList":[{"mobileNumber":"343","email":"43fsf"},
									               {"mobileNumber":"422","email":"cd"},
												   {"mobileNumber":"44","email":"fd"}],
									"social":[{"socialTypeCd":22,"urlLink":"fd","socialTypeName":"Facebook"},
									          {"socialTypeCd":23,"urlLink":"","socialTypeName":"Twitter"},
											  {"socialTypeCd":24,"urlLink":"","socialTypeName":"Google"}],
									"address":{"addressLine1":"fd","addressLine2":null,"pincode":"343","city":null,
									           "state":null,"district":null,"countryCode":null,"country":null,
											   "latitude":null,"longitude":null},
									"media":[{"mediaUrl":"https://jdfuserauth01.blob.core.windows.net/swomb/10ded6fb-365a-4f4b-8c89-cab730b2b03b.png","contentType":"image/png","fileType":".png","fileName":"Screenshot from 2022-05-06 13-39-23.png","mediaType":"Image","thumbnailUrl":"https://jdfuserauth01.blob.core.windows.net/swomb/bc05828f-97b7-4832-b2de-76bb8465587e.png","isUploaded":true,"keyName":"logo"},
									         {"mediaUrl":"https://jdfuserauth01.blob.core.windows.net/swomb/ab9b86e5-5bcb-4ea8-8e96-eeb591924161.png","contentType":"image/png","fileType":".png","fileName":"Screenshot from 2022-05-06 13-39-23.png","mediaType":"Image","thumbnailUrl":"https://jdfuserauth01.blob.core.windows.net/swomb/2a477ab6-10e9-4353-b7cc-c9bb77fa7db3.png","isUploaded":true,"keyName":"coverImage"}],
									"appUserSno":2}')
*/


--get_org_detail
----------------

CREATE OR REPLACE FUNCTION operator.get_org_detail(p_data json)
    RETURNS json
AS $BODY$
declare 
begin
raise notice '%',p_data;
return ( select json_build_object('detailSno',org_detail_sno,
										   'logo',org_logo,
										   'coverImage',org_banner,
										   'website',org_website )from operator.org_detail where 
		org_sno = (p_data->>'orgSno')::bigint);
end;
$BODY$
LANGUAGE plpgsql;


--get_org_contact
-----------------

CREATE OR REPLACE FUNCTION operator.get_org_contact(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--get_org_social_link
---------------------

CREATE OR REPLACE FUNCTION operator.get_org_social_link(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


-- get_address
--------------
CREATE OR REPLACE FUNCTION operator.get_address(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--get_org
---------


CREATE OR REPLACE FUNCTION operator.get_org(p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
AS $BODY$
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
$BODY$;




--update_org_sgl
----------------

CREATE OR REPLACE FUNCTION operator.update_org_sgl(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;

--update_org_detail
-------------------

CREATE OR REPLACE FUNCTION operator.update_org_detail(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;

--update_org_contact
--------------------
CREATE OR REPLACE FUNCTION operator.update_org_contact(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--update_org_social_link
------------------------

CREATE OR REPLACE FUNCTION operator.update_org_social_link(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;

--update_address
----------------

CREATE OR REPLACE FUNCTION operator.update_address(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;

--update_org
------------

CREATE OR REPLACE FUNCTION operator.update_org(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


/*

select * from operator.update_org('{"orgSno":1,
								  "orgName":"jdf",
								  "orgStatusCd":21,
								  "orgDetails":{"detailSno":1,"regNumber":"9768767","website":"www.jdf.com"},
								  "contactList":[{"orgContactSno":1,"contactSno":1,"mobileNumber":"976675","email":"aa@gmail.com"},
								                 {"orgContactSno":2,"contactSno":2,"mobileNumber":"64545","email":null},
								                 {"orgContactSno":3,"contactSno":3,"mobileNumber":"97766756564","email":"cc@gmail.com"}],
								  "social":[{"orgSocialLinkSno":1,"socialLinkSno":1,"urlLink":"ff","socialTypeCd":18,"socialTypeName":"Facebook"},
								            {"orgSocialLinkSno":2,"socialLinkSno":2,"urlLink":"","socialTypeCd":19,"socialTypeName":"Twitter"},
								            {"orgSocialLinkSno":3,"socialLinkSno":3,"urlLink":"","socialTypeCd":20,"socialTypeName":"Google"}],
								  "address":{"addressSno":1,"addressLine1":"d3","addressLine2":"thuraipakkam","pincode":600097,
								             "city":"chennai","state":"tamilnadu","district":"chennai","countryCode":91,
								             "country":"india","latitude":null,"longitude":null},
								  "media":[{"mediaUrl":null,"contentType":null,"fileType":"","fileName":null,"mediaType":null,"thumbnailUrl":null,"isUploaded":true},
								           {"keyName":"coverImage","fileName":"cloud.jpg","fileType":".jpg","mediaUrl":"https://jdfuserauth01.blob.core.windows.net/swomb/d054897e-337e-4f06-87c7-780453af09d0.jpg","mediaType":"Image","isUploaded":true,"contentType":"image/jpeg","thumbnailUrl":"https://jdfuserauth01.blob.core.windows.net/swomb/e67a065a-0f76-43ad-b862-b314fea381b0.jpg"}],
								  "appUserSno":2}')
								  
*/


--create_driver
---------------
	
-- CREATE OR REPLACE FUNCTION operator.create_driver(p_data json)
--     RETURNS json
-- AS $BODY$
-- declare 
-- driverSno bigint;
-- _app_user_sno bigint;
-- isAlreadyExists bigint;
-- begin
-- raise notice ' p_data1 %',p_data;
-- select count(*) into isAlreadyExists from driver.driver d where d.driver_mobile_number =(p_data->>'driverMobileNumber');
-- if isAlreadyExists=0 then
-- select (select operator.insert_driver(p_data)->>'data')::json->>'driverSno' into driverSno;
-- raise notice ' driverSno %',driverSno;
-- INSERT INTO portal.app_user( mobile_no,user_status_cd)
-- 	VALUES (p_data->>'driverMobileNumber',
-- 	portal.get_enum_sno('{"cd_value":"InActive","cd_type":"user_status_cd"}')) returning app_user_sno into _app_user_sno;
-- perform operator.insert_driver(p_data);
-- perform operator.insert_operator_driver((select (p_data)::jsonb || ('{"driverSno": ' || driverSno ||' }')::jsonb )::json);
-- perform portal.create_app_user_role(json_build_object('appUserSno',_app_user_sno,'roleCd',(p_data->>'roleCd')::smallint));
--   return (select json_build_object('data',json_build_object('driverSno',driverSno)));
--   else
--   return (select json_build_object('data',json_build_object('msg','This Mobile Number is Already Exists')));
--   end if;
-- end;
-- $BODY$
-- LANGUAGE plpgsql;

--insert_operator_driver
---------------------------
CREATE OR REPLACE FUNCTION operator.insert_operator_driver(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;



--insert_operator_route
------------------------
CREATE OR REPLACE FUNCTION operator.insert_operator_route(
	p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;




--insert_vehicle_route
-----------------------
CREATE OR REPLACE FUNCTION operator.insert_vehicle_route(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


 --insert_single
------------------

CREATE OR REPLACE FUNCTION operator.insert_single(
	p_data json)
    RETURNS json
AS $BODY$
declare 
singleSno bigint;
begin
--  raise notice '%',p_data;

insert into operator.org_owner(route_sno,org_sno,vehicle_sno,starting_time,running_time,active_flag)  values(
(p_data->>'routeSno')::bigint,(p_data->>'orgSno')::bigint,(p_data->>'vehicleSno')::bigint,(p_data->>'starting_time')::time,(p_data->>'running_time')::time,(p_data->>'activeFlag')::boolean
) returning single_sno  INTO singleSno;

 return (select json_build_object('data',json_build_object('singleSno',singleSno))); 
end;
$BODY$
LANGUAGE plpgsql;


--check_route
-----------------
CREATE OR REPLACE FUNCTION operator.check_route(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;



--check_operator_route
----------------------


CREATE OR REPLACE FUNCTION operator.check_operator_route(p_data json)
    RETURNS bigint
AS $BODY$
declare 
begin
return(select count(*) from operator.operator_route  where operator_sno=(p_data->>'operatorSno')::bigint and route_sno=(p_data->>'routeSno')::bigint);
end;
$BODY$
LANGUAGE plpgsql;


--add_vehicle_info
----------------------

CREATE OR REPLACE FUNCTION operator.add_vehicle_info(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE 'plpgsql';



--insert_vehicle
-----------------
CREATE OR REPLACE FUNCTION operator.insert_vehicle(
	p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;

--insert_org_vehicle
----------------------
CREATE OR REPLACE FUNCTION operator.insert_org_vehicle(
	p_data json)
    RETURNS json
AS $BODY$
declare 
orgVehicleSno bigint;
begin
insert into operator.org_vehicle(org_sno,vehicle_sno) 
     values ((p_data->>'orgSno')::bigint,
			 (p_data->>'vehicleSno')::bigint
            ) returning org_vehicle_sno  INTO orgVehicleSno;

  return (select json_build_object('data',json_build_object('orgVehicleSno',orgVehicleSno)));
end;
$BODY$
LANGUAGE plpgsql;

--insert_vehicle_owner
-----------------------

CREATE OR REPLACE FUNCTION operator.insert_vehicle_owner(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--insert_vehicle_detail
-----------------------
CREATE OR REPLACE FUNCTION operator.insert_vehicle_detail(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;


--get_org_vehicle
--------------------
CREATE OR REPLACE FUNCTION operator.get_org_vehicle(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;

--get_operator_vehicle
------------------------

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
$BODY$
LANGUAGE plpgsql;





--get_mileage_dtl
------------------


CREATE OR REPLACE FUNCTION operator.get_mileage_dtl(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;



--get_operator_vehicle_dtl
---------------------------
CREATE OR REPLACE FUNCTION operator.get_operator_vehicle_dtl(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;



--get_operator_vehicle_owner
-----------------------------

CREATE OR REPLACE FUNCTION operator.get_operator_vehicle_owner(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;

--update_vehicle
-------------------
CREATE OR REPLACE FUNCTION operator.update_vehicle(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;



--update_vehicle_owner
------------------------

CREATE OR REPLACE FUNCTION operator.update_vehicle_owner(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;



--update_vehicle_detail
--------------------------
CREATE OR REPLACE FUNCTION operator.update_vehicle_detail(
	p_data json)
    RETURNS json
    
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;



--update_vehicle_info
-----------------------------
CREATE OR REPLACE FUNCTION operator.update_vehicle_info(
	p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;




--delete_single_route
------------------------
CREATE OR REPLACE FUNCTION operator.delete_single_route(p_data json)
    RETURNS json
AS $BODY$
declare 
dates json;
singleRouteSno bigint;
begin
 delete from operator.single_route 
 where vehicle_sno =(p_data->>'vehicleSno')::bigint and route_sno=(p_data->>'routeSno')::bigint;
 
 return(json_build_object('data',json_agg(json_build_object('isdelete',true))));
end;
$BODY$
LANGUAGE plpgsql;


--get_org_route
----------------
CREATE OR REPLACE FUNCTION operator.get_org_route(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;



--get_single_route
------------------------

CREATE OR REPLACE FUNCTION operator.get_single_route(
	p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
 LANGUAGE plpgsql;

--insert_single_route
---------------------

CREATE OR REPLACE FUNCTION operator.insert_single_route(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--update_single_route
------------------------
CREATE OR REPLACE FUNCTION operator.update_single_route(p_data json)
RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;



--insert_fuel
---------------
CREATE OR REPLACE FUNCTION operator.insert_fuel(
	p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE 'plpgsql';


--get_fc_expiry_date
----------------------
CREATE OR REPLACE FUNCTION operator.get_fc_expiry_date(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--get_insurance_expiry_date
----------------------------

CREATE OR REPLACE FUNCTION operator.get_insurance_expiry_date(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--get_pollution_expiry_date
----------------------------
CREATE OR REPLACE FUNCTION operator.get_pollution_expiry_date(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;

--get_tax_expiry_date
-----------------------
CREATE OR REPLACE FUNCTION operator.get_tax_expiry_date(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;

--get_permit_expiry_date
--------------------------

CREATE OR REPLACE FUNCTION operator.get_permit_expiry_date(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--get_vehicles_and_drivers
---------------------------
CREATE OR REPLACE FUNCTION operator.get_vehicles_and_drivers(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--get_bus_report
-----------------

CREATE OR REPLACE FUNCTION operator.get_bus_report(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--get_fuel_report
------------------

CREATE OR REPLACE FUNCTION operator.get_fuel_report(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;




--insert_trip
--------------

CREATE OR REPLACE FUNCTION operator.insert_trip(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--insert_trip_route
--------------------
CREATE OR REPLACE FUNCTION operator.insert_trip_route(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--get_trip_all_vehicle
-----------------------

CREATE OR REPLACE FUNCTION operator.get_trip_all_vehicle(p_data json)
    RETURNS json
AS $BODY$
declare 
begin
return ( select json_build_object('data',(select json_build_object('orgSno',ov.org_sno,
								  'vehicleRegNumber',v.vehicle_reg_number,
								  'vehicleName',v.vehicle_name,
								  'districtName',a.district_name,
								  'stateName',a.state_name))) from operator.org_vehicle ov 
inner join operator.vehicle v on v.vehicle_sno=ov.vehicle_sno
inner join operator.org_detail od on od.org_sno=ov.org_sno
inner join operator.address a on a.address_sno=od.address_sno);

end;
$BODY$
LANGUAGE plpgsql;


--get_trip_all_vehicle
-----------------------

CREATE OR REPLACE FUNCTION operator.get_trip_all_vehicle(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;



--accept_reject_operator_kyc
-----------------------------
CREATE OR REPLACE FUNCTION operator.accept_reject_operator_kyc(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--update_via
-------------
CREATE OR REPLACE FUNCTION operator.update_via(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE 'plpgsql';



--update_vehicle_route
-----------------------

CREATE OR REPLACE FUNCTION operator.update_vehicle_route(p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
AS $BODY$
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
$BODY$;


--accept_reject_vehicle_kyc
----------------------------

CREATE OR REPLACE FUNCTION operator.accept_reject_vehicle_kyc(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;



--delete_all_vehicle
----------------------
CREATE OR REPLACE FUNCTION operator.delete_all_vehicle(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare 
begin

 delete from operator.vehicle where vehicle_sno=(p_data->>'vehicleSno')::bigint;
 delete from operator.org_vehicle where vehicle_sno=(p_data->>'vehicleSno')::bigint;
 delete from operator.vehicle_detail where vehicle_sno=(p_data->>'vehicleSno')::bigint;
 delete from operator.vehicle_owner where vehicle_sno=(p_data->>'vehicleSno')::bigint;
 
return(json_build_object('data',json_agg(json_build_object('isdelete',true))));

end;
$BODY$;


--get_fuel_info
------------------
CREATE OR REPLACE FUNCTION operator.get_fuel_info(p_data json)
 RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;





--update_org_attendance
-------------------------

CREATE OR REPLACE FUNCTION operator.update_org_attendance(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--update_org_fuel
------------------
CREATE OR REPLACE FUNCTION operator.update_org_fuel(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;

--get_sum_odometer_reading
----------------------------

CREATE OR REPLACE FUNCTION operator.get_sum_odometer_reading(p_data json)
    RETURNS json
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
$$
LANGUAGE plpgsql;


--update_active_status
-----------------------

CREATE OR REPLACE FUNCTION operator.update_active_status(p_data json)
    RETURNS json
	
AS $$
declare 
begin
raise notice '%',p_data;

update operator.vehicle set active_flag = false
where vehicle_sno = (p_data->>'vehicleSno')::bigint;

return 
( json_build_object('data',json_build_object('vehicleSno',(p_data->>'vehicleSno')::bigint)));
end;
$$
LANGUAGE plpgsql;



--update_driver_status
----------------------

CREATE OR REPLACE FUNCTION operator.update_driver_status(p_data json)
    RETURNS json
AS $BODY$
declare 
begin
-- update driver.driver set accept_status_cd=124 where driver_sno=(p_data->>'driverSno')::bigint;
delete from operator.operator_driver 
where driver_sno = (p_data->>'driverSno')::bigint and org_sno = (p_data->>'orgSno')::bigint;

return (json_build_object('data',json_build_object('driverSno',(p_data->>'driverSno')::bigint)));
end;
$BODY$
LANGUAGE plpgsql;




---update_operator_vehicle_route
--------------------------------

CREATE OR REPLACE FUNCTION operator.update_operator_vehicle_route(
	p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE 'plpgsql';


--get_org_contract_vehicle
---------------------------
CREATE OR REPLACE FUNCTION operator.get_org_contract_vehicle(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE 'plpgsql';


--get_separate_single_route
---------------------------

CREATE OR REPLACE FUNCTION operator.get_separate_single_route(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$ 
LANGUAGE plpgsql;


--insert_attendance_manually
----------------------------

CREATE OR REPLACE FUNCTION operator.insert_attendance_manually(
	p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE 'plpgsql';






--fuel_data
------------
CREATE OR REPLACE FUNCTION operator.fuel_data(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;

--get_dashboard_count
---------------------

drop function if exists operator.get_dashboard_count;
CREATE OR REPLACE FUNCTION operator.get_dashboard_count(p_data json)
    RETURNS json
AS $BODY$
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
-- 	due_fixed_expiry_count bigint;
-- 	due_variable_expiry_count bigint;
	due_count bigint;
-- 	due_expiry_list json;
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
-- 	select count(*) into booking_count from rent.booking b inner join operator.org_vehicle ov on b.vehicle_sno = ov.vehicle_sno where ov.org_sno=(p_data->>'orgSno')::bigint and b.active_flag=true;
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
-- 		json_agg(json_build_object('title','Driver License Expiry','count',driver_license_count,'class','text-danger bg-danger', 'icon','fa fa-id-card-o','path','driver'))::jsonb || 
		json_agg(json_build_object('title','Total Running Drivers/Vehicle','count',driver_running_count,'class','text-secondary bg-secondary','icon','bi bi-person-circle','path','driving-action'))::jsonb ||
-- 		json_agg(json_build_object('title','Total Running Vehicle','count',vehicle_running_count,'class','text-warning bg-warning','icon','bi bi-bus-front','path','driving-action'))::jsonb || 
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
-- 		json_agg(json_build_object('title','Transport License Expiry','count',driver_transport_license_count,'class','bg-warning','icon','fa fa-user-circle-o','path','driver'))::jsonb ||				 
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
	
$BODY$
LANGUAGE 'plpgsql';



--get_driver_report
--------------------
CREATE OR REPLACE FUNCTION operator.get_driver_report(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;

--get_driver_report_dtl
--------------------------
CREATE OR REPLACE FUNCTION operator.get_driver_report_dtl(p_data json)
    RETURNS json
AS $BODY$
begin
return(select json_build_object('data',json_agg(json_build_object('report',(with driver_list as (select distinct d.driver_sno, d.driver_name from driver.driver d
	inner join operator.operator_driver od on od.driver_sno=d.driver_sno 
	where od.org_sno=(p_data->>'orgSno')::bigint and 
	case when (p_data->>'driverSno')::bigint is not null then d.driver_sno=(p_data->>'driverSno')::bigint else true end )
	SELECT json_agg(json_build_object('driverSno',dl.driver_sno,'driverName',dl.driver_name,
	'report',(select * from operator.fuel_data(json_build_object('driverSno',dl.driver_sno))))) FROM driver_list dl))))
);
end;
$BODY$
LANGUAGE plpgsql;

--create_operator_driver
------------------------
CREATE OR REPLACE FUNCTION operator.create_operator_driver(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--get_codesHdrType
--------------------

CREATE OR REPLACE FUNCTION operator.get_codesHdrType(p_data json)
    RETURNS json
AS $BODY$
declare 
_codesHdrType json;
begin

 select json_agg(cd_value) into _codesHdrType
	  from portal.codes_dtl where codes_hdr_sno = (p_data->>'codesHdrSno')::smallint  and  ('{' || codes_dtl_sno || '}')::int[] &&  
	  translate ((p_data->>'codesHdrType')::text,'[]','{}')::int[] ;
	  
return _codesHdrType;

end;
$BODY$
 LANGUAGE plpgsql;


 --get_fuel_report_count
------------------------
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
case when (p_data->>'filledDate')::timestamp is not null and (p_data->>'toDate')::timestamp is null then f.filled_date::date=(p_data->>'filledDate')::date else true end;

return (select  json_build_object('data',json_agg(json_build_object('count',_count))));

end;
$BODY$;



--get_bus_report_count
-----------------------

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






--get_address_city
------------------


CREATE OR REPLACE FUNCTION operator.get_address_city(
	p_data json)
    RETURNS json
AS $BODY$
declare 
begin

return (
with city_name as(
select DISTINCT lower(trim(city_name)) as city from operator.address)
select json_build_object('data',(select json_agg(city))) from city_name
);
   
end;
$BODY$
LANGUAGE plpgsql;


--get_address_district
----------------------


CREATE OR REPLACE FUNCTION operator.get_address_district(
	p_data json)
    RETURNS json
AS $BODY$
declare 
begin

return (
with district_name as(
select DISTINCT lower(trim(district_name)) as district from operator.address)
select json_build_object('data',(select json_agg(district))) from district_name
);
   
end;
$BODY$
LANGUAGE plpgsql;


--accept_reject_driver_kyc
--------------------------

CREATE OR REPLACE FUNCTION operator.accept_reject_driver_kyc(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare 
toId bigint;
token_list json;
reason text;
begin

select app_user_sno into toId from  driver.driver_user where driver_sno=(p_data->>'driverSno')::bigint;
if (p_data->>'kycStatus')::smallint=19 then
perform notification.insert_notification(json_build_object(
			'title','Verified ','message','Dear Driver your KYC is Successfully verified ','actionId',null,'routerLink','driver','fromId',p_data->>'appUserSno',
			'toId',toId,
			'createdOn',p_data->>'createdOn'
			));
			reason:='Dear Driver your KYC is Successfully verified';
else
perform notification.insert_notification(json_build_object(
			'title','Rejected ','message','Dear Driver Your Kyc is rejected due to  '||(p_data->>'rejectReason')||'','actionId',null,'routerLink','driver','fromId',p_data->>'appUserSno',
			'toId',toId,
			'createdOn',p_data->>'createdOn'
			)); 
			raise notice'%',p_data->>'rejectReason';
			reason:='Dear Driver Your Kyc is rejected due to  '|| (p_data->>'rejectReason')::text;
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
$BODY$;



--get_approval
--------------

CREATE OR REPLACE FUNCTION operator.get_approval(p_data json)
RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--get_all_org_count
--------------------

CREATE OR REPLACE FUNCTION operator.get_all_org_count(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare
_count bigint;
begin
select count(*) into _count from operator.org;
return (select  json_build_object('data',json_agg(json_build_object('count',_count))));

end;
$BODY$;


--get_all_vehicle_count
------------------------

CREATE OR REPLACE FUNCTION operator.get_all_vehicle_count(
	p_data json)
    RETURNS json
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
$BODY$
LANGUAGE 'plpgsql';


--insert_vehicle_driver
-------------------------
CREATE OR REPLACE FUNCTION operator.insert_vehicle_driver(p_data json)
    RETURNS json
    
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;

--get_vehicle_driver
---------------------

CREATE OR REPLACE FUNCTION operator.get_vehicle_driver(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;

--get_org_contact_dtl
---------------------

CREATE OR REPLACE FUNCTION operator.get_org_contact_dtl(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--get_assign_driver_count
--------------------------

CREATE OR REPLACE FUNCTION operator.get_assign_driver_count(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;


--get_verify_report
--------------------

CREATE OR REPLACE FUNCTION operator.get_verify_report(p_data json)
    RETURNS json
AS $BODY$
declare 
begin
raise notice '%',p_data;
 return (select json_build_object('data',(select json_agg(json_build_object(
	 'report',(select * from operator.get_verify_data(json_build_object('reportId',d.report_id)))))									  
	from (select da.report_id from  driver.driver_attendance da
	where  da.accept_status=true and da.is_calculated=false and da.vehicle_sno=(p_data->>'vehicleSno')::bigint
	group by report_id  order by report_id desc)d ))); 
end;
$BODY$
LANGUAGE plpgsql;




--get_verify_data
------------------
CREATE OR REPLACE FUNCTION operator.get_verify_data(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE 'plpgsql';



--get_all_tyre_type
-------------------
CREATE OR REPLACE FUNCTION operator.get_all_tyre_type(p_data json)
    RETURNS json
AS $BODY$
declare 
tyreType json;
begin
raise notice'%love',p_data;
 select json_agg(tyre_type) into tyreType
	  from master_data.tyre_type where  ('{' || tyre_type_sno || '}')::int[] &&  
	  translate ((p_data->>'tyreTypeSno')::text,'[]','{}')::int[] ;
return tyreType;
end;
$BODY$
LANGUAGE plpgsql;

--get_all_tyre_size
--------------------
CREATE OR REPLACE FUNCTION operator.get_all_tyre_size(p_data json)
    RETURNS json
AS $BODY$
declare 
tyreSize json;
begin
raise notice'%love',p_data;
 select json_agg(tyre_size) into tyreSize
	  from master_data.tyre_size where  ('{' || tyre_size_sno || '}')::int[] &&  
	  translate ((p_data->>'tyreSizeSno')::text,'[]','{}')::int[] ;
return tyreSize;
end;
$BODY$
LANGUAGE plpgsql;

--get_toll_pass_detail
-----------------------


CREATE OR REPLACE FUNCTION operator.get_toll_pass_detail(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--insert_toll_pass_detail
--------------------------


CREATE OR REPLACE FUNCTION operator.insert_toll_pass_detail(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;

--insert_vehicle_due
---------------------

CREATE OR REPLACE FUNCTION operator.insert_vehicle_due(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;


--insert_vehicle_due_fixed_pay
-------------------------------
CREATE OR REPLACE FUNCTION operator.insert_vehicle_due_fixed_pay(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE 'plpgsql';




--insert_variable_pay
----------------------


CREATE OR REPLACE FUNCTION operator.insert_variable_pay(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;


--get_vehicle_due_fixed_pay
----------------------------

CREATE OR REPLACE FUNCTION operator.get_vehicle_due_fixed_pay(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;


--get_variable_pay
-------------------
CREATE OR REPLACE FUNCTION operator.get_variable_pay(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;


--update_vehicle_due_fixed_pay
-------------------------------


CREATE OR REPLACE FUNCTION operator.update_vehicle_due_fixed_pay(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;

--update_variable_pay
---------------------

CREATE OR REPLACE FUNCTION operator.update_variable_pay(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE 'plpgsql';

--delete_vehicle_due_fixed_pay
-------------------------------
CREATE OR REPLACE FUNCTION operator.delete_vehicle_due_fixed_pay(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
AS $BODY$
declare 
vehicleDueSno bigint;
begin
 delete from operator.vehicle_due_fixed_pay
 where vehicle_due_sno =(p_data->>'vehicleDueSno')::bigint;
 
 return(json_build_object('data',json_agg(json_build_object('isdelete',true))));
end;
$BODY$;


--delete_variable_pay
----------------------

CREATE OR REPLACE FUNCTION operator.delete_variable_pay(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
AS $BODY$
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
$BODY$;


--delete_toll_pass_detail
-------------------------

CREATE OR REPLACE FUNCTION operator.delete_toll_pass_detail(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
AS $BODY$
declare 
tollPassDetailSno bigint;
begin
 delete from operator.toll_pass_detail
 where toll_pass_detail_sno =(p_data->>'tollPassDetailSno')::bigint;
 
 return(json_build_object('data',json_agg(json_build_object('isdelete',true))));
end;
$BODY$;


--update_toll_pass_detail
-------------------------

CREATE OR REPLACE FUNCTION operator.update_toll_pass_detail(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;



--insert_org_account
--------------------

CREATE OR REPLACE FUNCTION operator.insert_org_account(
	p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE plpgsql;


--get_org_account
----------------

CREATE OR REPLACE FUNCTION operator.get_org_account(p_data json)
    RETURNS json
AS $BODY$
declare 
begin
raise notice '%',p_data;
return ( select json_agg(json_build_object('bankAccountDetailSno',od.bank_account_detail_sno,
										   'bankAccountName',od.bank_account_name
										  ))from operator.bank_account_detail od
		where od.org_sno = (p_data->>'orgSno')::bigint and case when (od.bank_account_name is null)  then od.bank_account_detail_sno=(p_data->>'bankAccountDetailSno')::bigint else true end);
end;
$BODY$
LANGUAGE plpgsql;



--update_org_account
--------------------

CREATE OR REPLACE FUNCTION operator.update_org_account(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;



--get_vehicle_due_expiry_details
---------------------------------

CREATE OR REPLACE FUNCTION operator.get_vehicle_due_expiry_details(p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE 'plpgsql';



--get_all_toll_expiry
---------------------

CREATE OR REPLACE FUNCTION operator.get_all_toll_expiry(
	p_data json)
    RETURNS json
AS $BODY$
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
$BODY$
LANGUAGE 'plpgsql';



--update_toll_paid_details
--------------------------

CREATE OR REPLACE FUNCTION operator.update_toll_paid_details(
	p_data json)
    RETURNS json
AS $BODY$
declare 
tollPassDetailSno bigint;
begin
raise notice '%',p_data;
update operator.toll_pass_detail set is_paid = (p_data->>'isPaid')::boolean
								where toll_pass_detail_sno = (p_data->>'tollPassDetailSno')::bigint 
								returning toll_pass_detail_sno into tollPassDetailSno;

  return (select json_build_object('tollPassDetailSno',tollPassDetailSno));

end;
$BODY$
LANGUAGE plpgsql;



--update_due_fixed_pay
----------------------

CREATE OR REPLACE FUNCTION operator.update_due_fixed_pay(p_data json)
    RETURNS json
AS $BODY$
declare 
vehicleDueVariablePaySno bigint;
begin
raise notice '%',p_data;
update operator.vehicle_due_variable_pay set is_pass_paid = (p_data->>'isPassPaid')::boolean
								where vehicle_due_variable_pay_sno = (p_data->>'vehicleDueVariablePaySno')::bigint 
								returning vehicle_due_variable_pay_sno into vehicleDueVariablePaySno;

  return (select json_build_object('vehicleDueVariablePaySno',vehicleDueVariablePaySno));

end;
$BODY$
LANGUAGE plpgsql;





