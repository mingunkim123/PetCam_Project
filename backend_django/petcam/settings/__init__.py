"""
DJANGO_ENV 환경변수에 따라 dev 또는 prod 설정 로드
기본값: dev
"""
import os

env = os.environ.get('DJANGO_ENV', 'dev')
if env == 'prod':
    from .prod import *
else:
    from .dev import *
