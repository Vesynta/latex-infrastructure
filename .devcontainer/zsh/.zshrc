# shellcheck shell=bash
# Project-managed Zsh profile for the DevContainer.
# Optimised for human terminals (Cursor/VS Code) and agent/programmatic shells.

# Non-interactive shells: keep quiet.
[[ $- != *i* ]] && return

: "${LANG:=C.UTF-8}"
: "${LC_ALL:=C.UTF-8}"
export LANG LC_ALL

path_prepend() {
	case ":${PATH}:" in
		*:"$1":*) ;;
		*) PATH="$1${PATH:+:$PATH}" ;;
	esac
}
[[ -d /opt/venv/bin ]] && path_prepend /opt/venv/bin
[[ -d /mise/shims ]] && path_prepend /mise/shims
[[ -d /usr/local/bin ]] && path_prepend /usr/local/bin
[[ -d "${HOME}/.local/bin" ]] && path_prepend "${HOME}/.local/bin"
export PATH
unset -f path_prepend

# Persist history across DevContainer rebuilds (bind-mounted workspace).
if [[ -z "${HISTFILE:-}" ]]; then
	if [[ -d /app/.persist ]]; then
		HISTFILE=/app/.persist/zsh_history
	elif [[ -d /code/.persist ]]; then
		HISTFILE=/code/.persist/zsh_history
	elif [[ -d /repo/.persist ]]; then
		HISTFILE=/repo/.persist/zsh_history
	else
		HISTFILE="${HOME}/.zsh_history"
	fi
fi
export HISTFILE
HISTSIZE=200000
SAVEHIST=200000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END

alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias gst='git status -sb'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gl='git pull --ff-only'
alias gp='git push'
alias m='make'

# Human terminals: full OMZ. Agent / extension-spawned shells: lean prompt.
_DEV_FANCY=1
[[ -n "${CURSOR_AGENT:-}" || -n "${COPILOT_AGENT:-}" ]] && _DEV_FANCY=0
[[ -n "${CLAUDECODE:-}" || -n "${CLAUDE_CODE:-}" || -n "${CLAUDE_CODE_CHILD_SESSION:-}" ]] && _DEV_FANCY=0
[[ -n "${AI_AGENT:-}" || -n "${GEMINI_CLI:-}" || -n "${CODEX_SANDBOX:-}" ]] && _DEV_FANCY=0
[[ "${TERM_PROGRAM:-}" == "vscode" && -z "${VSCODE_USER_TERMINAL:-}" ]] && _DEV_FANCY=0

if [[ $_DEV_FANCY -eq 1 ]]; then
	export ZSH="${HOME}/.oh-my-zsh"
	zstyle ':omz:update' mode disabled
	DISABLE_AUTO_TITLE="true"
	HIST_STAMPS="yyyy-mm-dd"
	ZSH_THEME="amuse"
	plugins=(
		git gh docker docker-compose
		python safe-paste zsh-interactive-cd
		zsh-autosuggestions zsh-syntax-highlighting
	)
	# shellcheck disable=SC1091
	[[ -r "${ZSH}/oh-my-zsh.sh" ]] && source "${ZSH}/oh-my-zsh.sh"
else
	PROMPT='%n@%m %1~ %# '
fi

if [[ "${TERM_PROGRAM:-}" == "vscode" && -z "${VSCODE_SHELL_INTEGRATION:-}" ]]; then
	_vsc_si=""
	for _vsc_root in "${HOME}/.cursor-server/bin" "${HOME}/.vscode-server/bin"; do
		[[ -d "${_vsc_root}" ]] || continue
		# shellcheck disable=SC1009,SC1036,SC1072,SC1073
		_vsc_si="$(print -r -- ${_vsc_root}/*/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-rc.zsh(N.om[1]))"
		[[ -n "${_vsc_si}" ]] && break
	done
	if [[ -z "${_vsc_si}" ]]; then
		if (( $+commands[cursor] )); then
			_vsc_si="$(cursor --locate-shell-integration-path zsh 2>/dev/null)" || true
		elif (( $+commands[code] )); then
			_vsc_si="$(code --locate-shell-integration-path zsh 2>/dev/null)" || true
		fi
	fi
	# shellcheck disable=SC1090
	[[ -n "${_vsc_si}" && -r "${_vsc_si}" ]] && . "${_vsc_si}"
	unset _vsc_si _vsc_root
fi
