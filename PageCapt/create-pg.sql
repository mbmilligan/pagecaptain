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
	type[] smallint,
	status smallint,
	description text,
	scoring text,
	cost double,
	owner integer REFERENCES User(uid)
		ON DELETE SET NULL
		ON UPDATE CASCADE,

	PRIMARY KEY (inum)
	);

CREATE INDEX list_owner_idx ON List(owner);

CREATE TABLE Tip (
	time timestamp 
		DEFAULT CURRENT_TIMESTAMP,
	class smallint,
	reference integer,
	data text
	);

CREATE INDEX tip_time_idx ON Tip(time);
