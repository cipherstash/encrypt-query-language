from sqlalchemy.orm import DeclarativeBase, mapped_column, Mapped, sessionmaker
from sqlalchemy.types import TypeDecorator, String, Integer, Date, Boolean, Float
from sqlalchemy import create_engine, select, text
from sqlalchemy.exc import IntegrityError
import json

import sys
import os

class CsTypeDecorator(TypeDecorator):
    def __init__(self, table_name, column_name):
        super().__init__()
        self.table_name = table_name
        self.column_name = column_name

    def process_bind_param(self, value, dialect):
        if value is not None:
            value_dict = {
                "k": "pt",
                "p": str(value),
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

class EncryptedInt(CsTypeDecorator):
    impl = String

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

class EncryptedBoolean(CsTypeDecorator):
    impl = String

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def process_bind_param(self, value, dialect):
        if value is not None:
            value = str(value).lower()
        return super().process_bind_param(value, dialect)

class EncryptedDate(CsTypeDecorator):
    impl = String

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

class EncryptedFloat(CsTypeDecorator):
    impl = String

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

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
    encrypted_int = mapped_column(EncryptedInt(__tablename__, "encrypted_int"))
    encrypted_boolean = mapped_column(EncryptedBoolean(__tablename__, "encrypted_boolean"))
    encrypted_date = mapped_column(EncryptedDate(__tablename__, "encrypted_date"))
    encrypted_float = mapped_column(EncryptedFloat(__tablename__, "encrypted_float"))
    encrypted_utf8_str = mapped_column(EncryptedUtf8Str(__tablename__, "encrypted_utf8_str"))
    encrypted_jsonb = mapped_column(EncryptedJsonb(__tablename__, "encrypted_jsonb"))

    def __init__(self, e_utf8_str=None, e_jsonb=None, e_int=None, e_float=None, e_date=None, e_bool=None):
        self.encrypted_utf8_str = e_utf8_str
        self.encrypted_jsonb = e_jsonb
        self.encrypted_int = e_int
        self.encrypted_float = e_float
        self.encrypted_date = e_date
        self.encrypted_boolean = e_bool

    def __repr__(self):
        return f"<Example(id={self.id}, encrypted_utf8_str={self.encrypted_utf8_str}, encrypted_jsonb={self.encrypted_jsonb}, encrypted_int={self.encrypted_int}, encrypted_float={self.encrypted_float}, encrypted_date={self.encrypted_date}, encrypted_boolean={self.encrypted_boolean})>"
