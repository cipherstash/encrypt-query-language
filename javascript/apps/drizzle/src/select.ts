import { getPlaintext } from "@cipherstash/eql";
import { users } from "./schema";
import { db } from "./db";

const sqlResult = db
	.select({
		email: users.email_encrypted,
	})
	.from(users)
	.toSQL();

const data = await db.select().from(users).execute();

console.log("[INFO] SQL statement:", sqlResult.sql);
console.log("[INFO] All emails have been decrypted by CipherStash Proxy");
console.log(
	"Emails:",
	JSON.stringify(
		data.map((row) => getPlaintext(row.email_encrypted)),
		null,
		2,
	),
);
process.exit(0);
