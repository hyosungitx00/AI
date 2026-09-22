# 활성화 체크리스트 (SE38/SE80 사용자용)

> 코드를 붙여넣은 뒤, 아래를 위에서부터 실행한다. □ 가 하나라도 실패하면 다음으로 가지 않는다.

## 1. 생성·저장

- [ ] 오브젝트명·패키지·TR이 `00-common` §0과 일치한다 (오타·`ZTEST` 없음)
- [ ] 프로그램 속성(Type=Executable/Module Pool/Function Group)이 맞다
- [ ] Top/Main/Subroutine/Include 분할 시 **생성 순서**(Harness §3.1)를 지켰다

## 2. 정적 검사

- [ ] `Ctrl+F2` Syntax Check → 에러 0건 (경고는 사유 기록)
- [ ] Extended Check(SLAM/SCI, `Ctrl+F3`) → Error 0건
- [ ] 금지 문법 검사: 릴리스(ECC/7.40/7.50) 초과 문법 없음 (`DATA(`·`VALUE #()` 등)
- [ ] `SELECT *` 없음, `FOR ALL ENTRIES` 앞 빈 체크 있음

## 3. 실행 스모크

- [ ] F8 실행 → 선택화면/첫 화면 표시
- [ ] T1(대표값) 입력 → 덤프 없이 결과 표시
- [ ] T2(0건)·T3(권한/검증실패) → 규정 메시지 표시

## 4. 실패 시 회수물 (그대로 AI에 붙여넣기)

```text
- 프로그램:
- 입력값(T1/T2/T3 중):
- 메시지 전문:
- ST22 덤프명:
- 에러 행번호(Syntax):
- SY-SUBRC:
```
