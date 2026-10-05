# RTMS AptTrade 서울 수집

## `.env` (`C:\ClaudeAI\.env`) — 사용자 설정 기준

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=***

BASE_URL=https://apis.data.go.kr
DEFAULT_PAGE_NO=1
DEFAULT_ROWS_CNT=100

TRADE_BASIC=1613000/RTMSDataSvcAptTrade
TRADE_BASIC_SVC=getRTMSDataSvcAptTrade
TRADE_BASIC_URL=${BASE_URL}/${TRADE_BASIC}/${TRADE_BASIC_SVC}
TRADE_BASIC_FMT=JSON

# 필수 — 공공데이터포털 인증키
SERVICE_KEY=발급키
```

## 실행

```bat
pip install requests psycopg2-binary python-dotenv
python collect_rtms_apt_trade_seoul.py
```

출력: `RawData\getRTMSDataSvcAptTrade_Seoul.csv|json`, `getRTMSDataSvcAptTrade.log`
