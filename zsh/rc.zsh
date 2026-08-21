# ~/.zshrc — 대화형 셸 전용. 환경변수는 .zshenv, 로그인 1회성은 .zprofile.

# ── 플러그인 (antidote) ──────────────────────────────────────────────
# ANTIDOTE_HOME 기본값은 ~/Library/Caches — OS 캐시 정리에 날아가면
# 정적 번들만 남아 깨진 경로를 source 하므로 캐시 밖에 둔다.
# 가드 이유: 새 기기에서 `brew bundle` 전에 셸을 열면 이 줄이 매번
# 에러를 뱉는다. 없으면 조용히 건너뛰고 셸은 정상 동작한다.
# HOMEBREW_PREFIX 는 .zprofile 의 `brew shellenv` 가 넣는다(.zprofile 이
# .zshrc 보다 먼저 읽힌다). 경로를 박으면 Intel Mac(/usr/local)에서 가드에
# 걸려 *조용히* 플러그인만 안 뜬다 — 에러도 안 나서 알아채기 어렵다.
export ANTIDOTE_HOME=$HOME/.zsh/plugins
_antidote=${HOMEBREW_PREFIX:-/opt/homebrew}/opt/antidote/share/antidote/antidote.zsh
if [[ -r $_antidote ]]; then
  source $_antidote
  # 번들 목록은 저장소 파일을 직접 가리킨다 — ~/.zsh_plugins.txt 심링크가
  # 필요 없다. 생성물(정적 번들)은 기기별 경로를 담으므로 홈에 둔다.
  #
  # ★ 번들이 둘로 쪼개져 있다. 여기는 compinit **전**에 와야 하는 것만
  #   (fpath 만 건드리는 zsh-completions). 위젯을 감싸는 플러그인과 fzf-tab 은
  #   zsh_plugins_late.txt 이고 이 파일 맨 아래에서 로드한다.
  antidote load ${DOTFILES:-$HOME/dotfiles}/zsh/zsh_plugins.txt \
                ${ZDOTDIR:-$HOME}/.zsh_plugins.zsh
fi
unset _antidote

# ── completion ──────────────────────────────────────────────────────
# ~/.zsh 는 이 기기에 직접 떨군 completion 을 담는다(_swift · _hermes 등
# Xcode·RN 툴체인이 배포하는 것들). ANTIDOTE_HOME 도 그 아래 plugins/ 다.
# completions/ 는 앞으로 정리해 넣을 자리 — 없어도 fpath 는 조용히 무시한다.
fpath=(~/.zsh ~/.zsh/completions $fpath)

# compinit 전체 검사는 ~27ms 로 기동 최대 비용이다. 덤프가 24시간 넘게
# 묵었을 때만 전체 재생성하고, 평소엔 -C 로 검사를 건너뛴다.
# 새 completion 이 즉시 안 잡히면 `rm ~/.zcompdump && compinit`.
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # 대소문자 무시
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.cache/zsh/zcompcache

# ⚠ `menu select` 가 아니라 `menu no` 다. fzf-tab 이 모호한 접두어를 가로채려면
#   zsh 의 기본 완성 메뉴가 뜨면 안 된다(업스트림 요구사항). fzf-tab 을 빼면
#   이 줄을 `menu select` 로 되돌려야 화살표 선택이 살아난다.
zstyle ':completion:*' menu no
# 그룹 헤더. fzf-tab 이 이 형식을 읽어 후보를 묶어 보여준다.
zstyle ':completion:*:descriptions' format '[%d]'

# ── history ─────────────────────────────────────────────────────────
# /etc/zshrc 기본값(2000/1000)은 SAVEHIST < HISTSIZE 라 종료 시 절반이 버려진다.
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY EXTENDED_HISTORY HIST_IGNORE_ALL_DUPS \
       HIST_IGNORE_SPACE HIST_REDUCE_BLANKS HIST_VERIFY

# ── 셸 동작 ─────────────────────────────────────────────────────────
# /etc/zshrc 가 setopt BEEP 을 켜므로 NO_BEEP 은 명시적으로 꺼야 한다.
setopt AUTO_CD EXTENDED_GLOB INTERACTIVE_COMMENTS NO_BEEP

# ── alias ───────────────────────────────────────────────────────────
alias vim="nvim"
alias vi="nvim"
alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

# eza. ⚠ eza 의 -t 는 ls 와 달리 "시간 정렬"이 아니라 --time 필드 인자를
# 요구한다 — `ls -lt` 는 에러가 난다. 시간 정렬은 `ll --sort=newest` 로.
#
# ⚠ --git 을 붙이지 않는다. 예전 주석은 "실측 5.8ms / --git 포함 5.7ms" 라며
#   공짜라고 적고 있었는데, 지금 기준으로 틀렸다. 사내 모노레포(추적 11k,
#   워킹트리 1.4M 파일)에서 --git 342ms / 없이 13ms — 27배다. 표시할 항목이
#   5개뿐인 하위 디렉터리에서도 341ms 다. eza 가 항목 수와 무관하게 저장소
#   전체의 git 상태를 계산하기 때문이고, 프롬프트에서 starship 을 걷어낸 것과
#   원인이 같다. 변경 여부는 nvim 의 gitsigns 와 lazygit 이 이미 보여준다.
#
# --icons 는 반드시 =auto 로 쓴다. 인자 없는 --icons 는 always 와 같아서
# `ls | grep` 이나 스크립트로 글리프가 그대로 새어나간다. auto 는 tty 가
# 아니면 자동으로 끈다. 폰트는 Brewfile 의 nerd font cask 가 보장한다.
#
# lt·tree 별칭은 두지 않는다. lt 는 --sort=modified 가 ls -lt 와 정렬 방향이
# 반대였고, tree 는 --level=2 로 조용히 잘려서 "하위에 없다"로 오독된다.
# 둘 다 진짜 이름을 가리면서 동작만 다른 쪽이라 없는 편이 낫다.
if (( $+commands[eza] )); then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -l  --group-directories-first --icons=auto --time-style=long-iso'
  alias la='eza -la --group-directories-first --icons=auto --time-style=long-iso'
fi

# HOMEBREW_GITHUB_API_TOKEN 은 brew 만 읽는다(워크스페이스 전체 확인함).
# 매 셸에서 `gh auth token` 을 부르면 16.5ms 인데 대부분의 셸은 brew 를
# 쓰지 않으므로, 실제로 brew 를 부를 때 한 번만 채운다.
brew() {
  [[ -n $HOMEBREW_GITHUB_API_TOKEN ]] || \
    export HOMEBREW_GITHUB_API_TOKEN="$(command gh auth token 2>/dev/null)"
  command brew "$@"
}

# ── 터미널 통합 (Ghostty) ───────────────────────────────────────────
# Ghostty 는 자기가 "직접" 띄운 셸에만 이 통합을 자동 주입한다. zellij·tmux
# 팬이나 `exec zsh` 안에서는 안 걸려서 프롬프트 마킹(이전 프롬프트로 점프)과
# 새 split 의 작업 디렉터리 상속이 죽는다. 중복 초기화는 스크립트 자체가
# _ghostty_state 로 막으므로 직접 띄운 셸에서 다시 불러도 무해하다.
if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
  source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
fi

# ── 프롬프트 ────────────────────────────────────────────────────────
# 브랜치와 워크트리 여부만 보여준다. 외부 프로세스를 하나도 부르지 않는다.
#
# starship 을 쓰다 걷어냈다. 이유는 비용이다 — 사내 모노레포(추적 11k,
# 워킹트리 1.4M 파일)에서 프롬프트 한 번이 실측 271ms 였고, 그중 250ms 가
# git_status 하나였다. `git status` 자체가 그 저장소에서 270ms 다.
# starship 은 동기식이라 그동안 커서가 안 온다.
#
# 비싼 건 브랜치가 아니라 더티 상태다. 브랜치는 .git/HEAD 한 줄이고 zsh 는
# $(<파일) 로 fork 없이 읽는다 — 같은 저장소에서 0.17ms(약 1,600배).
# 더티 표시는 일부러 뺐다. 변경 여부는 nvim 의 gitsigns 와 lazygit 이
# 훨씬 잘 보여주고, 프롬프트에서 중복이다.
#
# ⚠ vcs_info(zsh 동봉)는 대안이 아니다. 내장이라 가벼울 것 같지만 내부에서
#   git 을 여러 번 fork 해서 실측 84ms — `git rev-parse` 단독(27ms)보다 느리다.
_git_prompt_precmd() {
  emulate -L zsh
  _GITPROMPT=''
  local dir=$PWD gitdir head name
  while [[ -n $dir ]]; do
    if [[ -d $dir/.git ]]; then gitdir=$dir/.git; break
    elif [[ -f $dir/.git ]]; then           # 워크트리는 .git 이 파일이다
      gitdir=${"$(<$dir/.git)"#gitdir: }; break
    fi
    [[ $dir == / ]] && break
    dir=${dir:h}
  done
  [[ -n $gitdir && -r $gitdir/HEAD ]] || return
  head=${"$(<$gitdir/HEAD)"}
  if [[ $head == ref:* ]]; then name=${head##*/}; else name="@${head[1,7]}"; fi
  [[ $gitdir == */worktrees/* ]] && name+=" ⑂"
  _GITPROMPT=" %F{magenta}${name}%f"
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _git_prompt_precmd
setopt PROMPT_SUBST
PROMPT='%F{cyan}%~%f${_GITPROMPT}
%F{green}❯%f '

# ── fzf ─────────────────────────────────────────────────────────────
# brew 의존이라 존재할 때만 부른다.

# tty 가 붙은 셸에서만. tty 없는 `zsh -i -c` 에서 fzf 가
# "can't change option: zle" 를 두 줄 뱉는 걸 막는다.
# (`-o zle` 로는 안 된다 — 그 셸에서도 zle 옵션 자체는 켜져 있다.)
if [[ -t 0 ]] && (( $+commands[fzf] )); then
  source <(fzf --zsh)              # Ctrl-R 퍼지 히스토리 · Ctrl-T · Alt-C
fi

# ── 디렉터리 점프 ───────────────────────────────────────────────────
# z <조각> 으로 자주 가는 디렉터리로 뛴다. zi 는 fzf 로 골라서 뛴다
# (그래서 위 fzf 블록보다 뒤에 온다).
#
# rupa/z 를 쓰다 옮겼다. 그쪽은 마지막 릴리스가 2023-12 로 사실상 멈췄고,
# 셸 스크립트라 매 chpwd 마다 서브셸을 띄웠다. zoxide 는 단일 바이너리다.
# 기존 rupa/z 기록 102개는 `zoxide import z < ~/.z` 로 한 번 옮겼다.
# (0.10 문법 주의 — 옛 문서의 `--from z ~/.z` 도, 경로를 인자로 주는 것도
#  통하지 않는다. 서브커맨드 + stdin 이다.)
#
# 다른 brew 의존과 같은 이유로 존재할 때만 부른다.
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

# ── 키 바인딩 ───────────────────────────────────────────────────────
# 위/아래 = 입력한 접두어로 히스토리 검색 (zsh 내장 위젯).
# 문장 중간 매칭은 fzf 의 Ctrl-R 이 담당하므로 별도 플러그인을 쓰지 않는다.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# ── 위젯을 감싸는 플러그인 (반드시 맨 끝) ───────────────────────────
# 순서가 곧 규약이다:
#   compinit → fzf-tab → autosuggestions → syntax-highlighting
#
# fzf-tab 은 compinit 이 만든 완성 시스템을 가로채므로 그 뒤여야 한다.
# 뒤의 둘은 ZLE 위젯을 감싸므로, 감쌀 대상이 전부 만들어진 뒤여야 한다 —
# 위 fzf 블록의 Ctrl-R/Ctrl-T 위젯과 아래 키 바인딩까지 포함해서.
# 그래서 이 로드가 파일의 마지막이다. syntax-highlighting 이 맨 끝인 것도
# 업스트림 요구사항이다.
#
# 예전에는 셋 다 파일 맨 위 한 번의 antidote load 로 들어갔다. compinit 보다
# 먼저였고 fzf 위젯보다도 먼저였다 — 권장 순서를 어긴 상태였고, 그대로
# fzf-tab 을 번들에 한 줄 추가했다면 *조용히* 동작하지 않았을 것이다.
if (( $+functions[antidote] )); then
  antidote load ${DOTFILES:-$HOME/dotfiles}/zsh/zsh_plugins_late.txt \
                ${ZDOTDIR:-$HOME}/.zsh_plugins_late.zsh
fi

# fzf-tab 미리보기. eza 가 없으면 미리보기 창만 비고 완성 자체는 동작한다.
(( $+commands[eza] )) && \
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons=always $realpath'
