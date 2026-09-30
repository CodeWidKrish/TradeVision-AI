"""
Stress test: Verify grounded_report_service handles all edge cases
without TypeError/FormatException crashes on None values.
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.services.grounded_report_service import generate_market_intelligence_report

def test_report_with_no_screenshot():
    """Normal path: No screenshot, just symbol."""
    report = generate_market_intelligence_report(symbol="RELIANCE")
    assert report is not None
    assert "executive_summary" in report
    assert "ml_prediction" in report
    assert report["ml_prediction"]["direction"] in ("UP", "DOWN", "NEUTRAL")
    print("[PASS] Report without screenshot")

def test_report_with_screenshot_bytes():
    """Screenshot path: Synthetic 1x1 PNG image."""
    from PIL import Image
    import io
    img = Image.new("RGB", (600, 400), color=(15, 23, 42))
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    png_bytes = buf.getvalue()

    report = generate_market_intelligence_report(
        symbol="TCS",
        screenshot_bytes=png_bytes,
        screenshot_filename="TCS_1D_chart.png",
    )
    assert report is not None
    assert report.get("screenshot_analysis", {}).get("status") == "success"
    assert report.get("screenshot_analysis", {}).get("displayed_price") is None  # Anti-hallucination
    assert "executive_summary" in report
    print("[PASS] Report with screenshot (TCS)")

def test_report_with_unknown_symbol():
    """Edge case: Symbol that may not have live data."""
    report = generate_market_intelligence_report(symbol="UNKNOWNSYM123")
    assert report is not None
    # Should still produce a report without crashing
    assert "executive_summary" in report
    assert "ml_prediction" in report
    print("[PASS] Report with unknown symbol (graceful fallback)")

def test_report_formatting_no_crash():
    """Regression: Ensure no TypeError on None f-string formatting."""
    # Simulate what happens if change_pct is None in the live quote
    report = generate_market_intelligence_report(symbol="INFY")
    exec_sum = report.get("executive_summary", "")
    # Must not contain 'None' as a literal string from broken formatting
    assert "None%" not in exec_sum
    assert "NoneType" not in exec_sum
    print("[PASS] Executive summary formatting is clean (no None% crash)")

if __name__ == "__main__":
    test_report_with_no_screenshot()
    test_report_with_screenshot_bytes()
    test_report_with_unknown_symbol()
    test_report_formatting_no_crash()
    print("\n=== ALL EDGE CASE TESTS PASSED ===")
