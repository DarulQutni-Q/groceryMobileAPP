from concurrent.futures import ThreadPoolExecutor, TimeoutError
from threading import Event
from uuid import UUID

from fastapi import Depends, Request
from sqlalchemy.orm import Session
from test_upload import photo, setup_product

from app.db.session import get_db
from app.models.toko import Toko
from app.routers.produk import get_produk
from app.services.toko import get_store


def test_delete_racing_upload_leaves_no_orphaned_photo(pg_client, account):
    client = pg_client
    headers, path = setup_product(client, account)
    client.post(path + "/foto", headers=headers, files={"file": ("old.png", photo(), "image/png")})
    loaded, release = Event(), Event()

    def pause_delete(
        produk_id: UUID,
        request: Request,
        toko: Toko = Depends(get_store),
        db: Session = Depends(get_db),
    ):
        produk = get_produk(produk_id, toko, db)
        if request.method == "DELETE":
            loaded.set()
            assert release.wait(10)
        return produk

    client.app.dependency_overrides[get_produk] = pause_delete
    try:
        with ThreadPoolExecutor(max_workers=2) as pool:
            delete = pool.submit(client.delete, path, headers=headers)
            assert loaded.wait(10)
            upload = pool.submit(
                client.post,
                path + "/foto",
                headers=headers,
                files={"file": ("new.png", photo(), "image/png")},
            )
            try:
                upload.result(timeout=1)
            except TimeoutError:
                pass
            finally:
                release.set()
            assert delete.result(timeout=10).status_code == 200
            assert upload.result(timeout=10).status_code in (200, 404)
        assert list(client.app.state.settings.uploads_dir.iterdir()) == []
    finally:
        release.set()
        client.app.dependency_overrides.clear()
