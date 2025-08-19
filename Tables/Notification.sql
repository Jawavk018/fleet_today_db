CREATE TABLE IF NOT EXISTS notification.notification(
    notification_sno bigserial PRIMARY KEY,
    title text,
    message text,
    action_id bigint,
    router_link text,
    from_id bigint,
    to_id bigint,
	created_on timestamp,
	notification_status_cd smallint default 117,
    active_flag boolean NOT NULL default true,
    FOREIGN KEY(notification_status_cd) REFERENCES portal.codes_dtl(codes_dtl_sno)
);
