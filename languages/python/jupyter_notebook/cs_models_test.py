import unittest
from datetime import date

from cs_models import *

class TestExampleModel(unittest.TestCase):
    def setUp(self):
        # TODO: configure database URL in environment variable and use a test db (not getting_started)
        self.engine = create_engine('postgresql://postgres:postgres@localhost:6432/cipherstash_getting_started')
        Session = sessionmaker(bind=self.engine)
        self.session = Session()
        BaseModel.metadata.create_all(self.engine)

        self.session.query(Example).delete()
        self.example = Example(
            e_int=1, e_utf8_str="str", e_jsonb='{"key": "value"}', e_float=1.1, e_date=date(2024, 1, 1), e_bool=True
        )
        self.session.add(self.example)
        self.session.commit()

    def test_encrypted_int(self):
        found = self.session.query(Example).filter(Example.id == self.example.id).one()
        self.assertEqual(found.encrypted_int, 1)

    def test_encrypted_boolean(self):
        found = self.session.query(Example).filter(Example.id == self.example.id).one()
        self.assertEqual(found.encrypted_boolean, True)

    def test_encrypted_date(self):
        found = self.session.query(Example).filter(Example.id == self.example.id).one()
        self.assertEqual(found.encrypted_date, date(2024, 1, 1))

    def test_encrypted_float(self):
        found = self.session.query(Example).filter(Example.id == self.example.id).one()
        self.assertEqual(found.encrypted_float, 1.1)
    
    def test_encrypted_utf8_str(self):
        found = self.session.query(Example).filter(Example.id == self.example.id).one()
        self.assertEqual(found.encrypted_utf8_str, "str")

    def test_encrypted_jsonb(self):
        found = self.session.query(Example).filter(Example.id == self.example.id).one()
        self.assertEqual(found.encrypted_jsonb,  {"key": "value"})
    
if __name__ == '__main__':
    unittest.main()
