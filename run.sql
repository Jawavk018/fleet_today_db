--connect
---------
--sudo su postgres

--psql -h localhost -p 5432 -U bus_admin bus_db;

-- bus123

-- \i run.sql;


--schema creation
------------------

\i Schemas/Schema.sql;


--tables creation
-----------------
\i Tables/Portal.sql;

\i Tables/Config.sql;

\i Tables/Master.sql;

\i Tables/Media.sql;

\i Tables/Operator.sql;

\i Tables/StageCarriage.sql;

\i Tables/driver.sql;

\i Tables/rent.sql;

\i Tables/Notification.sql;

\i Tables/tyre.sql;

---static data
---------------

\i StaticData/Portal.sql;

\i StaticData/Operator.sql;

\i StaticData/driver.sql;

\i StaticData/tyre.sql;

\i StaticData/notification.sql;

\i StaticData/Master.sql;




--functions
-------------

\i Functions/Config.sql;

\i Functions/Portal.sql;

\i Functions/Operator.sql;

\i Functions/Media.sql;

\i Functions/Master.sql;

\i Functions/driver.sql;

\i Functions/rent.sql;

\i Functions/Notification.sql;

\i Functions/tyre.sql;


---insert

---------

\i Insert/config.sql;

\i Insert/portal.sql;

\i Insert/master_data.sql;


--statement
------------

\i statement/viewStatement.sql;




