insert into  portal.codes_hdr(codes_hdr_sno,code_type) values(10,'attendance_status_cd');

INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(28,10,'open',1);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(29,10,'close',2);

insert into  portal.codes_hdr(codes_hdr_sno,code_type) values(18,'driving_type_cd');

INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(51,18,'LMV',1);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(52,18,'LMV-TR',2);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(53,18,'HMV',3);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(54,18,'HGMV',4);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(55,18,'HPTV',5);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(56,18,'HPMY',6);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(57,18,'TRAILER',7);


insert into  portal.codes_hdr(codes_hdr_sno,code_type) values(26,'blood_group_cd');

INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(84,26,'O+',1);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(85,26,'O-',2);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(86,26,'A+',3);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(87,26,'A-',4);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(88,26,'B+',5);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(89,26,'B-',6);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(90,26,'AB+',7);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(91,26,'AB-',8);



insert into  portal.codes_hdr(codes_hdr_sno,code_type) values(35,'accept_status_cd');

INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(122,35,'Accept',1);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(123,35,'Reject',2);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(124,35,'Not Accept',3);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(125,35,'Requested',4);


insert into  portal.codes_hdr(codes_hdr_sno,code_type) values(36,'due_type_cd');

INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(129,36,'Fixed',1);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(130,36,'Variable',2);


insert into  portal.codes_hdr(codes_hdr_sno,code_type) values(37,'remainder_type_cd');

INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(131,37,'1 day',1);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(132,37,'7 days',2);



insert into  portal.codes_hdr(codes_hdr_sno,code_type) values(38,'fuel_fill_type_cd');

INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(133,38,'Fuel Filled',1);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(134,38,'Partially Filled',2);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(135,38,'No Filled',3);



insert into  portal.codes_hdr(codes_hdr_sno,code_type) values(39,'drive_type_cd');

INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(136,39,'Passenger Vehicle',1);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(137,39,'Goods Vehicle',2);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(151,39,'Light Passenger Vehicle',3);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(152,39,'Light Goods Vehicle',4);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(153,39,'Special Vehicle',5);



insert into  portal.codes_hdr(codes_hdr_sno,code_type) values(40,'job_type_cd');

INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(138,40,'City / town bus',1,136);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(139,40,'Mofussil bus',2,136);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(140,40,'Omni bus',3,136);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(141,40,'Mini bus',4,136);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(142,40,'School / college bus',5,136);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(143,40,'Staff bus',6,136);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(144,40,'Normal truck',7,137);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(145,40,'Taurus truck',8,137);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(146,40,'Trailer',9,137);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(147,40,'Tanker',10,137);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(148,40,'Container',11,137);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(149,40,'Tripper',12,137);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(150,40,'Special Vehicle',13,137);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(154,40,'Van',14,151);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(155,40,'Car',15,151);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(156,40,'Mini truck',16,152);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(157,40,'Tata ace',17,152);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(158,40,'Harvester',18,153);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(159,40,'Construction vehicles',19,153);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(160,40,'Crane',20,153);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(161,40,'Ambulance',21,153);









