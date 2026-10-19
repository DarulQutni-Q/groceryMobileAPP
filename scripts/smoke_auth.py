import argparse
import json
import secrets
import subprocess
import uuid


def request(base_url, method, path, expected, data=None, token=None):
    config = [f"url = {json.dumps(base_url + path)}", f"request = {json.dumps(method)}"]
    config.append('header = "Content-Type: application/json"')
    if data is not None:
        config.append(f"data = {json.dumps(json.dumps(data))}")
    if token:
        config.append(f"header = {json.dumps('Authorization: Bearer ' + token)}")
    result = subprocess.run(
        ["curl", "--silent", "--show-error", "--max-time", "20", "--config", "-",
         "--write-out", "\n%{http_code}"],
        input="\n".join(config), text=True, capture_output=True, check=True,
    )
    body, status = result.stdout.rsplit("\n", 1)
    assert int(status) == expected, f"{method} {path}: expected {expected}, got {status}"
    print(f"PASS {method} {path}: {status}")
    return json.loads(body)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", required=True)
    args = parser.parse_args()
    base = args.base_url.rstrip("/")
    account = {
        "nama_pemilik": "Pemilik Uji", "nama_toko": "Toko Pengujian A1",
        "email": f"a1-{uuid.uuid4().hex}@example.com",
        "password": secrets.token_urlsafe(9) + "A1!",
    }
    request(base, "GET", "/health", 200)
    session = request(base, "POST", "/auth/register", 200, account)
    duplicate = request(base, "POST", "/auth/register", 400, account)
    assert duplicate["detail"] == "Email sudah terdaftar"
    request(base, "POST", "/auth/register", 422, {**account, "password": "123"})
    request(base, "POST", "/auth/login", 401,
            {"email": account["email"], "password": "Salah123!"})
    request(base, "GET", "/auth/me", 401)
    profile = request(base, "GET", "/auth/me", 200, token=session["access_token"])
    assert "password_hash" not in profile and "password" not in profile
    login = request(base, "POST", "/auth/login", 200,
                    {"email": account["email"], "password": account["password"]})
    refreshed = request(base, "POST", "/auth/refresh", 200,
                        {"refresh_token": login["refresh_token"]})
    request(base, "PATCH", "/auth/fcm-token", 200,
            {"fcm_token": "fcm-dummy-acceptance"}, refreshed["access_token"])
    request(base, "POST", "/auth/google", 503, {"id_token": "not-configured"})
    print("PASS acceptance curl: no credentials printed")


if __name__ == "__main__":
    main()
