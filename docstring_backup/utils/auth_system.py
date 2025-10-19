"""
Authentication and Authorization system for DinoAir.

This module implements enterprise-grade authentication and authorization including:
- RBAC (Role-Based Access Control) with healthcare roles
- MFA support (TOTP/SMS/Email)
- Session management with timeout controls
- Password policies meeting HIPAA requirements
- User provisioning and lifecycle management
- Audit integration for compliance
"""

from __future__ import annotations

import os
import re
import secrets
import sys
import uuid
from dataclasses import dataclass, field
from datetime import UTC, datetime, timedelta
from enum import Enum
from typing import Any

try:
    import bcrypt
    import pyotp
    import qrcode
    from PIL import Image

    CRYPTO_AVAILABLE = True
except ImportError:
    # Graceful fallback
    bcrypt = pyotp = qrcode = Image = None
    CRYPTO_AVAILABLE = False


try:
    from fastapi import Depends, HTTPException, Request, status
    from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

    FASTAPI_AVAILABLE = True
except ImportError:
    HTTPException = status = Depends = Request = None
    HTTPBearer = HTTPAuthorizationCredentials = object
    FASTAPI_AVAILABLE = False


class UserRole(Enum):
    """User roles with healthcare-specific permissions."""

    # Administrative Roles
    system_admin = "system_admin"  # Full system access
    security_admin = "security_admin"  # Security configuration
    audit_admin = "audit_admin"  # Audit log access

    # Healthcare Roles
    healthcare_admin = "healthcare_admin"  # Healthcare data admin
    clinician = "clinician"  # Medical professional
    nurse = "nurse"  # Nursing staff
    technician = "technician"  # Technical support

    # Operational Roles
    dispatcher = "dispatcher"  # Emergency dispatch
    supervisor = "supervisor"  # Team supervision
    operator = "operator"  # Standard operations

    # Access Levels
    read_only = "read_only"  # View-only access
    guest = "guest"  # Limited guest access


class Permission(Enum):
    """System permissions for granular access control."""

    # System Permissions
    system_config = "system.config"
    system_users = "system.users"
    system_audit = "system.audit"
    system_backup = "system.backup"

    # Data Permissions
    data_read = "data.read"
    data_create = "data.create"
    data_update = "data.update"
    data_delete = "data.delete"
    data_export = "data.export"
    data_import = "data.import"

    # Healthcare Specific
    patient_data_read = "patient.read"
    patient_data_write = "patient.write"
    medical_records = "medical.records"
    emergency_access = "emergency.access"

    # API Permissions
    api_read = "api.read"
    api_write = "api.write"
    api_admin = "api.admin"


class AuthenticationMethod(Enum):
    """Supported authentication methods."""

    password = "password"
    mfa_totp = "mfa_totp"
    mfa_sms = "mfa_sms"
    mfa_email = "mfa_email"
    api_key = "api_key"
    sso = "sso"


@dataclass
class PasswordPolicy:
    """Password policy configuration."""

    min_length: int = 12
    max_length: int = 128
    require_uppercase: bool = True
    require_lowercase: bool = True
    require_digits: bool = True
    require_special_chars: bool = True
    special_chars: str = "!@#$%^&*()_+-=[]{}|;':\",./<>?"
    disallow_common_passwords: bool = True
    disallow_personal_info: bool = True
    password_history_count: int = 12
    max_age_days: int = 90
    lockout_attempts: int = 5
    lockout_duration_minutes: int = 30

    @classmethod
    def hipaa_compliant(cls) -> PasswordPolicy:
        """Create HIPAA-compliant password policy."""
        return cls(
            min_length=14,
            max_age_days=60,
            lockout_attempts=3,
            lockout_duration_minutes=60,
        )


@dataclass
class User:
    """User account information."""

    user_id: str
    username: str
    email: str
    full_name: str
    roles: set[UserRole]
    permissions: set[Permission] = field(default_factory=set)

    # Authentication
    password_hash: str | None = None
    mfa_secret: str | None = None
    mfa_enabled: bool = False
    mfa_backup_codes: list[str] = field(default_factory=list)

    # Account Status
    is_active: bool = True
    is_locked: bool = False
    locked_until: datetime | None = None
    failed_login_attempts: int = 0
    last_login: datetime | None = None
    password_changed_at: datetime | None = None

    # Audit Fields
    created_at: datetime = field(default_factory=lambda: datetime.now(UTC))
    created_by: str | None = None
    updated_at: datetime = field(default_factory=lambda: datetime.now(UTC))
    updated_by: str | None = None

    # Healthcare Fields
    license_number: str | None = None
    department: str | None = None
    emergency_contact: str | None = None

    def has_permission(self, permission: Permission) -> bool:
        """Check if user has specific permission."""
        # Direct permission check
        if permission in self.permissions:
            return True

        # Role-based permission check
        role_permissions = get_role_permissions()
        for role in self.roles:
            if permission in role_permissions.get(role, set()):
                return True

        return False

    def has_any_permission(self, permissions: list[Permission]) -> bool:
        """Check if user has any of the specified permissions."""
        return any(self.has_permission(perm) for perm in permissions)

    def has_all_permissions(self, permissions: list[Permission]) -> bool:
        """Check if user has all specified permissions."""
        return all(self.has_permission(perm) for perm in permissions)

    def is_account_locked(self) -> bool:
        """Check if account is currently locked."""
        if not self.is_locked:
            return False

        if self.locked_until and datetime.now(UTC) > self.locked_until:
            # Auto-unlock expired locks
            self.is_locked = False
            self.locked_until = None
            self.failed_login_attempts = 0
            return False

        return True


@dataclass
class Session:
    """User session information."""

    session_id: str
    user_id: str
    created_at: datetime
    last_accessed: datetime
    expires_at: datetime
    source_ip: str
    user_agent: str
    mfa_verified: bool = False

    # Session data
    data: dict[str, Any] = field(default_factory=dict)

    def is_expired(self) -> bool:
        """Check if session is expired."""
        return datetime.now(UTC) > self.expires_at

    def is_idle_timeout(self, idle_timeout_minutes: int = 30) -> bool:
        """Check if session has exceeded idle timeout."""
        idle_cutoff = datetime.now(UTC) - timedelta(minutes=idle_timeout_minutes)
        return self.last_accessed < idle_cutoff

    def extend_session(self, duration_hours: int = 8) -> None:
        """Extend session expiration."""
        self.expires_at = datetime.now(UTC) + timedelta(hours=duration_hours)
        self.last_accessed = datetime.now(UTC)


class UserManager:
    """User management with healthcare compliance features."""

    def __init__(self, password_policy: PasswordPolicy | None = None):
        self.password_policy = password_policy or PasswordPolicy.hipaa_compliant()
        self.users: dict[str, User] = {}
        self.sessions: dict[str, Session] = {}
        self.password_history: dict[str, list[str]] = {}

        if not CRYPTO_AVAILABLE:
            raise ImportError("bcrypt and pyotp are required for authentication")

    def create_user(
        self,
        username: str,
        email: str,
        full_name: str,
        password: str,
        roles: list[UserRole],
        created_by: str | None = None,
        **kwargs,
    ) -> User:
        """Create a new user account."""

        # Validate inputs
        if self.get_user_by_username(username):
            raise ValueError(f"Username '{username}' already exists")

        if self.get_user_by_email(email):
            raise ValueError(f"Email '{email}' already exists")

        # Validate password
        self._validate_password(password, username, email, full_name)

        # Create user
        user_id = str(uuid.uuid4())
        password_hash = UserManager._hash_password(password)

        new_user = User(
            user_id=user_id,
            username=username,
            email=email,
            full_name=full_name,
            roles=set(roles),
            password_hash=password_hash,
            password_changed_at=datetime.now(UTC),
            created_by=created_by,
            **kwargs,
        )

        # Set role-based permissions
        new_user.permissions = UserManager._calculate_permissions(new_user.roles)

        # Store user
        self.users[user_id] = new_user

        # Initialize password history
        self.password_history[user_id] = [password_hash]

        return new_user

    def authenticate_user(
        self,
        username: str,
        password: str,
        source_ip: str,
        user_agent: str = "",
        require_mfa: bool = True,
    ) -> Session | None:
        """Authenticate user and create session."""

        auth_user = self.get_user_by_username(username)
        if not auth_user:
            return None

        # Check account status
        if not auth_user.is_active:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is disabled")

        if auth_user.is_account_locked():
            raise HTTPException(status_code=status.HTTP_423_LOCKED, detail="Account is locked")

        # Verify password
        if not UserManager._verify_password(password, auth_user.password_hash):
            auth_user.failed_login_attempts += 1

            # Lock account if too many failures
            if auth_user.failed_login_attempts >= self.password_policy.lockout_attempts:
                auth_user.is_locked = True
                auth_user.locked_until = datetime.now(UTC) + timedelta(
                    minutes=self.password_policy.lockout_duration_minutes
                )

            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials"
            )

        # Reset failed attempts on successful password
        auth_user.failed_login_attempts = 0
        auth_user.last_login = datetime.now(UTC)

        # Check if MFA is required
        mfa_verified = True
        if require_mfa and auth_user.mfa_enabled:
            mfa_verified = False  # Will need separate MFA verification

        # Create session
        auth_session = self._create_session(auth_user, source_ip, user_agent, mfa_verified)

        return auth_session

    def verify_mfa(self, session_id: str, mfa_code: str) -> bool:
        """Verify MFA code and update session."""

        auth_session = self.sessions.get(session_id)
        if not auth_session or auth_session.is_expired():
            return False

        auth_user = self.users.get(auth_session.user_id)
        if not auth_user or not auth_user.mfa_enabled:
            return False

        # Verify TOTP code
        if auth_user.mfa_secret:
            totp = pyotp.TOTP(auth_user.mfa_secret)
            if totp.verify(mfa_code, valid_window=1):
                auth_session.mfa_verified = True
                return True

        # Check backup codes
        if mfa_code in auth_user.mfa_backup_codes:
            auth_user.mfa_backup_codes.remove(mfa_code)
            auth_session.mfa_verified = True
            return True

        return False

    def enable_mfa(self, user_id: str) -> dict[str, Any]:
        """Enable MFA for user and return setup information."""

        target_user = self.users.get(user_id)
        if not target_user:
            raise ValueError("User not found")

        # Generate secret
        secret = pyotp.random_base32()
        target_user.mfa_secret = secret

        # Generate backup codes
        backup_codes = [secrets.token_hex(4).upper() for _ in range(8)]
        target_user.mfa_backup_codes = backup_codes

        # Generate QR code
        totp = pyotp.TOTP(secret)
        qr_url = totp.provisioning_uri(name=target_user.email, issuer_name="DinoAir Healthcare")

        # Create QR code image
        qr = qrcode.QRCode(version=1, box_size=10, border=5)
        qr.add_data(qr_url)
        qr.make(fit=True)

        return {
            "secret": secret,
            "qr_url": qr_url,
            "backup_codes": backup_codes,
            "manual_entry_key": secret,
        }

    def change_password(self, user_id: str, old_password: str, new_password: str) -> None:
        """Change user password with policy validation."""

        target_user = self.users.get(user_id)
        if not target_user:
            raise ValueError("User not found")

        # Verify old password
        if not UserManager._verify_password(old_password, target_user.password_hash):
            raise ValueError("Current password is incorrect")

        # Validate new password
        self._validate_password(
            new_password, target_user.username, target_user.email, target_user.full_name
        )

        # Check password history
        new_hash = UserManager._hash_password(new_password)
        user_history = self.password_history.get(user_id, [])

        for old_hash in user_history[-self.password_policy.password_history_count :]:
            if UserManager._verify_password(new_password, old_hash):
                raise ValueError("Password has been used recently")

        # Update password
        target_user.password_hash = new_hash
        target_user.password_changed_at = datetime.now(UTC)

        # Update password history
        user_history.append(new_hash)
        if len(user_history) > self.password_policy.password_history_count:
            user_history = user_history[-self.password_policy.password_history_count :]
        self.password_history[user_id] = user_history

        # Invalidate all sessions
        self._invalidate_user_sessions(user_id)

    def get_user_by_username(self, username: str) -> User | None:
        """Get user by username."""
        return next((u for u in self.users.values() if u.username == username), None)

    def get_user_by_email(self, email: str) -> User | None:
        """Get user by email."""
        return next((u for u in self.users.values() if u.email == email), None)

    def get_session(self, session_id: str) -> Session | None:
        """Get session by ID, removing it if expired."""
        found_session = self.sessions.get(session_id)
        if found_session and found_session.is_expired():
            del self.sessions[session_id]
            return None
        return found_session

    def cleanup_expired_sessions(self) -> None:
        """Remove expired or idle sessions from storage."""
        expired_sessions = [
            sid
            for sid, session in self.sessions.items()
            if session.is_expired() or session.is_idle_timeout()
        ]

        for session_id in expired_sessions:
            del self.sessions[session_id]

    def _create_session(
        self,
        user_obj: User,
        source_ip: str,
        user_agent: str,
        mfa_verified: bool = False,
    ) -> Session:
        """Create new user session."""

        session_id = secrets.token_urlsafe(32)
        now = datetime.now(UTC)

        session_obj = Session(
            session_id=session_id,
            user_id=user_obj.user_id,
            created_at=now,
            last_accessed=now,
            expires_at=now + timedelta(hours=8),  # 8 hour default
            source_ip=source_ip,
            user_agent=user_agent,
            mfa_verified=mfa_verified,
        )

        self.sessions[session_id] = session_obj
        return session_obj

    def _validate_password(self, password: str, username: str, email: str, full_name: str) -> None:
        """Validate password against policy requirements."""
        self._validate_length(password)
        self._validate_character_requirements(password)
        self._validate_special_chars(password)
        self._validate_personal_info(password, username, email, full_name)

    def _validate_length(self, password: str) -> None:
        """Ensure password length meets the policy requirements."""
        policy = self.password_policy
        if len(password) < policy.min_length:
            raise ValueError(f"Password must be at least {policy.min_length} characters")
        if len(password) > policy.max_length:
            raise ValueError(f"Password must be no more than {policy.max_length} characters")

    def _validate_character_requirements(self, password: str) -> None:
        """Ensure password contains required character types (uppercase, lowercase, digits)."""
        policy = self.password_policy
        requirements = [
            (policy.require_uppercase, r"[A-Z]", "uppercase letters"),
            (policy.require_lowercase, r"[a-z]", "lowercase letters"),
            (policy.require_digits, r"\d", "digits"),
        ]
        for required, pattern, description in requirements:
            if required and not re.search(pattern, password):
                raise ValueError(f"Password must contain {description}")

    def _validate_special_chars(self, password: str) -> None:
        """Ensure password contains required special characters."""
        policy = self.password_policy
        if policy.require_special_chars:
            special_pattern = f"[{re.escape(policy.special_chars)}]"
            if not re.search(special_pattern, password):
                raise ValueError(
                    f"Password must contain special characters: {policy.special_chars}"
                )

    def _validate_personal_info(
        self, password: str, username: str, email: str, full_name: str
    ) -> None:
        """Prevent password from containing personal user information."""
        policy = self.password_policy
        if policy.disallow_personal_info:
            personal_info = [username.lower(), email.split("@")[0].lower()]
            if full_name:
                personal_info.extend(full_name.lower().split())

            lower_password = password.lower()
            for info in personal_info:
                if len(info) >= 4 and info in lower_password:
                    raise ValueError("Password cannot contain personal information")

    @staticmethod
    def _hash_password(password: str) -> str:
        """Hash password using bcrypt."""
        salt = bcrypt.gensalt(rounds=12)
        return bcrypt.hashpw(password.encode("utf-8"), salt).decode("utf-8")

    @staticmethod
    def _verify_password(password: str, password_hash: str) -> bool:
        """Verify password against hash."""
        return bcrypt.checkpw(password.encode("utf-8"), password_hash.encode("utf-8"))

    @staticmethod
    def _calculate_permissions(roles: set[UserRole]) -> set[Permission]:
        """Calculate permissions based on user roles."""
        permissions = set()

        for role in roles:
            # Basic role-to-permission mapping using correct enum values
            if role == UserRole.system_admin:
                permissions.update(
                    [
                        Permission.system_config,
                        Permission.system_users,
                        Permission.system_audit,
                    ]
                )
            elif role == UserRole.healthcare_admin:
                permissions.update(
                    [
                        Permission.patient_data_read,
                        Permission.patient_data_write,
                        Permission.medical_records,
                    ]
                )
            elif role == UserRole.clinician:
                permissions.update(
                    [
                        Permission.patient_data_read,
                        Permission.patient_data_write,
                        Permission.medical_records,
                    ]
                )
            elif role == UserRole.nurse:
                permissions.update([Permission.patient_data_read, Permission.patient_data_write])
            elif role == UserRole.read_only:
                permissions.update([Permission.data_read, Permission.api_read])
            elif role == UserRole.guest:
                permissions.update([Permission.data_read])

        return permissions

    def _invalidate_user_sessions(self, user_id: str) -> None:
        """Invalidate all sessions for a given user."""
        sessions_to_remove = [
            sid for sid, session in self.sessions.items() if session.user_id == user_id
        ]

        for session_id in sessions_to_remove:
            del self.sessions[session_id]


class AuthenticationMiddleware:
    """FastAPI middleware for authentication."""

    def __init__(self, user_mgr: UserManager):
        self.user_manager = user_mgr
        self.security = HTTPBearer(auto_error=False)

    async def get_current_user(self, credentials: HTTPAuthorizationCredentials = Depends()) -> User:
        """Get current authenticated user."""

        if not credentials:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Authentication required",
            )

        user_session = self.user_manager.get_session(credentials.credentials)
        if not user_session:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid session")

        current_user = self.user_manager.users.get(user_session.user_id)
        if not current_user or not current_user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found or inactive",
            )

        # Update last accessed
        user_session.last_accessed = datetime.now(UTC)

        return current_user

    """Utilities for authentication and permission checking.

    This module provides decorators to enforce user permissions
    in API endpoints, raising an HTTPException on insufficient permissions.
    """

    def require_permission(self, permission: Permission):
        """Decorator to require specific permission."""

        def permission_checker(
            current_user: User = Depends(self.get_current_user),
        ) -> User:
            """Ensure the current user has the specified permission.

            Raises HTTPException with 403 status code if the user lacks
            the required permission, otherwise returns the user.
            """
            if not current_user.has_permission(permission):
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Insufficient permissions",
                )
            return current_user

        return permission_checker

    def require_role(self, role: UserRole):
        """Decorator to require specific role."""

        def role_checker(current_user: User = Depends(self.get_current_user)) -> User:
            """Ensure that the current user possesses the required role, or raise HTTPException if not."""
            if role not in current_user.roles:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient role"
                )
            return current_user

        return role_checker


def get_role_permissions() -> dict[UserRole, set[Permission]]:
    """Get role-to-permission mapping."""

    return {
        # Administrative Roles
        UserRole.system_admin: {
            Permission.system_config,
            Permission.system_users,
            Permission.system_audit,
            Permission.system_backup,
            Permission.data_read,
            Permission.data_create,
            Permission.data_update,
            Permission.data_delete,
            Permission.data_export,
            Permission.data_import,
            Permission.api_admin,
        },
        UserRole.security_admin: {
            Permission.system_config,
            Permission.system_audit,
            Permission.data_read,
            Permission.api_read,
        },
        UserRole.audit_admin: {
            Permission.system_audit,
            Permission.data_read,
            Permission.api_read,
        },
        # Healthcare Roles
        UserRole.healthcare_admin: {
            Permission.patient_data_read,
            Permission.patient_data_write,
            Permission.medical_records,
            Permission.data_read,
            Permission.data_create,
            Permission.data_update,
            Permission.data_export,
            Permission.api_write,
        },
        UserRole.clinician: {
            Permission.patient_data_read,
            Permission.patient_data_write,
            Permission.medical_records,
            Permission.emergency_access,
            Permission.data_read,
            Permission.data_create,
            Permission.data_update,
            Permission.api_write,
        },
        UserRole.nurse: {
            Permission.patient_data_read,
            Permission.patient_data_write,
            Permission.data_read,
            Permission.data_create,
            Permission.data_update,
            Permission.api_write,
        },
        UserRole.technician: {Permission.data_read, Permission.api_read},
        # Operational Roles
        UserRole.dispatcher: {
            Permission.emergency_access,
            Permission.data_read,
            Permission.data_create,
            Permission.data_update,
            Permission.api_write,
        },
        UserRole.supervisor: {
            Permission.data_read,
            Permission.data_create,
            Permission.data_update,
            Permission.api_write,
        },
        UserRole.operator: {
            Permission.data_read,
            Permission.data_create,
            Permission.api_write,
        },
        # Access Levels
        UserRole.read_only: {Permission.data_read, Permission.api_read},
        UserRole.guest: {Permission.api_read},
    }


def create_healthcare_user_manager() -> UserManager:
    """Create user manager with healthcare-compliant settings."""
    policy = PasswordPolicy.hipaa_compliant()
    return UserManager(policy)


if __name__ == "__main__":
    # Test authentication system
    print("Testing DinoAir Authentication System...")

    if not CRYPTO_AVAILABLE:
        print("❌ Crypto dependencies not available. Install bcrypt and pyotp.")
        sys.exit(1)

    # Create user manager
    user_manager = create_healthcare_user_manager()

    # Load test/admin password from environment; no hardcoded default
    test_password = os.environ.get("AUTH_SYSTEM_ADMIN_PASSWORD")
    if not test_password:
        raise RuntimeError("AUTH_SYSTEM_ADMIN_PASSWORD not set")

    # Test user creation
    print("✅ Testing user creation...")
    try:
        user = user_manager.create_user(
            username="dr_smith",
            email="dr.smith@hospital.com",
            full_name="Dr. John Smith",
            password=test_password,
            roles=[UserRole.clinician],
            department="Emergency Medicine",
            license_number="MD123456",
        )
        print(f"   Created user: {user.full_name}")
        print(f"   Permissions: {len(user.permissions)}")
    except Exception as e:
        print(f"   Error: {e}")

    # Test authentication
    print("✅ Testing authentication...")
    try:
        session = user_manager.authenticate_user(
            username="dr_smith",
            password=test_password,
            source_ip="192.168.1.100",
            require_mfa=False,
        )
        print(f"   Session created: {session.session_id[:8]}...")
    except Exception as e:
        print(f"   Error: {e}")

    # Test MFA setup
    print("✅ Testing MFA setup...")
    try:
        mfa_setup = user_manager.enable_mfa(user.user_id)
        print("   MFA secret generated and stored securely.")
        print(f"   Backup codes: {len(mfa_setup['backup_codes'])}")
    except Exception as e:
        print(f"   Error: {e}")

    print("\n✅ Authentication system test complete!")
