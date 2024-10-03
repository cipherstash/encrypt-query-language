import { parseArgs } from 'node:util'
import { eqlPayload } from '@cipherstash/eql'
import { db } from './db'
import { users } from './schema'

const { values, positionals } = parseArgs({
  args: Bun.argv,
  options: {
    email: {
      type: 'string',
    },
  },
  strict: true,
  allowPositionals: true,
})

const email = values.email

if (!email) {
  throw new Error('[ERROR] the email command line argument is required')
}

await db
  .insert(users)
  .values({
    email,
    email_encrypted: eqlPayload({
      plaintext: email,
      table: 'users',
      column: 'email_encrypted',
    }),
  })
  .execute()

console.log(
  "[INFO] You've inserted a new user with an encrypted email from the plaintext",
  email,
)
process.exit(0)
