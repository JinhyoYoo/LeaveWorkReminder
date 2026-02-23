#!/usr/bin/env python3
"""퇴근 알리미 앱 소개 문서 PDF 생성 - Paperlogy 폰트"""
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor, white
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    Image as RLImage, PageBreak, HRFlowable, KeepTogether
)
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.enums import TA_CENTER, TA_LEFT
import os

# ── 폰트 등록 ──
FONT_DIR = os.path.expanduser("~/Library/Fonts")
pdfmetrics.registerFont(TTFont("Paper",      f"{FONT_DIR}/Paperlogy-4Regular.ttf"))
pdfmetrics.registerFont(TTFont("Paper-Light", f"{FONT_DIR}/Paperlogy-3Light.ttf"))
pdfmetrics.registerFont(TTFont("Paper-Mid",   f"{FONT_DIR}/Paperlogy-5Medium.ttf"))
pdfmetrics.registerFont(TTFont("Paper-Semi",  f"{FONT_DIR}/Paperlogy-6SemiBold.ttf"))
pdfmetrics.registerFont(TTFont("Paper-Bold",  f"{FONT_DIR}/Paperlogy-7Bold.ttf"))
pdfmetrics.registerFont(TTFont("Paper-XBold", f"{FONT_DIR}/Paperlogy-8ExtraBold.ttf"))

# ── 색상 ──
C_PRIMARY  = HexColor("#374789")
C_DARK     = HexColor("#1d1d2b")
C_GRAY     = HexColor("#6b7280")
C_LGRAY    = HexColor("#9ca3af")
C_BG       = HexColor("#f4f5fa")
C_BORDER   = HexColor("#d1d5db")
C_WHITE    = white
C_WARN_BG  = HexColor("#fff7ed")
C_WARN     = HexColor("#ea580c")

# ── 스타일 ──
s_cover_title = ParagraphStyle("CoverTitle", fontName="Paper-XBold", fontSize=32, textColor=C_PRIMARY, alignment=TA_CENTER, leading=42)
s_cover_sub   = ParagraphStyle("CoverSub",   fontName="Paper-Light", fontSize=13, textColor=C_GRAY, alignment=TA_CENTER, leading=20)
s_cover_ver   = ParagraphStyle("CoverVer",   fontName="Paper-Light", fontSize=10, textColor=C_LGRAY, alignment=TA_CENTER)

s_h1    = ParagraphStyle("H1",    fontName="Paper-Bold", fontSize=17, textColor=C_PRIMARY, spaceBefore=20, spaceAfter=10, leading=24)
s_h2    = ParagraphStyle("H2",    fontName="Paper-Semi", fontSize=13, textColor=C_DARK, spaceBefore=14, spaceAfter=7, leading=19)
s_body  = ParagraphStyle("Body",  fontName="Paper",      fontSize=10, textColor=C_DARK, leading=17, spaceAfter=5)
s_bull  = ParagraphStyle("Bull",  fontName="Paper",      fontSize=10, textColor=C_DARK, leading=17, leftIndent=14, spaceAfter=3)
s_note  = ParagraphStyle("Note",  fontName="Paper-Light",fontSize=9,  textColor=C_GRAY, leading=14, spaceAfter=4, leftIndent=4)
s_warn  = ParagraphStyle("Warn",  fontName="Paper-Mid",  fontSize=9,  textColor=C_WARN, leading=14, spaceAfter=4, leftIndent=4)
s_code  = ParagraphStyle("Code",  fontName="Courier",    fontSize=8.5,textColor=HexColor("#374151"), backColor=C_BG, leading=13, leftIndent=8, rightIndent=8, spaceBefore=2, spaceAfter=2, borderPadding=(4, 6, 4, 6))
s_foot  = ParagraphStyle("Foot",  fontName="Paper-Light",fontSize=8,  textColor=C_LGRAY, alignment=TA_CENTER)

# 테이블 셀용 (wordWrap 보장)
s_tcell     = ParagraphStyle("TCell",     fontName="Paper",     fontSize=9.5, textColor=C_DARK,  leading=14)
s_tcell_b   = ParagraphStyle("TCellB",    fontName="Paper-Semi",fontSize=9.5, textColor=C_DARK,  leading=14)
s_tcell_w   = ParagraphStyle("TCellW",    fontName="Paper-Semi",fontSize=9.5, textColor=C_WHITE, leading=14)
s_tcell_sm  = ParagraphStyle("TCellSm",   fontName="Paper",     fontSize=9,   textColor=C_DARK,  leading=13)
s_tcell_smb = ParagraphStyle("TCellSmB",  fontName="Paper-Semi",fontSize=9,   textColor=C_DARK,  leading=13)
s_tcell_smw = ParagraphStyle("TCellSmW",  fontName="Paper-Semi",fontSize=9,   textColor=C_WHITE, leading=13)

# ── 헬퍼 ──
def P(text, style=s_body):
    return Paragraph(text, style)

def make_table(headers, rows, col_widths, small=False):
    """Paragraph로 감싼 테이블 생성 (텍스트 줄바꿈 보장)"""
    hstyle = s_tcell_smw if small else s_tcell_w
    cstyle = s_tcell_sm if small else s_tcell
    bstyle = s_tcell_smb if small else s_tcell_b

    data = [[P(h, hstyle) for h in headers]]
    for row in rows:
        cells = []
        for i, val in enumerate(row):
            st = bstyle if i == 0 else cstyle
            cells.append(P(val, st))
        data.append(cells)

    t = Table(data, colWidths=col_widths, repeatRows=1)
    t.setStyle(TableStyle([
        ('BACKGROUND',  (0, 0), (-1, 0), C_PRIMARY),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [C_WHITE, C_BG]),
        ('GRID',        (0, 0), (-1, -1), 0.5, C_BORDER),
        ('TOPPADDING',  (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING',(0, 0), (-1, -1), 6),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
        ('RIGHTPADDING',(0, 0), (-1, -1), 8),
        ('VALIGN',      (0, 0), (-1, -1), 'TOP'),
    ]))
    return t

# ── PDF 생성 ──
OUTPUT = os.path.expanduser("~/Downloads/퇴근알리미_소개.pdf")
ICON   = os.path.expanduser("~/LeaveWorkReminder/icon_preview.png")
W = A4[0] - 50*mm  # 사용 가능 폭

doc = SimpleDocTemplate(
    OUTPUT, pagesize=A4,
    topMargin=28*mm, bottomMargin=22*mm,
    leftMargin=25*mm, rightMargin=25*mm
)
story = []

# ━━━━━━━━━━ 표지 ━━━━━━━━━━
story.append(Spacer(1, 50*mm))
if os.path.exists(ICON):
    story.append(RLImage(ICON, width=60*mm, height=60*mm, hAlign='CENTER'))
    story.append(Spacer(1, 12*mm))

story.append(P("퇴근 알리미", s_cover_title))
story.append(Spacer(1, 5*mm))
story.append(P("퇴근 시간 버스 도착 알림 macOS 메뉴바 앱", s_cover_sub))
story.append(Spacer(1, 8*mm))
story.append(HRFlowable(width="40%", thickness=1, color=C_PRIMARY, spaceAfter=8*mm))
story.append(P("v1.2  ·  macOS 14.0+ (Sonoma)  ·  Swift 6 / SwiftUI", s_cover_ver))

story.append(PageBreak())

# ━━━━━━━━━━ 1. 개요 ━━━━━━━━━━
story.append(P("1. 개요", s_h1))
story.append(P(
    "퇴근 알리미는 퇴근 시간에 맞춰 버스 도착 정보를 실시간으로 모니터링하고, "
    "도보 시간과 엘리베이터 대기 시간을 고려하여 최적의 출발 시점에 "
    "시스템 알림을 보내는 macOS 메뉴바 상주 앱입니다."))
story.append(Spacer(1, 3*mm))

story.append(make_table(
    ["기능", "설명"],
    [
        ["메뉴바 상주",          "Dock 아이콘 없이 메뉴바에서만 동작"],
        ["실시간 버스 도착 정보", "서울시 공공 버스 API를 통해 60초 간격 조회"],
        ["다중 버스 모니터링",    "여러 노선을 동시에 모니터링, 가장 빠른 버스 기준 알림"],
        ["스마트 알림",          "도보 + 엘리베이터 + 여유 시간을 계산하여 출발 시점 알림"],
        ["자동 도보 시간 계산",   "MapKit 활용, 사무실 → 정류소 도보 시간 자동 계산"],
        ["노선 확인",            "정류소의 전체 노선 목록 조회 및 선택 기능"],
        ["주말 자동 비활성화",    "토/일요일 모니터링 자동 건너뛰기"],
        ["Sleep/Wake 대응",     "Mac 잠자기 해제 시 스케줄 자동 재확인"],
    ],
    [34*mm, W - 34*mm]
))

# ━━━━━━━━━━ 2. 시스템 요구사항 ━━━━━━━━━━
story.append(P("2. 시스템 요구사항", s_h1))
story.append(make_table(
    ["항목", "내용"],
    [
        ["운영체제",   "macOS 14.0 (Sonoma) 이상"],
        ["아키텍처",   "Apple Silicon (arm64) / Intel (x86_64)"],
        ["API 키",    "공공데이터포털 (data.go.kr) 인증키 필요"],
        ["네트워크",   "인터넷 연결 필수"],
    ],
    [28*mm, W - 28*mm]
))

# ━━━━━━━━━━ 3. 설치 방법 ━━━━━━━━━━
story.append(P("3. 설치 방법", s_h1))
for i, t in enumerate([
    "LeaveWorkReminder.dmg 파일을 더블 클릭하여 마운트합니다.",
    "열린 창에서 퇴근 알리미 앱을 Applications 폴더로 드래그합니다.",
    "Applications 폴더에서 앱을 실행합니다.",
    "최초 실행 시 시스템 알림 권한을 허용해주세요.",
], 1):
    story.append(P(f"<b>{i}.</b>&nbsp;&nbsp;{t}", s_bull))

story.append(Spacer(1, 2*mm))
story.append(P(
    "앱이 확인되지 않은 개발자로 표시될 경우: "
    "시스템 설정 → 개인 정보 보호 및 보안 → '확인 없이 열기'를 클릭하세요.", s_note))

# ━━━━━━━━━━ 4. API 키 발급 ━━━━━━━━━━
story.append(P("4. API 키 발급 가이드", s_h1))
story.append(P("이 앱은 서울시 공공 버스 API를 사용합니다. 사용 전 API 키 발급이 필요합니다."))
story.append(Spacer(1, 2*mm))

for i, t in enumerate([
    "data.go.kr 에 회원가입 및 로그인합니다.",
    "검색창에 <b>서울특별시_정류소정보조회 서비스</b>를 검색 후 활용신청합니다.",
    "마찬가지로 <b>서울특별시_버스도착정보조회 서비스</b>도 활용신청합니다.",
    "활용 목적에 '개인 프로젝트' 등을 입력합니다.",
    "승인 후 (즉시 ~ 2시간) 마이페이지 → 활용신청 현황에서 인증키를 확인합니다.",
    "<b>일반 인증키(Encoding)</b>를 복사합니다.",
    "앱 설정 → API 탭에서 <b>'등록' 버튼</b>을 클릭한 후 키를 붙여넣고 저장합니다.",
    "<b>API 연결 테스트</b> 버튼으로 정상 동작을 확인합니다.",
], 1):
    story.append(P(f"<b>{i}.</b>&nbsp;&nbsp;{t}", s_bull))

story.append(Spacer(1, 2*mm))
story.append(P("두 API 모두 같은 인증키를 사용합니다. Encoding / Decoding 키 어느 쪽이든 입력 가능합니다.", s_note))

story.append(Spacer(1, 3*mm))
story.append(P("인증키 동기화 주의사항", s_h2))
story.append(P(
    "data.go.kr에서 API 키 승인 후에도 실제 API 서버(ws.bus.go.kr)에 즉시 반영되지 않습니다. "
    "<b>인증키 동기화는 매주 월요일</b>에 진행되므로, 승인 후 가장 가까운 월요일까지 "
    "대기가 필요할 수 있습니다."))
story.append(Spacer(1, 1*mm))
story.append(P(
    "동기화 전에는 API 테스트 시 인증 실패(에러코드 30) 오류가 발생할 수 있습니다. "
    "이 경우 월요일 이후 다시 시도해주세요.", s_note))
story.append(P(
    "키 재발급 시 동기화가 리셋되므로 재발급은 삼가주세요. "
    "문의: 1566-0025 내선 2", s_warn))

# ━━━━━━━━━━ 5. 사용 방법 ━━━━━━━━━━
story.append(PageBreak())
story.append(P("5. 사용 방법", s_h1))

story.append(P("5.1 기본 설정", s_h2))
story.append(P("메뉴바 버스 아이콘 클릭 → 설정(기어 아이콘)을 눌러 설정 창을 엽니다."))
story.append(Spacer(1, 2*mm))

story.append(make_table(
    ["탭", "항목", "설명"],
    [
        ["일반", "정류소 번호 (arsId)",    "버스 정류소 고유번호\n(정류소 표지판에서 확인)"],
        ["일반", "노선 확인",              "'노선 확인' 버튼으로 정류소 전체 노선 조회 및 선택"],
        ["일반", "버스 번호",              "여러 노선 추가 가능 (추가/제거 버튼)"],
        ["일반", "모니터링 시작 시간",       "매일 이 시간부터 도착 정보 조회 시작"],
        ["일반", "사무실 주소",             "도보 시간 자동 계산에 사용 (도보 시간 설정 내)"],
        ["일반", "도보 시간 모드",          "자동(MapKit) 또는 수동 입력 선택"],
        ["일반", "엘리베이터 / 여유 시간",  "각각 0~30분 설정 가능 (기본 각 5분)"],
        ["API",  "API 키",               "'등록' 버튼 클릭 후 키 입력, 마스킹 표시"],
        ["API",  "발급 가이드",            "별도 창에서 발급 절차 안내"],
    ],
    [16*mm, 38*mm, W - 54*mm],
    small=True
))

story.append(P("5.2 동작 흐름", s_h2))
for i, t in enumerate([
    "앱 시작 → 알림 권한 요청, 설정 로드",
    "매일 설정된 체크 시간 (기본 16:50) 대기",
    "체크 시간 도달 → 정류소/노선 정보 확인 (최초 1회, 이후 캐시)",
    "60초 간격으로 버스 도착 정보 폴링",
    "도착 예상 시간 ≤ 총 리드타임 → 시스템 알림 발송",
    "하루 1회 알림 후 플래그 설정 (UI에서는 계속 갱신)",
    "운행 종료 감지 시 폴링 중단, 다음 날 대기",
], 1):
    story.append(P(f"<b>{i}.</b>&nbsp;&nbsp;{t}", s_bull))

story.append(P("5.3 메뉴바 팝오버", s_h2))
story.append(P("메뉴바의 버스 아이콘을 클릭하면 팝오버가 열립니다."))
for item in [
    "다중 버스 도착 현황 (각 버스별 첫번째/다음 도착 메시지, 가장 빠른 버스 강조)",
    "모니터링 상태 표시 (대기 / 모니터링 중 / 알림 완료 / 오류)",
    "리드타임 비교: 여유 있음 / 지금 출발 / 이번 버스 못탐 + 다음 출발 시점 안내",
    "'지금 확인' 버튼으로 수동 즉시 조회",
    "'모니터링 시작/중단' 버튼",
    "오늘의 확인 기록 (최근 5건)",
]:
    story.append(P(f"•&nbsp;&nbsp;{item}", s_bull))

# ━━━━━━━━━━ 6. 알림 타이밍 계산 ━━━━━━━━━━
story.append(P("6. 알림 타이밍 계산", s_h1))
story.append(P("앱은 다음 공식으로 최적 출발 시점을 계산합니다."))
story.append(Spacer(1, 3*mm))

story.append(P("<b>Step 1.</b>&nbsp;&nbsp;도보 시간 → 5분 단위 올림", s_bull))
story.append(Spacer(1, 1*mm))
story.append(make_table(
    ["실제 도보", "3분", "5분", "6분", "12분"],
    [["올림 결과", "5분", "5분", "10분", "15분"]],
    [28*mm] + [int((W - 28*mm) / 4)] * 4,
    small=True
))

story.append(Spacer(1, 3*mm))
story.append(P("<b>Step 2.</b>&nbsp;&nbsp;총 리드타임 = 올림된 도보 + 엘리베이터 + 여유 시간", s_bull))
story.append(P("엘리베이터와 여유 시간은 설정에서 변경 가능 (기본 각 5분)", s_note))
story.append(P("예: 도보 6분 → 올림 10분 + 5분 + 5분 = <b>총 20분</b>", s_note))

story.append(Spacer(1, 2*mm))
story.append(P("<b>Step 3.</b>&nbsp;&nbsp;도착 시간과 리드타임 비교", s_bull))
story.append(P("도착 시간 &gt; 리드타임 → <b>\"아직 여유 있음\"</b>", s_note))
story.append(P("도착 시간 = 리드타임 → <b>\"지금 출발하세요!\"</b> (알림 발송)", s_note))
story.append(P("도착 시간 &lt; 리드타임 → <b>\"이번 버스는 못타요. ○○분 뒤에 퇴근하세요\"</b>", s_note))
story.append(P("다음 탈 수 있는 버스(모든 노선의 1차/2차 도착 중 리드타임 이상)를 찾아 출발 시점을 안내합니다.", s_note))

story.append(Spacer(1, 5*mm))
story.append(P("알림 예시", s_h2))
story.append(make_table(
    ["항목", "내용"],
    [
        ["제목", "퇴근 알리미 - 지금 출발하세요!"],
        ["부제", "1311번 버스 20분 후 도착"],
        ["본문", "도보 10분 + 엘리베이터 5분\n현재 위치: 서울특별시 강남구 테헤란로2길 27\n다음 버스: 35분후[8번째 전]"],
    ],
    [20*mm, W - 20*mm]
))

# ━━━━━━━━━━ 7. 기술 정보 ━━━━━━━━━━
story.append(PageBreak())
story.append(P("7. 기술 정보", s_h1))
story.append(make_table(
    ["항목", "내용"],
    [
        ["플랫폼",    "macOS 14.0+ (Sonoma)"],
        ["언어",      "Swift 6, SwiftUI"],
        ["UI",        "MenuBarExtra (메뉴바 상주)"],
        ["API",       "서울시 공공 버스 API (ws.bus.go.kr)"],
        ["알림",      "UserNotifications 프레임워크"],
        ["도보 계산",  "MapKit MKDirections"],
        ["설정 저장",  "@AppStorage (UserDefaults)"],
        ["자동 실행",  "SMAppService"],
        ["빌드",      "Swift Package Manager"],
    ],
    [28*mm, W - 28*mm]
))

# ━━━━━━━━━━ 8. 프로젝트 구조 ━━━━━━━━━━
story.append(P("8. 프로젝트 구조", s_h1))
structure = [
    "LeaveWorkReminder/",
    "├── App/",
    "│   ├── LeaveWorkReminderApp.swift      @main, MenuBarExtra + Settings",
    "│   └── AppDelegate.swift               알림 delegate, 권한 요청",
    "├── Models/",
    "│   ├── AppSettings.swift               @AppStorage 기반 설정",
    "│   ├── BusArrivalInfo.swift            도착 정보 모델",
    "│   └── StationRouteInfo.swift          정류소/노선 정보 모델",
    "├── Services/",
    "│   ├── SeoulBusAPIService.swift        API 클라이언트 (actor)",
    "│   ├── XMLParsingService.swift         XML 파서",
    "│   ├── WalkingTimeService.swift        MapKit 도보 시간 계산",
    "│   ├── NotificationService.swift       시스템 알림",
    "│   └── ArrivalMonitorService.swift     핵심 오케스트레이터",
    "├── Views/",
    "│   ├── MenuBarView.swift              메뉴바 팝오버",
    "│   ├── StatusView.swift               버스 도착 현황",
    "│   └── SettingsView.swift             설정 화면 (일반/API 2탭)",
    "├── ViewModels/",
    "│   └── MenuBarViewModel.swift         메인 뷰모델",
    "└── Utilities/",
    "    ├── TimeCalculator.swift            시간 계산 로직",
    "    └── Constants.swift                API URL, 기본값",
]
for line in structure:
    story.append(P(line, s_code))

# ━━━━━━━━━━ 9. 문제 해결 ━━━━━━━━━━
story.append(Spacer(1, 4*mm))
story.append(P("9. 문제 해결", s_h1))

s_q = ParagraphStyle("Q", fontName="Paper-Semi", fontSize=10, textColor=C_DARK, spaceBefore=10, spaceAfter=2, leading=15)
s_a = ParagraphStyle("A", fontName="Paper",      fontSize=10, textColor=C_GRAY, leftIndent=12, spaceAfter=6, leading=16)

qa = [
    ("API 키 인증 실패 (에러코드 7 또는 30)",
     "data.go.kr에서 해당 API의 활용신청이 필요합니다. "
     "'서울특별시_정류소정보조회 서비스'와 '서울특별시_버스도착정보조회 서비스' "
     "두 가지를 모두 신청하세요. 승인 후에도 인증키 동기화가 매주 월요일에 "
     "진행되므로, 가장 가까운 월요일까지 대기가 필요할 수 있습니다. "
     "키 재발급은 동기화를 리셋하므로 삼가주세요."),
    ("알림이 오지 않음",
     "시스템 설정 → 알림 → 퇴근 알리미가 '허용'인지 확인하세요. "
     "'방해 금지 모드' 활성화 시 알림이 표시되지 않습니다."),
    ("버스를 찾을 수 없음",
     "정류소 번호(arsId)가 정확한지 확인하세요. "
     "'노선 확인' 버튼으로 해당 정류소의 전체 노선 목록을 조회하고 "
     "원하는 버스를 선택할 수 있습니다."),
    ("도보 시간이 계산되지 않음",
     "사무실 주소가 정확한지 확인하세요. "
     "자동 계산 실패 시 일반 탭에서 '수동 입력' 모드로 전환하세요."),
    ("앱이 메뉴바에 표시되지 않음",
     "앱을 다시 실행해보세요. "
     "Dock에는 표시되지 않고 메뉴바에만 아이콘이 나타납니다."),
]
for q, a in qa:
    story.append(KeepTogether([P(f"Q. {q}", s_q), P(f"A. {a}", s_a)]))

# ━━━━━━━━━━ 푸터 ━━━━━━━━━━
story.append(Spacer(1, 12*mm))
story.append(HRFlowable(width="100%", thickness=0.5, color=C_BORDER, spaceAfter=3*mm))
story.append(P("퇴근 알리미 v1.2  ·  macOS 14.0+  ·  2026", s_foot))

doc.build(story)
print(f"PDF 생성 완료: {OUTPUT}")
