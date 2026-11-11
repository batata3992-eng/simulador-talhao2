"""Contratos da página de Análise Agronômica (analise.html) integrada à API."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HTML = (ROOT / "analise.html").read_text(encoding="utf-8")
MAIN = (ROOT / "backend" / "main.py").read_text(encoding="utf-8")
BAT = (ROOT / "run.bat").read_text(encoding="utf-8")


def test_analysis_uses_shared_app_js_and_real_endpoints():
    assert '<script src="app.js"></script>' in HTML
    assert "/analytics/farm/${farmId}?layer=${layer}" in HTML
    assert 'apiGet("/farms")' in HTML


def test_analysis_has_no_hardcoded_demo_data():
    assert "demoTalhoes" not in HTML and "demoSeries" not in HTML
    assert "USE_API = false" not in HTML


def test_analysis_requires_login_and_handles_401():
    assert 'window.location.href = "auth.html"' in HTML
    assert "res.status === 401" in HTML


def test_analysis_warns_when_data_is_not_real_sentinel():
    assert "Dados Sentinel-2 L2A reais" in HTML
    assert "Dados procedurais" in HTML and "Valores de contingência" in HTML


def test_backend_serves_analysis_page():
    assert '"analise.html"' in MAIN.split("_FRONTEND_STATIC_FILES")[1].split("\n")[0]


def test_launcher_starts_backend_and_frontend():
    assert "uvicorn main:app" in BAT and "http.server" in BAT and "analise.html" in BAT
