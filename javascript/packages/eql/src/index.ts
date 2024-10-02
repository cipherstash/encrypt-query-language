export * from "./cs_encrypted_v1";
import type { CsEncryptedV1Schema } from "./cs_encrypted_v1";

type EqlPayload = {
	plaintext: string;
	table: string;
	column: string;
	version?: number;
	schemaVersion?: number;
};

export const eqlPayload = ({
	plaintext,
	table,
	column,
	version = 1,
}: EqlPayload): CsEncryptedV1Schema => {
	return {
		v: version,
		s: 1,
		k: "pt",
		p: plaintext,
		i: {
			t: table,
			c: column,
		},
	};
};

export const getPlaintext = (
	payload: CsEncryptedV1Schema | null,
): string | undefined => {
	if (payload?.k === "pt") {
		return payload.p;
	}
	return undefined;
};

export const getCiphertext = (
	payload: CsEncryptedV1Schema | null,
): string | undefined => {
	if (payload?.k === "ct") {
		return payload.c;
	}
	return undefined;
};
