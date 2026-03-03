import os
import sys

# Add parent directory to path to import database
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from database import engine
from sqlalchemy import text


def add_columns():
    with engine.connect() as conn:
        print("Adding latitude column...")
        try:
            conn.execute(
                text("ALTER TABLE photos ADD COLUMN IF NOT EXISTS latitude FLOAT;")
            )
            print("Added latitude.")
        except Exception as e:
            print(f"Error adding latitude: {e}")

        print("Adding longitude column...")
        try:
            conn.execute(
                text("ALTER TABLE photos ADD COLUMN IF NOT EXISTS longitude FLOAT;")
            )
            print("Added longitude.")
        except Exception as e:
            print(f"Error adding longitude: {e}")

        conn.commit()


if __name__ == "__main__":
    add_columns()
