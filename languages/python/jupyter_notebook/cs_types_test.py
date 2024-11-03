import unittest
import json
from datetime import date
from cs_types import *

class EqlTest(unittest.TestCase):
    def test(self):
        self.assertTrue(True)

    def test_to_db_format(self):
        self.assertEqual(
            CsInt(1, "table", "column").to_db_format(),
            '{"k": "pt", "p": "1", "i": {"t": "table", "c": "column"}, "v": 1, "q": null}'
        )

    def test_from_parsed_json_uses_p_value(self):
        parsed = json.loads('{"k": "pt", "p": "1", "i": {"t": "table", "c": "column"}, "v": 1, "q": null}')
        self.assertEqual(
            CsInt.from_parsed_json(parsed),
            1
        )

    def test_cs_int_prints_value(self):
        cs_int = CsInt(1, "table", "column")
        self.assertEqual(
            cs_int.value_in_db_format(),
            "1"
        )

    def test_ces_int_makes_int(self):
        self.assertEqual(
            CsInt.value_from_db_format("1"),
            1
        )

    def test_cs_bool_prints_value_in_lower_case(self):
        cs_bool = CsBool(True, "table", "column")
        self.assertEqual(
            cs_bool.value_in_db_format(),
            "true"
        )
    
    def test_cs_bool_returns_bool(self):
        self.assertEqual(
            CsBool.value_from_db_format("true"),
            True
        )

    def test_cs_date_prints_value(self):
        cs_date = CsDate(date(2024, 11, 1), "table", "column")
        self.assertEqual(
            cs_date.value_in_db_format(),
            "2024-11-01"
        )

    def test_cs_date_returns_datetime(self):
        self.assertEqual(
            CsDate.value_from_db_format("2024-11-01"),
            date(2024, 11, 1)
        )

    def test_cs_float_prints_value(self):
        cs_float = CsFloat(1.1, "table", "column")
        self.assertEqual(
            cs_float.value_in_db_format(),
            "1.1"
        )

    def test_cs_float_returns_float(self):
        self.assertEqual(
            CsFloat.value_from_db_format("1.1"),
            1.1
        )

    def test_cs_text_prints_value(self):
        cs_text = CsText("text", "table", "column")
        self.assertEqual(
            cs_text.value_in_db_format(),
            "text"
        )
    
    def test_cs_text_returns_value(self):
        self.assertEqual(
            CsText.value_from_db_format("text"),
            "text"
        )

    def test_cs_jsonb_prints_json_string(self):
        cs_jsonb = CsJsonb({"a": 1}, "table", "column")
        self.assertEqual(
            cs_jsonb.value_in_db_format("ste_vec"),
            '{"a": 1}'
        )

    def test_cs_jsonb_prints_value_for_ejson_path(self):
        cs_jsonb = CsJsonb("$.a.b", "table", "column")
        self.assertEqual(
            cs_jsonb.value_in_db_format("ejson_path"),
            '$.a.b'
        )

    def test_cs_jsonb_returns_value(self):
        self.assertEqual(
            CsJsonb.value_from_db_format('{"a": 1}'),
            {"a": 1}
        )

    def test_cs_row_makes_row(self):
        cs_row = CsRow(
            {"encrypted_int": json.loads(CsInt(1, "table", "column").to_db_format()),
             "encrypted_boolean": json.loads(CsBool(True, "table", "column").to_db_format()),
             "encrypted_date": json.loads(CsDate(date(2024, 11, 1), "table", "column").to_db_format()),
             "encrypted_float": json.loads(CsFloat(1.1, "table", "column").to_db_format()),
             "encrypted_utf8_str": json.loads(CsText("text", "table", "column").to_db_format()),
             "encrypted_jsonb": json.loads(CsJsonb('{"a": 1}', "table", "column").to_db_format())
            })

        self.assertEqual(
            cs_row.row,
            {"encrypted_int": 1,
             "encrypted_boolean": True,
             "encrypted_date": date(2024, 11, 1),
             "encrypted_float": 1.1,
             "encrypted_utf8_str": "text",
             "encrypted_jsonb": '"{\\"a\\": 1}"'
            }
        )

if __name__ == '__main__':
    unittest.main()