# shellcheck shell=bash
# Duplicati：sso=proxy（网关代填 PreAuth 令牌）；清单没有 mcp。

web_assert() { grep -qi 'duplicati\|ngclient'; }   # stdin：SPA 首页（<title>Backup</title>，引用 ngclient）

identity_check() { # 网关带 PreAuth 令牌后，systeminfo 直接返回系统信息而不是登录质询
  SMOKE_WEB_URL="${SMOKE_WEB_URL%/}"  # 套件给的地址带尾斜杠，拼路径前剥掉，避免 // 打不进路由
  local info anon
  info="$(web_get /api/v1/systeminfo)" || { echo "systeminfo 失败：$info"; return 1; }
  grep -q '"ServerVersion"' <<<"$info" ||
    { echo "systeminfo 不是系统信息：$(head -c 200 <<<"$info")"; return 1; }
  # PreAuth 认证不带用户概念，但匿名请求必须进不来：无会话时网关挡在前面
  anon="$(curl -sS --noproxy '*' -o /dev/null -w '%{http_code}' "$SMOKE_WEB_URL/api/v1/systeminfo")"
  case "$anon" in
    401|301|302|303|307|308) : ;;
    *) echo "匿名请求没被网关拦住：$anon"; return 1 ;;
  esac
}

# 数据：备份任务的配置存在应用自己的 SQLite（docker-compose.yml 的 ${WONTON_APP_DATA}/data）。
# data_write 经应用自己的 API 建一个停用的备份任务（名字带随机标记，指向 /data 下的空目录，
# 停用保证调度器不会真跑），任务 id 记进 SMOKE_STATE；data_check 在升级、重装后从任务列表读回比对。
_dp_marker_file() { # 标记文件：SMOKE_STATE 在 dev.sh probes 里是目录，目录里放标记文件
  if [[ -d "${SMOKE_STATE:-}" ]]; then printf '%s/data-marker' "$SMOKE_STATE"; else printf '%s' "${SMOKE_STATE:-}"; fi
}

data_write() {
  local marker out id
  marker="wonton-smoke-$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')"
  dweb --fresh / -L >/dev/null || { echo "重建网关会话失败"; return 1; }
  out="$(web_get /api/v1/backups -X POST -H 'Content-Type: application/json' \
    --data "$(jq -nc --arg n "$marker" --arg p "$(tr -dc a-zA-Z0-9 </dev/urandom | head -c 24)" '{
      Backup:{Name:$n,Description:"wonton smoke 数据探针，停用不跑",
        TargetURL:"file:///data/wonton-smoke-target",Sources:["/data"],Enabled:false,
        Settings:[{Name:"passphrase",Value:$p}]},
      Schedule:null}')")" || { echo "建备份任务失败：$out"; return 1; }
  id="$(jq -r '.Backup.ID // .ID // empty' <<<"$out")"
  [[ -n "$id" ]] || { echo "建任务没返回 ID：$out"; return 1; }
  jq -nc --arg id "$id" --arg name "$marker" '{id:$id,name:$name}' >"$(_dp_marker_file)" ||
    { echo "写不进标记文件 $(_dp_marker_file)"; return 1; }
  echo "已建停用备份任务 $marker（ID $id）"
}

data_check() {
  local marker out
  marker="$(cat "$(_dp_marker_file)" 2>/dev/null)" || true
  [[ -n "$marker" ]] || { echo "没有 data_write 留下的标记（SMOKE_STATE=${SMOKE_STATE:-未设置}）"; return 1; }
  dweb --fresh / -L >/dev/null || { echo "重建网关会话失败"; return 1; }
  out="$(web_get "/api/v1/backup/$(jq -r .id <<<"$marker")")" ||
    { echo "读不回任务 $(jq -r .name <<<"$marker")（ID $(jq -r .id <<<"$marker")）：$out"; return 1; }
  jq -e --arg n "$(jq -r .name <<<"$marker")" --arg i "$(jq -r .id <<<"$marker")" \
    '.Backup.Name == $n and .Backup.ID == $i' <<<"$out" >/dev/null ||
    { echo "任务内容对不上：$(head -c 200 <<<"$out")"; return 1; }
  echo "备份任务 $(jq -r .name <<<"$marker") 还在（ID $(jq -r .id <<<"$marker")）"
}
