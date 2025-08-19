
--tyre
-------

insert into  portal.codes_hdr(codes_hdr_sno,code_type) values(23,'tyre_type_cd');

INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(74,23,'Tube Tyre',1);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(75,23,'Tubeless Tyre',2);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(76,23,'Cross Ply Tyre',3);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(77,23,'Radial Ply Tyre',4);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(78,23,'Bias Ply Tyre',5);


insert into  portal.codes_hdr(codes_hdr_sno,code_type) values(24,'tyre_usage_cd');

INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(79,24,'New Tyre',1);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(80,24,'Regrooving',2);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(81,24,'Repair',3);


insert into  portal.codes_hdr(codes_hdr_sno,code_type) values(25,'reason_status_cd');

INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(82,25,'puncher',1);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(83,25,'damaged',2);


insert into  portal.codes_hdr(codes_hdr_sno,code_type) values(28,'payment_mode_cd');

INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(105,28,'Online',1);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(106,28,'Offline',2);


insert into  portal.codes_hdr(codes_hdr_sno,code_type) values(27,'tyre_activity_type_cd');

INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(97,27,'Insert',1);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(98,27,'Remove',2);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(99,27,'Retired',3);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(100,27,'Rotation',4);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(101,27,'Pucher',5);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(102,27,'Busted',6);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(103,27,'Powder',7);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(104,27,'Stepny',8);


insert into  portal.codes_hdr(codes_hdr_sno,code_type) values(29,'tyre_size_cd');

INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(107,29,'385/65R22.5',1);
INSERT INTO  portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(108,29,'315/80R22.5',2);

INSERT INTO portal.codes_hdr(codes_hdr_sno,code_type) values(34,'tyre_model');
INSERT INTO portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(118,34,'CDTire',1);
INSERT INTO portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(119,34,'Dtire',2);
INSERT INTO portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(120,34,'FTire',3);
INSERT INTO portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(121,34,'SWIFT',4);

