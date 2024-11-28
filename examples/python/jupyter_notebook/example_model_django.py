from django.db import models
from eqlpy.eqldjango import *

# Example model for Django ORM
class Example(models.Model):
    encrypted_int = EncryptedInt(table="examples", column="encrypted_int", null=True)
    encrypted_boolean = EncryptedBoolean(
        table="examples", column="encrypted_boolean", null=True
    )
    encrypted_date = EncryptedDate(table="examples", column="encrypted_date", null=True)
    encrypted_float = EncryptedFloat(table="examples", column="encrypted_float", null=True)
    encrypted_utf8_str = EncryptedText(
        table="examples", column="encrypted_utf8_str", null=True
    )
    encrypted_jsonb = EncryptedJsonb(table="examples", column="encrypted_jsonb", null=True)

    class Meta:
        app_label = "eqlpy.eqldjango"
        db_table = "examples"

