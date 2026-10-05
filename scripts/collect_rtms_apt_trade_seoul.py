# -*- coding: utf-8 -*-
"""서울(sido_cd=11) 아파트 매매 실거래 수집 → PostgreSQL + CSV/JSON

대상 API: getRTMSDataSvcAptTradeDev
조건:
  - StanRegin.sido_cd = 11 의 lawd_cd 별 호출
  - deal_ymd = 202401 ~ 202610
  - 페이지 간 대기 0.5초
  - RtmsDataTrade 있으면 DROP 후 재생성
  - API 오류 건은 skip + 로그 기록

경로(Windows):
  C:\\ClaudeAI\\.env
  C:\\ClaudeAI\\myProject03\\RawData\\getRTMSDataSvcAptTradeDev_Seoul.csv
  C:\\ClaudeAI\\myProject03\\RawData\\getRTMSDataSvcAptTradeDev_Seoul.json
  C:\\ClaudeAI\\myProject03\\RawData\\getRTMSDataSvcAptTradeDev.log

실행:
  pip install requests psycopg2-binary python-dotenv
  python collect_rtms_apt_trade_seoul.py
"""
from __future__ import annotations

import csv
import json
import os
import sys
import time
import traceback
import xml.etree.ElementTree as ET
from datetime import datetime
from pathlib import Path
from typing import Any
from urllib.parse import unquote

import requests

try:
    from dotenv import load_dotenv
except ImportError:
    load_dotenv = None  # type: ignore

try:
    import psycopg2
    from psycopg2.extras import execute_batch
except ImportError:
    print("psycopg2 필요: pip install psycopg2-binary")
    raise

# ---------------------------------------------------------------------------
# 경로 / 상수
# ---------------------------------------------------------------------------
ENV_PATH = Path(r"C:\ClaudeAI\.env")
OUT_DIR = Path(r"C:\ClaudeAI\myProject03\RawData")
CSV_PATH = OUT_DIR / "getRTMSDataSvcAptTradeDev_Seoul.csv"
JSON_PATH = OUT_DIR / "getRTMSDataSvcAptTradeDev_Seoul.json"
LOG_PATH = OUT_DIR / "getRTMSDataSvcAptTradeDev.log"

DEFAULT_API_URL = (
    "http://apis.data.go.kr/1613000/RTMSDataSvcAptTradeDev/getRTMSDataSvcAptTradeDev"
)

DEAL_YMD_FROM = "202401"
DEAL_YMD_TO = "202610"
PAGE_DELAY_SEC = 0.5
NUM_OF_ROWS = 1000
REQUEST_TIMEOUT = 60

# API item 표준 필드 (Dev) — 응답에 없으면 NULL
API_FIELDS = [
    "aptDong",
    "aptNm",
    "aptSeq",
    "bonbun",
    "bubun",
    "buildYear",
    "buyerGbn",
    "cdealDay",
    "cdealType",
    "dealAmount",
    "dealDay",
    "dealMonth",
    "dealYear",
    "dealingGbn",
    "estateAgentSggNm",
    "excluUseAr",
    "floor",
    "jibun",
    "landLeaseholdGbn",
    "rgstDate",
    "roadNm",
    "sggCd",
    "slerGbn",
    "umdNm",
]

AUDIT_FIELDS = ["erdate", "ertime", "aedate", "aetime"]


# ---------------------------------------------------------------------------
# 유틸
# ---------------------------------------------------------------------------
def now_audit() -> dict[str, str]:
    n = datetime.now()
    return {
        "erdate": n.strftime("%Y%m%d"),
        "ertime": n.strftime("%H%M%S"),
        "aedate": n.strftime("%Y%m%d"),
        "aetime": n.strftime("%H%M%S"),
    }


def log_error(msg: str) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    line = f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {msg}\n"
    with LOG_PATH.open("a", encoding="utf-8") as f:
        f.write(line)
    print("ERROR:", msg)


def month_range(start_yyyymm: str, end_yyyymm: str) -> list[str]:
    y = int(start_yyyymm[:4])
    m = int(start_yyyymm[4:6])
    ey = int(end_yyyymm[:4])
    em = int(end_yyyymm[4:6])
    out: list[str] = []
    while (y, m) <= (ey, em):
        out.append(f"{y:04d}{m:02d}")
        m += 1
        if m > 12:
            m = 1
            y += 1
    return out


def load_env() -> None:
    if load_dotenv is None:
        raise SystemExit("python-dotenv 필요: pip install python-dotenv")
    if not ENV_PATH.is_file():
        raise SystemExit(f".env 없음: {ENV_PATH}")
    load_dotenv(ENV_PATH)


def env_first(*keys: str, default: str | None = None) -> str | None:
    for k in keys:
        v = os.getenv(k)
        if v is not None and str(v).strip() != "":
            return str(v).strip()
    return default


def get_service_key() -> str:
    key = env_first(
        "DATA_GO_SERVICE_KEY",
        "RTMS_SERVICE_KEY",
        "serviceKey",
        "SERVICE_KEY",
        "공공데이터_서비스키",
    )
    if not key:
        raise SystemExit(
            ".env에 DATA_GO_SERVICE_KEY (또는 serviceKey / RTMS_SERVICE_KEY) 필요"
        )
    # 이중 인코딩 방지: 이미 인코딩된 키면 디코드 후 requests가 다시 인코딩
    if "%" in key:
        key = unquote(key)
    return key


def get_api_url() -> str:
    return env_first(
        "RTMS_APT_TRADE_URL",
        "getRTMSDataSvcAptTradeDev",
        "DATA_GO_RTMS_APT_TRADE_URL",
        default=DEFAULT_API_URL,
    ) or DEFAULT_API_URL


def pg_connect():
    dsn = env_first("DATABASE_URL", "POSTGRES_URL", "PG_DSN")
    if dsn:
        return psycopg2.connect(dsn)
    host = env_first("PGHOST", "DB_HOST", "POSTGRES_HOST", default="localhost")
    port = env_first("PGPORT", "DB_PORT", "POSTGRES_PORT", default="5432")
    user = env_first("PGUSER", "DB_USER", "POSTGRES_USER")
    password = env_first("PGPASSWORD", "DB_PASSWORD", "POSTGRES_PASSWORD")
    dbname = env_first("PGDATABASE", "DB_NAME", "POSTGRES_DB")
    if not all([user, password, dbname]):
        raise SystemExit(
            ".env에 DATABASE_URL 또는 PGHOST/PGUSER/PGPASSWORD/PGDATABASE 필요"
        )
    return psycopg2.connect(
        host=host, port=port, user=user, password=password, dbname=dbname
    )


# ---------------------------------------------------------------------------
# StanRegin
# ---------------------------------------------------------------------------
def fetch_lawd_cds(conn) -> list[str]:
    """sido_cd = 11 인 lawd_cd 목록 (컬럼 대소문자 유연)."""
    candidates = [
        '''SELECT DISTINCT TRIM(lawd_cd::text) AS lawd_cd
           FROM "StanRegin" WHERE sido_cd::text = '11'
           AND lawd_cd IS NOT NULL ORDER BY 1''',
        '''SELECT DISTINCT TRIM("LAWD_CD"::text) AS lawd_cd
           FROM "StanRegin" WHERE "SIDO_CD"::text = '11'
           AND "LAWD_CD" IS NOT NULL ORDER BY 1''',
        '''SELECT DISTINCT TRIM(lawd_cd::text) AS lawd_cd
           FROM stanregin WHERE sido_cd::text = '11'
           AND lawd_cd IS NOT NULL ORDER BY 1''',
        '''SELECT DISTINCT TRIM(region_cd::text) AS lawd_cd
           FROM "StanRegin" WHERE sido_cd::text = '11'
           AND region_cd IS NOT NULL ORDER BY 1''',
    ]
    last_err = None
    with conn.cursor() as cur:
        for sql in candidates:
            try:
                cur.execute(sql)
                rows = [r[0] for r in cur.fetchall() if r[0]]
                # 법정동 5자리(시군구)만 — 10자리면 앞 5자리
                cleaned = []
                for x in rows:
                    s = str(x).strip()
                    if len(s) >= 5:
                        s = s[:5]
                    if s.isdigit() and len(s) == 5:
                        cleaned.append(s)
                cleaned = sorted(set(cleaned))
                if cleaned:
                    print(f"StanRegin lawd_cd {len(cleaned)}건")
                    return cleaned
            except Exception as e:
                last_err = e
                conn.rollback()
    raise RuntimeError(f"StanRegin에서 lawd_cd 조회 실패: {last_err}")


# ---------------------------------------------------------------------------
# API
# ---------------------------------------------------------------------------
def parse_xml_items(text: str) -> tuple[str, str, int, list[dict[str, str]]]:
    """return resultCode, resultMsg, totalCount, items"""
    root = ET.fromstring(text)
    code = (root.findtext(".//resultCode") or "").strip()
    msg = (root.findtext(".//resultMsg") or "").strip()
    total_s = (root.findtext(".//totalCount") or "0").strip()
    try:
        total = int(total_s)
    except ValueError:
        total = 0

    items: list[dict[str, str]] = []
    for item in root.findall(".//item"):
        row: dict[str, str] = {}
        for child in list(item):
            tag = child.tag.split("}")[-1] if "}" in child.tag else child.tag
            row[tag] = (child.text or "").strip()
        items.append(row)
    return code, msg, total, items


def fetch_page(
    session: requests.Session,
    api_url: str,
    service_key: str,
    lawd_cd: str,
    deal_ymd: str,
    page_no: int,
) -> tuple[str, str, int, list[dict[str, str]]]:
    params = {
        "serviceKey": service_key,
        "LAWD_CD": lawd_cd,
        "DEAL_YMD": deal_ymd,
        "pageNo": str(page_no),
        "numOfRows": str(NUM_OF_ROWS),
    }
    resp = session.get(api_url, params=params, timeout=REQUEST_TIMEOUT)
    resp.raise_for_status()
    # 일부 게이트웨이는 JSON
    ctype = (resp.headers.get("Content-Type") or "").lower()
    text = resp.text
    if "json" in ctype or text.lstrip().startswith("{"):
        data = resp.json()
        header = data.get("response", {}).get("header", data.get("header", {}))
        body = data.get("response", {}).get("body", data.get("body", {}))
        code = str(header.get("resultCode", "")).strip()
        msg = str(header.get("resultMsg", "")).strip()
        total = int(body.get("totalCount") or 0)
        raw_items = body.get("items", {})
        if isinstance(raw_items, dict):
            items = raw_items.get("item", [])
        else:
            items = raw_items or []
        if isinstance(items, dict):
            items = [items]
        norm = []
        for it in items:
            if isinstance(it, dict):
                norm.append({k: ("" if v is None else str(v).strip()) for k, v in it.items()})
        return code, msg, total, norm
    return parse_xml_items(text)


def is_ok_code(code: str) -> bool:
    return code in ("00", "000", "0", "")


def is_nodata(code: str, msg: str) -> bool:
    c = code.strip()
    m = (msg or "").upper()
    return c in ("03", "3") or "NO DATA" in m or "NODATA" in m.replace(" ", "")


# ---------------------------------------------------------------------------
# DB DDL / DML
# ---------------------------------------------------------------------------
def recreate_table(conn) -> None:
    cols_api = ",\n  ".join(f'"{c}" TEXT' for c in API_FIELDS)
    ddl = f'''
DROP TABLE IF EXISTS "RtmsDataTrade";
CREATE TABLE "RtmsDataTrade" (
  id BIGSERIAL PRIMARY KEY,
  lawd_cd VARCHAR(10) NOT NULL,
  {cols_api},
  erdate CHAR(8) NOT NULL,
  ertime CHAR(6) NOT NULL,
  aedate CHAR(8) NOT NULL,
  aetime CHAR(6) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_rtmsdatatrade_lawd ON "RtmsDataTrade"(lawd_cd);
CREATE INDEX IF NOT EXISTS idx_rtmsdatatrade_deal
  ON "RtmsDataTrade"("dealYear", "dealMonth");
'''
    with conn.cursor() as cur:
        cur.execute(ddl)
    conn.commit()
    print('테이블 "RtmsDataTrade" DROP + CREATE 완료')


def insert_rows(conn, rows: list[dict[str, Any]]) -> int:
    if not rows:
        return 0
    col_names = ["lawd_cd"] + API_FIELDS + AUDIT_FIELDS
    placeholders = ", ".join(["%s"] * len(col_names))
    quoted = ", ".join(f'"{c}"' for c in col_names)
    sql = f'INSERT INTO "RtmsDataTrade" ({quoted}) VALUES ({placeholders})'
    values = []
    for r in rows:
        values.append(tuple(r.get(c, "") for c in col_names))
    with conn.cursor() as cur:
        execute_batch(cur, sql, values, page_size=500)
    conn.commit()
    return len(values)


def normalize_item(lawd_cd: str, item: dict[str, str], audit: dict[str, str]) -> dict[str, str]:
    row = {"lawd_cd": lawd_cd}
    for f in API_FIELDS:
        row[f] = item.get(f, "")
    # API에 있는데 표준 목록 외 필드는 버림(DDL 고정). 필요 시 로그.
    row.update(audit)
    return row


# ---------------------------------------------------------------------------
# 파일 저장
# ---------------------------------------------------------------------------
def save_csv_json(rows: list[dict[str, str]]) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    fieldnames = ["lawd_cd"] + API_FIELDS + AUDIT_FIELDS
    with CSV_PATH.open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        w.writeheader()
        for r in rows:
            w.writerow({k: r.get(k, "") for k in fieldnames})
    with JSON_PATH.open("w", encoding="utf-8") as f:
        json.dump(
            [{k: r.get(k, "") for k in fieldnames} for r in rows],
            f,
            ensure_ascii=False,
            indent=2,
        )
    print(f"CSV 저장: {CSV_PATH} ({len(rows)}건)")
    print(f"JSON 저장: {JSON_PATH}")


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
def main() -> int:
    load_env()
    service_key = get_service_key()
    api_url = get_api_url()
    months = month_range(DEAL_YMD_FROM, DEAL_YMD_TO)
    print("API:", api_url)
    print(f"deal_ymd: {DEAL_YMD_FROM} ~ {DEAL_YMD_TO} ({len(months)}개월)")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    # 로그 파일 새로 시작
    LOG_PATH.write_text("", encoding="utf-8")

    conn = pg_connect()
    try:
        lawd_list = fetch_lawd_cds(conn)
        recreate_table(conn)

        all_rows: list[dict[str, str]] = []
        session = requests.Session()
        session.headers.update({"Accept": "application/xml, application/json, */*"})

        total_ok = 0
        total_skip = 0

        for i, lawd_cd in enumerate(lawd_list, 1):
            print(f"\n[{i}/{len(lawd_list)}] lawd_cd={lawd_cd}")
            for deal_ymd in months:
                page = 1
                while True:
                    try:
                        code, msg, total, items = fetch_page(
                            session, api_url, service_key, lawd_cd, deal_ymd, page
                        )
                    except Exception as e:
                        total_skip += 1
                        log_error(
                            f"API 예외 lawd_cd={lawd_cd} deal_ymd={deal_ymd} "
                            f"page={page}: {e}\n{traceback.format_exc()}"
                        )
                        break

                    if is_nodata(code, msg):
                        # 해당 월 데이터 없음 → 정상 skip
                        break

                    if not is_ok_code(code):
                        total_skip += 1
                        log_error(
                            f"API 오류 lawd_cd={lawd_cd} deal_ymd={deal_ymd} "
                            f"page={page} resultCode={code} resultMsg={msg}"
                        )
                        break

                    audit = now_audit()
                    batch = [normalize_item(lawd_cd, it, audit) for it in items]
                    if batch:
                        insert_rows(conn, batch)
                        all_rows.extend(batch)
                        total_ok += len(batch)
                        print(
                            f"  {deal_ymd} p{page}: +{len(batch)} "
                            f"(누적 {total_ok}, totalCount={total})"
                        )

                    # 다음 페이지?
                    fetched = page * NUM_OF_ROWS
                    if not items or fetched >= total:
                        break
                    page += 1
                    time.sleep(PAGE_DELAY_SEC)

        save_csv_json(all_rows)
        print(f"\n완료: 적재 {total_ok}건, 오류 skip {total_skip}건")
        print(f"오류 로그: {LOG_PATH}")
        return 0
    finally:
        conn.close()


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("중단됨")
        raise SystemExit(130)
