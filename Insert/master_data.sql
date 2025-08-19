
--states

select * from master_data.create_state('{"stateName":"Tamil Nadu"}');
select * from master_data.create_state('{"stateName":"Andhra Pradesh"}');
select * from master_data.create_state('{"stateName":"Arunachal Pradesh"}');
select * from master_data.create_state('{"stateName":"Assam"}');
select * from master_data.create_state('{"stateName":"Bihar"}');
select * from master_data.create_state('{"stateName":"Chhattisgarh"}');
select * from master_data.create_state('{"stateName":"Goa"}');
select * from master_data.create_state('{"stateName":"Gujarat"}');
select * from master_data.create_state('{"stateName":"Haryana"}');
select * from master_data.create_state('{"stateName":"Himachal Pradesh"}');
select * from master_data.create_state('{"stateName":"Jharkhand"}');
select * from master_data.create_state('{"stateName":"Karnataka"}');
select * from master_data.create_state('{"stateName":"Kerala"}');
select * from master_data.create_state('{"stateName":"Madhya Pradesh"}');
select * from master_data.create_state('{"stateName":"Maharashtra"}');
select * from master_data.create_state('{"stateName":"Manipur"}');
select * from master_data.create_state('{"stateName":"Meghalaya"}');
select * from master_data.create_state('{"stateName":"Mizoram"}');
select * from master_data.create_state('{"stateName":"Nagaland"}');
select * from master_data.create_state('{"stateName":"Odisha"}');
select * from master_data.create_state('{"stateName":"Punjab"}');
select * from master_data.create_state('{"stateName":"Rajasthan"}');
select * from master_data.create_state('{"stateName":"Sikkim"}');
select * from master_data.create_state('{"stateName":"Telangana"}');
select * from master_data.create_state('{"stateName":"Tripura"}');
select * from master_data.create_state('{"stateName":"Uttar Pradesh"}');
select * from master_data.create_state('{"stateName":"Uttarakhand"}');
select * from master_data.create_state('{"stateName":"West Bengal"}');


--district

select * from master_data.create_district(
	json_build_object('districtName','Ariyalur',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Chengalpattu',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Chennai',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Coimbatore',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Cuddalore',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Dharmapuri',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Dindigul',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Erode',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Kallakurichi',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Kanchipuram',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Kanyakumari',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Karur',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Krishnagiri',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Madurai',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Mayiladuthurai',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Nagapattinam',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Nilgiris',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Namakkal',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Perambalur',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Pudukkottai',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Ramanathapuram',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Ranipet',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Salem',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Sivaganga',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Tenkasi',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Tirupur',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Tiruchirappalli',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Theni',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Tirunelveli',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Thanjavur',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Thoothukudi',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Tirupattur',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Tiruvallur',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Tiruvarur',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Tiruvannamalai',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Vellore',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Viluppuram',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));
select * from master_data.create_district(
	json_build_object('districtName','Virudhunagar',
					  'stateSno',(select state_sno from master_data.state where upper(state_name) = upper('Tamil Nadu')
		)));


--city


--chennai

-- select * from master_data.create_city(
-- 	json_build_object('cityName','Chennai North',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Chennai South',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Chennai Central',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','	Sriperumbudur',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Maduravoyal',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Ambattur',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Madhavaram',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Tiruvottiyur',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','	Radhakrishnan Nagar',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Perambur',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Kolathur',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Villivakkam',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Thiru. Vi. Ka. Nagar',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Egmore',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Royapuram',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Harbour',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Chepauk-Thiruvallikeni',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Thousand Lights',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Anna Nagar',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Virugampakkam',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Saidapet',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Thiyagaraya Nagar',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Mylapore',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Velachery',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Sholinganallur',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Alandur',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Chennai')
-- 		)));


-- --salem

-- select * from master_data.create_city(
-- 	json_build_object('cityName','Attur',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Salem')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Gangavalli',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Salem')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Idappadi',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Salem')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Kadayampatti',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Salem')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Mettur',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Salem')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Omalur',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Salem')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Sankagiri',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Salem')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Vazhapadi',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Salem')
-- 		)));
-- select * from master_data.create_city(
-- 	json_build_object('cityName','Yercaud',
-- 					  'districtSno',(select district_sno from master_data.district where upper(district_name) = upper('Salem')
-- 		)));

