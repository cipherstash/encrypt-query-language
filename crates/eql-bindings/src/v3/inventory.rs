//! The `all()` inventory — every v3 domain payload type in `eql-domains::CATALOG`
//! order. Moved out of `mod.rs` so PR 4's emitter can own it: this hand-written
//! version is REPLACED by `eql-codegen` output (`// @generated`) at cutover
//! (Task 8). The architectural module doc + `pub mod` decls stay in the
//! hand-written `mod.rs`.

use std::marker::PhantomData;

use super::domain_type::DomainType;
use super::{bool, date, float4, float8, int2, int4, int8, numeric, text, timestamptz};

/// Every v3 domain type, in `eql-domains::CATALOG` order.
pub fn all() -> Vec<Box<dyn DomainType>> {
    vec![
        Box::new(PhantomData::<int4::Int4>),
        Box::new(PhantomData::<int4::Int4Eq>),
        Box::new(PhantomData::<int4::Int4OrdOre>),
        Box::new(PhantomData::<int4::Int4Ord>),
        Box::new(PhantomData::<int2::Int2>),
        Box::new(PhantomData::<int2::Int2Eq>),
        Box::new(PhantomData::<int2::Int2OrdOre>),
        Box::new(PhantomData::<int2::Int2Ord>),
        Box::new(PhantomData::<int8::Int8>),
        Box::new(PhantomData::<int8::Int8Eq>),
        Box::new(PhantomData::<int8::Int8OrdOre>),
        Box::new(PhantomData::<int8::Int8Ord>),
        Box::new(PhantomData::<date::Date>),
        Box::new(PhantomData::<date::DateEq>),
        Box::new(PhantomData::<date::DateOrdOre>),
        Box::new(PhantomData::<date::DateOrd>),
        Box::new(PhantomData::<timestamptz::Timestamptz>),
        Box::new(PhantomData::<timestamptz::TimestamptzEq>),
        Box::new(PhantomData::<timestamptz::TimestamptzOrdOre>),
        Box::new(PhantomData::<timestamptz::TimestamptzOrd>),
        Box::new(PhantomData::<numeric::Numeric>),
        Box::new(PhantomData::<numeric::NumericEq>),
        Box::new(PhantomData::<numeric::NumericOrdOre>),
        Box::new(PhantomData::<numeric::NumericOrd>),
        Box::new(PhantomData::<text::Text>),
        Box::new(PhantomData::<text::TextEq>),
        Box::new(PhantomData::<text::TextMatch>),
        Box::new(PhantomData::<text::TextOrdOre>),
        Box::new(PhantomData::<text::TextOrd>),
        Box::new(PhantomData::<text::TextSearch>),
        Box::new(PhantomData::<bool::Bool>),
        Box::new(PhantomData::<float4::Float4>),
        Box::new(PhantomData::<float4::Float4Eq>),
        Box::new(PhantomData::<float4::Float4OrdOre>),
        Box::new(PhantomData::<float4::Float4Ord>),
        Box::new(PhantomData::<float8::Float8>),
        Box::new(PhantomData::<float8::Float8Eq>),
        Box::new(PhantomData::<float8::Float8OrdOre>),
        Box::new(PhantomData::<float8::Float8Ord>),
    ]
}
