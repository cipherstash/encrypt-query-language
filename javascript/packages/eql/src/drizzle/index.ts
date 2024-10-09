import { sql } from "drizzle-orm";
import {
	type PgTable,
	getTableConfig,
	type PgColumn,
} from "drizzle-orm/pg-core";
import { eqlPayload } from "../";

export const cs_match_v1 = (
	table: PgTable,
	column: PgColumn,
	plaintext: string,
) => {
	const tableName = getTableConfig(table)?.name;
	const columnName = column.name;

	const payload = JSON.stringify(
		eqlPayload({
			plaintext,
			table: tableName,
			column: columnName,
		}),
	);

	return sql`cs_match_v1(${column}) @> cs_match_v1(${payload})`;
};
