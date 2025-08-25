# Prometheus & Grafana

Prometheus와 Grafana는 클라우드 네이티브 엔지니어링의 대표적인 모니터링 도구 

## Prometheus

주요 특징:
- 메트릭 수집 & 저장: 애플리케이션, 노드, 파드에서 CPU·메모리·네트워크 같은 시계열 데이터를 pull 방식으로 수집
- 알람(Alertmanager 연동): 특정 조건(예: CPU > 80%)일 때 알람을 트리거
- 서비스 디스커버리: 쿠버네티스와 통합해 자동으로 새 파드·서비스 감지

동작 방식:
1.	Exporter가 메트릭을 노출
2.	Prometheus Server가 Pull 방식으로 수집, TSDB에 저장 
3.	PromQL로 조회 -> 그라파나 같은 시각화 도구와 연동 
4.	조건 만족 시 Altermanager를 통해 알림 발송
5.	특수 케이스에는 푸시게이트 사용 

## Grafana
- Prometheus 데이터를 시각화하여 차트와 데이터로 표현
- 팀별 맞춤형 대시보드 생성 가능 (개발자용, 운영자용 등)
- Alertmanager와 연동해 이메일, Slack 알림 발송 

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








