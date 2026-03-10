# Tenant provisioning logic
from sqlalchemy.orm import Session
from ..auth_service.models import Tenant, User

def create_tenant(db: Session, name: str, email: str):
    tenant = Tenant(tenant_name=name)
    db.add(tenant)
    db.commit()
    db.refresh(tenant)
    admin_user = User(tenant_id=tenant.id, email=email, role='admin')
    db.add(admin_user)
    db.commit()
    return tenant.id
