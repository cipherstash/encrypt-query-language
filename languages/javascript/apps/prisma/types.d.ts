import type { CsEncryptedV1Schema } from "@cipherstash/eql";

declare global {
	namespace PrismaJson {
		type CsEncryptedType = CsEncryptedV1Schema;
	}
}
