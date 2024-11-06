import unittest
from datetime import date

from cs_models import *

class TestExampleModel(unittest.TestCase):
    pg_password = os.getenv('PGPASSWORD', 'postgres')
    pg_user = os.getenv('PGUSER', 'postgres')
    pg_host = os.getenv('PGHOST', 'localhost')
    pg_port = os.getenv('PGPORT', '6432')
    pg_db = os.getenv('PGDATABASE', 'cs_test_db')

    def setUp(self):
        self.engine = create_engine(f'postgresql://{self.pg_user}:{self.pg_password}@{self.pg_host}:{self.pg_port}/{self.pg_db}')
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

    def test_example_prints_value(self):
        self.example.id = 1
        self.assertEqual(
            str(self.example),
            "<Example(id=1, encrypted_utf8_str=str, encrypted_jsonb={'key': 'value'}, encrypted_int=1, encrypted_float=1.1, encrypted_date=2024-01-01, encrypted_boolean=True)>"
        )
    
if __name__ == '__main__':
    unittest.main()
