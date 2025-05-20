CREATE TABLE IF NOT EXISTS "users" (
	"id" serial PRIMARY KEY NOT NULL,
	"email" varchar,
	"email_encrypted" "cs_encrypted_v2",
	CONSTRAINT "users_email_unique" UNIQUE("email")
);
