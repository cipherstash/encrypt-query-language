-- REQUIRE: src/schema.sql

--! @file src/ste_vec/types.sql
--! @brief Domain type for individual STE-vec entries
--!
--! Defines `eql_v2.ste_vec_entry` as a DOMAIN over `jsonb` constrained to the
--! shape of a single element inside an `sv` array — a JSON object that
--! carries at minimum a selector field (`s`). This is the type returned by
--! the `->` operator on `eql_v2_encrypted` (a single sv element extracted by
--! selector) and the type accepted by sv-element extractors such as
--! `eql_v2.ore_cllw(eql_v2.ste_vec_entry)` and
--! `eql_v2.hmac_256(eql_v2.ste_vec_entry)`.
--!
--! Why a separate type. Before #219, the `(eql_v2_encrypted)` overloads of
--! sv-element extractors read fields like `oc` off the root `data` jsonb,
--! which is misleading: a root `EncryptedPayload` or `SteVecPayload` (the
--! shapes that an actual `eql_v2_encrypted` column value carries) never has
--! `oc` at the root. The previous pattern only worked because the `->`
--! operator merged ste-vec entry fields into a fake root-shaped payload
--! before the extractor ran. This domain type makes the distinction
--! explicit: `eql_v2_encrypted` is the root shape; `eql_v2.ste_vec_entry`
--! is the per-entry shape; extractors are typed accordingly.
--!
--! @note The CHECK constraint reflects the cipherstash-suite emission
--!       contract:
--!         - `s` (selector — column-name HMAC) and `c` (ciphertext) are
--!           emitted on every sv element.
--!         - Each sv element carries **exactly one** of `hm` (HMAC-256, for
--!           hash-equality queries) or `oc` (CLLW ORE, for ordered queries)
--!           — they are mutually exclusive. A given selector / field is
--!           configured for one mode or the other; the crypto layer emits
--!           the corresponding term and only that term.
--!       Other fields (`a` for array marker, etc.) are allowed but not
--!       required.
--!
--! @see src/operators/->.sql
--! @see src/ore_cllw/functions.sql
--! @see src/hmac_256/functions.sql
CREATE DOMAIN eql_v2.ste_vec_entry AS jsonb
  CHECK (
    jsonb_typeof(VALUE) = 'object'
    AND VALUE ? 's'
    AND VALUE ? 'c'
    AND (VALUE ? 'hm') <> (VALUE ? 'oc')
  );
