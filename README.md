<img width="1910" height="910" alt="image" src="https://github.com/user-attachments/assets/57a8e6ee-f5e8-4c1a-89c7-1aad75a8bda8" /># Prometheus & Grafana

Prometheus와 Grafana는 클라우드 네이티브 엔지니어링의 대표적인 모니터링 도구 

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

## 1. ncp-iam-authenticator 설치
### 1) ncp-iam-authenticator 실행 파일 다운로드
```bash
curl -o ncp-iam-authenticator -L https://github.com/NaverCloudPlatform/ncp-iam-authenticator/releases/latest/download/ncp-iam-authenticator_linux_amd64
```

### 2) 실행할 수 있는 권한 추가
```bash
chmod +x ./ncp-iam-authenticator
```

### 3) bin폴더에 파일 복사 및 환경변수 추가
```bash
mkdir -p $HOME/bin && cp ./ncp-iam-authenticator $HOME/bin/ncp-iam-authenticator && export PATH=$PATH:$HOME/bin
```
```bash
echo 'export PATH=$PATH:$HOME/bin' >> ~/.bash_profile
```

### 4) 정상동작 확인
```bash
ncp-iam-authenticator help
```

## 2. kubeconfig 생성
### 1. configure 파일에 api 키 설정
```bash
$ cat <<EOF > ~/.ncloud/configure
[DEFAULT]
ncloud_access_key_id = ACCESSKEYACCESSKEYAC
ncloud_secret_access_key = SECRETKEYSECRETKEYSECRETKEYSECRETKEYSECR
ncloud_api_url = https://ncloud.apigw.gov-ntruss.com

[project]
ncloud_access_key_id = ACCESSKEYACCESSKEYAC
ncloud_secret_access_key = SECRETKEYSECRETKEYSECRETKEYSECRETKEYSECR
ncloud_api_url = https://ncloud.apigw.gov-ntruss.com
EOF
```

### 2. kubeconfig 생성
```bash
ncp-iam-authenticator create-kubeconfig --region KR --clusterUuid <cluster-uuid> --output kubeconfig.yaml
```
```bash
cp kubeconfig.yaml ~/.kube/config
```
```bash
alias k=kubectl
```

## 3. 프로메테우스, 그라파나 설치

### 1. Helm 설치
```
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```
```
helm version
```

### 2. Kube-prometheus-stack 배포

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```
```
helm repo update
```
```
k create ns monitoring
```
```
helm install kps prometheus-community/kube-prometheus-stack -n monitoring
```
```
k get po -n monitoring
```

## 3. 그라파나 접속

```
k -n monitoring patch svc kps-grafana -p '{"spec":{"type":"LoadBalancer"}}'
```
```
k -n monitoring get svc kps-grafana -w
```

### 그라파나 접속
<img width="940" height="106" alt="image" src="https://github.com/user-attachments/assets/c7ee4200-8818-439e-abbb-8c3d50e032fd" />

주소: External-IP

ID: admin 

PW: prom-operator

## 4. 모니터링 테스트용 파드 배포

```
k run nginx --image=nginx --port=80
``` 
``` 
k expose po nginx --name=nginx-svc --port=80 --target-port80
```

### 1. 리소스 사용량 확인

Grafana -> Kubernetes/Compute Resources/ Pod 메뉴에서 nignx 확인

## 모니터링 알람 Teams 연동

### 1. New Team 생성
팀 만들기 -> ... -> 앱 -> Incoming Webhook 추가 ** 키값 복사 **

### 2. 그라파나 연동
Altering -> Alter rules -> Contact Points -> Create Contact Point -> Integration -> Microsoft Teams 선택 -> 웹훅 키 붙여넣기

### 3. 알람 룰 세팅
```
sum by (namespace, pod) (
  rate(container_cpu_usage_seconds_total{
    namespace="cpu-burn",
    pod=~"nginx.*",
    image!="",
    container!~"POD"
  }[2m])
)
```
when query is above 0.1 

<img width="940" height="626" alt="image" src="https://github.com/user-attachments/assets/b61d753d-95f6-46ac-aeb3-73fcb72e8520" />
<img width="942" height="308" alt="image" src="https://github.com/user-attachments/assets/1cb1dbce-b917-49d7-beb5-b83681c790ac" />

## 모니터링 테스트 

### 1. 파드 과부하

```
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cpu-burn
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cpu-burn
  template:
    metadata:
      labels:
        app: cpu-burn
    spec:
      containers:
      - name: busybox
        image: busybox
        command: ["/bin/sh", "-c", "while true; do :; done"]
        resources:
          requests:
            cpu: "100m"
            memory: "64Mi"
          limits:
            cpu: "500m"
            memory: "128Mi"
EOF
```

### 2. 팀즈에서 알람 확인 
<img width="940" height="469" alt="image" src="https://github.com/user-attachments/assets/778cc22b-56bb-4afe-ada9-15e07c63b280" />

### 3. Grafana 모니터링 
<img width="1498" height="845" alt="image" src="https://github.com/user-attachments/assets/a169af78-66c9-4fad-a5b7-d00e9bcd69cd" />


## 대시보드 커스터마이징

https://grafana.com/grafana/dashboards/747-pod-metrics/

### 1. CPU 사용량
```bash
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[$__rate_interval])) * 100)
```

### 2. Memory 사용량
```bash
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

### 3. Disk 사용량
```bash
100 - (
  node_filesystem_avail_bytes{fstype!~"tmpfs|overlay|squashfs",mountpoint!~"/var/lib/docker/.+|/var/lib/containerd/.+"}
  /
  node_filesystem_size_bytes{fstype!~"tmpfs|overlay|squashfs",mountpoint!~"/var/lib/docker/.+|/var/lib/containerd/.+"}
) * 100
```

### 4. 노드 상태
```bash
count(kube_node_status_condition{condition="Ready",status="true"} == 1)
```

### 5. 파드 상태
```bash
sum by (namespace, phase) (kube_pod_status_phase)
```

<img width="1910" height="910" alt="image" src="https://github.com/user-attachments/assets/80669956-1716-4a71-a600-a07ff4c63884" />





