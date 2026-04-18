"""
BitMLx Artifacts Viewer - Flask web app to visualize BitMLx compilation results.
"""

import os
import re
import shlex
import subprocess
import tempfile
from pathlib import Path

from flask import Flask, render_template, abort, request, jsonify

app = Flask(__name__)

ARTIFACTS_DIR = Path(__file__).resolve().parent.parent / "dist" / "bitmlx_artifacts"

APPS_INFO = {
    "ReceiverChosenDenomination": {
        "title": "Receiver Chosen Denomination",
        "description": "Quyên góp đa đồng, người nhận chọn denomination.",
    },
    "TwoPartyAgreement": {
        "title": "Two Party Agreement",
        "description": "Quyên góp đa đồng, hai bên đồng thuận thông qua coin-toss (reveal condition).",
    },
    "MultichainPaymentExchange": {
        "title": "Multichain Payment Exchange",
        "description": "Thanh toán có đổi tiền qua exchange service với tỷ giá cố định.",
    },
    "MultichainLoanMediator": {
        "title": "Multichain Loan Mediator",
        "description": "Vay cross-chain có mediator giám sát installment.",
    },
}


def parse_statistics(stats_path: Path) -> dict | None:
    """Parse statistics.txt to extract contract stats."""
    if not stats_path.exists():
        return None
    text = stats_path.read_text()
    # Find the data row (between the header separator lines)
    lines = [l.strip() for l in text.splitlines() if l.strip().startswith("|")]
    if len(lines) < 2:
        return None
    # Data row is the last pipe-delimited line
    data_line = lines[-1]
    cells = [c.strip() for c in data_line.split("|") if c.strip()]
    if len(cells) >= 4:
        return {
            "name": cells[0],
            "transactions": int(cells[1]),
            "depth": int(cells[2]),
            "time": cells[3],
        }
    return None


def parse_balzac_transactions(balzac_path: Path) -> int:
    """Count max transaction index in a .balzac file."""
    if not balzac_path.exists():
        return 0
    text = balzac_path.read_text()
    matches = re.findall(r"transaction\s+T(\d+)", text)
    if not matches:
        return 0
    return max(int(m) for m in matches)


def parse_rkt_participants(rkt_path: Path) -> list[str]:
    """Extract participant names from .rkt file."""
    if not rkt_path.exists():
        return []
    text = rkt_path.read_text()
    return re.findall(r'\(participant\s+"(\w+)"', text)


def parse_rkt_secrets(rkt_path: Path) -> list[str]:
    """Extract secret names from .rkt file."""
    if not rkt_path.exists():
        return []
    text = rkt_path.read_text()
    return re.findall(r'\(secret\s+"[^"]+"\s+(\w+)', text)


def get_app_data(app_name: str) -> dict | None:
    """Gather all data for one application."""
    app_dir = ARTIFACTS_DIR / app_name
    if not app_dir.is_dir():
        return None

    info = APPS_INFO.get(app_name, {"title": app_name, "description": ""})
    stats = parse_statistics(app_dir / "statistics.txt")

    # Read depth
    depth_file = app_dir / f"{app_name}_depth.txt"
    depth = None
    if depth_file.exists():
        content = depth_file.read_text().strip()
        if content.isdigit():
            depth = int(content)

    # Per-chain data
    chains = {}
    for chain in ("bitcoin", "dogecoin"):
        rkt = app_dir / f"{app_name}_{chain}.rkt"
        balzac = app_dir / f"{app_name}_{chain}.balzac"
        if rkt.exists() or balzac.exists():
            chains[chain] = {
                "rkt_exists": rkt.exists(),
                "balzac_exists": balzac.exists(),
                "rkt_size": rkt.stat().st_size if rkt.exists() else 0,
                "balzac_size": balzac.stat().st_size if balzac.exists() else 0,
                "tx_count": parse_balzac_transactions(balzac),
                "participants": parse_rkt_participants(rkt),
                "secrets": parse_rkt_secrets(rkt),
            }

    return {
        "name": app_name,
        "info": info,
        "stats": stats,
        "depth": depth,
        "chains": chains,
    }


def read_file_content(app_name: str, filename: str) -> str | None:
    """Read artifact file content safely."""
    file_path = ARTIFACTS_DIR / app_name / filename
    if not file_path.exists():
        return None
    # Prevent path traversal
    if not file_path.resolve().is_relative_to(ARTIFACTS_DIR.resolve()):
        return None
    return file_path.read_text()


@app.route("/")
def index():
    apps = []
    for name in APPS_INFO:
        data = get_app_data(name)
        if data:
            apps.append(data)
    return render_template("index.html", apps=apps)


@app.route("/app/<app_name>")
def app_detail(app_name):
    if app_name not in APPS_INFO:
        abort(404)
    data = get_app_data(app_name)
    if not data:
        abort(404)

    # Read file contents for display
    files = {}
    for chain in ("bitcoin", "dogecoin"):
        rkt_name = f"{app_name}_{chain}.rkt"
        balzac_name = f"{app_name}_{chain}.balzac"
        rkt_content = read_file_content(app_name, rkt_name)
        balzac_content = read_file_content(app_name, balzac_name)
        if rkt_content is not None:
            # Truncate very large files for display
            if len(rkt_content) > 50000:
                rkt_content = rkt_content[:50000] + f"\n\n... (truncated, full file: {len(rkt_content)} bytes)"
            files[rkt_name] = rkt_content
        if balzac_content is not None:
            if len(balzac_content) > 50000:
                balzac_content = balzac_content[:50000] + f"\n\n... (truncated, full file: {len(balzac_content)} bytes)"
            files[balzac_name] = balzac_content

    return render_template("detail.html", data=data, files=files)


PROJECT_ROOT = Path(__file__).resolve().parent.parent
DOCKER_IMAGE = os.environ.get("BITMLX_DOCKER_IMAGE", "blockchain-bitmlx:dev")

# ---------------------------------------------------------------------------
# Template definitions for the "Try" feature
# ---------------------------------------------------------------------------

TEMPLATES = {
    "SimpleExchange": {
        "title": "Simple Exchange",
        "description": "Hai bên hoán đổi tài sản: A gửi BTC, B gửi DOGE, swap trực tiếp.",
        "participants": [
            {"var": "pA", "name": "A", "pk": "pkA", "role": "Sender BTC",
             "btc": 1, "doge": 0},
            {"var": "pB", "name": "B", "pk": "pkB", "role": "Sender DOGE",
             "btc": 0, "doge": 1},
        ],
        "has_secrets": False,
        "time_start": 1,
        "time_delta": 10,
    },
    "ReceiverChosenDenomination": {
        "title": "Receiver Chosen Denomination",
        "description": "Quyên góp đa đồng, người nhận chọn denomination.",
        "participants": [
            {"var": "pA", "name": "A", "pk": "pkA", "role": "Donor",
             "btc": 1, "doge": 1},
            {"var": "pB", "name": "B", "pk": "pkB", "role": "Receiver",
             "btc": 0, "doge": 0},
        ],
        "has_secrets": False,
        "time_start": 1,
        "time_delta": 10,
    },
    "MultichainPaymentExchange": {
        "title": "Multichain Payment Exchange",
        "description": "Thanh toán có đổi tiền qua exchange service với tỷ giá cố định.",
        "participants": [
            {"var": "pC", "name": "C", "pk": "pkC", "role": "Customer",
             "btc": 10, "doge": 0},
            {"var": "pR", "name": "R", "pk": "pkR", "role": "Receiver",
             "btc": 0, "doge": 0},
            {"var": "pX", "name": "X", "pk": "pkX", "role": "Exchange",
             "btc": 0, "doge": 100},
        ],
        "has_secrets": False,
        "time_start": 1,
        "time_delta": 10,
    },
    "TwoPartyAgreement": {
        "title": "Two Party Agreement",
        "description": "Hai bên đồng thuận thông qua coin-toss (reveal condition).",
        "participants": [
            {"var": "pA", "name": "A", "pk": "pkA", "role": "Party A",
             "btc": 1, "doge": 1},
            {"var": "pB", "name": "B", "pk": "pkB", "role": "Party B",
             "btc": 0, "doge": 0},
        ],
        "has_secrets": True,
        "time_start": 1,
        "time_delta": 10,
    },
    "MultichainLoanMediator": {
        "title": "Multichain Loan Mediator",
        "description": "Vay cross-chain có mediator giám sát installment.",
        "participants": [
            {"var": "pB", "name": "B", "pk": "pkB", "role": "Borrower",
             "btc": 3, "doge": 0},
            {"var": "pL", "name": "L", "pk": "pkL", "role": "Lender",
             "btc": 0, "doge": 30},
            {"var": "pM", "name": "M", "pk": "pkM", "role": "Mediator",
             "btc": 0, "doge": 0},
        ],
        "has_secrets": False,
        "time_start": 1,
        "time_delta": 10,
    },
}


def _validate_name(s: str) -> str:
    """Sanitize a participant name to alphanumeric only."""
    cleaned = re.sub(r"[^A-Za-z0-9]", "", s)
    return cleaned[:20] if cleaned else "X"


def _build_coin_map(template_name: str, params: dict) -> dict[str, tuple[int, int]]:
    """Build old-coin -> new-coin mapping from original and new params."""
    template = TEMPLATES[template_name]
    mapping = {}
    for i, orig in enumerate(template["participants"]):
        p = params["participants"][i]
        old = (orig["btc"], orig["doge"])
        new = (int(p["btc"]), int(p["doge"]))
        mapping[orig["var"]] = (old, new)
    return mapping


def generate_hs_source(template_name: str, params: dict) -> str:
    """Read the original .hs template and patch participant names, deposits,
    and all coin-amount tuples in the contract body."""
    original = PROJECT_ROOT / "vendor" / "BitMLx" / "app" / "Examples" / f"{template_name}.hs"
    source = original.read_text()

    template = TEMPLATES[template_name]

    # Replace module name to UserCustom
    source = source.replace(
        f"module Examples.{template_name}",
        "module Examples.UserCustom",
    )
    source = source.replace(
        f'exampleName = "{template_name}"',
        'exampleName = "UserCustom"',
    )

    # Build a ratio map: for each participant, compute the scale factor per chain
    # so that amounts in the contract body scale proportionally.
    coin_map = _build_coin_map(template_name, params)

    # Compute total old and new deposits per chain
    old_total_btc = sum(v[0][0] for v in coin_map.values())
    old_total_doge = sum(v[0][1] for v in coin_map.values())
    new_total_btc = sum(v[1][0] for v in coin_map.values())
    new_total_doge = sum(v[1][1] for v in coin_map.values())

    # Replace all coin tuples (X, Y) in the source proportionally
    # We do this by finding all integer tuple patterns and scaling them
    def scale_coin_tuple(match: re.Match) -> str:
        btc_val = int(match.group(1))
        doge_val = int(match.group(2))
        if old_total_btc > 0:
            new_btc = round(btc_val * new_total_btc / old_total_btc)
        else:
            new_btc = btc_val
        if old_total_doge > 0:
            new_doge = round(doge_val * new_total_doge / old_total_doge)
        else:
            new_doge = doge_val
        return f"({new_btc}, {new_doge})"

    # First, patch participant names and deposit lines specifically
    for i, orig in enumerate(template["participants"]):
        p = params["participants"][i]
        new_name = _validate_name(p["name"])
        new_pk = f"pk{new_name}"

        source = source.replace(
            f'pname = "{orig["name"]}", pk = "{orig["pk"]}"',
            f'pname = "{new_name}", pk = "{new_pk}"',
        )

        old_dep_line = f'{orig["var"]} ! ({orig["btc"]}, {orig["doge"]}) $ "{orig["name"]}_deposit"'
        new_dep_line = f'{orig["var"]} ! ({int(p["btc"])}, {int(p["doge"])}) $ "{new_name}_deposit"'
        source = source.replace(old_dep_line, new_dep_line)

    # Now scale all remaining coin tuples in Withdraw/Split/contract body
    # Match patterns like ((X, Y), pSomething)  or  (X, Y)  used for coins
    # We target tuples inside (( )) which are coin distributions
    source = re.sub(
        r"\(\((\d+),\s*(\d+)\)",
        lambda m: "((" + scale_coin_tuple(m)[1:],
        source,
    )

    return source


def run_compile_in_docker(hs_source: str, timeout: int = 300) -> dict:
    """Write UserCustom.hs, patch Main.hs, run pipeline in Docker, return results."""
    custom_hs = PROJECT_ROOT / "vendor" / "BitMLx" / "app" / "Examples" / "UserCustom.hs"
    main_hs = PROJECT_ROOT / "vendor" / "BitMLx" / "app" / "Main.hs"
    main_backup = PROJECT_ROOT / "vendor" / "BitMLx" / "app" / "Main.hs.bak"
    output_dir = PROJECT_ROOT / "vendor" / "BitMLx" / "output"

    original_main = main_hs.read_text()

    try:
        # Write custom module
        custom_hs.write_text(hs_source)

        # Patch Main.hs to include UserCustom
        patched_main = original_main
        patched_main = patched_main.replace(
            "import qualified Examples.Escrow as Escrow",
            "import qualified Examples.Escrow as Escrow\n"
            "import qualified Examples.UserCustom as UserCustom",
        )
        patched_main = patched_main.replace(
            '("Escrow", Escrow.example)',
            '("Escrow", Escrow.example)\n'
            '            , ("UserCustom", UserCustom.example)',
        )
        main_hs.write_text(patched_main)

        # Run pipeline
        docker_run = PROJECT_ROOT / "scripts" / "docker_run.sh"
        cmd = f'IMAGE={shlex.quote(DOCKER_IMAGE)} {shlex.quote(str(docker_run))} "./scripts/bitmlx_pipeline.sh UserCustom"'
        result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True,
            timeout=timeout, cwd=str(PROJECT_ROOT),
        )

        compile_output = result.stdout + result.stderr
        success = result.returncode == 0

        # Gather output files
        files = {}
        for f in sorted(output_dir.glob("UserCustom*")):
            content = f.read_text()
            if len(content) > 50000:
                content = content[:50000] + f"\n\n... (truncated, {len(content)} bytes total)"
            files[f.name] = content

        stats = parse_statistics(output_dir / "statistics.txt")

        depth = None
        depth_file = output_dir / "UserCustom_depth.txt"
        if depth_file.exists():
            d = depth_file.read_text().strip()
            if d.isdigit():
                depth = int(d)

        return {
            "success": success,
            "output": compile_output,
            "files": files,
            "stats": stats,
            "depth": depth,
        }

    finally:
        # Restore original Main.hs
        main_hs.write_text(original_main)
        # Clean up custom file
        if custom_hs.exists():
            custom_hs.unlink()


@app.route("/try")
def try_contract():
    return render_template("try.html", templates=TEMPLATES)


@app.route("/try/compile", methods=["POST"])
def try_compile():
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400

    template_name = data.get("template")
    if template_name not in TEMPLATES:
        return jsonify({"error": f"Unknown template: {template_name}"}), 400

    template = TEMPLATES[template_name]
    participants = data.get("participants", [])

    if len(participants) != len(template["participants"]):
        return jsonify({"error": "Participant count mismatch"}), 400

    # Validate deposits are non-negative integers
    for p in participants:
        try:
            p["btc"] = max(0, int(p.get("btc", 0)))
            p["doge"] = max(0, int(p.get("doge", 0)))
        except (ValueError, TypeError):
            return jsonify({"error": f"Invalid deposit for {p.get('name', '?')}"}), 400

    try:
        hs_source = generate_hs_source(template_name, {"participants": participants})
        result = run_compile_in_docker(hs_source, timeout=300)
        result["hs_source"] = hs_source
        return jsonify(result)
    except subprocess.TimeoutExpired:
        return jsonify({"error": "Compilation timed out (5 min limit)"}), 504
    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
