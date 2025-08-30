########################################
# Monitoring Workshop                  #
########################################

########################################
# 1. ncp-iam-authenticator 설치         #
########################################
curl -o ncp-iam-authenticator -L https://github.com/NaverCloudPlatform/ncp-iam-authenticator/releases/latest/download/ncp-iam-authenticator_linux_amd64
chmod +x ./ncp-iam-authenticator
mkdir -p $HOME/bin && cp ./ncp-iam-authenticator $HOME/bin/ncp-iam-authenticator && export PATH=$PATH:$HOME/bin
echo 'export PATH=$PATH:$HOME/bin' >> ~/.bash_profile
ncp-iam-authenticator help

########################################
# 2. kubeconfig 생성                    #
########################################
cat <<EOF > ~/.ncloud/configure
[DEFAULT]
ncloud_access_key_id = <AccessKey>
ncloud_secret_access_key = <SecretKey>
ncloud_api_url = https://ncloud.apigw.gov-ntruss.com

[project]
ncloud_access_key_id = <AccessKey>
ncloud_secret_access_key = <SecretKey>
ncloud_api_url = https://ncloud.apigw.gov-ntruss.com
EOF
ncp-iam-authenticator create-kubeconfig --region KR --clusterUuid <Cluster UUID> --output kubeconfig.yaml
mkdir -p ~/.kube
cp kubeconfig.yaml ~/.kube/config
alias k=kubectl 
k get nodes

########################################
# 3. Prometheus, Grafana 설치           #
########################################
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
k create ns monitoring
helm install kps prometheus-community/kube-prometheus-stack -n monitoring
k get po -n monitoring
k -n monitoring patch svc kps-grafana -p '{"spec":{"type":"NodePort"}}'
k -n monitoring get svc kps-grafana 

# ============================
# Namespaces
# ============================
kubectl apply -f - <<'YAML'
apiVersion: v1
kind: Namespace
metadata: { name: gpu }
---
apiVersion: v1
kind: Namespace
metadata: { name: service }
---
apiVersion: v1
kind: Namespace
metadata: { name: db }
YAML

# ============================
# ResourceQuotas (NS당 0.5 vCPU / 1.8GiB / 파드 3개)
# ============================
kubectl apply -f - <<'YAML'
apiVersion: v1
kind: ResourceQuota
metadata: { name: rq-gpu, namespace: gpu }
spec:
  hard:
    requests.cpu: "500m"
    limits.cpu: "600m"
    requests.memory: "1800Mi"
    limits.memory: "1900Mi"
    pods: "3"
---
apiVersion: v1
kind: ResourceQuota
metadata: { name: rq-service, namespace: service }
spec:
  hard:
    requests.cpu: "500m"
    limits.cpu: "600m"
    requests.memory: "1800Mi"
    limits.memory: "1900Mi"
    pods: "3"
---
apiVersion: v1
kind: ResourceQuota
metadata: { name: rq-db, namespace: db }
spec:
  hard:
    requests.cpu: "500m"
    limits.cpu: "600m"
    requests.memory: "1800Mi"
    limits.memory: "1900Mi"
    pods: "3"
YAML

# ============================
# LimitRanges (기본/상한 일관화)
# ============================
kubectl apply -f - <<'YAML'
apiVersion: v1
kind: LimitRange
metadata: { name: lr-gpu, namespace: gpu }
spec:
  limits:
    - type: Container
      defaultRequest: { cpu: "160m", memory: "600Mi" }
      default:        { cpu: "180m", memory: "620Mi" }
      max:            { cpu: "600m", memory: "650Mi" }
      min:            { cpu: "100m", memory: "256Mi" }
---
apiVersion: v1
kind: LimitRange
metadata: { name: lr-service, namespace: service }
spec:
  limits:
    - type: Container
      defaultRequest: { cpu: "160m", memory: "600Mi" }
      default:        { cpu: "180m", memory: "620Mi" }
      max:            { cpu: "600m", memory: "650Mi" }
      min:            { cpu: "100m", memory: "256Mi" }
---
apiVersion: v1
kind: LimitRange
metadata: { name: lr-db, namespace: db }
spec:
  limits:
    - type: Container
      defaultRequest: { cpu: "160m", memory: "600Mi" }
      default:        { cpu: "180m", memory: "620Mi" }
      max:            { cpu: "600m", memory: "650Mi" }
      min:            { cpu: "100m", memory: "256Mi" }
YAML

# ============================
# GPU Deployment (CPU+Mem 부하, tmpfs)
# - replicas: 3 (NS 파드 3개)
# - tmpfs 500Mi, dd ≈ 400Mi
# ============================
kubectl apply -f - <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: { name: dyn-cpu, namespace: gpu }
spec:
  replicas: 3
  selector: { matchLabels: { app: dyn-cpu } }
  template:
    metadata: { labels: { app: dyn-cpu } }
    spec:
      volumes:
        - name: ram
          emptyDir:
            medium: Memory
            sizeLimit: 500Mi
      containers:
      - name: load
        image: busybox:1.36
        command: ["/bin/sh","-c"]
        args:
          - |
            set -eu
            while true; do
              yes >/dev/null & P1=$!; yes >/dev/null & P2=$!
              dd if=/dev/zero of=/ram/memload bs=1M count=400 2>/dev/null || true
              sleep 15
              rm -f /ram/memload || true
              kill $P1 $P2 2>/dev/null || true
              sleep 5
            done
        volumeMounts:
          - { name: ram, mountPath: /ram }
        resources:
          requests: { cpu: "160m", memory: "600Mi" }
          limits:   { cpu: "180m", memory: "620Mi" }
YAML

# ============================
# Service Deployment (Dyn Mix: CPU+Mem 혼합)
# - tmpfs 500Mi, 단계별 150/300/450Mi
# ============================
kubectl apply -f - <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata: { name: dyn-mix-script, namespace: service }
data:
  run.sh: |
    #!/bin/sh
    set -eu
    while true; do
      yes >/dev/null & CP=$!
      dd if=/dev/zero of=/ram/m1.bin bs=1M count=150 2>/dev/null || true
      sleep 10; rm -f /ram/m1.bin; kill $CP 2>/dev/null || true; sleep 3

      yes >/dev/null & CP=$!
      dd if=/dev/zero of=/ram/m2.bin bs=1M count=300 2>/dev/null || true
      sleep 15; rm -f /ram/m2.bin; kill $CP 2>/dev/null || true; sleep 5

      yes >/dev/null & CP=$!
      dd if=/dev/zero of=/ram/m3.bin bs=1M count=450 2>/dev/null || true
      sleep 12; rm -f /ram/m3.bin; kill $CP 2>/dev/null || true; sleep 8
    done
---
apiVersion: apps/v1
kind: Deployment
metadata: { name: dyn-mix, namespace: service }
spec:
  replicas: 1
  selector: { matchLabels: { app: dyn-mix } }
  template:
    metadata: { labels: { app: dyn-mix } }
    spec:
      volumes:
      - name: ram
        emptyDir: { medium: Memory, sizeLimit: 500Mi }
      - name: script-src
        configMap: { name: dyn-mix-script, defaultMode: 0644 }
      - name: work
        emptyDir: {}
      initContainers:
      - name: normalize-script
        image: busybox:1.36
        command: ["/bin/sh","-c"]
        args: ["tr -d '\r' </scripts/run.sh >/work/run.sh && chmod +x /work/run.sh && /bin/sh -n /work/run.sh"]
        volumeMounts:
        - { name: script-src, mountPath: /scripts }
        - { name: work,       mountPath: /work }
      containers:
      - name: load
        image: busybox:1.36
        command: ["/work/run.sh"]
        volumeMounts:
        - { name: ram,  mountPath: /ram }
        - { name: work, mountPath: /work }
        resources:
          requests: { cpu: "160m", memory: "600Mi" }
          limits:   { cpu: "180m", memory: "620Mi" }
YAML

# ============================
# DB Deployment (디스크 I/O + Mem, tmpfs)
# - replicas: 3 (NS 파드 3개)
# - tmpfs 500Mi, 메모리 부하 450Mi
# ============================
kubectl apply -f - <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: { name: dyn-io, namespace: db }
spec:
  replicas: 3
  selector: { matchLabels: { app: dyn-io } }
  template:
    metadata: { labels: { app: dyn-io } }
    spec:
      volumes:
        - name: data
          emptyDir: {}                # 디스크 I/O
        - name: ram
          emptyDir:
            medium: Memory
            sizeLimit: 500Mi
      containers:
      - name: load
        image: busybox:1.36
        command: ["/bin/sh","-c"]
        args:
          - |
            set -eu
            while true; do
              dd if=/dev/zero of=/data/blob bs=8M count=256 2>/dev/null || true
              sync; rm -f /data/blob || true
              dd if=/dev/zero of=/ram/mem.bin bs=1M count=450 2>/dev/null || true
              sleep 20
              rm -f /ram/mem.bin || true
              sleep 10
            done
        volumeMounts:
          - { name: data, mountPath: /data }
          - { name: ram,  mountPath: /ram }
        resources:
          requests: { cpu: "160m", memory: "600Mi" }
          limits:   { cpu: "180m", memory: "620Mi" }
YAML

# ============================
# Net Server + Client (Service) - fixed resources
# ============================
kubectl apply -f - <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: { name: net-srv, namespace: service }
spec:
  replicas: 1
  selector: { matchLabels: { app: net-srv } }
  template:
    metadata: { labels: { app: net-srv } }
    spec:
      containers:
      - name: httpd
        image: busybox:1.36
        command: ["/bin/sh","-c"]
        args:
          - |
            set -eu
            mkdir -p /www
            dd if=/dev/zero of=/www/bigfile bs=1M count=200 status=none
            exec httpd -f -p 8080 -h /www
        ports:
        - { name: http, containerPort: 8080 }
        resources:
          requests: { cpu: "100m", memory: "256Mi" }
          limits:   { cpu: "200m", memory: "300Mi" }
---
apiVersion: v1
kind: Service
metadata: { name: net-srv, namespace: service }
spec:
  selector: { app: net-srv }
  ports:
    - { name: http, port: 8080, targetPort: 8080 }
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata: { name: net-gen, namespace: service }
spec:
  replicas: 1
  selector: { matchLabels: { app: net-gen } }
  template:
    metadata: { labels: { app: net-gen } }
    spec:
      containers:
      - name: client
        image: busybox:1.36
        command: ["/bin/sh","-c"]
        args:
          - |
            set -eu
            while true; do
              wget -q -O - http://net-srv:8080/bigfile > /dev/null || true
              sleep 2
            done
        resources:
          requests: { cpu: "100m", memory: "256Mi" }
          limits:   { cpu: "200m", memory: "300Mi" }
YAML
