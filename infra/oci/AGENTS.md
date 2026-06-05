# AGENTS.md

## OKE Cluster 접속

- 로컬 개발환경에선 OCI Bastion으로 OKE production 클러스터에 접속한다.
- 현재 개발환경 기준 kubeconfig는 `~/.kube/litomi-prod-seoul`을 사용한다.
- OCI OCID, private endpoint IP, ssh-metadata 출력값은 repo에 기록하지 않는다.

### Bastion tunnel 여는 법

1. Bastion port-forwarding session을 만든다. Terraform의 Bastion TTL이 10800초라
   session TTL도 10800초로 맞춘다.

   ```sh
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
   `kubectl`이 동작한다. 종료할 때는 `Ctrl-C`로 끊는다.

   ```sh
   ssh -i "$BASTION_SSH_KEY" -N \
     -L "127.0.0.1:${LOCAL_API_PORT}:${TARGET_PRIVATE_IP}:${TARGET_PORT}" \
     -p 22 "${SESSION_ID}@host.bastion.ap-seoul-1.oci.oraclecloud.com" \
     -o ExitOnForwardFailure=yes \
     -o ServerAliveInterval=30 \
     -o ServerAliveCountMax=3 \
     -o StrictHostKeyChecking=accept-new
   ```
