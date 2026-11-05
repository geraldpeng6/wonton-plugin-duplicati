# scripts/smoke.sh 的一项一项探测，跟着插件走。没写的项会 FAIL 并给出写法，不会默认放行。
#
# 页面：web_assert 从标准输入读页面，命中的确是应用的真实页面时返回 0。
# 身份：identity_check 用应用自己的“当前用户”接口断言认出的是主人管理员。没有用户体系时写 IDENTITY_NA=1，
#       并在 SMOKE_NOTE 里写原因。dweb / web_get 是带主人会话的请求助手，可继续走应用自己的登录链。
# 工具：MCP_TOOL 写一个只读工具名（可带插件前缀），MCP_ARGS 是 JSON 参数；mcp_assert 从标准输入读调用结果。
#       要断言多个工具时改成写 mcp_check；调用前要备数据时写 before_mcp。
# 装之前要准备（如先配出口代理）：写 before_install。

SSO=proxy
MCP=0

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
