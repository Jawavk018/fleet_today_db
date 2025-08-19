INSERT INTO portal.codes_hdr(codes_hdr_sno,code_type) values(34,'tyre_model');
INSERT INTO portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(118,34,'CDTire',1);
INSERT INTO portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(119,34,'Dtire',2);
INSERT INTO portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(120,34,'FTire',3);
INSERT INTO portal.CODES_DTL(codes_dtl_sno,CODES_HDR_SNO,CD_VALUE,SEQNO) VALUES(121,34,'SWIFT',4);



alter table tyre.tyre add column if not exists tyre_company_name text,add column if not exists tyre_model smallint,
add foreign key(tyre_model) REFERENCES portal.codes_dtl(codes_dtl_sno);
