"""
Models package — importa todos os modelos para que Alembic e
SQLAlchemy Base.metadata conheçam todas as tabelas.
"""

from app.models.user import User, UserRole, AuthProvider  # noqa: F401
from app.models.store import Store, StoreStatus  # noqa: F401
from app.models.product import Product, SkuVariant, ProductCategory  # noqa: F401
from app.models.order import Order, OrderShipment, OrderItem  # noqa: F401
from app.models.payment import Payment, PaymentEvent  # noqa: F401
from app.models.address import Address  # noqa: F401
from app.models.stock_reservation import StockReservation  # noqa: F401
from app.models.rma import RmaRequest, RmaItem  # noqa: F401
from app.models.cart import CartSession, CartItem  # noqa: F401
from app.models.coupon import Coupon, AppliedCoupon  # noqa: F401
from app.models.delivery_tracking import DeliveryTracking  # noqa: F401
from app.models.wishlist import Wishlist  # noqa: F401
from app.models.review import Review  # noqa: F401
from app.models.notification_token import NotificationToken  # noqa: F401
