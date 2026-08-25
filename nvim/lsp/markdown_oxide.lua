-- markdown-oxide — PKM 마크다운 언어 서버
-- https://github.com/Feel-ix-343/markdown-oxide
--
-- 노트 기능을 플러그인이 아니라 LSP 로 제공한다:
--   [[위키링크]] 완성 · 백링크(references) · 태그 · 헤딩/블록 참조
--   데일리 노트 · 미해결 링크 진단
--
-- ★ 경로를 설정에 박지 않는다. root_markers 로 버퍼마다 노트 루트를 찾으므로
--   ~/notes 와 Obsidian 볼트가 각각 독립된 노트 저장소로 동시에 동작한다.
--   (~/notes/.moxide.toml · 볼트/.obsidian)

---@param client vim.lsp.Client
---@param bufnr integer
---@param cmd string
local function jump(client, bufnr, cmd)
  return client:exec_cmd({
    title = ("Markdown-Oxide-%s"):format(cmd),
    command = "jump",
    arguments = { cmd },
  }, { bufnr = bufnr })
end

---@type vim.lsp.Config
return {
  cmd = { "markdown-oxide" },
  filetypes = { "markdown" },
  -- ★ `.git` 을 일부러 뺐다.
  -- notes/ 가 ~/workspace 저장소 안에 있어서 `.git` 을 두면 워크스페이스 전체
  -- 마크다운 716개(production 681 · toolbox 30)가 인덱싱되고, 백링크와
  -- [[링크]] 완성 후보에 프로젝트 문서가 전부 섞여 들어온다.
  -- 노트 저장소를 명시한 곳에서만 서버를 띄운다.
  root_markers = { ".moxide.toml", ".obsidian" },

  -- root_markers 만으로는 위 의도가 성립하지 않는다. 마커를 못 찾으면 Neovim 은
  -- 서버를 안 띄우는 게 아니라 root_dir = nil 인 단일 파일 모드로 그냥 띄운다.
  -- 실측(2026-08-11): 노트 저장소 밖의 마크다운을 열면 .moxide.toml/.obsidian
  -- 탐색은 둘 다 nil 인데도 markdown_oxide 가 root_dir=nil 로 부착됐다.
  -- 이 플래그가 있어야 "노트 저장소에서만 뜬다"가 실제가 된다.
  workspace_required = true,

  on_attach = function(client, bufnr)
    -- :LspToday / :LspTomorrow / :LspYesterday
    for _, cmd in ipairs({ "today", "tomorrow", "yesterday" }) do
      local name = "Lsp" .. cmd:gsub("^%l", string.upper)
      vim.api.nvim_buf_create_user_command(bufnr, name, function()
        jump(client, bufnr, cmd)
      end, { desc = ("%s 데일리 노트 열기"):format(cmd) })
    end

    -- ★ :Daily — 서버의 jump 는 위 3개가 아니라 **임의 날짜 문자열**을 받는다
    -- (fuzzydate). 위 세 명령은 그 특수 케이스일 뿐이라 여기서 열어 준다.
    --   :Daily                :Daily two days ago    :Daily next monday
    --   :Daily last friday    :Daily +7 / -7         :Daily prev / next
    -- 셸에서는 `zd` (dotfiles/zsh/rc.zsh) — cwd 를 볼트로 고정해서 부른다.
    vim.api.nvim_buf_create_user_command(bufnr, "Daily", function(opts)
      jump(client, bufnr, opts.args ~= "" and opts.args or "today")
    end, { nargs = "*", desc = "데일리 노트 — 자연어 날짜 (:Daily next monday)" })
  end,
}
