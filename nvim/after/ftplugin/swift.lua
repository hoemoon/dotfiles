-- Swift 편집 설정.
--
-- `after/` 인 이유는 markdown 쪽과 같다 — Neovim 런타임의 ftplugin 이 나중에
-- 덮어쓰지 못하게 한다.
--
-- ⚠ Neovim 은 `syntax/swift.vim`(정규식)은 동봉하지만 `indent/swift.vim` 은
--   **동봉하지 않는다.** 즉 Swift 들여쓰기는 'smartindent' 수준이 전부이고,
--   SwiftUI 의 result-builder 체인이나 trailing closure 에서는 어긋난다.
--   `==` 로 손보는 걸 각오할 것. (treesitter swift 파서를 넣어도 indent 는
--   여전히 나쁘다 — 하이라이팅만 좋아진다)

-- 전역은 2칸이지만 Swift 관례는 4칸
vim.bo.expandtab = true
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4
vim.bo.tabstop = 4

vim.bo.commentstring = "// %s"

-- 산문용으로 켜둔 conceal 은 코드에서 글자를 지워버릴 수 있다.
vim.wo.conceallevel = 0

-- 접기 폴백. Swift 접기는 sourcekit-lsp 의 foldingRange 에 얹혀 있는데
-- (동봉 treesitter 파서에 swift 가 없다), buildServer.json/Package.swift 를
-- 못 찾으면 서버가 아예 안 붙어 fold 가 0 이 된다. 그때는 들여쓰기로 접는다.
-- LSP 가 붙으면 lsp.lua 의 LspAttach 가 이 창-버퍼의 foldexpr 을 덮어쓴다.
vim.wo.foldmethod = "indent"
