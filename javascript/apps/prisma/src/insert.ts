import { parseArgs } from 'node:util'
import { eqlPayload } from '@cipherstash/eql'
import { prisma } from './db'
import type { InputJsonValue } from '@prisma/client/runtime/library'

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

await prisma.user.create({
  data: {
    email,
    email_encrypted: eqlPayload({
      plaintext: email,
      table: 'users',
      column: 'email_encrypted',
    }),
  },
})

console.log(
  "[INFO] You've inserted a new user with an encrypted email from the plaintext",
  email,
)
process.exit(0)
