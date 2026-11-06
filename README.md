# 云吞插件：Duplicati

开发流程见[插件开发指南](https://github.com/geraldpeng6/wonton-docs/blob/main/develop.md)。

这个插件把共享文件夹里的文档和照片加密备份到主人选的目的地：S3、WebDAV 等网盘，或本机的 `backups` 共享文件夹。
备份先加密再上传，存储服务商看不到内容；支持按块去重、压缩和增量备份。恢复时文件回到本机的 `backups`
文件夹，再从那里拷回要放的位置（要备份的共享文件夹只读挂载，恢复不能直接写回原处）。打开网页不用再登录一次。

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

## 先跑起来

```bash
scripts/dev.sh up
scripts/dev.sh install
```

`up` 在本机起一套云吞并打印它的地址，用 `scripts/dev.sh token` 输出的用户令牌登录；`install` 列出插件要的权限，确认后
装上并打印插件网页的地址。

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
| `LICENSE`、`NOTICE` | 插件许可证、上游 MIT 许可证和商标声明 |
