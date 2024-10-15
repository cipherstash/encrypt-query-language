from sqlalchemy.orm import DeclarativeBase, mapped_column, Mapped, sessionmaker
from sqlalchemy.types import TypeDecorator, String
from sqlalchemy import create_engine, select, text
from sqlalchemy.exc import IntegrityError
import json

import sys
import os

from cs_types import CsText, CsJsonb

class CsTypeDecorator(TypeDecorator):
    def __init__(self, table_name, column_name):
        super().__init__()
        self.table_name = table_name
        self.column_name = column_name

    def process_bind_param(self, value, dialect):
        if value is not None:
            value_dict = {
                "k": "pt",
                "p": value,
                "i": {
                    "t": self.table_name,
                    "c": self.column_name
                },
                "v": 1,
            }
            value = json.dumps(value_dict)
        return value

    def process_result_value(self, value, dialect):
        if value is None:
            return None
        return value['p']


class EncryptedUtf8Str(CsTypeDecorator):
    impl = String

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)


class EncryptedJsonb(CsTypeDecorator):
    impl = String

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

class BaseModel(DeclarativeBase):
    pass

class Example(BaseModel):
    __tablename__ = "examples"

    id: Mapped[int] = mapped_column(primary_key=True)
    encrypted_utf8_str = mapped_column(EncryptedUtf8Str("examples", "encrypted_utf8_str"))
    encrypted_jsonb = mapped_column(EncryptedJsonb("examples", "encrypted_jsonb"))

    def __init__(self, utf8_str=None, jsonb=None):
        self.encrypted_utf8_str = utf8_str
        self.encrypted_jsonb = jsonb

    def __repr__(self):
        return f"<Example(id={self.id}, encrypted_utf8_str={self.encrypted_utf8_str}, encrypted_jsonb={self.encrypted_jsonb})>"
