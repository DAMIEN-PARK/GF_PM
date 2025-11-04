# GrowFit Platform Admin Frontend

## 개요
GrowFit Platform Admin 리포지토리는 교육용 AI 실습 플랫폼의 3-티어 관리 화면 프로토타입(정적 HTML/CSS) 모음입니다. 각 티어는 다음과 같이 권한과 기능이 구분됩니다.

- **Superviser**: 멀티 테넌트 기반의 전체 플랫폼 관리를 담당합니다. 조직/사용자/과금/모니터링/시스템 설정 전반을 다룹니다.
- **Partner**: 개별 조직(회사) 단위에서 프로젝트·사용자·AI 실습 환경과 정산을 운영합니다.
- **User**: 학습자 관점에서 자신의 실습, 프로젝트, 문서 및 계정 정보를 확인하고 관리합니다.

모든 화면은 한국어 UI를 기준으로 작성되었으며, `/common` 디렉터리의 공용 스타일시트를 공유합니다.

## 디렉터리 구조
```
GF_PM/
├── Superviser-admin/   # 플랫폼 총괄 관리자 화면(7개)
├── Partner-admin/      # 조직 운영자 화면(6개)
├── User/               # 학습자 전용 화면(7개)
└── common/             # 공용 스타일(CSS) 및 유틸(JS)
```

각 HTML 파일은 `../common`의 `variables.css`, `layout.css`, `components.css`를 임포트하여 일관된 디자인 토큰, 레이아웃, UI 구성 요소를 재사용합니다.

## 역할별 페이지 요약
### Superviser (플랫폼 총괄 관리자)
- `platform-dashboard.html`: 플랫폼 전반 KPI, 트래픽·에러 추세, 운영 지표 위젯.
- `organization-management.html`: 조직 생성/편집 모달, 테넌트 상태 필터, 파트너 관리자 배정 UI.
- `user-management.html`: 역할/조직 필터와 일괄 작업 컨트롤을 갖춘 사용자 테이블.
- `revenue-billing.html`: 조직별 청구 현황, 결제 상태, 매출 통계 카드.
- `analytics-reports.html`: 기간 선택, 다운로드 액션이 포함된 분석 리포트 섹션.
- `system-monitoring.html`: 실시간 상태 배지, 에러 로그, 서비스 헬스체크 컴포넌트.
- `platform-settings.html`: 기능 플래그, 리소스 한도 등 글로벌 설정 폼.

### Partner (조직/회사 운영자)
- `dashboard.html`: 조직 전용 KPI, 실습 참여율, 프로젝트 진행 현황.
- `project-management.html`: 프로젝트별 참여자, 상태 태그, 일정 관리 카드.
- `student-management.html`: 조직 사용자 관리 테이블, 초대/권한 편집 컨트롤.
- `ai-practice-management.html`: 실습 템플릿, 세션 모니터링, 콘텐츠 카드.
- `revenue-settlement.html`: 이용 요금, 정산 이력, 세금계산서 발급 버튼.
- `settings.html`: 조직 프로필, API 키 관리, 보안 설정.

### User (학습/실습 참여자)
- `dashboard.html`: 개인 KPI, 성취 배지, 최근 실습 활동 요약.
- `practice.html`: 실습 세션 상태 카드, 모델 학습/중지 액션 버튼.
- `my-projects.html`: 참여 중인 프로젝트 리스트, 산출물 관리.
- `my-agents.html`: 개인 AI 에이전트 설정, 로그, 파라미터 카드.
- `my-documents.html`: 문서 업로드, 카테고리 필터, 검색 UI.
- `history.html`: 실습 실행/접속 기록 타임라인.
- `profile.html`: 계정 설정, 보안 정보, 알림 환경 설정.

## 공통 스타일 및 스크립트
- `common/variables.css`: 색상, 타이포그래피, 간격 등 디자인 토큰 정의.
- `common/layout.css`: 그리드/플렉스 기반 레이아웃, 페이지 래퍼, 헤더/사이드바 스타일.
- `common/components.css`: 카드, 테이블, 배지, 버튼 등 UI 컴포넌트 스타일.
- `common/layout.js`, `common/utils.js`: 정적 페이지 시연용 인터랙션 헬퍼(모달 토글, 알림 등).

각 페이지는 `<style>` 블록을 통해 역할별 포인트 컬러 변수를 재정의하여 UI 톤을 차별화합니다.

## 사용 방법
1. 리포지토리를 클론하거나 다운로드합니다.
2. 정적 서버(`npx serve`, VSCode Live Server 등)로 `GF_PM` 루트를 열거나, 각 HTML 파일을 브라우저에서 직접 실행합니다.
3. 역할별 HTML을 탐색하여 화면 구조와 컴포넌트를 검토합니다.

## 향후 개선 아이디어
- 공통 레이아웃 컴포넌트를 템플릿 엔진(예: Handlebars, React)으로 리팩터링하여 중복 제거.
- 실제 백엔드 연동을 위한 API 명세 정의 및 목 데이터 JSON 분리.
- 반응형/접근성 점검(키보드 네비게이션, ARIA 속성 보강).
- 다국어 지원을 위한 i18n 구조화.

---
이 README는 현재 HTML 프로토타입 구조 파악을 돕기 위한 초안입니다. 필요한 내용이 있다면 이 구조를 기반으로 보완해 주세요.
