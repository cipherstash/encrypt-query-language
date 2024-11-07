import unittest
import json
from datetime import date
from cs_types import *

class EqlTest(unittest.TestCase):
    def setUp(self):
        self.template_dict = json.loads('{"k": "pt", "p": "1", "i": {"t": "table", "c": "column"}, "v": 1, "q": null}')

    def test(self):
        self.assertTrue(True)

    def test_to_db_format(self):
        self.assertEqual(
            CsInt(1, "table", "column").to_db_format(),
            '{"k": "pt", "p": "1", "i": {"t": "table", "c": "column"}, "v": 1, "q": null}'
        )

    def test_from_parsed_json_uses_p_value(self):
        self.template_dict["p"] = "1"
        self.assertEqual(
            CsInt.from_parsed_json(self.template_dict),
            1
        )

    def test_cs_int_to_db_format(self):
        cs_int = CsInt(123, "table", "column")
        self.assertEqual(
            '{"k": "pt", "p": "123", "i": {"t": "table", "c": "column"}, "v": 1, "q": null}',
            cs_int.to_db_format()
        )

    def test_cs_int_from_parsed_json(self):
        self.template_dict["p"] = "123"
        self.assertEqual(
            CsInt.from_parsed_json(self.template_dict),
            123
        )

    def test_cs_bool_to_db_format_true(self):
        cs_bool = CsBool(True, "table", "column")
        self.assertEqual(
            '{"k": "pt", "p": "true", "i": {"t": "table", "c": "column"}, "v": 1, "q": null}',
            cs_bool.to_db_format()
        )
    
    def test_cs_bool_to_db_format_false(self):
        cs_bool = CsBool(False, "table", "column")
        self.assertEqual(
            '{"k": "pt", "p": "false", "i": {"t": "table", "c": "column"}, "v": 1, "q": null}',
            cs_bool.to_db_format()
        )
    
    def test_cs_bool_from_parsed_json_true(self):
        self.template_dict["p"] = "true"
        self.assertEqual(
            CsBool.from_parsed_json(self.template_dict),
            True
        )

    def test_cs_bool_from_parsed_json_false(self):
        self.template_dict["p"] = "false"
        self.assertEqual(
            CsBool.from_parsed_json(self.template_dict),
            False
        )

    def test_cs_date_to_db_format(self):
        cs_date = CsDate(date(2024, 11, 1), "table", "column")
        self.assertEqual(
            '{"k": "pt", "p": "2024-11-01", "i": {"t": "table", "c": "column"}, "v": 1, "q": null}',
            cs_date.to_db_format()
        )

    def test_cs_date_from_parsed_json(self):
        self.template_dict["p"] = "2024-11-01"
        self.assertEqual(
            CsDate.from_parsed_json(self.template_dict),
            date(2024, 11, 1)
        )

    def test_cs_float_to_db_format(self):
        cs_float = CsFloat(1.1, "table", "column")
        self.assertEqual(
            '{"k": "pt", "p": "1.1", "i": {"t": "table", "c": "column"}, "v": 1, "q": null}',
            cs_float.to_db_format()
        )

    def test_cs_float_from_parsed_json(self):
        self.template_dict["p"] = "1.1"
        self.assertEqual(
            CsFloat.from_parsed_json(self.template_dict),
            1.1
        )

    def test_cs_text_to_db_format(self):
        cs_text = CsText("text", "table", "column")
        self.assertEqual(
            '{"k": "pt", "p": "text", "i": {"t": "table", "c": "column"}, "v": 1, "q": null}',
            cs_text.to_db_format()
        )
    
    def test_cs_text_from_parsed_json(self):
        self.template_dict["p"] = "text"
        self.assertEqual(
            CsText.from_parsed_json(self.template_dict),
            "text"
        )

    def test_cs_jsonb_prints_json_string(self):
        cs_jsonb = CsJsonb({"a": 1}, "table", "column")
        self.assertEqual(
            cs_jsonb._value_in_db_format("ste_vec"),
            '{"a": 1}'
        )

    def test_cs_jsonb_prints_value_for_ejson_path(self):
        cs_jsonb = CsJsonb("$.a.b", "table", "column")
        self.assertEqual(
            cs_jsonb._value_in_db_format("ejson_path"),
            '$.a.b'
        )

    def test_cs_jsonb_returns_value(self):
        self.assertEqual(
            CsJsonb._value_from_db_format('{"a": 1}'),
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