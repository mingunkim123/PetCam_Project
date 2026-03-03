"""
=============================================================================
Refresh Token 모델 정의
=============================================================================

Refresh Token이 뭔가요?
    로그인하면 2개의 토큰을 받습니다:
    
    1. Access Token (출입증)
       - 유효기간: 짧음 (30분)
       - 용도: API 요청할 때 사용
       - 특징: 자주 갱신해야 함
    
    2. Refresh Token (갱신권)
       - 유효기간: 길음 (7일)
       - 용도: Access Token이 만료되면 새로 발급받을 때 사용
       - 특징: DB에 저장됨, 탈취되면 무효화 가능

왜 2개를 쓰나요?
    보안과 편의성의 균형!
    
    - Access Token만 쓰면?
      → 유효기간 짧으면: 자주 로그인해야 함 (불편)
      → 유효기간 길면: 탈취당하면 오래 악용됨 (위험)
    
    - 둘 다 쓰면?
      → Access Token은 짧게 (탈취되어도 금방 만료)
      → Refresh Token으로 자동 갱신 (사용자는 편함)
      → Refresh Token 탈취 시 DB에서 무효화 가능 (안전)
=============================================================================
"""

import uuid
from datetime import datetime

from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from database import Base


class RefreshToken(Base):
    """
    Refresh Token 저장 테이블
    
    각 필드 설명:
        id: 토큰의 고유 ID (UUID)
        user_id: 이 토큰의 주인 (users 테이블 참조)
        token: 실제 토큰 문자열 (랜덤 생성)
        expires_at: 만료 시간
        revoked: 무효화 여부 (True면 사용 불가)
        created_at: 생성 시간
    """
    
    __tablename__ = "refresh_tokens"
    
    # =========================================================================
    # 기본 키
    # =========================================================================
    id = Column(
        UUID(as_uuid=True),      # UUID 타입 사용
        primary_key=True,        # 기본 키
        default=uuid.uuid4       # 자동으로 UUID 생성
    )
    
    # =========================================================================
    # 사용자 참조 (외래 키)
    # =========================================================================
    # 이 토큰이 누구의 것인지
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),  # 사용자 삭제 시 토큰도 삭제
        nullable=False,
        index=True  # 검색 속도 향상
    )
    
    # =========================================================================
    # 토큰 문자열
    # =========================================================================
    # 실제로 클라이언트에게 전달되는 토큰 값
    token = Column(
        String(255),
        unique=True,   # 중복 불가
        nullable=False,
        index=True     # 검색 속도 향상 (토큰으로 조회하니까)
    )
    
    # =========================================================================
    # 만료 시간
    # =========================================================================
    expires_at = Column(
        DateTime,
        nullable=False
    )
    
    # =========================================================================
    # 무효화 여부
    # =========================================================================
    # True = 이 토큰은 더 이상 사용할 수 없음
    # 로그아웃하거나 보안 문제 발생 시 True로 변경
    revoked = Column(
        Boolean,
        default=False,
        nullable=False
    )
    
    # =========================================================================
    # 생성 시간
    # =========================================================================
    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False
    )
    
    # =========================================================================
    # 관계 설정 (User 모델과 연결)
    # =========================================================================
    # user = relationship("User", back_populates="refresh_tokens")
    
    def is_valid(self) -> bool:
        """
        토큰이 유효한지 확인합니다.
        
        유효 조건:
            1. 무효화되지 않음 (revoked == False)
            2. 만료 시간이 지나지 않음
        
        Returns:
            True: 유효함, False: 무효함
        """
        # 무효화되었으면 False
        if self.revoked:
            return False
        
        # 만료되었으면 False
        if datetime.utcnow() > self.expires_at:
            return False
        
        return True
