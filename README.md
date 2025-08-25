# monitoring


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
    namespace="example",
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
k run example --image=busybox -n default -- /bin/sh -c "while true; do
```

### 2. 팀즈에서 알람 확인 
<img width="940" height="469" alt="image" src="https://github.com/user-attachments/assets/778cc22b-56bb-4afe-ada9-15e07c63b280" />








