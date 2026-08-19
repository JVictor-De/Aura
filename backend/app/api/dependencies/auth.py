"""
Dependency de autenticação para rotas da API.

Re-exporta as dependências de segurança como convenção de imports
para as rotas. As rotas importam de aqui em vez de app.core.security.

Referências:
- ARCHITECTURE.md §7: api/dependencies/auth.py → get_current_user, require_role
- TECHNICAL_AUDIT.md §4.1.C: Perfis customer, merchant, admin
"""

from app.core.security import (
    get_current_user,
    require_role,
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)

__all__ = [
    "get_current_user",
    "require_role",
    "create_access_token",
    "create_refresh_token",
    "decode_token",
    "hash_password",
    "verify_password",
]
