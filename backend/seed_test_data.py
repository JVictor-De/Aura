"""
Script de seed para criar contas de teste no Zoe.

Contas criadas:
  CUSTOMER  → cliente@zoe.test  / Test@1234
  MERCHANT  → lojista@zoe.test  / Test@1234  (com loja "Zoe Store Teste")
  ADMIN     → admin@zoe.test    / Test@1234  (insert direto no banco)

Uso (dentro do container):
  docker exec zoe_backend python seed_test_data.py
"""

import asyncio
import bcrypt
import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker

from app.config import get_settings
from app.models.user import User, UserRole, AuthProvider


def _bcrypt_hash(plain: str) -> str:
    """Hash direto via bcrypt, sem passar pelo passlib (evita bug de compatibilidade)."""
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt(rounds=12)).decode()

BASE_URL = "http://localhost:8000"

CUSTOMER = {
    "email": "cliente@zoeteste.com",
    "password": "Test@1234",
    "name": "Cliente Teste",
    "phone": "11999990001",
    "cpf": "111.111.111-11",
}

MERCHANT = {
    "email": "lojista@zoeteste.com",
    "password": "Test@1234",
    "name": "Lojista Teste",
    "phone": "11999990002",
    "cpf": "222.222.222-22",
    "store_name": "Zoe Store Teste",
    "cnpj": "12.345.678/0001-90",
}

ADMIN = {
    "email": "admin@zoeteste.com",
    "password": "Test@1234",
    "name": "Admin Zoe",
    "phone": "11999990003",
}

# ──────────────────────────────────────────────────────────────────────────────
# HTTP helpers
# ──────────────────────────────────────────────────────────────────────────────

def _register(client: httpx.Client, path: str, payload: dict, label: str) -> bool:
    try:
        r = client.post(f"{BASE_URL}{path}", json=payload, timeout=15)
        if r.status_code in (200, 201):
            data = r.json()
            print(f"  ✅  {label} registrado — role: {data.get('role')}")
            return True
        elif r.status_code == 400 and "already" in r.text.lower():
            print(f"  ⚠️   {label} já existe — pulando")
            return True
        else:
            print(f"  ❌  {label} falhou: {r.status_code} — {r.text[:200]}")
            return False
    except Exception as exc:
        print(f"  ❌  {label} erro HTTP: {exc}")
        return False


def _login_test(client: httpx.Client, email: str, password: str, label: str):
    try:
        r = client.post(f"{BASE_URL}/api/v1/auth/login",
                        json={"email": email, "password": password}, timeout=10)
        if r.status_code == 200:
            data = r.json()
            print(f"  🔑  Login OK — {label} | role: {data.get('role')}")
        else:
            print(f"  ⚠️   Login falhou para {label}: {r.status_code}")
    except Exception as exc:
        print(f"  ❌  Login erro: {exc}")


# ──────────────────────────────────────────────────────────────────────────────
# Admin via DB direto
# ──────────────────────────────────────────────────────────────────────────────

async def _create_admin_if_missing():
    settings = get_settings()
    engine = create_async_engine(settings.DATABASE_URL, echo=False)
    session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with session_factory() as session:
        result = await session.execute(
            select(User).where(User.email == ADMIN["email"])
        )
        existing = result.scalar_one_or_none()
        if existing:
            print(f"  ⚠️   Admin já existe — pulando")
        else:
            admin = User(
                email=ADMIN["email"],
                hashed_password=_bcrypt_hash(ADMIN["password"]),
                name=ADMIN["name"],
                phone=ADMIN["phone"],
                role=UserRole.ADMIN,
                auth_provider=AuthProvider.EMAIL,
                is_active=True,
            )
            session.add(admin)
            await session.commit()
            print(f"  ✅  Admin criado via banco")

    await engine.dispose()


# ──────────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────────

async def main():
    print("\n═══════════════════════════════════════════════")
    print("   ZOE — Seed de contas de teste")
    print("═══════════════════════════════════════════════\n")

    with httpx.Client() as client:
        # 1. Customer
        print("▶ Registrando CUSTOMER …")
        _register(client, "/api/v1/auth/register/customer",
                  {k: v for k, v in CUSTOMER.items()}, "Customer")

        # 2. Merchant
        print("▶ Registrando MERCHANT …")
        _register(client, "/api/v1/auth/register/merchant",
                  {k: v for k, v in MERCHANT.items()}, "Merchant")

        # 3. Admin (sem endpoint público — insert direto)
        print("▶ Criando ADMIN (via DB) …")
        await _create_admin_if_missing()

        # 4. Testa login das 3 contas
        print("\n▶ Validando logins …")
        _login_test(client, CUSTOMER["email"], CUSTOMER["password"], "cliente@zoeteste.com")
        _login_test(client, MERCHANT["email"], MERCHANT["password"], "lojista@zoeteste.com")
        _login_test(client, ADMIN["email"], ADMIN["password"], "admin@zoeteste.com")

    print("\n═══════════════════════════════════════════════")
    print("   Contas de teste")
    print("═══════════════════════════════════════════════")
    print(f"  CUSTOMER : {CUSTOMER['email']}  /  {CUSTOMER['password']}")
    print(f"  MERCHANT : {MERCHANT['email']}  /  {MERCHANT['password']}")
    print(f"  ADMIN    : {ADMIN['email']}      /  {ADMIN['password']}")
    print("═══════════════════════════════════════════════\n")


if __name__ == "__main__":
    asyncio.run(main())
