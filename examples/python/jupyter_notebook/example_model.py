from sqlalchemy.orm import mapped_column, Mapped
from eqlpy.eqlalchemy import *

class Example(BaseModel):
    __tablename__ = "examples"

    id: Mapped[int] = mapped_column(primary_key=True)
    encrypted_int = mapped_column(EncryptedInt(__tablename__, "encrypted_int"))
    encrypted_boolean = mapped_column(
        EncryptedBoolean(__tablename__, "encrypted_boolean")
    )
    encrypted_date = mapped_column(EncryptedDate(__tablename__, "encrypted_date"))
    encrypted_float = mapped_column(EncryptedFloat(__tablename__, "encrypted_float"))
    encrypted_utf8_str = mapped_column(
        EncryptedUtf8Str(__tablename__, "encrypted_utf8_str")
    )
    encrypted_jsonb = mapped_column(EncryptedJsonb(__tablename__, "encrypted_jsonb"))

    def __init__(
        self,
        e_utf8_str=None,
        e_jsonb=None,
        e_int=None,
        e_float=None,
        e_date=None,
        e_bool=None,
    ):
        self.encrypted_utf8_str = e_utf8_str
        self.encrypted_jsonb = e_jsonb
        self.encrypted_int = e_int
        self.encrypted_float = e_float
        self.encrypted_date = e_date
        self.encrypted_boolean = e_bool

    def __repr__(self):
        return (
            "<Example("
            f"id={self.id}, "
            f"encrypted_utf8_str={self.encrypted_utf8_str}, "
            f"encrypted_jsonb={self.encrypted_jsonb}, "
            f"encrypted_int={self.encrypted_int}, "
            f"encrypted_float={self.encrypted_float}, "
            f"encrypted_date={self.encrypted_date}, "
            f"encrypted_boolean={self.encrypted_boolean}"
            ")>"
        )
