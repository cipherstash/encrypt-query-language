import { getEmailArg } from '@cipherstash-jseql-examples/utils'
import { cs_match_v1 } from '@cipherstash/jseql/drizzle'
import { getPlaintext } from '@cipherstash/jseql'
import { db } from './db'
import { users } from './schema'

const email = getEmailArg({
  required: false,
})

const sql = db
  .select({
    email: users.email_encrypted,
  })
  .from(users)

if (email) {
  sql.where(cs_match_v1(users, users.email_encrypted, email))
}

const sqlResult = sql.toSQL()
console.log('[INFO] SQL statement:', sqlResult)

const data = await sql.execute()
console.log('[INFO] All emails have been decrypted by CipherStash Proxy')
console.log(
  'Emails:',
  JSON.stringify(
    data.map((row) => row.email && getPlaintext(row.email)),
    null,
    2,
  ),
)

process.exit(0)
