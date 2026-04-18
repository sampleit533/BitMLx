import os
import re
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BITMLX_DIR = ROOT / "vendor" / "BitMLx"
OUT_DIR = BITMLX_DIR / "output"


def _run(cmd: list[str]) -> None:
    subprocess.run(cmd, cwd=ROOT, check=True)


def _read_text(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="replace")


def _max_tx_num(balzac_text: str) -> int:
    # Matches lines like: transaction T123 { 
    nums = [int(m.group(1)) for m in re.finditer(r"^transaction T(\d+)\s*\{\s*$", balzac_text, re.M)]
    assert nums, "no transaction lines found in .balzac output"
    return max(nums)


def test_receiver_chosen_denomination_compiles_and_stats_match():
    _run(["bash", "-lc", "./scripts/bitmlx_pipeline.sh ReceiverChosenDenomination"])

    btc = OUT_DIR / "ReceiverChosenDenomination_bitcoin.balzac"
    doge = OUT_DIR / "ReceiverChosenDenomination_dogecoin.balzac"
    depth = OUT_DIR / "ReceiverChosenDenomination_depth.txt"

    assert btc.exists()
    assert doge.exists()
    assert depth.exists()

    assert _max_tx_num(_read_text(btc)) == 51
    assert _max_tx_num(_read_text(doge)) == 51
    assert depth.read_text().strip() == "6"


def test_two_party_agreement_compiles_and_stats_match():
    _run(["bash", "-lc", "./scripts/bitmlx_pipeline.sh TwoPartyAgreement"])

    btc = OUT_DIR / "TwoPartyAgreement_bitcoin.balzac"
    doge = OUT_DIR / "TwoPartyAgreement_dogecoin.balzac"
    depth = OUT_DIR / "TwoPartyAgreement_depth.txt"

    assert btc.exists()
    assert doge.exists()
    assert depth.exists()

    assert _max_tx_num(_read_text(btc)) == 51
    assert _max_tx_num(_read_text(doge)) == 51
    assert depth.read_text().strip() == "6"


def test_multichain_payment_exchange_compiles_and_stats_match():
    _run(["bash", "-lc", "./scripts/bitmlx_pipeline.sh MultichainPaymentExchange"])

    btc = OUT_DIR / "MultichainPaymentExchange_bitcoin.balzac"
    doge = OUT_DIR / "MultichainPaymentExchange_dogecoin.balzac"
    depth = OUT_DIR / "MultichainPaymentExchange_depth.txt"

    assert btc.exists()
    assert doge.exists()
    assert depth.exists()

    assert _max_tx_num(_read_text(btc)) == 207
    assert _max_tx_num(_read_text(doge)) == 207
    assert depth.read_text().strip() == "9"


def test_multichain_loan_mediator_compiles_and_stats_match():
    _run(["bash", "-lc", "./scripts/bitmlx_pipeline.sh MultichainLoanMediator"])

    btc = OUT_DIR / "MultichainLoanMediator_bitcoin.balzac"
    doge = OUT_DIR / "MultichainLoanMediator_dogecoin.balzac"
    depth = OUT_DIR / "MultichainLoanMediator_depth.txt"

    assert btc.exists()
    assert doge.exists()
    assert depth.exists()

    assert _max_tx_num(_read_text(btc)) == 4098
    assert _max_tx_num(_read_text(doge)) == 4098
    assert depth.read_text().strip() == "27"
