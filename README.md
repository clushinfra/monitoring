# Prometheus & Grafana 모니터링 워크샵

## NKS 클러스터 접속 정보
https://drive.google.com/file/d/1eQXRmvxssA_1uyH91OgreHsDxnxs31Zq/view?usp=sharing

## 목차

1. Prometheus, Grafana 소개
2. 쉘 스크립트를 이용한 실습용 동적 파드 배포
3. Microsoft teams 알람 연동
4. Grafana 대시보드 커스터마이징

## Prometheus

CNCF(Cloud Native Computing Foundation)에서 관리하는 오픈소스 모니터링 시스템

주요 특징:

- 메트릭 수집 & 저장: 애플리케이션, 노드, 파드에서 CPU·메모리·네트워크 같은 시계열 데이터를 pull 방식으로 수집
- 알람(Alertmanager 연동): 특정 조건(예: CPU > 80%)일 때 알람을 트리거
- 서비스 디스커버리: 쿠버네티스와 통합해 자동으로 새 파드·서비스 감지

프로메테우스 주요 컴포넌트

<img width="741" height="437" alt="image" src="https://github.com/user-attachments/assets/96a21b1e-7ba3-4a55-8d5f-9c7ccc3cf155" />

1.	Prometheus Server (핵심 엔진) 
-	메트릭 수집: Exporter나 쿠버네티스 API로부터 메트릭 데이터를 Pull 방식으로 가져옴 
-	저장: Time-Series Database에 데이터를 저장 
-	쿼리: PromQL 언어를 통해 데이터 분석 가능
2.	Exporter (데이터 수집 에이전트) 
-	Prometheus가 직접 애플리케이션 내부까지 볼 수 없으니, Exporter가 데이터를 노출해 줌 
-	종류 : 
	  - Node Exporter: 노드 CPU/메모리/디스크 등 시스템 메트릭
    -	cAdvisor: 컨테이너 리소스 메트릭
    -	Kube-state-metrics: 쿠버네티스 리소스 상태 (Pod, Deployment 등) 
    -	애플리케이션 Exporter: MySQL, Nginx, Redis 등 전용 
3.	Altermanager
- Prometheus에서 정의한 알람 규칙(예: CPU > 80% 5분 이상)을 받아 실제 알림 발송담당
- Slack, 이메일, PageDuty, Teams 등으로 전송 가능
4.	PushGateway (선택적 컴포넌트) 
-	원래 Prometheus는 Pull 방식, 하지만 짧게 실행되는 Job (배치 작업, CI 파이프라인 등)은 Pull이 불가능 
-	이때 Pushgateway를 통해 Prometheus에 직접 Push 가능

동작 방식:
1.	Exporter가 메트릭을 노출
2.	Prometheus Server가 Pull 방식으로 수집, TSDB에 저장 
3.	PromQL로 조회 -> 그라파나 같은 시각화 도구와 연동 
4.	조건 만족 시 Altermanager를 통해 알림 발송
5.	특수 케이스에는 푸시게이트 사용 

## Grafana
- 시각화 전용 오픈소스 도구
  
주요 특징:

- 프로메테우스(또는 다른 데이터 소스: Loki, InfluxDB 등) 데이터를 기반으로 대시보드 제공
- 다양한 차트, 패널, 알림 규칙 설정 가능
- Slack/Teams/Email 같은 외부 알림 연동 지원

주요 컴포넌트:

1.	Data Source (데이터 소스)
- Grafana는 데이터를 직접 수집하지 않음 → 외부 데이터 소스를 연결해야 함.
- 예시: Prometheus(메트릭), Loki(로그), Tempo(트레이싱), MySQL/Elasticsearch 등.

2.	Dashboard (대시보드)
- 데이터를 시각화하는 UI 컴포넌트.
- 패널(Panel) 단위로 구성 → 차트, 게이지, 테이블 등으로 표현.
- 팀/서비스별로 맞춤형 대시보드 제작 가능.

3.	Panel (패널)
- 대시보드 안에서 실제 데이터를 표현하는 개별 단위.
- 예: CPU 사용량 라인차트, 메모리 게이지, 로그 테이블.

4.	Query Engine (쿼리 엔진)
- PromQL, LogQL, SQL 등 데이터 소스별 질의어를 실행.
- 대시보드 패널이 실시간으로 데이터를 가져오도록 지원.

5.	Alerting (알람)
- 특정 조건을 만족하면 Slack, Teams, Email 등으로 알림 발송.
- Prometheus Alertmanager와 달리, 여러 데이터 소스를 동시에 대상으로 삼을 수 있음.

6.	User & Team Management (사용자/권한 관리)
- 조직 단위로 사용자/권한(Role)을 관리 가능.
- 운영팀, 개발팀, 경영진 등 각자 다른 대시보드 권한 부여.

7.	Plugin System (플러그인 시스템)
- 커뮤니티/기업이 만든 다양한 플러그인 설치 가능.
- 데이터 소스 플러그인, 시각화 플러그인, 앱 플러그인 등.

동작 방식: 
1.	외부 데이터 소스(Prometheus 등)에서 데이터를 가져옴
2.	Query Engine이 질의 실행
3.	Dashboard → Panel 형태로 시각화
4.	필요 시 Alerting 기능으로 알림 발송
5.	User/Team Management, Plugin System으로 협업과 확장 지원

