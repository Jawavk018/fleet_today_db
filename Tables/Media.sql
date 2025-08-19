CREATE TABLE IF NOT EXISTS media.media(
    media_sno bigserial PRIMARY KEY,
    container_name  varchar(60) not null 
);

CREATE TABLE IF NOT EXISTS media.media_detail(
    media_detail_sno bigserial PRIMARY KEY,
    azure_id text,
    media_sno bigint,
    media_url text,
    thumbnail_url text,
    media_type  varchar(20),
    content_type varchar(20),
    media_size int,
    media_detail_description varchar(200), 
    isUploaded boolean default true,
    FOREIGN KEY(media_sno) REFERENCES media.media(media_sno)
);
 