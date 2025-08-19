create view waiting_approval_org AS (select * from operator.org o where ((o.org_status_cd = 20)));
create view waiting_approval_vehicle AS (select * from operator.vehicle v where ((v.kyc_status = 20)));
create view waiting_approval_driver AS (select * from driver.driver d where ((d.kyc_status = 20)));




CREATE EXTENSION IF NOT EXISTS cube;
CREATE EXTENSION IF NOT EXISTS earthdistance;
