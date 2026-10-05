# getRTMSDataSvcAptTradeDev (서울) 수집 스크립트

## 실행

```bat
pip install -r requirements-rtms.txt
python collect_rtms_apt_trade_seoul.py
```

## `.env` (`C:\ClaudeAI\.env`) 예

```env
# PostgreSQL
PGHOST=localhost
PGPORT=5432
PGUSER=postgres
PGPASSWORD=your_password
PGDATABASE=your_db
# 또는 DATABASE_URL=postgresql://user:pass@host:5432/dbname

# 공공데이터포털 인증키 (Decoding 키 권장 — 스크립트가 재인코딩)
DATA_GO_SERVICE_KEY=발급키

# 선택: API URL 오버라이드
# RTMS_APT_TRADE_URL=http://apis.data.go.kr/1613000/RTMSDataSvcAptTradeDev/getRTMSDataSvcAptTradeDev
```

## 동작 요약

1. `StanRegin` where `sido_cd=11` → `lawd_cd` 목록
2. `deal_ymd` 202401~202610, API 페이징(페이지당 1000, 페이지 간 0.5초)
3. `"RtmsDataTrade"` DROP 후 재생성 → INSERT
4. CSV/JSON/오류 로그를 `C:\ClaudeAI\myProject03\RawData\` 에 저장
