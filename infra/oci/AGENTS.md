# AGENTS.md

## OKE Cluster 접속

- 로컬 개발환경에선 OCI Bastion으로 OKE production 클러스터에 접속한다.
- 현재 개발환경 기준 kubeconfig는 `~/.kube/litomi-prod-seoul`을 사용한다.
- OCI OCID, private endpoint IP, ssh-metadata 출력값은 repo에 기록하지 않는다.
- OKE Cluster 는 kubectl 로 직접 수정하지 않는다. Terraform 으로만 수정한다.

### Bastion tunnel 여는 법

1. Bastion port-forwarding session을 만든다. Terraform의 Bastion TTL이 10800초라
   session TTL도 10800초로 맞춘다.

   ```sh
   export KUBECONFIG="$HOME/.kube/litomi-prod-seoul"
   export BASTION_NAME="litomi-prod-oke-api-bastion"
   export CLUSTER_NAME="litomi-prod-oke"
   export BASTION_SSH_KEY="$HOME/.ssh/litomi-prod-bastion"
   export LOCAL_API_PORT="16443"

   BASTION_ID="$(oci search resource structured-search \
     --query-text "query all resources where displayName = '$BASTION_NAME'" \
     --limit 1 \
     --query 'data.items[0].identifier' \
     --raw-output)"

   CLUSTER_ID="$(oci search resource structured-search \
     --query-text "query all resources where displayName = '$CLUSTER_NAME'" \
     --limit 1 \
     --query 'data.items[0].identifier' \
     --raw-output)"

   CLUSTER_PRIVATE_ENDPOINT="$(oci ce cluster get \
     --cluster-id "$CLUSTER_ID" \
     --query 'data.endpoints."private-endpoint"' \
     --raw-output)"

   TARGET_PRIVATE_IP="${CLUSTER_PRIVATE_ENDPOINT%:*}"
   TARGET_PORT="${CLUSTER_PRIVATE_ENDPOINT##*:}"

   SESSION_ID="$(oci bastion session create-port-forwarding \
     --bastion-id "$BASTION_ID" \
     --display-name "local-oke-api-tunnel" \
     --key-type PUB \
     --ssh-public-key-file "${BASTION_SSH_KEY}.pub" \
     --target-private-ip "$TARGET_PRIVATE_IP" \
     --target-port "$TARGET_PORT" \
     --session-ttl 10800 \
     --wait-for-state SUCCEEDED \
     --wait-interval-seconds 5 \
     --max-wait-seconds 180 \
     --query 'data.resources[0].identifier' \
     --raw-output)"
   ```

2. SSH tunnel을 foreground로 띄운다. 이 프로세스가 살아 있는 동안에만
   `kubectl`이 동작한다. 종료할 때는 `Ctrl-C`로 끊는다(로컬 터널만 닫히므로
   session 정리는 아래 "정리하는 법" 참고).

   session이 `SUCCEEDED`가 된 직후에는 SSH 인증이 아직 준비되지 않아
   `Permission denied (publickey)`가 날 수 있다. 10~15초 기다렸다 재시도한다.
   ssh-agent에 다른 키가 많으면 엉뚱한 키를 먼저 제시하다 거부당할 수 있으므로
   `IdentitiesOnly=yes`로 지정한 키만 쓰게 한다.

   ```sh
   ssh -i "$BASTION_SSH_KEY" -N \
     -L "127.0.0.1:${LOCAL_API_PORT}:${TARGET_PRIVATE_IP}:${TARGET_PORT}" \
     -p 22 "${SESSION_ID}@host.bastion.ap-seoul-1.oci.oraclecloud.com" \
     -o IdentitiesOnly=yes \
     -o ExitOnForwardFailure=yes \
     -o ServerAliveInterval=30 \
     -o ServerAliveCountMax=3 \
     -o StrictHostKeyChecking=accept-new
   ```

3. 다른 터미널에서 접속을 확인한다.

   ```sh
   KUBECONFIG="$HOME/.kube/litomi-prod-seoul" kubectl get ns
   ```

### Bastion tunnel 정리하는 법

`Ctrl-C`로 SSH를 끊으면 로컬 터널만 닫히고, OCI Bastion session은
TTL(10800초)이 만료될 때까지 `ACTIVE`로 남는다. 작업이 끝나면 session도
명시적으로 삭제한다.

```sh
oci bastion session delete --session-id "$SESSION_ID" --force
```

같은 shell이 아니어서 `$SESSION_ID`가 없으면, display-name으로 남아 있는
`ACTIVE` session을 찾아 지운다.

```sh
BASTION_ID="$(oci search resource structured-search \
  --query-text "query all resources where displayName = '$BASTION_NAME'" \
  --limit 1 --query 'data.items[0].identifier' --raw-output)"

oci bastion session list \
  --bastion-id "$BASTION_ID" \
  --session-lifecycle-state ACTIVE --all \
  --query "data[?\"display-name\"=='local-oke-api-tunnel'].id | join(' ', @)" \
  --raw-output \
  | xargs -n1 -I{} oci bastion session delete --session-id {} --force
```
