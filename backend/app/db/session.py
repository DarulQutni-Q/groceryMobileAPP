from fastapi import Request


def get_db(request: Request):
    with request.app.state.sessions() as session:
        yield session
