import argparse
import subprocess
import time
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--adb", required=True)
    parser.add_argument("--flutter", default="flutter")
    parser.add_argument("--device", default="emulator-5554")
    args = parser.parse_args()
    if not args.device.startswith("emulator-"):
        parser.error("Pengujian offline ini hanya untuk emulator.")
    root = Path(__file__).resolve().parents[1]
    package = "com.daclanari.seller.dev"

    def adb(*command, check=False, **kwargs):
        return subprocess.run(
            [args.adb, "-s", args.device, *command],
            capture_output=True,
            text=True,
            timeout=15,
            check=check,
            **kwargs,
        )

    def network(kind, enabled):
        result = adb("shell", "svc", kind, "enable" if enabled else "disable")
        if result.returncode:
            raise RuntimeError(result.stderr)

    wifi = adb(
        "shell", "settings", "get", "global", "wifi_on", check=True
    ).stdout.strip()
    data = adb(
        "shell", "settings", "get", "global", "mobile_data", check=True
    ).stdout.strip()
    cleanup = adb("shell", "run-as", package, "rm", "-f", "code_cache/a4-network-stage")
    if cleanup.returncode and "unknown package" not in cleanup.stderr:
        raise RuntimeError(cleanup.stderr)
    if cleanup.returncode:
        print("App belum terpasang; tidak ada sinyal lama.", flush=True)
    folder = root / "artifacts/a4"
    folder.mkdir(parents=True, exist_ok=True)
    command = [
        args.flutter,
        "drive",
        "--keep-app-running",
        "--driver=test_driver/a4.dart",
        "--target=integration_test/a4_test.dart",
        "--flavor",
        "dev",
        "-d",
        args.device,
    ]
    with (folder / "device.log").open("w") as log:
        process = subprocess.Popen(
            command, cwd=root / "apps/seller", stdout=log, stderr=subprocess.STDOUT
        )
        try:
            monitor(process, adb, network, package)
            code = process.wait()
            print(f"Perjalanan perangkat keluar dengan kode {code}.", flush=True)
            raise SystemExit(code)
        finally:
            network("wifi", wifi == "1")
            network("data", data == "1")
            if process.poll() is None:
                process.terminate()


def monitor(process, adb, network, package):
    deadline = time.monotonic() + 900
    handled = set()
    while process.poll() is None:
        if time.monotonic() > deadline:
            raise TimeoutError("Perjalanan perangkat melewati 15 menit.")
        result = adb("shell", "run-as", package, "cat", "code_cache/a4-network-stage")
        expected = ("No such file", "not debuggable", "unknown package")
        if result.returncode and not any(value in result.stderr for value in expected):
            raise RuntimeError(result.stderr)
        stage = result.stdout.strip() if result.returncode == 0 else ""
        if stage == "disable" and stage not in handled:
            network("wifi", False)
            network("data", False)
            handled.add(stage)
            print("Wi-Fi dan data emulator dimatikan.", flush=True)
        if stage == "enable" and stage not in handled:
            network("wifi", True)
            network("data", True)
            time.sleep(4)
            adb(
                "shell",
                "run-as",
                package,
                "tee",
                "code_cache/a4-network-stage",
                input="online",
                check=True,
            )
            handled.add(stage)
            print("Wi-Fi dan data emulator dipulihkan.", flush=True)
        time.sleep(1)


if __name__ == "__main__":
    main()
