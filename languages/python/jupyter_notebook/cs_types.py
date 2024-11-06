from psycopg2.extras import RealDictCursor
from pprint import pprint
from datetime import datetime
import json
from enum import Enum

class CsValue:
    def __init__(self, v, t: str, c: str):
        self.value = v
        self.table = t
        self.column = c

    def to_db_format(self, query_type = None):
        data = {
            "k": "pt",
            "p": self._value_in_db_format(query_type),
            "i": {
              "t": str(self.table),
              "c": str(self.column)
            },
            "v": 1,
            "q": query_type,
        }
        return json.dumps(data)

    @classmethod
    def from_parsed_json(cls, parsed):
        return cls._value_from_db_format(parsed["p"])

class CsInt(CsValue):
    def _value_in_db_format(self, query_type):
        return str(self.value)

    @classmethod
    def _value_from_db_format(cls, s: str):
        return int(s)

class CsBool(CsValue):
    def _value_in_db_format(self, query_type):
        return str(self.value).lower()

    @classmethod
    def _value_from_db_format(cls, s: str):
        return s.lower() == 'true'

class CsDate(CsValue):
    def _value_in_db_format(self, query_type):
        return self.value.isoformat()

    @classmethod
    def _value_from_db_format(cls, s: str):
        return datetime.fromisoformat(s).date()

class CsFloat(CsValue):
    def _value_in_db_format(self, query_type):
        return str(self.value)

    @classmethod
    def _value_from_db_format(cls, s: str):
        return float(s)

class CsText(CsValue):
    def _value_in_db_format(self, query_type):
        return self.value

    @classmethod
    def _value_from_db_format(cls, s: str):
        return s

class CsJsonb(CsValue):
    def _value_in_db_format(self, query_type):
        if query_type == "ejson_path":
            return self.value
        else:
            return json.dumps(self.value)

    @classmethod
    def _value_from_db_format(cls, s: str):
        return json.loads(s)

class CsRow:
    column_function_mapping = {
        'encrypted_int': CsInt.from_parsed_json,
        'encrypted_boolean': CsBool.from_parsed_json,
        'encrypted_date': CsDate.from_parsed_json,
        'encrypted_float': CsFloat.from_parsed_json,
        'encrypted_utf8_str': CsText.from_parsed_json,
        'encrypted_jsonb': CsText.from_parsed_json
    }

    @staticmethod
    def id_map(x):
        return x

    def __init__(self, row):
        self.row = {}
        for k, v in row.items():
            if v == None:
                self.row[k] = None
            else:
                mapping = self.column_function_mapping.get(k, self.id_map)
                self.row[k] = mapping(v)