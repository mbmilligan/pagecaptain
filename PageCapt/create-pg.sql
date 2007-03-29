-- 
-- Create ScavHunt Database for PostgreSQL
-- 

CREATE TABLE Users (
	uid SERIAL,
	login varchar(16) NOT NULL UNIQUE,
	name text,
	address text,
	phone text,
	email text,
	contact text,
	password varchar(16),

	PRIMARY KEY (uid)
	);

CREATE INDEX user_login_idx ON Users(login);

CREATE TABLE List (
	inum smallint NOT NULL UNIQUE,
	points double precision,
	type smallint,
	status smallint,
	description text,
	scoring text,
	cost double precision,
	owner integer REFERENCES Users(uid)
		ON DELETE SET NULL
		ON UPDATE CASCADE,

	PRIMARY KEY (inum)
	);

CREATE INDEX list_owner_idx ON List(owner);

CREATE TABLE Tip (
	time timestamp 
		DEFAULT CURRENT_TIMESTAMP,
	class smallint,
	creator integer REFERENCES Users(uid)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	reference integer REFERENCES List(inum)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
	used smallint DEFAULT '0',
	key  varchar(16),
	data text
	);

CREATE INDEX tip_time_idx ON Tip(time);
