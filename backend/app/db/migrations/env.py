from alembic import context
from sqlalchemy import create_engine, pool

from app.core.config import Settings
from app.db.base import Base
from app.models.user import User

target_metadata = Base.metadata
assert User.__table__.metadata is target_metadata


def run_migrations():
    url = Settings().database_url
    if context.is_offline_mode():
        context.configure(url=url, target_metadata=target_metadata, literal_binds=True)
        with context.begin_transaction():
            context.run_migrations()
    else:
        engine = create_engine(url, poolclass=pool.NullPool, hide_parameters=True)
        try:
            with engine.connect() as connection:
                context.configure(connection=connection, target_metadata=target_metadata)
                with context.begin_transaction():
                    context.run_migrations()
        finally:
            engine.dispose()


run_migrations()
