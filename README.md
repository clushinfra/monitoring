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
ncp-iam-authenticator create-kubeconfig --region <region-code> --clusterUuid <cluster-uuid> --output kubeconfig.yaml
```
```bash
cp kubeconfig.yaml ~/.kube/config
```
```bash
alias k=kubectl
```

## 3. 프로메테우스, 그라파나 설치

### 1. Helm 설치
```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```
```bash
helm version
```

### 2. Kube-prometheus-stack 배포

```bash
$ helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```
```bash
helm repo update
```
```bash
k create ns monitoring
```
```bash
helm install kps prometheus-community/kube-prometheus-stack -n monitoring
```
```bash
k get po -n monitoring
```

## 3. 그라파나 접속

```bash
k -n monitoring patch svc kps-grafana -p '{"spec":{"type":"LoadBalancer"}}'
```
```bash
k -n monitoring get svc kps-grafana -w
```

### 그라파나 접속

주소: External-IP
ID: admin
PW: prom-operator

## 4. 모니터링 테스트용 파드 배포

```bash
k run nginx --image=nginx --port=80
``` 
``` 
k expose po nginx --name=nginx-svc --port=80 --target-port80
```














