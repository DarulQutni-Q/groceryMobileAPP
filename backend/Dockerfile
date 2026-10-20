FROM python:3.14-slim
WORKDIR /srv
COPY requirements.lock .
RUN pip install --no-cache-dir -r requirements.lock
COPY alembic.ini .
COPY app ./app
RUN useradd --create-home grocery && mkdir /srv/uploads && chown grocery:grocery /srv/uploads
USER grocery
EXPOSE 8000
CMD ["sh", "-c", "alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port 8000 --no-access-log"]
