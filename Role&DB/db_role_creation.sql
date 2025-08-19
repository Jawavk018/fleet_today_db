   
-- step 1 ->  following way to open the terminal 

 	-- open setup folder and right click and press open in terminal 

-- step 2 -> enter following command
 
    	-- sudo su postgres 

           -- (or)

        -- sudo su - postgres

-- step 3 -> enter following command

    	-- psql

-- step 4 -> enter following command

	-- \i db_role_creation.sql;

--create role
-------------

CREATE ROLE "bus_admin" WITH LOGIN  PASSWORD 'bus123' SUPERUSER INHERIT CREATEDB CREATEROLE REPLICATION;


--create Database
-----------------

CREATE DATABASE bus_db
  WITH OWNER = "bus_admin"
       --ENCODING = 'UTF8'
       --TABLESPACE = pg_default
       --LC_COLLATE = 'en_US.utf8'
       --LC_CTYPE = 'en_US.utf8'
       CONNECTION LIMIT = 2000;


--drop role
-----------

-- DROP ROLE "bus_admin";


--drop database
---------------
-- DROP DATABASE bus_db;









