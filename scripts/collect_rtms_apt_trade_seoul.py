# -*- coding: utf-8 -*-
"""서울(sido_cd=11) 아파트 매매 실거래 수집 → PostgreSQL + CSV/JSON

C:\\ClaudeAI\\.env 설정 예:
  DB_HOST / DB_PORT / DB_NAME / DB_USER / DB_PASSWORD
  BASE_URL / TRADE_BASIC / TRADE_BASIC_SVC / TRADE_BASIC_FMT
  DEFAULT_PAGE_NO / DEFAULT_ROWS_CNT
  SERVICE_KEY (또는 serviceKey / DATA_GO_SERVICE_KEY)

조건:
  - StanRegin.sido_cd = 11 → lawd_cd
  - deal_ymd = 202401 ~ 202610
  - 페이지 간 대기 0.5초
  - RtmsDataTrade DROP 후 재생성
  - API 오류 skip + RawData\\*.log

실행:
  pip install requests psycopg2-binary python-dotenv
  python collect_rtms_apt_trade_seoul.py
"""
from __future__ import annotations

import csv
import json
import os
import time
import traceback
import xml.etree.ElementTree as ET
from datetime import datetime
from pathlib import Path
from typing import Any
from urllib.parse import unquote

import requests
from dotenv import load_dotenv
import psycopg2
from psycopg2.extras import execute_batch

# ---------------------------------------------------------------------------
# 경로
# ---------------------------------------------------------------------------
ENV_PATH = Path(r"C:\ClaudeAI\.env")
OUT_DIR = Path(r"C:\ClaudeAI\myProject03\RawData")

DEAL_YMD_FROM = "202401"
DEAL_YMD_TO = "202610"
PAGE_DELAY_SEC = 0.5
REQUEST_TIMEOUT = 60

# 응답 필드 (영문 camelCase + 구 API 한글 태그)
API_FIELDS = [
    # Dev / 신규
    "aptDong", "aptNm", "aptSeq", "bonbun", "bubun", "buildYear", "buyerGbn",
    "cdealDay", "cdealType", "dealAmount", "dealDay", "dealMonth", "dealYear",
    "dealingGbn", "estateAgentSggNm", "excluUseAr", "floor", "jibun",
    "landLeaseholdGbn", "rgstDate", "roadNm", "sggCd", "slerGbn", "umdNm",
    # 구(한글) 태그 — Basic XML 호환
    "거래금액", "건축년도", "년", "월", "일", "아파트", "전용면적", "지번",
    "지역코드", "층", "법정동", "도로명", "거래유형", "중개사소재지",
    "해제여부", "해제사유발생일",
]
AUDIT_FIELDS = ["erdate", "ertime", "aedate", "aetime"]

# 한글 → 영문 매핑(가능하면 영문 컬럼에도 채움)
KO_TO_EN = {
    "거래금액": "dealAmount",
    "건축년도": "buildYear",
    "년": "dealYear",
    "월": "dealMonth",
    "일": "dealDay",
    "아파트": "aptNm",
    "전용면적": "excluUseAr",
    "지번": "jibun",
    "지역코드": "sggCd",
    "층": "floor",
    "법정동": "umdNm",
    "도로명": "roadNm",
    "거래유형": "dealingGbn",
    "중개사소재지": "estateAgentSggNm",
}


def now_audit() -> dict[str, str]:
    n = datetime.now()
    return {
        "erdate": n.strftime("%Y%m%d"),
        "ertime": n.strftime("%H%M%S"),
        "aedate": n.strftime("%Y%m%d"),
        "aetime": n.strftime("%H%M%S"),
    }


def month_range(start_yyyymm: str, end_yyyymm: str) -> list[str]:
    y, m = int(start_yyyymm[:4]), int(start_yyyymm[4:6])
    ey, em = int(end_yyyymm[:4]), int(end_yyyymm[4:6])
    out: list[str] = []
    while (y, m) <= (ey, em):
        out.append(f"{y:04d}{m:02d}")
        m += 1
        if m > 12:
            m, y = 1, y + 1
    return out


def env_first(*keys: str, default: str | None = None) -> str | None:
    for k in keys:
        v = os.getenv(k)
        if v is not None and str(v).strip() != "":
            return str(v).strip()
    return default


def load_config() -> dict[str, Any]:
    if not ENV_PATH.is_file():
        raise SystemExit(f".env 없음: {ENV_PATH}")
    load_dotenv(ENV_PATH, interpolate=True)

    base = (env_first("BASE_URL") or "https://apis.data.go.kr").rstrip("/")
    # Basic (사용자 .env)
    trade_path = (env_first("TRADE_BASIC") or "1613000/RTMSDataSvcAptTrade").strip("/")
    trade_svc = env_first("TRADE_BASIC_SVC") or "getRTMSDataSvcAptTrade"
    # Dev 오버라이드가 있으면 우선 (원래 요청명)
    if env_first("TRADE_DEV", "TRADE_DEV_SVC"):
        trade_path = (env_first("TRADE_DEV") or "1613000/RTMSDataSvcAptTradeDev").strip("/")
        trade_svc = env_first("TRADE_DEV_SVC") or "getRTMSDataSvcAptTradeDev"

    api_url = env_first("TRADE_BASIC_URL", "TRADE_DEV_URL", "RTMS_APT_TRADE_URL")
    if not api_url or "${" in api_url:
        api_url = f"{base}/{trade_path}/{trade_svc}"

    fmt = (env_first("TRADE_BASIC_FMT", "TRADE_DEV_FMT") or "JSON").upper()
    page_no = int(env_first("DEFAULT_PAGE_NO") or "1")
    rows = int(env_first("DEFAULT_ROWS_CNT") or "100")

    service_key = env_first(
        "SERVICE_KEY",
        "serviceKey",
        "DATA_GO_SERVICE_KEY",
        "RTMS_SERVICE_KEY",
        "API_KEY",
        "Decoding",
        "DECODING_KEY",
    )
    if not service_key:
        raise SystemExit(
            ".env에 SERVICE_KEY (또는 serviceKey / DATA_GO_SERVICE_KEY) 가 필요합니다."
        )
    if "%" in service_key:
        service_key = unquote(service_key)

    return {
        "api_url": api_url,
        "service_key": service_key,
        "fmt": fmt,
        "page_no": page_no,
        "rows": rows,
        "svc_name": trade_svc,
    }


def out_paths(svc_name: str) -> tuple[Path, Path, Path]:
    csv_p = OUT_DIR / f"{svc_name}_Seoul.csv"
    json_p = OUT_DIR / f"{svc_name}_Seoul.json"
    log_p = OUT_DIR / f"{svc_name}.log"
    return csv_p, json_p, log_p


def log_error(log_path: Path, msg: str) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    line = f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {msg}\n"
    with log_path.open("a", encoding="utf-8") as f:
        f.write(line)
    print("ERROR:", msg)


def pg_connect():
    dsn = env_first("DATABASE_URL", "POSTGRES_URL", "PG_DSN")
    if dsn:
        return psycopg2.connect(dsn)
    host = env_first("DB_HOST", "PGHOST", default="localhost")
    port = env_first("DB_PORT", "PGPORT", default="5432")
    user = env_first("DB_USER", "PGUSER")
    password = env_first("DB_PASSWORD", "PGPASSWORD")
    dbname = env_first("DB_NAME", "PGDATABASE")
    if not all([user, password, dbname]):
        raise SystemExit(".env에 DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASSWORD 필요")
    return psycopg2.connect(
        host=host, port=port, user=user, password=password, dbname=dbname
    )


def fetch_lawd_cds(conn) -> list[str]:
    candidates = [
        '''SELECT DISTINCT TRIM(lawd_cd::text) FROM "StanRegin"
           WHERE sido_cd::text='11' AND lawd_cd IS NOT NULL ORDER BY 1''',
        '''SELECT DISTINCT TRIM("LAWD_CD"::text) FROM "StanRegin"
           WHERE "SIDO_CD"::text='11' AND "LAWD_CD" IS NOT NULL ORDER BY 1''',
        '''SELECT DISTINCT TRIM(lawd_cd::text) FROM stanregin
           WHERE sido_cd::text='11' AND lawd_cd IS NOT NULL ORDER BY 1''',
    ]
    last_err = None
    with conn.cursor() as cur:
        for sql in candidates:
            try:
                cur.execute(sql)
                cleaned: list[str] = []
                for (x,) in cur.fetchall():
                    if not x:
                        continue
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
    raise RuntimeError(f"StanRegin lawd_cd 조회 실패: {last_err}")


def parse_xml_items(text: str) -> tuple[str, str, int, list[dict[str, str]]]:
    root = ET.fromstring(text)
    code = (root.findtext(".//resultCode") or "").strip()
    msg = (root.findtext(".//resultMsg") or "").strip()
    try:
        total = int((root.findtext(".//totalCount") or "0").strip())
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


def parse_json_payload(data: Any) -> tuple[str, str, int, list[dict[str, str]]]:
    # OpenAPI 오류 래퍼
    if isinstance(data, dict) and "OpenAPI_ServiceResponse" in data:
        cmm = data["OpenAPI_ServiceResponse"].get("cmmMsgHeader", {})
        code = str(cmm.get("returnReasonCode", cmm.get("errMsg", "ERR")))
        msg = str(cmm.get("returnAuthMsg", cmm.get("errMsg", "")))
        return code, msg, 0, []

    header = data.get("response", {}).get("header", data.get("header", {}))
    body = data.get("response", {}).get("body", data.get("body", {}))
    code = str(header.get("resultCode", "")).strip()
    msg = str(header.get("resultMsg", "")).strip()
    try:
        total = int(body.get("totalCount") or 0)
    except (TypeError, ValueError):
        total = 0
    raw_items = body.get("items", {})
    if raw_items is None or raw_items == "":
        items = []
    elif isinstance(raw_items, dict):
        items = raw_items.get("item", [])
    else:
        items = raw_items or []
    if isinstance(items, dict):
        items = [items]
    if not isinstance(items, list):
        items = []
    norm = []
    for it in items:
        if isinstance(it, dict):
            norm.append({k: ("" if v is None else str(v).strip()) for k, v in it.items()})
    return code, msg, total, norm


def fetch_page(
    session: requests.Session,
    api_url: str,
    service_key: str,
    lawd_cd: str,
    deal_ymd: str,
    page_no: int,
    num_of_rows: int,
    fmt: str,
) -> tuple[str, str, int, list[dict[str, str]]]:
    params: dict[str, str] = {
        "serviceKey": service_key,
        "LAWD_CD": lawd_cd,
        "DEAL_YMD": deal_ymd,
        "pageNo": str(page_no),
        "numOfRows": str(num_of_rows),
    }
    if fmt == "JSON":
        params["_type"] = "json"

    resp = session.get(api_url, params=params, timeout=REQUEST_TIMEOUT)
    resp.raise_for_status()
    text = resp.text
    ctype = (resp.headers.get("Content-Type") or "").lower()

    if fmt == "JSON" or "json" in ctype or text.lstrip().startswith("{"):
        try:
            return parse_json_payload(resp.json())
        except json.JSONDecodeError:
            # JSON 요청인데 XML이 온 경우
            return parse_xml_items(text)
    return parse_xml_items(text)


def is_ok_code(code: str) -> bool:
    return code in ("00", "000", "0", "")


def is_nodata(code: str, msg: str) -> bool:
    m = (msg or "").upper()
    return code.strip() in ("03", "3") or "NO DATA" in m or "NODATA" in m.replace(" ", "")


def recreate_table(conn) -> None:
    # PostgreSQL 식별자: 한글 컬럼은 따옴표 필요
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
'''
    with conn.cursor() as cur:
        cur.execute(ddl)
    conn.commit()
    print('테이블 "RtmsDataTrade" DROP + CREATE 완료')


def normalize_item(lawd_cd: str, item: dict[str, str], audit: dict[str, str]) -> dict[str, str]:
    row: dict[str, str] = {"lawd_cd": lawd_cd}
    for f in API_FIELDS:
        row[f] = item.get(f, "")
    # 한글 → 영문 보조 채움
    for ko, en in KO_TO_EN.items():
        if item.get(ko) and not row.get(en):
            row[en] = item[ko]
        if ko in row and not row[ko] and item.get(en):
            row[ko] = item[en]
    row.update(audit)
    return row


def insert_rows(conn, rows: list[dict[str, Any]]) -> int:
    if not rows:
        return 0
    col_names = ["lawd_cd"] + API_FIELDS + AUDIT_FIELDS
    placeholders = ", ".join(["%s"] * len(col_names))
    quoted = ", ".join(f'"{c}"' for c in col_names)
    sql = f'INSERT INTO "RtmsDataTrade" ({quoted}) VALUES ({placeholders})'
    values = [tuple(r.get(c, "") for c in col_names) for r in rows]
    with conn.cursor() as cur:
        execute_batch(cur, sql, values, page_size=500)
    conn.commit()
    return len(values)


def save_csv_json(csv_path: Path, json_path: Path, rows: list[dict[str, str]]) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    fieldnames = ["lawd_cd"] + API_FIELDS + AUDIT_FIELDS
    with csv_path.open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        w.writeheader()
        for r in rows:
            w.writerow({k: r.get(k, "") for k in fieldnames})
    with json_path.open("w", encoding="utf-8") as f:
        json.dump(
            [{k: r.get(k, "") for k in fieldnames} for r in rows],
            f,
            ensure_ascii=False,
            indent=2,
        )
    print(f"CSV 저장: {csv_path} ({len(rows)}건)")
    print(f"JSON 저장: {json_path}")


def main() -> int:
    cfg = load_config()
    api_url = cfg["api_url"]
    service_key = cfg["service_key"]
    fmt = cfg["fmt"]
    rows_cnt = cfg["rows"]
    start_page = cfg["page_no"]
    svc_name = cfg["svc_name"]
    csv_path, json_path, log_path = out_paths(svc_name)

    months = month_range(DEAL_YMD_FROM, DEAL_YMD_TO)
    print("API URL :", api_url)
    print("FMT     :", fmt, "| rows:", rows_cnt)
    print(f"deal_ymd: {DEAL_YMD_FROM} ~ {DEAL_YMD_TO} ({len(months)}개월)")
    print("출력    :", csv_path.name, "/", json_path.name)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    log_path.write_text("", encoding="utf-8")

    conn = pg_connect()
    try:
        lawd_list = fetch_lawd_cds(conn)
        recreate_table(conn)

        all_rows: list[dict[str, str]] = []
        session = requests.Session()
        session.headers.update({"Accept": "application/json, application/xml, */*"})

        total_ok = 0
        total_skip = 0

        for i, lawd_cd in enumerate(lawd_list, 1):
            print(f"\n[{i}/{len(lawd_list)}] lawd_cd={lawd_cd}")
            for deal_ymd in months:
                page = start_page
                while True:
                    try:
                        code, msg, total, items = fetch_page(
                            session,
                            api_url,
                            service_key,
                            lawd_cd,
                            deal_ymd,
                            page,
                            rows_cnt,
                            fmt,
                        )
                    except Exception as e:
                        total_skip += 1
                        log_error(
                            log_path,
                            f"API 예외 lawd_cd={lawd_cd} deal_ymd={deal_ymd} page={page}: {e}\n"
                            f"{traceback.format_exc()}",
                        )
                        break

                    if is_nodata(code, msg):
                        break

                    if not is_ok_code(code):
                        total_skip += 1
                        log_error(
                            log_path,
                            f"API 오류 lawd_cd={lawd_cd} deal_ymd={deal_ymd} page={page} "
                            f"resultCode={code} resultMsg={msg}",
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

                    fetched = page * rows_cnt
                    if not items or fetched >= total:
                        break
                    page += 1
                    time.sleep(PAGE_DELAY_SEC)

        save_csv_json(csv_path, json_path, all_rows)
        print(f"\n완료: 적재 {total_ok}건, 오류 skip {total_skip}건")
        print(f"오류 로그: {log_path}")
        return 0
    finally:
        conn.close()


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("중단됨")
        raise SystemExit(130)
