# 끝말잇기 멀티 게임

> AWS 기반 실시간 1대1 랜덤 매칭 끝말잇기 웹 게임

---

## 프로젝트 소개

한국어 끝말잇기를 기반으로 한 실시간 랜덤 매칭 멀티플레이어 게임입니다.  
플레이어는 자신의 ELO 순위점수에 맞는 상대와 자동 매칭되어 끝말잇기 대결을 펼치고, 결과에 따라 레이팅이 변동됩니다.

---

## 기술 스택

| 영역 | 기술 |
|------|------|
| 프론트엔드 | JavaScript, HTML, CSS |
| 백엔드 | Node.js, WebSocket |
| 인메모리 저장소 | Redis |
| 데이터베이스 | PostgreSQL |
| 인프라 | AWS (단일 서버, MVP 기준) |

---

## 주요 기능

- 회원가입 / 로그인
- ELO 레이팅 기반 자동 매칭 (대기 시간에 따라 탐색 범위 점진 확장)
- 실시간 1대1 끝말잇기 대전
- 목숨 5개 시스템 (실수 또는 시간 초과 시 차감, 0개 시 패배)
- 동적 제한시간 (랠리가 쌓일수록 입력 제한시간 감소)
- 승패에 따른 레이팅 변동
- 전적 조회 및 전체 랭킹

---

## 시스템 아키텍처

```
클라이언트 (JavaScript)
    │
    ├── REST API ──────────────► Node.js 서버
    │   (로그인, 매칭 요청,         │
    │    랭킹 조회 등)              ├── Redis
    │                              │   (매칭 큐, 게임 세션, 단어 캐시)
    └── WebSocket ────────────►   │
        (매칭 결과 수신,            └── PostgreSQL
         인게임 단어 송수신)            (유저 정보, 단어 원본 데이터)
```

**Server-Authoritative 구조**  
단어 유효성 검사, 턴 관리, 타이머, 레이팅 계산 등 모든 게임 판정은 서버에서 처리합니다. 클라이언트는 입력만 전송하고 결과를 수신합니다.

---

## 설치 및 실행

### 사전 요구사항

- Node.js 18 이상
- Redis 7 이상
- PostgreSQL 15 이상

### 설치

```bash
git clone https://github.com/your-repo/wordchain-game.git
cd wordchain-game
npm install
```

### 환경 변수 설정

```bash
cp .env.example .env
```

```env
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=wordchain
DB_USER=postgres
DB_PASSWORD=your_password
REDIS_HOST=localhost
REDIS_PORT=6379
JWT_SECRET=your_jwt_secret
```

### 데이터베이스 초기화

```bash
npm run db:migrate
npm run db:seed      # 단어 데이터 삽입
```

### 실행

```bash
# 개발 환경
npm run dev

# 프로덕션
npm start
```

---

## 개발 일정

| 단계 | 기간 | 내용 |
|------|------|------|
| 환경 구축 | 1~2주차 | 개발 환경 세팅, DB 설계, 단어 데이터 수집 |
| 백엔드 기초 | 3~5주차 | 인증 API, 단어 검증 로직, Redis 캐싱 |
| 매칭 시스템 | 6~7주차 | 매칭 큐, 레이팅 범위 확장, ELO 계산 |
| 인게임 서버 | 8~10주차 | WebSocket 서버, 세션 관리, 타이머, 목숨 처리 |
| 프론트엔드 | 7~12주차 | 웹 전체 화면 구현 (백엔드와 병행) |
| 통합 테스트 | 13~14주차 | E2E 테스트, 부하 테스트, 버그 수정 |
| 배포 및 마무리 | 15~16주차 | 서버 배포, 최종 점검 |

---

## 팀원

| 이름 | 학번 | 담당 |
|------|------|------|
| 박상윤 | 32201633 | Node.js 서버 구축, 단어사전 크롤링 |
| 공호찬 | 32220175 | 데이터베이스 설계 |
| 박종민 | 32211808 | 프론트엔드, UI/UX, AWS 배포 |

---

## 성공 기준

- 매칭, 인게임 진행, 레이팅 변동 오류 없이 정상 동작
- 단어 검증 오류 없음 (중복 단어 재사용, 끝 글자 불일치 통과 등)
- 동시 10게임 이상 서버 안정 동작
- 단어 제출 후 응답 200ms 이내
- 게임 도중 서버 크래시 없음

---

## 참고 문헌

- Elo, A. E. (1978). *The Rating of Chessplayers, Past and Present.* Arco Publishing.
- 국립국어원 표준국어대사전 오픈 API: https://opendict.korean.go.kr
- WebSocket Protocol, RFC 6455: https://datatracker.ietf.org/doc/html/rfc6455
- Redis 공식 문서: https://redis.io/docs
- UML 다이어그램: https://www.plantuml.com

# rhdghcks - DB
