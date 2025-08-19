
--get_current_district
----------------------


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
		  inner join driver.driver d on cast(d.current_district as int) = dd.district_sno  group by dd.district_sno
		 )md);
	   

end;
$BODY$;
