-- 
-- Create ScavHunt Database for PostgreSQL
-- 

CREATE TABLE User (
	uid SERIAL,
	login varchar(16) NOT NULL, UNIQUE,
	name varchar(32),
	address text,
	phone text,
	email text,
	contact text,
	password varchar(16),

	PRIMARY KEY (uid)
	);

CREATE INDEX user_login_idx ON User(login);

CREATE TABLE List (
	inum smallint NOT NULL, UNIQUE,
	points double,
	type smallint,
	status smallint,
	description text,
	scoring text,
	cost double,