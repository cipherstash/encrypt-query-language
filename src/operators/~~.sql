-- REQUIRE: src/schema.sql
-- REQUIRE: src/encrypted/types.sql
-- REQUIRE: src/bloom_filter/types.sql
-- REQUIRE: src/bloom_filter/functions.sql

--! @brief Pattern matching helper using bloom filters
--! @internal
--!
--! Internal helper for LIKE-style pattern matching on encrypted values.
--! Uses bloom filter index terms to test substring containment without decryption.
--! Requires 'match' index configuration on the column.
--!
--! @param a eql_v2_encrypted Haystack (value to search in)
--! @param b eql_v2_encrypted Needle (pattern to search for)
--! @return Boolean True if bloom filter of a contains bloom filter of b
--!
--! @see eql_v2."~~"
--! @see eql_v2.bloom_filter
--! @see eql_v2.add_search_config
CREATE FUNCTION eql_v2.like(a eql_v2_encrypted, b eql_v2_encrypted)
RETURNS boolean AS $$
  SELECT eql_v2.bloom_filter(a) @> eql_v2.bloom_filter(b);
$$ LANGUAGE SQL;

--! @brief Case-insensitive pattern matching helper
--! @internal
--!
--! Internal helper for ILIKE-style case-insensitive pattern matching.
--! Case sensitivity is controlled by index configuration (token_filters with downcase).
--! This function has same implementation as like() - actual case handling is in index terms.
--!
--! @param a eql_v2_encrypted Haystack (value to search in)
--! @param b eql_v2_encrypted Needle (pattern to search for)
--! @return Boolean True if bloom filter of a contains bloom filter of b
--!
--! @note Case sensitivity depends on match index token_filters configuration
--! @see eql_v2."~~"
--! @see eql_v2.add_search_config
CREATE FUNCTION eql_v2.ilike(a eql_v2_encrypted, b eql_v2_encrypted)
RETURNS boolean AS $$
  SELECT eql_v2.bloom_filter(a) @> eql_v2.bloom_filter(b);
$$ LANGUAGE SQL;

--! @brief LIKE operator for encrypted values (pattern matching)
--!
--! Implements the ~~ (LIKE) operator for substring/pattern matching on encrypted
--! text using bloom filter index terms. Enables WHERE col LIKE '%pattern%' queries
--! without decryption. Requires 'match' index configuration on the column.
--!
--! Pattern matching uses n-gram tokenization configured in match index. Token length
--! and filters affect matching behavior.
--!
--! @param a eql_v2_encrypted Haystack (encrypted text to search in)
--! @param b eql_v2_encrypted Needle (encrypted pattern to search for)
--! @return Boolean True if a contains b as substring
--!
--! @example
--! -- Search for substring in encrypted email
--! SELECT * FROM users
--! WHERE encrypted_email ~~ '%@example.com%'::text::eql_v2_encrypted;
--!
--! -- Pattern matching on encrypted names
--! SELECT * FROM customers
--! WHERE encrypted_name ~~ 'John%'::text::eql_v2_encrypted;
--!
--! @brief SQL LIKE operator (~~ operator) for encrypted text pattern matching
--!
--! @param a eql_v2_encrypted Left operand (encrypted value)
--! @param b eql_v2_encrypted Right operand (encrypted pattern)
--! @return boolean True if pattern matches
--!
--! @note Requires match index: eql_v2.add_search_config(table, column, 'match')
--! @see eql_v2.like
--! @see eql_v2.add_search_config
CREATE FUNCTION eql_v2."~~"(a eql_v2_encrypted, b eql_v2_encrypted)
  RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v2.like(a, b);
  END;
$$ LANGUAGE plpgsql;

CREATE OPERATOR ~~(
  FUNCTION=eql_v2."~~",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=eql_v2_encrypted,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

--! @brief Case-insensitive LIKE operator (~~*)
--!
--! Implements ~~* (ILIKE) operator for case-insensitive pattern matching.
--! Case handling depends on match index token_filters configuration (use downcase filter).
--! Same implementation as ~~, with case sensitivity controlled by index configuration.
--!
--! @param a eql_v2_encrypted Haystack
--! @param b eql_v2_encrypted Needle
--! @return Boolean True if a contains b (case-insensitive)
--!
--! @note Configure match index with downcase token filter for case-insensitivity
--! @see eql_v2."~~"
CREATE OPERATOR ~~*(
  FUNCTION=eql_v2."~~",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=eql_v2_encrypted,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

--! @brief LIKE operator for encrypted value and JSONB
--!
--! Overload of ~~ operator accepting JSONB on the right side. Automatically
--! casts JSONB to eql_v2_encrypted for bloom filter pattern matching.
--!
--! @param a eql_v2_encrypted Haystack (encrypted value)
--! @param b JSONB Needle (will be cast to eql_v2_encrypted)
--! @return Boolean True if a contains b as substring
--!
--! @example
--! SELECT * FROM users WHERE encrypted_email ~~ '%gmail%'::jsonb;
--!
--! @see eql_v2."~~"(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2."~~"(a eql_v2_encrypted, b jsonb)
  RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v2.like(a, b::eql_v2_encrypted);
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR ~~(
  FUNCTION=eql_v2."~~",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=jsonb,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

CREATE OPERATOR ~~*(
  FUNCTION=eql_v2."~~",
  LEFTARG=eql_v2_encrypted,
  RIGHTARG=jsonb,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

--! @brief LIKE operator for JSONB and encrypted value
--!
--! Overload of ~~ operator accepting JSONB on the left side. Automatically
--! casts JSONB to eql_v2_encrypted for bloom filter pattern matching.
--!
--! @param a JSONB Haystack (will be cast to eql_v2_encrypted)
--! @param b eql_v2_encrypted Needle (encrypted pattern)
--! @return Boolean True if a contains b as substring
--!
--! @example
--! SELECT * FROM users WHERE 'test@example.com'::jsonb ~~ encrypted_pattern;
--!
--! @see eql_v2."~~"(eql_v2_encrypted, eql_v2_encrypted)
CREATE FUNCTION eql_v2."~~"(a jsonb, b eql_v2_encrypted)
  RETURNS boolean
AS $$
  BEGIN
    RETURN eql_v2.like(a::eql_v2_encrypted, b);
  END;
$$ LANGUAGE plpgsql;


CREATE OPERATOR ~~(
  FUNCTION=eql_v2."~~",
  LEFTARG=jsonb,
  RIGHTARG=eql_v2_encrypted,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);

CREATE OPERATOR ~~*(
  FUNCTION=eql_v2."~~",
  LEFTARG=jsonb,
  RIGHTARG=eql_v2_encrypted,
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES,
  MERGES
);


-- -----------------------------------------------------------------------------
