#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
codex_home="${CODEX_HOME:-${HOME}/.codex_diy}"
bin_dir="${HOME}/.local/bin"
install_dir="${HOME}/.local/share/codex-cli"
codex_version="${CODEX_NPM_VERSION:-0.121.0}"
version_file="${install_dir}/.version"

mkdir -p "${codex_home}/rules" "${bin_dir}" "${install_dir}"

installed_version=""
if [[ -f "${version_file}" ]]; then
  installed_version="$(<"${version_file}")"
fi

if [[ "${installed_version}" != "${codex_version}" ]] || [[ ! -x "${install_dir}/node_modules/.bin/codex" ]]; then
  npm install \
    --prefix "${install_dir}" \
    --no-audit \
    --no-fund \
    "@openai/codex@${codex_version}"
  printf '%s\n' "${codex_version}" >"${version_file}"
fi

ln -sfn "${install_dir}/node_modules/.bin/codex" "${bin_dir}/codex"
ln -sfn "${repo_root}/.ide/codex-src" "${bin_dir}/codex-src"

config_path="${codex_home}/config.toml"
if [[ ! -f "${config_path}" ]] || [[ "${CODEX_CNB_RESET_CONFIG:-0}" == "1" ]]; then
  install -m 600 "${repo_root}/.ide/codex-config.toml" "${config_path}"
  printf "\n[projects.'%s']\ntrust_level = \"trusted\"\n" "${repo_root}" >>"${config_path}"
fi

if [[ -n "${CODEX_BASE_URL:-}" ]]; then
  if [[ "${CODEX_BASE_URL}" == *$'\n'* ]] || [[ "${CODEX_BASE_URL}" == *'"'* ]]; then
    printf 'CODEX_BASE_URL 不能包含换行或双引号。\n' >&2
    exit 1
  fi
  escaped_base_url="${CODEX_BASE_URL//\\/\\\\}"
  escaped_base_url="${escaped_base_url//&/\\&}"
  escaped_base_url="${escaped_base_url//|/\\|}"
  sed -i "s|^base_url = .*|base_url = \"${escaped_base_url}\"|" "${config_path}"
fi

install -m 600 "${repo_root}/.ide/default.rules" "${codex_home}/rules/default.rules"

append_shell_setting() {
  local file="$1"
  local line="$2"
  touch "${file}"
  grep -Fqx "${line}" "${file}" || printf '%s\n' "${line}" >>"${file}"
}

for shell_rc in "${HOME}/.profile" "${HOME}/.bashrc" "${HOME}/.zshrc"; do
  append_shell_setting "${shell_rc}" 'export CODEX_HOME="${CODEX_HOME:-$HOME/.codex_diy}"'
  append_shell_setting "${shell_rc}" 'export PATH="$HOME/.local/bin:$PATH"'
  append_shell_setting "${shell_rc}" 'export CODEX_UNSAFE_ALLOW_NO_SANDBOX="${CODEX_UNSAFE_ALLOW_NO_SANDBOX:-1}"'
done

export CODEX_HOME="${codex_home}"
export PATH="${bin_dir}:${PATH}"
export CODEX_UNSAFE_ALLOW_NO_SANDBOX="${CODEX_UNSAFE_ALLOW_NO_SANDBOX:-1}"

if [[ -z "${OPENAI_API_KEY:-}" ]]; then
  printf '提示：请在 CNB 个人设置的环境变量中添加 OPENAI_API_KEY，然后重启云原生开发环境。\n'
fi

active_base_url="$(sed -n 's/^base_url = "\(.*\)"/\1/p' "${config_path}" | head -n 1)"
if [[ "${active_base_url}" == http://* ]]; then
  printf '警告：当前 Codex 服务地址使用 HTTP，API 密钥会经过未加密连接；建议改用 HTTPS 地址。\n'
fi

printf 'Codex CNB 环境配置完成：'
"${bin_dir}/codex" --version
printf '源码运行命令：codex-src\n'
