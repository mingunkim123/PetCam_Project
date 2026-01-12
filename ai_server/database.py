# ai_server/database.py
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# DB 접속 규격 (Linker string)
DATABASE_URL = "postgresql://petuser:asd116511!@localhost/petdb"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base() # 테이블 설계를 위한 기본 클래스