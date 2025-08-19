
--insert_media
---------------
CREATE OR REPLACE FUNCTION media.insert_media(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare 
mediaSno bigint;
media json;
mediaDetail json;

begin
raise notice '%',p_data;

-- raise notice '%',_mediaList;
	if (p_data->>'mediaSno')::bigint is null then
  		insert into media.media(container_name) values (p_data->>'containerName')
  		returning media_sno into mediaSno;
	else
  		mediaSno:= (p_data->>'mediaSno')::bigint;
	end if;

if((p_data->>'deleteMediaList') is not null) then
for mediaDetail in SELECT * FROM json_array_elements((p_data->>'deleteMediaList')::json) loop
	raise notice 'mediaDetail %d',mediaDetail;
	delete from media.media_detail where media_detail_sno = (mediaDetail->>'mediaDetailSno')::bigint;
end loop;
end if;

for media in SELECT * FROM json_array_elements((p_data->>'mediaList')::json) loop
-- 	raise notice 'media %d',media;
	if (media->>'mediaDetailSno')::bigint is null then
	raise notice '%d','if';
		 insert into media.media_detail(media_sno,media_url,thumbnail_url,media_type,content_type,media_size,media_detail_description,azure_id,isUploaded)
		 values(mediaSno,media->>'mediaUrl',media->>'thumbnailUrl',media->>'mediaType',media->>'contentType',(media->>'mediaSize')::int,media->>'mediaDetailDescription',(media->>'azureId'),(media->>'isUploaded')::boolean);  
	else
	raise notice '%d','else';
		 update media.media_detail set media_url = media->>'mediaUrl',
									thumbnail_url = media->>'thumbnailUrl',
									media_type = media->>'mediaType',
									content_type = media->>'contentType',
									azure_id = media->>'azureId',
									media_size = (media->>'mediaSize')::int,
									media_detail_description = media->>'mediaDetailDescription'
									where media_detail_sno = (media->>'mediaDetailSno')::bigint;
	end if;
end loop;

return (select json_build_object('mediaSno',mediaSno));
end;
$BODY$;



--get_media_detail
------------------

CREATE OR REPLACE FUNCTION media.get_media_detail(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
AS $BODY$
begin
raise notice 'data %',p_data;
return (select json_agg(json_build_object(
'mediaDetailSno',d.media_detail_sno,
'mediaSno',d.media_sno,
'mediaUrl',d.media_url,
'thumbnailUrl',d.thumbnail_url,
'mediaType',d.media_type,
'contentType',d.content_type,
'azureId',d.azure_id,
'mediaSize',d.media_size,	
'mediaDetailDescription',d.media_detail_description,
'isUploaded',d.isUploaded	
)) from (select * from media.media_detail where media_sno=(p_data->>'mediaSno')::bigint)d);

end;
$BODY$;


/*
 select * from media.insert_media('{
			"mediaDescription":"fsfa",
			"mediaAreaCd":4,
			"mediaList":[{"mediaSno":null,
			"mediaUrl":"ertyu",
			"thumbnailUrl":"rertyu",
			"mediaType":"tte",							
			"contentType":"yywy",							
			"mediaSize":5,							
			"mediaDetailDescription":"gsgs"						
			}]		
	}')
*/

--delete_media
--------------

CREATE OR REPLACE FUNCTION media.delete_media(
	p_data json)
    RETURNS json
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
declare 
mediaSno bigint;
begin
   
   delete from media.media_detail where media_sno = (p_data->>'mediaSno')::bigint; 

   delete from media.media where media_sno = (p_data->>'mediaSno')::bigint 
   									returning media_sno into mediaSno;

return (select json_build_object('data',json_build_object('isdelete',true)));

end;
$BODY$;
