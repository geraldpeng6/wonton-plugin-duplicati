# 云吞插件：Duplicati

云吞（Wonton）的插件就是一个 `docker-compose.yml`，顶层多一个 `x-wonton` 字段，写明插件在云吞里的身份、网页入口和要的
权限。一个插件一个 Git 仓库，仓库根目录就是插件包，发布就是打 tag。主人在 App 里装上插件，核心按清单起容器、接好登录，
插件的网页在 App 里作为小程序打开。

这个插件把共享文件夹里的文档和照片加密备份到主人选的目的地：S3、WebDAV 等网盘，或本机的 `backups` 共享文件夹。
备份先加密再上传，存储服务商看不到内容；支持按块去重、压缩和增量备份，从任意备份点原样恢复。打开网页不用再登录一次。

## 许可证

插件包采用 [MIT License](LICENSE)，上游 Duplicati 标志不适用该许可，标志的许可与商标说明见 [NOTICE](NOTICE)。
独立容器中的 Duplicati 遵循上游许可证；清单的 `license` 填 Duplicati 的许可证。

| 组件 | 许可证 |
| --- | --- |
| Duplicati 2.4.1.0 | [MIT](https://github.com/duplicati/duplicati/blob/master/LICENSE) |
| duplicati/duplicati 官方镜像 | [MIT](https://github.com/duplicati/duplicati/blob/master/LICENSE)（镜像包装代码随上游发布） |

## 图标来源

`icon.svg` 按 Duplicati 官方应用图标（`Assets/application icon/application_icon.svg`）的三个圆角方块布局与配色重绘；
来源、版权、处理方式、上游 MIT 全文和商标说明见 [NOTICE](NOTICE)。Duplicati 名称及标志是 Duplicati Inc. 的商标，
权利归其权利人所有；此处仅用于标识插件集成的上游应用，不表示本插件与 Duplicati 项目存在官方合作、隶属或认可关系。

## 准备

- Docker Engine 28 或更新的版本，带 Compose 插件（`docker compose`）。Linux 上的 Docker Engine、macOS 上的 Docker Desktop 和
  OrbStack 都行。
- `git`、`curl`（7.76 或更新）、`python3`。
- Docker 要在本机：开发环境的数据目录是这个仓库下的路径，网页也开在本机的端口上。在远程主机上开发见后面的
  “在远程主机上开发”。

不用装云吞，也不要 root：脚本用发布的核心镜像（`ghcr.io/geraldpeng6/wonton-core`）检查插件、起开发环境。

## 先跑起来

```bash
scripts/dev.sh up
```

```bash
scripts/dev.sh install
```

`up` 在本机起一套云吞，打印它的地址（实例名取自目录名加 4 位随机数，端口随机）。浏览器打开，用 `scripts/dev.sh token`
输出的主人令牌登录。`install` 先列出插件要的权限，确认后装上，打印插件网页的地址。

装好后第一次打开就是 Duplicati 的网页，经核心网关代登录，不再要第二次密码。要备份的共享文件夹（`documents`、`photos`）
只读挂进容器，本机目的地是可写的 `backups` 共享文件夹；网盘目的地（S3、WebDAV 等）在网页里自己配，经核心的出口出网。

## 仓库里有什么

| 路径 | 内容 |
| --- | --- |
| `docker-compose.yml` | 插件本身：compose 加上 `x-wonton` 清单 |
| `icon.svg` | 清单引用的图标 |
| `screenshots/` | 商店详情页里的截图 |
| `scripts/check.sh` | 检查插件包，规则和安装时一样 |
| `scripts/dev.sh` | 开发环境：起一套云吞，装、重装、卸载插件，看日志 |
| `scripts/smoke-probes.sh` | `scripts/dev.sh smoke` 对这个插件逐项的探测 |
| `scripts/publish.sh` | 发布一个版本：打 tag、推送 |
| `AGENTS.md` | 给人和 AI 编程代理的规则 |
| `LICENSE` | 插件包自己的许可证 |
| `NOTICE` | 图标等第三方素材的许可和声明 |
| `.wonton/` | 开发环境的设置、密钥和数据，不提交 |

插件包是 `docker-compose.yml` 加上它引用的文件：`icon`、`notices`。README、截图、Dockerfile、源码都不在插件包里，核心
不取。引用的路径相对仓库根目录，不能是绝对路径、不能含 `..`、不能用变量，也不能经过软链接；单个文件不超过 1 MiB，
整个插件包不超过 2 MiB。安装时插件包以 tar 归档上传，归档里只能有普通文件和目录，最多 256 项。

插件的 compose 和清单怎么写，见[插件规范](https://github.com/geraldpeng6/wonton-docs/blob/main/plugin-spec.md)和模板仓库
[geraldpeng6/wonton-plugin-template](https://github.com/geraldpeng6/wonton-plugin-template) 的 README。

## 开发环境

| 命令 | 做什么 |
| --- | --- |
| `scripts/dev.sh up` | 起开发环境，等到都健康；再执行一次就是拉最新的核心镜像重启（`WONTON_PULL=never` 时不拉） |
| `scripts/dev.sh install [--yes] [<git 引用>]` | 预览、确认后安装；给了 tag、分支或提交就装那个版本（用你自己的 git 导出，私有仓库也行） |
| `scripts/dev.sh reinstall [--yes]` | 装着就先卸载（保留数据），再装上工作区里的：改了插件包以后用 |
| `scripts/dev.sh uninstall [--purge]` | 卸载；`--purge` 连插件的数据一起删 |
| `scripts/dev.sh status` | 开发环境的服务和装着的插件 |
| `scripts/dev.sh logs [<服务>]` | 跟着看核心的日志；给了插件的服务名就看那个服务的 |
| `scripts/dev.sh token` | 主人令牌 |
| `scripts/dev.sh web [--jar <文件>] [--fresh] [<路径> [<curl 参数>…]]` | 以主人的身份请求插件网页上的地址（默认 `/`），其余参数交给 curl：没有浏览器时验证网页和接口。默认沿用 `session` 的会话，能带着它走完应用自己的登录链 |
| `scripts/dev.sh session [--new]` | 建立（`--new` 重建）主人会话，cookie 留在 `.wonton/session.cookies` |
| `scripts/dev.sh mcp list` | Bot 经 MCP 总线能调到的工具（JSON），在 Hermes gateway 容器里用官方 SDK 执行 |
| `scripts/dev.sh mcp call <工具> [<JSON>]` | 经 MCP 总线调用工具，参数是 JSON 对象，默认 `{}` |
| `scripts/dev.sh smoke` | 合并前的端到端冒烟：装得上、网页打得开、主人身份能用、工具 Bot 调得到，任何 FAIL 退出非 0 |
| `scripts/dev.sh pair` | 终端里出配对二维码，App 扫码连上这套开发环境 |
| `scripts/dev.sh down` | 停下，数据都留着 |
| `scripts/dev.sh purge` | 删掉整个开发环境 |

`smoke` 把工作区复制到临时目录，起一套以 `smoke` 开头的一次性实例，四项都跑真实请求，跑完删掉容器、网络、卷和目录，
不动已有的 `.wonton`。插件自己的探测写在 `scripts/smoke-probes.sh`，没写探测的项 FAIL 并给出写法。
要用出口代理时设 `WONTON_DEV_EGRESS_PROXY=http://…`，不设就不配。

开发环境和正式安装用同一份 compose（核心、身份提供方 Ory Hydra、Matrix 服务器 Tuwunel），只是项目名、核心的容器名
和实例名不同；核心起来后同样预装模型网关 magpie（`ai.usemagpie.magpie`）。第一次 `up` 时定下设置，写在 `.wonton/.env`：

- 实例名（`WONTON_INSTANCE`）：默认是目录名（去掉 `wonton-plugin-` 前缀）加 4 位随机数。核心建的容器、网络和卷都带上它，
  如（示例）`wonton-duplicati3f2a--app-duplicati-duplicati--duplicati`，再打上 `wonton.instance` 标签。几个人或几个 Agent 共用一台
  Docker 时各起各的开发环境，同一个插件也能在几套里同时装，卸载时只删自己那套的。
- 基础域名是 `<实例名>.wonton.localhost`，核心在 `http://<实例名>.wonton.localhost:<端口>/`，插件网页在
  `http://<slug>.<实例名>.wonton.localhost:<端口>/`。
- 端口：网页用一个随机挑的空闲端口，隧道（UDP）用下一个。
- 核心镜像：默认 `ghcr.io/geraldpeng6/wonton-core:beta`。第一次 `up` 时可以用 `WONTON_CORE_IMAGE` 换掉；本机构建的镜像再
  加上 `WONTON_PULL=never`，不去拉取。之后改 `.wonton/.env` 里的 `WONTON_CORE_SOURCE` 再 `up`。
- 要用带本地官方索引的开发镜像：在主仓库里执行
  `docker build --target dev -t wonton-core:plugin-dev -f deploy/dev/core/Dockerfile .`，再
  `WONTON_CORE_IMAGE=wonton-core:plugin-dev WONTON_PULL=never scripts/dev.sh up`。只有 `dev` 阶段带
  `WONTON_STORE_INDEX` 指向的本地索引，默认的 `:beta` 没有它，从 GitHub 取。

几点要注意：

- `down` 只停核心、身份提供方和 Matrix 服务器，插件的容器由核心管，照常运行；不要了就 `uninstall` 或 `purge`。
- 实例名和基础域名定下后不能改：基础域名也是 Matrix 的服务器名，实例名改了就找不到已经装上的插件。要换就先 `purge`。
- 共用一台 Docker 时只用这些脚本起停和清理，不要 `docker system prune`、`docker volume prune`，也不要动名字里不是自己实例名
  的容器、网络和卷。
- 每套开发环境至少占 3 个 Docker 网络（核心一个，magpie 和每个插件各一个），Docker 默认的地址池大约 30 个。一台主机上
  开很多套、报 “all predefined address pools have been fully subnetted” 时，在 Docker 的 `daemon.json` 里把
  `default-address-pools` 配得更细（如 `/24`）。

### 排错

- 安装失败时，错误里有原因和失败的容器最近的日志。装上以后用 `scripts/dev.sh logs <服务>` 看，或者进容器看：
  `docker exec -it wonton-<实例名>--<slug>--<服务> sh`。
- `scripts/dev.sh status` 列出插件的状态：`running healthy` 是每个长期运行的服务都有健康检查而且都通过了；
  `running unknown` 是只知道在运行（有服务没有健康检查，或者核心重启后还没检查通过）；`degraded` 后面是原因。核心在
  安装时和每次启动时检查，两次检查之间不盯着插件，容器停了要看 `docker ps`。
- 管理接口用主人令牌调：

  ```bash
  curl -H "Authorization: Bearer $(scripts/dev.sh token)" http://<实例名>.wonton.localhost:<端口>/_wonton/api/plugins
  ```

### 在远程主机上开发

Docker 在另一台 Linux 主机上时，把仓库克隆到那台主机，在那里执行脚本。浏览器在自己的电脑上，用 SSH 把开发环境的端口转发
过来，再打开同样的地址：

```bash
ssh -L 21234:127.0.0.1:21234 <远程主机>
```

`*.localhost` 在自己的电脑上解析到本机，经转发到远程主机的开发环境，地址里的域名原样带到核心的网关。

### 在 App 里看

`scripts/dev.sh pair` 在终端里出配对二维码，用云吞 App 扫码，App 就连上这套开发环境，插件在主屏上。手机在局域网里时要能
访问这台主机的隧道端口（UDP，`.wonton/.env` 里的 `WONTON_TUNNEL_PORT`），在外面时经中继连上。

## 检查

```bash
scripts/check.sh
```

在核心镜像里执行 `wonton-core plugin check`，和安装时同一套解析和校验，再检查商店信息、图标和截图，最后列出插件包里的
文件和插件包摘要。不连 Docker 里的核心，也不联网。

- 插件包解析不了时只报这一条，和安装时报的一样。
- 不合格（退出码 1）：装不上的（核心不支持的权限、渲染不了的 compose），图标或截图处理不了。
- 提醒（退出码 0）：镜像没有按摘要固定，长期运行的服务没有健康检查，没有图标，图标的角是透明的，截图太小或横竖混用。

`scripts/check.sh --official` 按官方商店的要求：前三项提醒（镜像没按摘要固定、没有健康检查、没有图标）也算不合格，
还要有 `category`、`license` 和 `author`。

## 发布

1. 把清单的 `version` 改成新版本，写好 `release_notes`，确认 `notices` 和它引用的文件是最新的，提交。
2. 执行 `scripts/publish.sh`（要进官方商店加 `--official`）。它检查工作区干净、插件包合格；`images/` 里有自己的镜像时先
   构建、推送并按摘要写回，然后打 tag `v<版本>`，推送当前分支和 tag。本插件只用上游官方镜像，没有 `images/`，直接
   打 tag。

发布过的 tag 不要移动：已经装上的不受影响，但核心会提示主人这个 tag 被改过。带预发布后缀的版本（如 `v1.2.0-beta.1`）只能
按 tag 明确安装，不进商店，也不作为升级提示。

插件要用自己构建的镜像时，把 Dockerfile 放在 `images/<名字>/`，compose 里写 `image: ghcr.io/<你>/<名字>:<版本>`。
`publish.sh` 用 `docker buildx` 构建 linux/amd64 和 linux/arm64 的镜像，推上去，把 compose 里这一行改成新版本的摘要再
提交。这需要能构建多架构镜像的 buildx，和 `docker login` 登录镜像仓库；镜像要公开，主人的服务器才拉得到。核心不构建镜像，
所以 compose 里不能写 `build`。开发时先在本机构建同名的镜像（`docker build -t ghcr.io/<你>/<名字>:<版本> images/<名字>`），
本机有这个镜像时核心不去拉取。

仓库公开、加上 topic `wonton-plugin` 以后，插件出现在商店的社区插件里，标为“未审核”。想进官方商店，按 `--official` 的
要求准备好，向官方索引提 PR。仓库私有时核心取不到，用 `scripts/dev.sh install <tag>` 从本地导出安装。

## 界面

> Avoid unnecessary secondary labels and descriptions. Let the layout do the explaining.

插件自己的网页也照这条做：分组、顺序、位置和图标已经说明了的，不再加副标题、说明文字或标签重复一遍。错误、权限这类提示
不算多余，照常写清楚。

## 规则以哪里为准

插件包的完整规则和理由在[插件规范](https://github.com/geraldpeng6/wonton-docs/blob/main/plugin-spec.md)里。
规范和核心一起演进；说法对不上时以核心的检查为准：`scripts/check.sh` 通过、`scripts/dev.sh install` 装得上，插件包才算写对了。
