insert into portal.codes_hdr(codes_hdr_sno,code_type) values(1,'role_cd');

INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(1,1,'Admin',1);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(2,1,'Operator',2,2);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(3,1,'Sales/E-Commerce',3);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(4,1,'Service Provider',4);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(5,1,'User',5);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(6,1,'Driver',6);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(127,1,'Operator Admin',7,7);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO,filter_1) VALUES(128,1,'Manager',8,8);


insert into  portal.codes_hdr(codes_hdr_sno,code_type) values(2,'user_status_cd');

INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(7,2,'Active',1);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(8,2,'InActive',2);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(9,2,'Blocked',3);

insert into  portal.codes_hdr(codes_hdr_sno,code_type) values(3,'otp_expire_time');

INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,filter_1,SEQNO) VALUES(10,3,'5','true',1);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,filter_1,SEQNO) VALUES(11,3,'10','false',2);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,filter_1,SEQNO) VALUES(12,3,'15','false',3);

insert into  portal.codes_hdr(codes_hdr_sno,code_type) values(4,'gender_cd');

INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(13,4,'Male',1);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(14,4,'Female',2);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(15,4,'Third Gender',3);

insert into  portal.codes_hdr(codes_hdr_sno,code_type) values(5,'device_type_cd');

INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(16,5,'Android',1);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(17,5,'Ios',2);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(18,5,'Web',3);

insert into  portal.codes_hdr(codes_hdr_sno,code_type) values(22,'return_type_cd');

INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(72,22,'One Way Trip',1);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(73,22,'Rounded Trip',2);



