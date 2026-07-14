# CNB Codex 开发环境

仓库根目录的 `.cnb.yml` 会启动 CNB WebIDE 和 Docker 服务，并执行
`.ide/setup-codex.sh`：

- 安装与仓库开发容器一致的 `@openai/codex` 版本。
- 使用 `~/.codex_diy` 保存 Codex 配置。
- 复用本机 `codex_diy` 的模型、服务地址、推理等级和规则。
- 将当前仓库标记为可信项目。
- 提供 `codex-src` 命令，用当前分支源码编译并运行 Codex。

## CNB 环境变量

先在私有密钥仓库中创建一个 YAML 文件，例如 `codex.yml`：

```yaml
OPENAI_API_KEY: <Codex 服务的 API 密钥>
```

然后打开 **个人设置 > 云原生开发 > 个人环境变量**，引用该密钥文件并限制为当前仓库：

```yaml
- imports: https://cnb.cool/<你的密钥仓库>/-/blob/main/codex.yml
  use_in_slugs:
    - ruchong/ruchong/trae/codex
```

还支持以下可选环境变量：

- `CODEX_BASE_URL`：覆盖配置中的默认服务地址。
- `CODEX_NPM_VERSION`：覆盖默认安装的 Codex CLI 版本。

密钥只通过 CNB 环境变量注入，不提交 `auth.json`。

## 常用命令

```bash
codex
codex-src
```

如果需要用仓库模板重置云端 Codex 配置：

```bash
CODEX_CNB_RESET_CONFIG=1 bash .ide/setup-codex.sh
```

默认服务地址沿用了本机配置中的 HTTP 地址。为避免 API 密钥通过未加密连接传输，
建议在 CNB 中将 `CODEX_BASE_URL` 设置为 HTTPS 地址。
