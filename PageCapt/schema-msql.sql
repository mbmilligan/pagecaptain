-- Name: users Type: TABLE
--

CREATE TABLE users (
	owner integer NOT NULL AUTO_INCREMENT,
	nick varchar(20),
	name varchar(128),
	address varchar(128),
	phone varchar(20),
	email varchar(50),
	contact varchar(255),
	password varchar(20),
	PRIMARY KEY (owner),
	UNIQUE INDEX (nick)
);

-- Name: list Type: TABLE 
--
-- Note that Postgres-style referential contraints do
-- not work in MySQL.  Will have to code support by
-- hand before UIDs can change safely (they shouldn't
-- anyway).

-- We also have to change "index" to something else,
-- as it is a reserved keyword here.  Boo!

CREATE TABLE list (
	index smallint NOT NULL,
	points double,
	type smallint,
	status smallint,
	description text,
	scoring text,
	notes text,
	owner integer,
	cost double,
	PRIMARY KEY (index),
	INDEX (type),
	INDEX (status),
	INDEX (owner)
);
