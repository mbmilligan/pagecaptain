-- Name: users_owner_seq Type: SEQUENCE
--

CREATE SEQUENCE "users_owner_seq" start 1 increment 1;

-- Name: users Type: TABLE
--

CREATE TABLE "users" (
	"owner" integer DEFAULT nextval('"users_owner_seq"'::text) NOT NULL,
	"nick" text,
	"name" text,
	"address" text,
	"phone" text,
	"email" text,
	"contact" text,
	"password" text,
	constraint primary key ("owner")
);

-- Name: list Type: TABLE 
--

CREATE TABLE "list" (
	"index" smallint NOT NULL,
	"points" double precision,
	"type" smallint,
	"status" smallint,
	"description" text,
	"scoring" text,
	"notes" text,
	"owner" integer 
		REFERENCES users ("owner")
		ON UPDATE CASCADE
		ON DELETE SET NULL,
	"cost" double precision,
	constraint "list_pkey" Primary Key ("index")
);
