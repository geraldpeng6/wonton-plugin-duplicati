# shellcheck shell=bash
# Duplicati：sso=proxy（网关代填 PreAuth 令牌）；清单没有 mcp。

web_assert() { grep -qi 'duplicati\|ngclient'; }   # stdin：SPA 首页（<title>Backup</title>，引用 ngclient）

identity_check() { # 网关带 PreAuth 令牌后，systeminfo 直接返回系统信息而不是登录质询
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
