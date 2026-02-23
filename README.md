# 퇴근 알리미 🚌

퇴근 시간에 맞춰 버스 도착 정보를 실시간으로 모니터링하고, 최적의 출발 시점에 알림을 보내는 macOS 메뉴바 앱입니다.

## 주요 기능

- **메뉴바 상주** — Dock 아이콘 없이 메뉴바에서만 동작
- **실시간 버스 도착 정보** — 서울시 공공 버스 API를 통해 60초 간격 조회
- **다중 버스 모니터링** — 여러 노선을 동시에 모니터링, 가장 빠른 버스 기준 알림
- **스마트 알림** — 도보 + 엘리베이터 + 여유 시간을 계산하여 출발 시점 알림
- **자동 도보 시간 계산** — MapKit 활용, 사무실 → 정류소 도보 시간 자동 계산
- **노선 확인** — 정류소의 전체 노선 목록 조회 및 선택
- **주말 자동 비활성화** — 토/일요일 모니터링 자동 건너뛰기

## 스크린샷

| 메뉴바 팝오버 | 설정 (일반) | 설정 (API) |
|:---:|:---:|:---:|
| 버스 도착 현황 및 리드타임 비교 | 정류소, 버스, 도보 시간 설정 | API 키 관리 및 가이드 |

## 다운로드

- [설치 파일 (DMG)](docs/LeaveWorkReminder.dmg)
- [앱 소개 문서 (PDF)](docs/퇴근알리미_소개.pdf)

## 시스템 요구사항

- macOS 14.0 (Sonoma) 이상
- 서울시 공공 버스 API 인증키 ([data.go.kr](https://data.go.kr)에서 발급)

## 빌드 및 실행

```bash
# 빌드 + 앱 번들 생성 + DMG 생성
bash build_app.sh

# 앱 실행
open .build/release/LeaveWorkReminder.app

# 설치용 DMG
open .build/LeaveWorkReminder.dmg
```

> Swift Package Manager로 빌드합니다. Xcode 설치 없이 Command Line Tools만 있으면 됩니다.

## API 키 발급

1. [data.go.kr](https://data.go.kr) 회원가입 및 로그인
2. **서울특별시_정류소정보조회 서비스** 활용신청
3. **서울특별시_버스도착정보조회 서비스** 활용신청
4. 승인 후 마이페이지에서 **일반 인증키(Encoding)** 복사
5. 앱 설정 → API 탭 → 등록 버튼 클릭 후 키 입력

> ⚠️ API 키 동기화는 **매주 월요일** 진행됩니다. 승인 직후에는 인증 실패(에러코드 30)가 발생할 수 있으며, 월요일 이후 정상 동작합니다. 키 재발급 시 동기화가 리셋되므로 재발급은 삼가주세요.

## 알림 타이밍 계산

```
총 리드타임 = 도보 시간(5분 단위 올림) + 엘리베이터 + 여유 시간
```

| 상태 | 조건 | 메시지 |
|---|---|---|
| 여유 있음 | 도착 시간 > 리드타임 | "아직 여유 있음" |
| 지금 출발 | 도착 시간 = 리드타임 | "지금 출발하세요!" |
| 못 탐 | 도착 시간 < 리드타임 | "이번 버스는 못타요. ○○분 뒤에 퇴근하세요" |

## 프로젝트 구조

```
LeaveWorkReminder/
├── App/                    # 앱 진입점, AppDelegate
├── Models/                 # AppSettings, BusArrivalInfo, StationRouteInfo
├── Services/               # API 클라이언트, 알림, 도보 시간 계산, 모니터링
├── Views/                  # MenuBarView, StatusView, SettingsView
├── ViewModels/             # MenuBarViewModel
└── Utilities/              # TimeCalculator, Constants
```

## 기술 스택

Swift 6 · SwiftUI · MenuBarExtra · Swift Package Manager · MapKit · UserNotifications

## 라이선스

MIT License
