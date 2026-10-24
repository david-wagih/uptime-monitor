import asyncio

import httpx

from uptime.checker import check_url
from uptime.db import SessionLocal
from uptime.models import CheckResult, Monitor
from uptime.worker import run_once


def fake_client(handler) -> httpx.AsyncClient:
    return httpx.AsyncClient(transport=httpx.MockTransport(handler))


def check(handler, url="https://example.com"):
    async def go():
        async with fake_client(handler) as client:
            return await check_url(client, url)

    return asyncio.run(go())


def test_check_up():
    outcome = check(lambda request: httpx.Response(200))
    assert outcome.is_up and outcome.status_code == 200 and outcome.latency_ms is not None


def test_check_down_on_server_error():
    outcome = check(lambda request: httpx.Response(503))
    assert not outcome.is_up and outcome.status_code == 503


def test_check_down_on_connection_error():
    def refuse(request):
        raise httpx.ConnectError("connection refused")

    outcome = check(refuse)
    assert not outcome.is_up and outcome.status_code is None
    assert "ConnectError" in outcome.error


def test_run_once_stores_results():
    with SessionLocal() as session:
        session.add_all(
            [Monitor(name="ok", url="https://ok.test"), Monitor(name="bad", url="https://bad.test")]
        )
        session.commit()

    def handler(request):
        return httpx.Response(200 if request.url.host == "ok.test" else 500)

    async def go():
        async with fake_client(handler) as client:
            return await run_once(client)

    assert asyncio.run(go()) == 2
    with SessionLocal() as session:
        results = {r.status_code: r.is_up for r in session.query(CheckResult)}
    assert results == {200: True, 500: False}
