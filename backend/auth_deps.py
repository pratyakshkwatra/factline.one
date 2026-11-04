from typing import Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from database import get_db
from models.user import User, UserRole 
from security import decode_token
import config as settings

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/sign_in")
oauth2_scheme_optional = OAuth2PasswordBearer(tokenUrl="auth/sign_in", auto_error=False)

def get_optional_current_user(
    db: Session = Depends(get_db), token: Optional[str] = Depends(oauth2_scheme_optional)
) -> Optional[User]:
    if not token:
        return None
    payload = decode_token(token)
    if not payload:
        return None
    user_id = payload.get("sub")
    if user_id is None:
        return None
    try:
        return db.query(User).filter(User.id == int(user_id)).first()
    except Exception:
        return None

def get_current_user(
    db: Session = Depends(get_db), token: str = Depends(oauth2_scheme)
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    payload = decode_token(token)
    if not payload:
        raise credentials_exception
        
    user_id = payload.get("sub")
    if user_id is None:
        raise credentials_exception
        
    user = db.query(User).filter(User.id == int(user_id)).first()
    if user is None:
        raise credentials_exception
    return user

def get_current_editor(current_user: User = Depends(get_current_user)) -> User:
    if current_user.role != UserRole.editor:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="The user does not have permissions for this action",
        )
    return current_user
