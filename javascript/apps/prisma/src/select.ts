import { prisma } from './db'

const allUsers = await prisma.user.findMany()

console.log('[INFO] All emails have been decrypted by CipherStash Proxy')
console.log(
  'Emails:',
  JSON.stringify(
    allUsers.map((row) => row.email_encrypted?.p),
    null,
    2,
  ),
)

await prisma.$disconnect()
process.exit(0)
