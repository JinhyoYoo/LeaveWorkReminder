#!/usr/bin/env python3
"""퇴근 알리미 발표 문서 PDF 생성 - 16:9 슬라이드"""
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor, white
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, HRFlowable
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

# ── 페이지 (16:9) ──
PAGE_W = 338*mm
PAGE_H = 190*mm
MARGIN_T = 18*mm
MARGIN_B = 14*mm
MARGIN_L = 22*mm
MARGIN_R = 22*mm
W = PAGE_W - MARGIN_L - MARGIN_R  # 콘텐츠 폭

# ── 색상 ──
C_PRIMARY  = HexColor("#374789")
C_ACCENT   = HexColor("#5b6abf")
C_DARK     = HexColor("#1d1d2b")
C_GRAY     = HexColor("#6b7280")
C_LGRAY    = HexColor("#9ca3af")
C_BG       = HexColor("#f4f5fa")
C_BORDER   = HexColor("#d1d5db")
C_WHITE    = white
C_BLUE_BG  = HexColor("#eff1fb")

# ── 스타일 ──
s_cover_title = ParagraphStyle("CT", fontName="Paper-XBold", fontSize=48, textColor=C_PRIMARY, alignment=TA_CENTER, leading=60)
s_cover_sub   = ParagraphStyle("CS", fontName="Paper-Light", fontSize=18, textColor=C_GRAY, alignment=TA_CENTER, leading=28)
s_cover_info  = ParagraphStyle("CI", fontName="Paper-Light", fontSize=13, textColor=C_LGRAY, alignment=TA_CENTER)

s_slide_title = ParagraphStyle("ST", fontName="Paper-Bold", fontSize=28, textColor=C_PRIMARY, spaceAfter=4, leading=36)
s_slide_sub   = ParagraphStyle("SS", fontName="Paper-Semi", fontSize=16, textColor=C_ACCENT, spaceBefore=6, spaceAfter=3, leading=22)
s_body        = ParagraphStyle("B",  fontName="Paper", fontSize=14, textColor=C_DARK, leading=21, spaceAfter=3)
s_bullet      = ParagraphStyle("BL", fontName="Paper", fontSize=14, textColor=C_DARK, leading=21, leftIndent=16, spaceAfter=2)
s_bullet_b    = ParagraphStyle("BB", fontName="Paper-Mid", fontSize=14, textColor=C_DARK, leading=21, leftIndent=16, spaceAfter=2)
s_highlight   = ParagraphStyle("HL", fontName="Paper-Semi", fontSize=15, textColor=C_PRIMARY, leading=22, spaceAfter=3, leftIndent=16)
s_note        = ParagraphStyle("N",  fontName="Paper-Light", fontSize=12, textColor=C_GRAY, leading=17, spaceAfter=2, leftIndent=16)
s_quote       = ParagraphStyle("Q",  fontName="Paper-Mid", fontSize=16, textColor=C_PRIMARY, leading=25, leftIndent=24, rightIndent=24, spaceBefore=4, spaceAfter=4, borderPadding=(8, 10, 8, 10), backColor=C_BLUE_BG)
s_code        = ParagraphStyle("CD", fontName="Courier", fontSize=12, textColor=HexColor("#374151"), backColor=C_BG, leading=18, leftIndent=10, rightIndent=10, spaceBefore=3, spaceAfter=3, borderPadding=(6, 8, 6, 8))
s_foot        = ParagraphStyle("F",  fontName="Paper-Light", fontSize=9, textColor=C_LGRAY, alignment=TA_CENTER)

s_num_big     = ParagraphStyle("NB", fontName="Paper-XBold", fontSize=44, textColor=C_ACCENT, alignment=TA_CENTER, leading=52)
s_num_label   = ParagraphStyle("NL", fontName="Paper-Mid", fontSize=12, textColor=C_GRAY, alignment=TA_CENTER, leading=16)

s_tcell   = ParagraphStyle("TC",  fontName="Paper", fontSize=13, textColor=C_DARK, leading=18)
s_tcell_b = ParagraphStyle("TCB", fontName="Paper-Semi", fontSize=13, textColor=C_DARK, leading=18)
s_tcell_w = ParagraphStyle("TCW", fontName="Paper-Semi", fontSize=13, textColor=C_WHITE, leading=18)

# ── 헬퍼 ──
def P(text, style=s_body):
    return Paragraph(text, style)

def slide_header(title):
    return [
        P(title, s_slide_title),
        HRFlowable(width="100%", thickness=2, color=C_PRIMARY, spaceAfter=3*mm),
    ]

def bullet(text, bold=False):
    return P(f"•&nbsp;&nbsp;{text}", s_bullet_b if bold else s_bullet)

def make_table(headers, rows, col_widths):
    data = [[P(h, s_tcell_w) for h in headers]]
    for row in rows:
        cells = []
        for i, val in enumerate(row):
            cells.append(P(val, s_tcell_b if i == 0 else s_tcell))
        data.append(cells)
    t = Table(data, colWidths=col_widths, repeatRows=1)
    t.setStyle(TableStyle([
        ('BACKGROUND',   (0, 0), (-1, 0), C_PRIMARY),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [C_WHITE, C_BG]),
        ('GRID',         (0, 0), (-1, -1), 0.5, C_BORDER),
        ('TOPPADDING',   (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING',(0, 0), (-1, -1), 4),
        ('LEFTPADDING',  (0, 0), (-1, -1), 8),
        ('RIGHTPADDING', (0, 0), (-1, -1), 8),
        ('VALIGN',       (0, 0), (-1, -1), 'MIDDLE'),
    ]))
    return t

def number_block(items):
    """숫자 강조 블록 - 각 셀에 Paragraph 사용"""
    col_w = W / len(items)
    row = []
    for num, label in items:
        cell_content = P(f"<font size='44'>{num}</font><br/><font size='13' color='#6b7280'>{label}</font>",
                        ParagraphStyle("NC", fontName="Paper-XBold", fontSize=44, textColor=C_ACCENT,
                                       alignment=TA_CENTER, leading=54, spaceAfter=0))
        row.append(cell_content)
    t = Table([row], colWidths=[col_w] * len(items))
    t.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('ALIGN',  (0, 0), (-1, -1), 'CENTER'),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
    ]))
    return t

# ── PDF 생성 ──
OUTPUT = os.path.expanduser("~/Downloads/퇴근알리미_발표.pdf")

doc = SimpleDocTemplate(
    OUTPUT, pagesize=(PAGE_W, PAGE_H),
    topMargin=MARGIN_T, bottomMargin=MARGIN_B,
    leftMargin=MARGIN_L, rightMargin=MARGIN_R
)
story = []

# ━━━━━━━━━━ 표지 ━━━━━━━━━━
story.append(Spacer(1, 30*mm))
story.append(P("퇴근 알리미", s_cover_title))
story.append(Spacer(1, 5*mm))
story.append(HRFlowable(width="25%", thickness=2, color=C_PRIMARY, spaceAfter=5*mm))
story.append(P("AI와 함께 만든 macOS 퇴근 버스 알림 앱", s_cover_sub))
story.append(Spacer(1, 35*mm))
story.append(P("2026.02  ·  Swift 6 / SwiftUI  ·  Claude Code", s_cover_info))

story.append(PageBreak())

# ━━━━━━━━━━ 1. 왜 만들었나 ━━━━━━━━━━
story.extend(slide_header("1. 왜 만들었나"))

story.append(P("문제 상황", s_slide_sub))
story.append(bullet("퇴근 시간마다 버스 앱을 열어 도착 시간을 <b>수동 확인</b>하는 번거로움"))
story.append(bullet("너무 일찍 나가면 정류소에서 <b>기다림</b>, 너무 늦으면 버스를 <b>놓침</b>"))
story.append(bullet("도보 시간, 엘리베이터 대기 등을 <b>매번 머릿속으로 계산</b>"))

story.append(P("해결 아이디어", s_slide_sub))
story.append(P(
    "\"도보 시간과 대기 시간을 고려해서, 지금 나가면 딱 맞는 버스를 탈 수 있을 때 알려주는 앱\"",
    s_quote))

story.append(P("목표", s_slide_sub))
story.append(bullet("<b>제로 인터랙션</b> — 설정만 해두면 매일 자동으로 알림"))
story.append(bullet("<b>메뉴바 상주</b> — Dock 아이콘 없이 최소한의 존재감"))
story.append(bullet("<b>정확한 타이밍</b> — 실시간 API 데이터 기반 계산"))

story.append(PageBreak())

# ━━━━━━━━━━ 2. 무엇을 만들었나 ━━━━━━━━━━
story.extend(slide_header("2. 무엇을 만들었나"))

story.append(number_block([
    ("7", "주요 기능"),
    ("2,800+", "코드 라인"),
    ("25", "소스 파일"),
]))

story.append(Spacer(1, 2*mm))

story.append(make_table(
    ["기능", "설명"],
    [
        ["실시간 모니터링",    "서울시 공공 버스 API, 60초 간격 폴링"],
        ["다중 버스 지원",     "여러 노선 동시 모니터링, 가장 빠른 버스 기준 알림"],
        ["스마트 리드타임",    "도보(5분 올림) + 엘리베이터 + 여유 시간 자동 계산\n알림: [확인] 종료 / [다음 버스 타자] 재알림"],
        ["도보 시간 자동 계산", "MapKit으로 사무실 → 정류소 경로 계산"],
        ["노선 확인/선택",     "정류소 전체 노선 조회 후 클릭으로 추가"],
        ["상태별 안내 메시지",  "여유 있음 / 지금 출발 / 못탐 + 다음 출발 안내"],
        ["주말/Sleep 대응",   "주말 자동 비활성화, Mac 깨어남 시 재확인"],
    ],
    [38*mm, W - 38*mm]
))

story.append(PageBreak())

# ━━━━━━━━━━ 3. 어떻게 만들었나 ━━━━━━━━━━
story.extend(slide_header("3. 어떻게 만들었나"))

story.append(P("개발 환경", s_slide_sub))
story.append(make_table(
    ["항목", "선택", "이유"],
    [
        ["AI 도구",   "Claude Code (Opus)", "터미널 기반 AI 페어 프로그래밍"],
        ["언어",      "Swift 6",            "macOS 네이티브, 최신 동시성 모델"],
        ["UI",        "SwiftUI",            "선언적 UI, MenuBarExtra 지원"],
        ["빌드",      "Swift Package Manager", "Xcode 없이 CLI만으로 빌드"],
        ["API",       "서울시 공공 버스 API",  "실시간 도착 정보 제공"],
        ["도보 계산",  "MapKit MKDirections",  "애플 네이티브 경로 탐색"],
    ],
    [28*mm, 46*mm, W - 74*mm]
))

story.append(P("개발 프로세스", s_slide_sub))
story.append(bullet("Claude Code에 요구사항을 <b>자연어로 전달</b>"))
story.append(bullet("AI가 코드 생성 → 빌드 → 오류 수정까지 <b>자동 반복</b>"))
story.append(bullet("사람은 <b>기획, 검증, 피드백</b>에 집중"))

story.append(PageBreak())

# ━━━━━━━━━━ 4. Lesson Learned (1/2) ━━━━━━━━━━
story.extend(slide_header("4. Lesson Learned (1/2)"))

story.append(P("AI 페어 프로그래밍", s_slide_sub))
story.append(bullet("요구사항을 <b>명확하게 전달</b>하면 AI의 코드 품질이 높아짐"))
story.append(bullet("\"버스 번호 추가 버튼 넣어줘\" 보다 <b>\"추가/제거 UI, 최소 1개 필수, 다중 모니터링\"</b>이 효과적"))
story.append(bullet("AI가 생성한 코드도 <b>직접 테스트하고 피드백</b>하는 과정이 필수"))
story.append(P("→ 사람은 What과 Why, AI는 How에 집중하는 분업이 효율적", s_note))

story.append(P("공공 API 사용 시 주의사항", s_slide_sub))
story.append(bullet("data.go.kr 승인 ≠ 즉시 사용 가능 — <b>인증키 동기화가 매주 월요일</b>"))
story.append(bullet("서울 버스 API는 <b>HTTP 전용</b> (HTTPS 미지원) → ATS 예외 설정 필요"))
story.append(bullet("API 키 <b>재발급 시 동기화 리셋</b> → 절대 재발급 금지"))
story.append(P("→ 공공 API는 문서에 없는 운영 규칙이 있을 수 있으므로 사전 확인 필요", s_note))

story.append(PageBreak())

# ━━━━━━━━━━ 4. Lesson Learned (2/2) ━━━━━━━━━━
story.extend(slide_header("4. Lesson Learned (2/2)"))

story.append(P("Xcode 없는 macOS 앱 개발", s_slide_sub))
story.append(bullet("SPM 빌드 결과물은 <b>앱 번들(.app)이 아님</b> → 수동 번들 생성 스크립트 필요"))
story.append(bullet("<b>코드 서명 없이</b>는 시스템 알림(UNUserNotificationCenter)이 <b>동작하지 않음</b>"))
story.append(bullet("ad-hoc 서명 (<b>codesign --sign -</b>)으로 로컬 환경에서는 해결 가능"))
story.append(P("→ 네이티브 기능(알림, 카메라 등)을 쓸 때는 코드 서명이 사실상 필수", s_note))

story.append(Spacer(1, 3*mm))
story.append(P("핵심 요약", s_slide_sub))
story.append(make_table(
    ["주제", "교훈"],
    [
        ["AI 협업",    "명확한 요구사항 전달 + 사람의 검증이 핵심"],
        ["공공 API",   "문서 외 운영 규칙 존재, 사전 조사 필수"],
        ["SPM 빌드",   "앱 번들 + 코드 서명까지 직접 구성해야 함"],
    ],
    [30*mm, W - 30*mm]
))

story.append(PageBreak())

# ━━━━━━━━━━ 5. 마무리 ━━━━━━━━━━
story.extend(slide_header("5. 마무리"))

story.append(Spacer(1, 15*mm))
story.append(P(
    "\"매일 반복되는 작은 불편함을 자동화하면,<br/>"
    "그 시간과 에너지를 더 의미 있는 일에 쓸 수 있다.\"",
    s_quote))

story.append(Spacer(1, 12*mm))
story.append(P("GitHub", s_slide_sub))
story.append(P("https://github.com/JinhyoYoo/LeaveWorkReminder", s_highlight))

story.append(Spacer(1, 15*mm))
story.append(HRFlowable(width="100%", thickness=0.5, color=C_BORDER, spaceAfter=3*mm))
story.append(P("퇴근 알리미 v1.3  ·  Built with Claude Code  ·  2026", s_foot))

doc.build(story)
print(f"PDF 생성 완료: {OUTPUT}")
