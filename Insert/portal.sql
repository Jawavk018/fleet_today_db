
--create admin

  select * from portal.insert_user_profile(json_build_object('appUserSno',
		(select create_app_user->>'appUserSno' from portal.create_app_user('{"mobileNumber":"9790300667","status":"Active","role":"Admin","deviceId":"12345","timeZone":"Asia/Calcutta","password":"Apple123","confirmPassword":"Apple123"}')),
														   'firstName','Admin','lastName','Admin','mobileNumber','9790300667','genderCd',portal.get_enum_sno('{"cd_value":"Male","cd_type":"gender_cd"}')));


 
  select * from portal.insert_user_profile(json_build_object('appUserSno',
		(select create_app_user->>'appUserSno' from portal.create_app_user('{"mobileNumber":"9385940104","status":"Active","role":"Admin","deviceId":"12345","timeZone":"Asia/Calcutta","password":"Apple123","confirmPassword":"Apple123"}')),
														   'firstName','Admin','lastName','Admin','mobileNumber','9385940104','genderCd',portal.get_enum_sno('{"cd_value":"Male","cd_type":"gender_cd"}')));



 --select * from portal.create_app_user('{"mobileNumber":"9790300667","password":"bustoday","status":"Active","role":"Admin"}');

--select * from portal.signin('{"mobileNumber":"9790300667","deviceId":"12345","timeZone":"Asia/Calcutta"}');

--create menu

-- select * from portal.create_menu('{"appMenuSno":19,"title":"Operator Attendance","href":"","icon":"pencil-square-o","routerLink":"/operatorAttendance","hasSubMenu":false,
-- 	 "parentMenuSno":9,"roleCd":"{2}","target":""}');

select * from portal.create_menu('{"appMenuSno":1, "title":"Dashboard","href":"","icon":"tachometer","routerLink":"/bus-dashboard","hasSubMenu":false,
	 "parentMenuSno":0,"roleCd":"{1,2,3,4,5,127,128}","target":""}');
	 
select * from portal.create_menu('{"appMenuSno":2, "title":"Operator","href":"","icon":"user","routerLink":"/operator","hasSubMenu":false,
	 "parentMenuSno":0,"roleCd":"{2,5}","target":""}');
	  
select * from portal.create_menu('{"appMenuSno":3,"title":"Vehicle","href":"","icon":"bus","routerLink":"/registervehicle","hasSubMenu":false,
	 "parentMenuSno":0,"roleCd":"{2}","target":""}');
	 
select * from portal.create_menu('{"appMenuSno":4, "title":"Approval","href":"","icon":"check","routerLink":"/approval","hasSubMenu":false,
	 "parentMenuSno":0,"roleCd":"{1}","target":""}');	 
	 
select * from portal.create_menu('{"appMenuSno":5,"title":"Operators","href":"","icon":"user","routerLink":"/operatorlist","hasSubMenu":false,
	 "parentMenuSno":0,"roleCd":"{1}","target":""}');
	 

select * from portal.create_menu('{"appMenuSno":6, "title":"Route","href":"","icon":"route","routerLink":null,"hasSubMenu":true,
	 "parentMenuSno":0,"roleCd":"{2}","target":""}');

select * from portal.create_menu('{"appMenuSno":7, "title":"Location","href":"","icon":"map-marker","routerLink":"/location","hasSubMenu":false,
	 "parentMenuSno":6,"roleCd":"{1,2}","target":""}');
	
select * from portal.create_menu('{"appMenuSno":8,"title":"Single","href":"","icon":"route","routerLink":"/single","hasSubMenu":false,
	 "parentMenuSno":6,"roleCd":"{2}","target":""}');

-- select * from portal.create_menu('{"appMenuSno":9,"title":"Driver","href":"","icon":"user-circle-o","routerLink":"/driver","hasSubMenu":false,
-- 	 "parentMenuSno":6,"roleCd":"{2}","target":""}');
	 

-- select * from portal.create_menu('{"appMenuSno":10,"title":"Driver Activity","href":"","icon":"bars","routerLink":null,"hasSubMenu":true,
-- 	 "parentMenuSno":0,"roleCd":"{2}","target":""}');

-- select * from portal.create_menu('{"appMenuSno":11,"title":"Attendance","href":"","icon":"id-card-o","routerLink":"/busAttendance","hasSubMenu":false,
-- 	 "parentMenuSno":10,"roleCd":"{2}","target":""}');  

-- select * from portal.create_menu('{"appMenuSno":12,"title":"Fuel","href":"","icon":"tachometer","routerLink":"/busFuel","hasSubMenu":false,
-- 	 "parentMenuSno":10,"roleCd":"{2}","target":""}');

select * from portal.create_menu('{"appMenuSno":9,"title":"Driver Activity","href":"","icon":"bars","routerLink":null,"hasSubMenu":true,
	 "parentMenuSno":0,"roleCd":"{2}","target":""}');

select * from portal.create_menu('{"appMenuSno":10,"title":"Driver","href":"","icon":"user-circle-o","routerLink":"/driver","hasSubMenu":false,
	 "parentMenuSno":9,"roleCd":"{2}","target":""}');
	 
select * from portal.create_menu('{"appMenuSno":11,"title":"Attendance","href":"","icon":"id-card-o","routerLink":"/busAttendance","hasSubMenu":false,
	 "parentMenuSno":9,"roleCd":"{2}","target":""}');  

select * from portal.create_menu('{"appMenuSno":12,"title":"Fuel","href":"","icon":"tachometer","routerLink":"/busFuel","hasSubMenu":false,
	 "parentMenuSno":9,"roleCd":"{2}","target":""}');
	 

select * from portal.create_menu('{"appMenuSno":13,"title":"Booking","href":"","icon":"money","routerLink":null,"hasSubMenu":true,
	 "parentMenuSno":0,"roleCd":"{2}","target":""}');

select * from portal.create_menu('{"appMenuSno":14,"title":"View-booking","href":"","icon":"user","routerLink":"/view-booking","hasSubMenu":false,
	 "parentMenuSno":13,"roleCd":"{2}","target":""}');

select * from portal.create_menu('{"appMenuSno":15,"title":"Booking calendar","href":"","icon":"calendar","routerLink":"/reminder","hasSubMenu":false,
"parentMenuSno":13,"roleCd":"{2}","target":""}');


select * from portal.create_menu('{"appMenuSno":16, "title":"Tyre","href":"","icon":"dot-circle-o","routerLink":null,"hasSubMenu":true,
	 "parentMenuSno":0,"roleCd":"{2}","target":""}');


select * from portal.create_menu('{"appMenuSno":17,"title":"Tyres","href":"","icon":"life-ring","routerLink":"/tyre","hasSubMenu":false,
	 "parentMenuSno":16,"roleCd":"{2}","target":""}');

select * from portal.create_menu('{"appMenuSno":18,"title":"Manage Tyre","href":"","icon":"file-text-o","routerLink":"/managetyre",
	"hasSubMenu":false,"parentMenuSno":16,"roleCd":"{2}","target":""}');

-- select * from portal.create_menu('{"appMenuSno":19,"title":"View Tyre","href":"","icon":"folder-open","routerLink":"/viewtyre",
-- 	"hasSubMenu":false,"parentMenuSno":16,"roleCd":"{2}","target":""}');
	
select * from portal.create_menu('{"appMenuSno":19,"title":"Report","href":"","icon":"clock-o","routerLink":null,"hasSubMenu":true,
	 "parentMenuSno":0,"roleCd":"{2}","target":""}');

select * from portal.create_menu('{"appMenuSno":20,"title":"Bus Report","href":"","icon":"bus","routerLink":"/bus-report","hasSubMenu":false,
	 "parentMenuSno":19,"roleCd":"{2}","target":""}');

select * from portal.create_menu('{"appMenuSno":21,"title":"Fuel Report","href":"","icon":"tachometer","routerLink":"/fuel-report",
	"hasSubMenu":false,"parentMenuSno":19,"roleCd":"{2}","target":""}');

select * from portal.create_menu('{"appMenuSno":22,"title":"Driver Report","href":"","icon":"users","routerLink":"/driver-report",
	"hasSubMenu":false,"parentMenuSno":19,"roleCd":"{2}","target":""}');

select * from portal.create_menu('{"appMenuSno":23,"title":"Vehicles","href":"","icon":"bus","routerLink":"/vehiclelist","hasSubMenu":false,
	 "parentMenuSno":0,"roleCd":"{1}","target":""}');

select * from portal.create_menu('{"appMenuSno":24,"title":"Drivers","href":"","icon":"user-circle-o","routerLink":"/driverlist","hasSubMenu":false,
	"parentMenuSno":0,"roleCd":"{1}","target":""}');	

select * from portal.create_menu('{"appMenuSno":25, "title":"Notification","href":"","icon":"bell","routerLink":"/notification","hasSubMenu":false,
	 "parentMenuSno":0,"roleCd":"{1,2}","target":""}');		
	

select * from portal.create_menu('{"appMenuSno":26, "title":"Assign driver vehicle","href":"","icon":"address-card","routerLink":"/assign-driver","hasSubMenu":false,
	 "parentMenuSno":9,"roleCd":"{2}","target":""}');		


select * from portal.create_menu('{"appMenuSno":27, "title":"Menu Permission","href":"","icon":"key","routerLink":"/menu-permission","hasSubMenu":false,
	 "parentMenuSno":0,"roleCd":"{2}","target":""}');



select * from portal.create_menu('{"appMenuSno":28, "title":"User","href":"","icon":"user","routerLink":null,"hasSubMenu":true,
	 "parentMenuSno":0,"roleCd":"{1,2,3,4,127,128}","target":""}');


select * from portal.create_menu('{"appMenuSno":29, "title":"Find Bus","href":"","icon":"bus","routerLink":"/find-bus","hasSubMenu":false,
	 "parentMenuSno":28,"roleCd":"{1,2,3,4,127,128}","target":""}');


select * from portal.create_menu('{"appMenuSno":30, "title":"Rent Bus","href":"","icon":"user","routerLink":"/rent-bus","hasSubMenu":false,
	 "parentMenuSno":28,"roleCd":"{1,2,3,4,127,128}","target":""}');


select * from portal.create_menu('{"appMenuSno":31, "title":"Trip Calculate","href":"","icon":"route","routerLink":"/trip-calculate","hasSubMenu":false,
	 "parentMenuSno":28,"roleCd":"{1,2,3,4,127,128}","target":""}');
	 
	 
	 
select * from portal.create_menu('{"appMenuSno":32, "title":"Find Bus","href":"","icon":"bus","routerLink":"/find-bus","hasSubMenu":false,
	 "parentMenuSno":0,"roleCd":"{5}","target":""}');

select * from portal.create_menu('{"appMenuSno":33, "title":"Rent Bus","href":"","icon":"user","routerLink":"/rent-bus","hasSubMenu":false,
	 "parentMenuSno":0,"roleCd":"{5}","target":""}');

select * from portal.create_menu('{"appMenuSno":34, "title":"Trip Calculate","href":"","icon":"route","routerLink":"/trip-calculate","hasSubMenu":false,
	 "parentMenuSno":0,"roleCd":"{5}","target":""}');


select * from portal.create_menu('{"appMenuSno":35,"title":"Jobs","href":"","icon":"briefcase","routerLink":null,"hasSubMenu":true,
	 "parentMenuSno":0,"roleCd":"{2}","target":""}');
	 
select * from portal.create_menu('{"appMenuSno":36,"title":"Job Search","href":"","icon":"search-plus","routerLink":"/job-search","hasSubMenu":false,
	 "parentMenuSno":35,"roleCd":"{2}","target":""}');	 
	 
select * from portal.create_menu('{"appMenuSno":37,"title":"Job Post","href":"","icon":"user-plus","routerLink":"/job-post","hasSubMenu":false,
	 "parentMenuSno":35,"roleCd":"{2}","target":""}');	
