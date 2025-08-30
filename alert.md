## 모니터링 알람 Teams 연동

## WEBHOOK URL
https://kbsys2015.webhook.office.com/webhookb2/a13c6d0b-97da-4dc7-8ba4-313c6cfa5da0@b84c843a-4ece-4ef7-8788-372e1f232c0a/IncomingWebhook/850e3899b8b145c3a09777d50e5c5753/679e4f4a-ec92-46d9-9bba-047e4e8477a7/V2lAfe2IpM89YcEMX7OC_aozTw5y61I0l629RKJ83mczg1


### 1. New Team 생성
팀 만들기 -> ... -> 앱 -> Incoming Webhook 추가 ** 키값 복사 **

<img width="170" height="260" alt="image" src="https://github.com/user-attachments/assets/7ad0b4fa-4680-4fe0-a729-285c3a53398e" />

- 새 채널 (팀이 존재 하는 경우)/ 새 팀
	- 채널 이름: grafana alert
	- 유형 선택: 비공개
<img width="203" height="309" alt="image" src="https://github.com/user-attachments/assets/545a3339-7a4f-42ed-9a17-88d953e7a2b9" />

- ** 채널 관리 ** 선택
- 채널 세부 정보 > 커넥터 > imcoming webhook
	- webhook 이름 설정
	- create 클릭
	- url 복사


### 2. 그라파나 연동
Altering -> Alter rules -> Contact Points -> Create Contact Point -> Integration -> Microsoft Teams 선택 -> 웹훅 키 붙여넣기




### 3. 알람 룰 세팅
```
sum by (namespace, pod) (
  rate(container_cpu_usage_seconds_total{
    pod=~"nginx.*",
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
