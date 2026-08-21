# 이 설정들이 동작하려면 필요한 것 전부.
#   brew bundle --file ~/dotfiles/Brewfile

tap "laishulu/homebrew" # macism

# ── bin/setup · bin/sync 가 의존 ───────────────────────
# 시스템 python(CLT 3.9, EOL)을 쓰지 않는다. 두 기기가 같은 버전을 쓰고
# pip 패키지를 마음대로 쓰려면 brew python 이어야 한다.
brew "python"

# ── 셸 ────────────────────────────────────────────────
# 없으면 zsh/zshrc 가 매 셸마다 에러를 뱉는다(가드가 있어 치명적이진 않으나
# 플러그인도 프롬프트도 안 뜬다). 플러그인 자체는 antidote 가 첫 실행 때
# ~/.zsh/plugins 로 클론한다 — brew 로 설치하지 않는다.
brew "antidote"  # 플러그인 관리 (zsh/zsh_plugins.txt)
brew "gh"        # zshrc 가 HOMEBREW_GITHUB_API_TOKEN 을 여기서 얻는다(없으면 빈 값)
brew "zoxide"    # 디렉터리 점프(z · zi). rupa/z 를 대체 — 그쪽은 2023-12 릴리스가 마지막

# ── 에디터 ─────────────────────────────────────────────
brew "neovim" # 0.12+ 필수 (vim.pack · autocomplete · treesitter 동봉 파서)

# ── LSP · 포매터 (mason.nvim 대신 brew 로 일원화) ──────
brew "lua-language-server"
brew "markdown-oxide" # 마크다운 PKM — [[링크]] · 백링크 · 데일리 노트
brew "stylua"
brew "prettier"

# ── fzf-lua 백엔드 ────────────────────────────────────
brew "fzf"
brew "ripgrep" # nvim 0.12 의 grepprg 기본값이기도 하다
brew "fd"
brew "bat" # 미리보기 문법 강조

# ── 셸 별칭이 의존 ────────────────────────────────────
brew "eza" # zshrc 의 ls/ll/la/lt/tree — 없으면 별칭을 건너뛴다(ls 는 살아있음)

# ── git ───────────────────────────────────────────────
# git/shared 가 core.pager 로 지정한다. 없으면 git 이 페이저를 못 찾아
# diff·log 출력이 깨진다 — 셸 별칭과 달리 폴백이 없으니 반드시 설치.
brew "git-delta"

# ── Swift / ObjC ──────────────────────────────────────
# nvim/lsp/sourcekit.lua 가 buildServer.json 을 요구한다(Xcode 프로젝트에서
# sourcekit-lsp 가 인덱스를 찾는 유일한 경로). 이 툴이 그 파일을 만든다 —
# 없으면 LSP 가 붙긴 하나 "run xcode-build-server config" 경고만 낸다.
# sourcekit-lsp·swift-format 자체는 Xcode 툴체인 번들이라 설치할 게 없다.
brew "xcode-build-server"

# ── 터미널 멀티플렉서 ─────────────────────────────────
# 설정이 깨지진 않지만, zsh/rc.zsh:81-83 이 Ghostty 셸 통합을 다시 source
# 하는 이유가 바로 이것이다 — Ghostty 는 직접 띄운 셸에만 주입해서 zellij
# 팬 안에서는 프롬프트 마킹과 작업 디렉터리 상속이 죽는다.
brew "zellij"

# ── macOS 전용 ────────────────────────────────────────
# 한글로 쓰다 <Esc> 를 눌러도 입력기가 한글에 남는 문제를 푼다.
# 없으면 nvim 설정이 조용히 비활성화되므로 Linux 에서도 안 깨진다.
brew "macism"

# ── 터미널 + 폰트 ─────────────────────────────────────
# 폰트가 없으면 ghostty/config 의 font-family 가 안 잡혀 글자가 깨진다.
cask "ghostty"
cask "font-jetbrains-mono-nerd-font" # 본문 + nvim 아이콘(nerd font)
cask "font-sarasa-gothic"            # 한글 (Sarasa Term K)
