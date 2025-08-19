--16-05-2023
--------------

ALTER TABLE operator.vehicle 
ADD COLUMN IF NOT EXISTS tyre_count_cd  smallint;

ALTER TABLE operator.vehicle 
ADD CONSTRAINT fk_tyre_count_cd FOREIGN KEY (tyre_count_cd) 
REFERENCES portal.codes_dtl(codes_dtl_sno);

insert into  portal.codes_hdr(codes_hdr_sno,code_type) values(32,'tyre_count_cd');

INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(113,32,'6 Tyres',1,6);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(114,32,'8 Tyres',2,8);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(115,32,'10 Tyres',3,10);


--20-06-2023
-------------


update portal.app_menu set title = 'Drivers', icon = 'user-circle-o', has_sub_menu = 'false', parent_menu_sno = 0,
                           router_link = '/driverlist' where app_menu_sno = 25


update portal.app_menu set title = 'Vehicles', icon = 'bus', has_sub_menu = 'false', parent_menu_sno = 0,
                           router_link = '/vehiclelist' where app_menu_sno = 24

update portal.app_menu set title = 'Notification', icon = 'bell', has_sub_menu = 'false', parent_menu_sno = 0,
                           router_link = '/notification' where app_menu_sno = 26

update portal.app_menu_role set app_menu_sno = 26 , role_cd = 2 where app_menu_role_sno = 33


update portal.app_menu_role set role_cd = 1 where app_menu_role_sno = 30

select * from portal.create_app_menu_role('{"appMenuSno":26,"roleCd":1}');	
