drop schema if exists config cascade;
drop schema if exists portal cascade;
drop schema if exists master_data cascade;
drop schema if exists media cascade;
drop schema if exists operator cascade;
drop schema if exists stage_carriage cascade;
drop schema if exists driver cascade;
drop schema if exists rent cascade;
drop schema if exists notification cascade;
drop schema if exists tyre cascade;


create schema if not exists config 
AUTHORIZATION bus_admin;

create schema if not exists portal 
AUTHORIZATION bus_admin;

create schema if not exists master_data 
AUTHORIZATION bus_admin;

create schema if not exists media 
AUTHORIZATION bus_admin;

create schema if not exists operator 
AUTHORIZATION bus_admin;

create schema if not exists stage_carriage 
AUTHORIZATION bus_admin;

create schema if not exists driver
AUTHORIZATION bus_admin;

create schema if not exists rent
AUTHORIZATION bus_admin;

create schema if not exists notification
AUTHORIZATION bus_admin;

create schema if not exists tyre
AUTHORIZATION bus_admin;

create EXTENSION if not exists citext;