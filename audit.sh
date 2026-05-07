#!/bin/bash
PASS=0; FAIL=0; NA=0

api_check() {
  local id=$1 desc=$2 flag=$3 expected=$4
  val=$(ps -ef | grep kube-apiserver | grep -v grep | grep -oP "\-\-${flag}=\K\S+" 2>/dev/null || echo "")
  if [[ -n "$val" && "$val" == *"$expected"* ]]; then
    printf "[✓] %-10s %s\n" "$id:" "$desc => PASS"; PASS=$((PASS+1))
  else
    printf "[✗] %-10s %s => FAIL  (got: %s)\n" "$id:" "$desc" "${val:-NOT_SET}"; FAIL=$((FAIL+1))
  fi
}

api_absent() {
  local id=$1 desc=$2 flag=$3
  val=$(ps -ef | grep kube-apiserver | grep -v grep | grep -oP "\-\-${flag}=\K\S+" 2>/dev/null || echo "")
  if [[ -z "$val" ]]; then
    printf "[✓] %-10s %s\n" "$id:" "$desc => PASS"; PASS=$((PASS+1))
  else
    printf "[✗] %-10s %s => FAIL  (got: %s)\n" "$id:" "$desc" "$val"; FAIL=$((FAIL+1))
  fi
}

cm_check() {
  local id=$1 desc=$2 flag=$3 expected=$4
  val=$(ps -ef | grep kube-controller-manager | grep -v grep | grep -oP "\-\-${flag}=\K\S+" 2>/dev/null || echo "")
  if [[ -n "$val" && "$val" == *"$expected"* ]]; then
    printf "[✓] %-10s %s\n" "$id:" "$desc => PASS"; PASS=$((PASS+1))
  else
    printf "[✗] %-10s %s => FAIL  (got: %s)\n" "$id:" "$desc" "${val:-NOT_SET}"; FAIL=$((FAIL+1))
  fi
}

sc_check() {
  local id=$1 desc=$2 flag=$3 expected=$4
  val=$(ps -ef | grep kube-scheduler | grep -v grep | grep -oP "\-\-${flag}=\K\S+" 2>/dev/null || echo "")
  if [[ -n "$val" && "$val" == *"$expected"* ]]; then
    printf "[✓] %-10s %s\n" "$id:" "$desc => PASS"; PASS=$((PASS+1))
  else
    printf "[✗] %-10s %s => FAIL  (got: %s)\n" "$id:" "$desc" "${val:-NOT_SET}"; FAIL=$((FAIL+1))
  fi
}

et_check() {
  local id=$1 desc=$2 flag=$3 expected=$4
  val=$(ps -ef | grep " etcd " | grep -v grep | grep -oP "\-\-${flag}=\K\S+" 2>/dev/null || echo "")
  if [[ -n "$val" && "$val" == *"$expected"* ]]; then
    printf "[✓] %-10s %s\n" "$id:" "$desc => PASS"; PASS=$((PASS+1))
  else
    printf "[✗] %-10s %s => FAIL  (got: %s)\n" "$id:" "$desc" "${val:-NOT_SET}"; FAIL=$((FAIL+1))
  fi
}

na_note() {
  printf "[?] %-10s %s => MANUAL\n" "$1:" "$2"; NA=$((NA+1))
}

echo "============================================================"
echo " CIS Kubernetes Benchmark v1.12.0 – Sections 1.2 / 1.3 / 1.4 / 2"
echo " Automated Check"
echo "============================================================"

echo "Section 1.2 – API Server"
echo "------------------------------------------------------------"
api_check  "1.2.1"   "anonymous-auth = false"                "anonymous-auth"                          "false"
api_absent "1.2.2"   "token-auth-file not set"               "token-auth-file"
api_check  "1.2.3"   "DenyServiceExternalIPs enabled"        "enable-admission-plugins"                "DenyServiceExternalIPs"
api_check  "1.2.4a"  "kubelet-client-certificate set"        "kubelet-client-certificate"              ".crt"
api_check  "1.2.4b"  "kubelet-client-key set"                "kubelet-client-key"                      ".key"
api_check  "1.2.5"   "kubelet-certificate-authority set"     "kubelet-certificate-authority"           ".crt"
api_check  "1.2.6"   "authorization-mode != AlwaysAllow"     "authorization-mode"                      "RBAC"
api_check  "1.2.7"   "authorization-mode includes Node"      "authorization-mode"                      "Node"
api_check  "1.2.8"   "authorization-mode includes RBAC"      "authorization-mode"                      "RBAC"
api_check  "1.2.9"   "EventRateLimit enabled"                "enable-admission-plugins"                "EventRateLimit"
v=$(ps -ef | grep kube-apiserver | grep -v grep | grep -oP "\-\-enable-admission-plugins=\K\S+" || echo "")
if [[ "$v" != *"AlwaysAdmit"* ]]; then
  printf "[✓] %-10s %s\n" "1.2.10:" "AlwaysAdmit not enabled => PASS"; PASS=$((PASS+1))
else
  printf "[✗] %-10s %s\n" "1.2.10:" "AlwaysAdmit must be removed => FAIL"; FAIL=$((FAIL+1))
fi
api_check  "1.2.11"  "AlwaysPullImages enabled"              "enable-admission-plugins"                "AlwaysPullImages"
api_absent "1.2.12"  "ServiceAccount not disabled"           "disable-admission-plugins"
api_absent "1.2.13"  "NamespaceLifecycle not disabled"       "disable-admission-plugins"
api_check  "1.2.14"  "NodeRestriction enabled"               "enable-admission-plugins"                "NodeRestriction"
api_check  "1.2.15"  "profiling = false"                     "profiling"                               "false"
api_check  "1.2.16"  "audit-log-path set"                    "audit-log-path"                          "audit.log"
api_check  "1.2.17"  "audit-log-maxage >= 30"                "audit-log-maxage"                        "30"
api_check  "1.2.18"  "audit-log-maxbackup >= 10"             "audit-log-maxbackup"                     "10"
api_check  "1.2.19"  "audit-log-maxsize >= 100"              "audit-log-maxsize"                       "100"
v=$(ps -ef | grep kube-apiserver | grep -v grep | grep -oP "\-\-request-timeout=\K\S+" 2>/dev/null || echo "")
if [[ -z "$v" || "$v" != "0" ]]; then
  printf "[✓] %-10s %s\n" "1.2.20:" "request-timeout acceptable (default 60s) => PASS"; PASS=$((PASS+1))
else
  printf "[✗] %-10s %s\n" "1.2.20:" "request-timeout=0 invalid => FAIL"; FAIL=$((FAIL+1))
fi
v=$(ps -ef | grep kube-apiserver | grep -v grep | grep -oP "\-\-service-account-lookup=\K\S+" 2>/dev/null || echo "")
if [[ -z "$v" || "$v" == "true" ]]; then
  printf "[✓] %-10s %s\n" "1.2.21:" "service-account-lookup = true (default) => PASS"; PASS=$((PASS+1))
else
  printf "[✗] %-10s %s\n" "1.2.21:" "service-account-lookup=false => FAIL"; FAIL=$((FAIL+1))
fi
api_check  "1.2.22"  "service-account-key-file set"          "service-account-key-file"                "sa.pub"
api_check  "1.2.23a" "etcd-certfile set"                     "etcd-certfile"                           ".crt"
api_check  "1.2.23b" "etcd-keyfile set"                      "etcd-keyfile"                            ".key"
api_check  "1.2.24a" "tls-cert-file set"                     "tls-cert-file"                           ".crt"
api_check  "1.2.24b" "tls-private-key-file set"              "tls-private-key-file"                    ".key"
api_check  "1.2.25"  "client-ca-file set"                    "client-ca-file"                          ".crt"
api_check  "1.2.26"  "etcd-cafile set"                       "etcd-cafile"                             ".crt"
api_check  "1.2.27"  "encryption-provider-config set"        "encryption-provider-config"              ".yaml"
api_check  "1.2.29"  "strong TLS ciphers only"               "tls-cipher-suites"                       "AES_128_GCM"
api_check  "1.2.30"  "token-expiration-extension = false"    "service-account-extend-token-expiration" "false"

echo "Section 1.3 – Controller Manager"
echo "------------------------------------------------------------"
cm_check "1.3.1" "terminated-pod-gc-threshold set"        "terminated-pod-gc-threshold"         "10"
cm_check "1.3.2" "profiling = false"                      "profiling"                           "false"
cm_check "1.3.3" "use-service-account-credentials = true" "use-service-account-credentials"     "true"
cm_check "1.3.4" "service-account-private-key-file set"   "service-account-private-key-file"    ".key"
cm_check "1.3.5" "root-ca-file set"                       "root-ca-file"                        ".crt"
cm_check "1.3.6" "RotateKubeletServerCertificate = true"  "feature-gates"                       "RotateKubeletServerCertificate=true"
cm_check "1.3.7" "bind-address = 127.0.0.1"               "bind-address"                        "127.0.0.1"

echo "Section 1.4 – Scheduler"
echo "------------------------------------------------------------"
sc_check "1.4.1" "profiling = false"        "profiling"    "false"
sc_check "1.4.2" "bind-address = 127.0.0.1" "bind-address" "127.0.0.1"

echo "Section 2 – etcd"
echo "------------------------------------------------------------"
et_check "2.1a" "cert-file set"             "cert-file"        ".crt"
et_check "2.1b" "key-file set"              "key-file"         ".key"
et_check "2.2"  "client-cert-auth = true"   "client-cert-auth" "true"
v=$(ps -ef | grep " etcd " | grep -v grep | grep -oP "\-\-auto-tls=\K\S+" 2>/dev/null || echo "")
if [[ "$v" != "true" ]]; then
  printf "[✓] %-10s %s\n" "2.3:" "auto-tls not true => PASS"; PASS=$((PASS+1))
else
  printf "[✗] %-10s %s\n" "2.3:" "auto-tls=true must be removed => FAIL"; FAIL=$((FAIL+1))
fi
na_note "2.4" "peer-cert-file (single etcd node)"
na_note "2.5" "peer-client-cert-auth (single etcd node)"
na_note "2.6" "peer-auto-tls (single etcd node)"
et_check "2.7" "etcd uses separate CA" "trusted-ca-file" "etcd"

echo "============================================================"
echo "Tổng: $((PASS+FAIL)) | PASS: $PASS | FAIL: $FAIL | N/A (manual): $NA"
if [[ $FAIL -eq 0 ]]; then
  echo "Tất cả automated checks đều PASS."
else
  echo "Có $FAIL check FAIL – chạy: ansible-playbook master_remediation.yml"
fi
echo "============================================================"
