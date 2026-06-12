# SpendMap 💸

> **위치 기반 지출 기록 iOS 앱**  
> "어디서 얼마를 썼는지" 지도 위에서 한눈에 확인하세요.

---

## 📹 시연 영상

[![SpendMap Demo](https://img.shields.io/badge/YouTube-시연영상-red?logo=youtube)](https://youtu.be/mQMYQ8D-Jbc)

---

## 📱 주요 기능

### 🗺 지도 기반 지출 시각화
- 앱 실행 시 현재 위치 자동 표시
- 지출 기록 시 해당 위치에 카테고리별 색상 핀 표시
- 핀 탭 → 지출 상세 정보 확인
- +/- 버튼으로 지도 확대·축소
- 우측 상단 위치 버튼으로 현재 위치로 즉시 이동

### ➕ 지출 추가
- 금액, 카테고리, 메모, 날짜 입력
- 현재 위치 자동 저장 (GPS 기반)
- 저장 완료 시 햅틱 피드백 제공
- 카테고리: 카페 / 식사 / 쇼핑 / 교통 / 기타

### 📋 지출 목록
- 날짜별 그룹화 및 일별 합계 표시
- 카테고리 필터링
- 검색 기능

### 📊 통계
- 이번 달 총 지출 도넛 차트
- 카테고리별 비율 및 순위
- 월별 바 차트

### 💰 예산 관리
- 월 예산 설정
- 예산 80% 도달 시 경고 알림
- 예산 초과 시 즉시 알럿 팝업 + 푸시 알림

### 🗑 지출 삭제
- 상세 화면에서 삭제 버튼
- 삭제 전 확인 알럿으로 실수 방지

---

## 🛠 기술 스택

| 항목 | 내용 |
|------|------|
| Language | Swift 5 |
| UI Framework | UIKit |
| Data | Core Data |
| Map | MapKit |
| Location | CoreLocation |
| Notification | UserNotifications |
| Icons | SF Symbols |
| Architecture | MVC |
| Minimum iOS | iOS 16+ |

---

## 📁 프로젝트 구조

```
SpendMap/
├── Controllers/
│   ├── MapViewController.swift       # 지도 메인 화면
│   ├── AddExpenseViewController.swift # 지출 추가
│   ├── ExpenseDetailViewController.swift # 지출 상세/삭제
│   ├── ListViewController.swift      # 지출 목록
│   ├── StatisticsViewController.swift # 통계
│   ├── SettingsViewController.swift  # 설정/예산
│   └── MainTabBarController.swift    # 탭바
├── Models/
│   ├── Category.swift                # 카테고리 열거형
│   └── Expense+CoreData*.swift       # CoreData 모델
├── Managers/
│   ├── CoreDataManager.swift         # 데이터 CRUD
│   ├── LocationManager.swift         # 위치 관리
│   └── NotificationManager.swift    # 알림 관리
├── Views/
│   ├── ExpenseAnnotationView.swift   # 지도 핀 뷰
│   ├── ExpenseTableCell.swift        # 목록 셀
│   ├── RecentExpenseCardView.swift   # 최근 지출 카드
│   ├── DonutChartView.swift          # 도넛 차트
│   ├── BarChartView.swift            # 바 차트
│   ├── CategoryChipView.swift        # 카테고리 칩
│   └── CategoryChipView.swift
└── Utils/
    └── AppColors.swift               # 앱 컬러 시스템
```

---

## 🚀 실행 방법

1. 저장소 클론
```bash
git clone https://github.com/본인계정/SpendMap.git
```
2. `SpendMap.xcodeproj` Xcode로 열기
3. 시뮬레이터 또는 실제 기기에서 빌드 & 실행
4. 위치 권한 허용 후 사용

---

## 📋 앱 사용성 평가 기준 대응

| 기준 | 구현 내용 |
|------|-----------|
| 효용성 | 지출+위치 동시 기록으로 소비 패턴 지도 시각화 |
| 완결성 | CRUD 전 기능 + 통계 + 예산 알림 구현 |
| 직관성 | 탭바 네비게이션, FAB(+) 버튼, 드래그 바텀시트 |
| 라벨링 | 전체 한국어 UI, 명확한 카테고리 명칭 |
| 시각디자인 | 다크 테마, 카테고리별 색상 코딩, SF Symbols 통일 |
| 학습용이성 | 진입 즉시 지도 표시, 핵심 버튼 시각적 강조 |
| 피드백 | 저장 햅틱, 예산 초과 알럿, 위치 실패 안내 |
| 오류 정정 | 삭제 확인 알럿, GPS 실패 시 서울 자동 폴백 |
