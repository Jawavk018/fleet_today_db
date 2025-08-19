
--get_config
------------
CREATE FUNCTION config.get_config(in_data json) RETURNS json
    LANGUAGE plpgsql
    AS $$
declare 
	i_environment_sno smallint := (in_data->>'environmentSno')::smallint;
	i_module_sno smallint := (in_data->>'moduleSno')::smallint;
	i_sub_module_sno smallint := (in_data->>'subModuleSno')::smallint;
	
begin
	return (select(json_build_object('data',json_agg(json_build_object(key1.config_key_attribute,conf.config_value)))))								
	FROM config.config conf, config.config_key key1 
	where 
	(conf.environment_sno in (0) 
	or (conf.environment_sno = i_environment_sno and conf.module_sno =0) 
	or (conf.environment_sno = i_environment_sno and conf.module_sno in (i_module_sno) and  
		conf.sub_module_sno in (0, i_sub_module_sno) ) )
	and conf.config_key_sno = key1.config_key_sno;		
end;
$$;



