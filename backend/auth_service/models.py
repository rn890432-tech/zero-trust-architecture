# Database models for multi-tenant SaaS SOC
from sqlalchemy import Column, Integer, String, TIMESTAMP, ForeignKey, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

class Tenant(Base):
    __tablename__ = 'tenants'
    id = Column(Integer, primary_key=True)
    tenant_name = Column(String)
    domain = Column(String)
    subscription_plan = Column(String)
    created_at = Column(TIMESTAMP)

class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True)
    tenant_id = Column(Integer, ForeignKey('tenants.id'))
    email = Column(String)
    role = Column(String)
    password_hash = Column(String)

class Subscription(Base):
    __tablename__ = 'subscriptions'
    id = Column(Integer, primary_key=True)
    tenant_id = Column(Integer, ForeignKey('tenants.id'))
    plan = Column(String)
    status = Column(String)
    start_date = Column(TIMESTAMP)
    end_date = Column(TIMESTAMP)

class APIKey(Base):
    __tablename__ = 'api_keys'
    id = Column(Integer, primary_key=True)
    tenant_id = Column(Integer, ForeignKey('tenants.id'))
    key = Column(String)
    created_at = Column(TIMESTAMP)
    expires_at = Column(TIMESTAMP)
