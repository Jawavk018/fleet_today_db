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

--get_token
----------------
CREATE OR REPLACE FUNCTION notification.get_token(p_data json)
    RETURNS json
AS $BODY$
declare
tokenList json;
begin
raise notice 'get_token %',p_data;
select json_agg(push_token_id) into tokenList from portal.signin_config where active_flag = true and 
push_token_id is not null and 
app_user_sno in (select value::text::bigint from json_array_elements((p_data->>'appUserList')::json));
  return (select json_build_object('tokenList',tokenList));
end;
$BODY$
LANGUAGE plpgsql;

--get_time_with_zone
----------------------
CREATE OR REPLACE FUNCTION portal.get_time_with_zone(p_data json)
  RETURNS text
 LANGUAGE plpgsql AS
$$
BEGIN
return (select (select now() AT TIME ZONE (p_data->>'timeZone')::text)::text);
END;
$$;


---get_notification
-------------------	 

CREATE OR REPLACE FUNCTION notification.get_notification(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;	 


--update_notification
---------------------
CREATE OR REPLACE FUNCTION notification.update_notification(p_data json)
    RETURNS json
AS $BODY$
declare 
begin
update notification.notification set notification_status_cd = 116 where  notification_sno = (p_data->>'notificationSno')::bigint;

return (select json_build_object('data',json_build_object('notificationStatusCd',116)));
end;
$BODY$
LANGUAGE plpgsql;


--get_notification_count
------------------------

CREATE OR REPLACE FUNCTION notification.get_notification_count(
	p_data json)
    RETURNS json
AS $BODY$
declare 
_count bigint;
begin
select count(*) into _count from notification.notification  where active_flag = true and to_id = (p_data->>'appUserSno')::bigint and notification_status_cd =117;
return (select  json_build_object('data',json_agg(json_build_object('count',_count))));
end;
$BODY$
LANGUAGE 'plpgsql';