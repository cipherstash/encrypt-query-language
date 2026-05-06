//! Index type constants for EQL tests
//!
//! Prevents typos in index type strings across test files

/// HMAC-256 index type
pub const HMAC: &str = "hm";

/// Blake3 index type
pub const BLAKE3: &str = "b3";

/// ORE 64-bit index type
pub const ORE64: &str = "ore64";

/// ORE CLLW U64 8-byte index type
pub const ORE_CLLW_U64_8: &str = "ore_cllw_u64_8";

/// ORE CLLW Variable 8-byte index type
pub const ORE_CLLW_VAR_8: &str = "ore_cllw_var_8";

/// ORE Block U64 8-byte 256-bit index type
pub const ORE_BLOCK_U64_8_256: &str = "ore_block_u64_8_256";
