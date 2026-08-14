-- sourcekit-lsp — Swift / Objective-C
--
-- Xcode 프로젝트(.xcworkspace/.xcodeproj)는 sourcekit-lsp 가 직접 읽지 못한다.
-- 빌드 정보를 넘겨줄 BSP 서버가 필요하고, 그 접점이 프로젝트 루트의
-- `buildServer.json` 이다. 보통 xcode-build-server 가 만든다:
--
--   brew install xcode-build-server
--   xcode-build-server config -workspace <이름>.xcworkspace -scheme <스킴>
--
-- 이 파일이 없으면 sourcekit-lsp 는 fallback 컴파일 인자로 돌아서 import 가
-- 전부 깨지고 같은 파일 안 심볼 말고는 정의로 점프하지 못한다.
--
-- SwiftPM 만 쓰는 저장소(Package.swift)는 BSP 없이도 동작한다.
--
-- ★ Xcode 나 Swift 툴체인이 없는 기기에서는 조용히 비활성된다.
--   Neovim 은 cmd 가 존재하지 않는 LSP 설정을 알림 없이 건너뛴다
--   (실측: 클라이언트 0개, 알림 0건, 버퍼를 더 열어도 누적 없음).
--   macism 과 같은 방식이라 Linux 에서도 설정이 깨지지 않는다.

local warned = {}
local toplevels = {}
local seed_sources = {}

-- xcode-build-server 가 이 루트에 대해 쓰는 캐시 디렉터리.
-- 서버의 규칙과 **글자 그대로 같아야** 한다 (server.py build_initialize):
--   ~/Library/Caches/xcode-build-server/<root_path 의 "/" 를 "-" 로 치환>
local function cache_dir(root)
  return vim.fn.expand("~/Library/Caches/xcode-build-server/") .. (root:gsub("/", "-"))
end

-- 저장소 루트를 git 에게 묻고, 그 위로는 올라가지 않는다.
--
-- `vim.fs.root(path, "buildServer.json")` 을 쓰면 안 된다. 워크트리를 체크아웃
-- **안쪽**에 두는 배치(예: `<repo>/.worktrees/<name>`)에서 위로 걸어 올라가다
-- 부모 체크아웃의 buildServer.json 을 잡아버린다. 그러면 LSP 가 조용히 엉뚱한
-- 트리에 붙어서, 워크트리 파일을 편집하는데 정의는 다른 체크아웃으로 점프한다.
-- 체크아웃 루트는 "여기서 멈춘다"는 **경계**다. 프로젝트 루트가 아니다(아래 project_root).
local function git_toplevel(path)
  local dir = vim.fs.dirname(path)
  if toplevels[dir] ~= nil then
    return toplevels[dir] or nil
  end
  local r = vim.system({ "git", "-C", dir, "rev-parse", "--show-toplevel" }, { text = true }):wait()
  local top = (r.code == 0) and vim.trim(r.stdout) or false
  toplevels[dir] = top
  return top or nil
end

-- 프로젝트 루트를 파일에서 위로 올라가며 찾되, 체크아웃 루트에서 멈춘다.
--
-- ★ "체크아웃 루트 = 프로젝트 루트" 로 두면 **모노레포에서 전부 깨진다.**
--   저장소 하나에 패키지를 여러 개 담는 배치(`<repo>/production/<앱>/Package.swift`)
--   에서는 git 루트에 Package.swift 도 buildServer.json 도 없다. 그래서 모든 Swift
--   파일이 "설정 안 됨" 으로 떨어져 fallback 인자로 돌고, import 가 깨진 채 경고만 뜬다.
--   (실측 2026-08-11: 한 저장소 안의 SwiftPM 패키지 8개가 전부 git 루트로 붙었다.)
--
--   그렇다고 `vim.fs.root` 로 무한정 올라가면 위 git_toplevel 주석의 워크트리 함정에
--   걸린다. 그래서 **아래로는 찾되 위로는 경계에서 멈춘다** — 둘 다 만족한다.
--
-- ★★ 그리고 **buildServer.json 이 Package.swift 를 이긴다. 깊이와 무관하게.**
--   "가장 가까운 것이 이긴다" 로 두면, 루트에 buildServer.json 이 있고 그 아래에
--   Xcode 가 함께 빌드하는 SwiftPM 패키지를 둔 배치에서 **코드의 대부분이 죽는다.**
--   중첩 패키지가 SwiftPM 모드로 붙는데, iOS 전용 패키지는 호스트에서 컴파일
--   플래그가 나오지 않아 hover/정의가 전부 nil 이 된다. 경고조차 안 뜬다 —
--   Package.swift 를 찾은 시점에 "설정됨" 으로 판정되기 때문이다.
--   (실측 2026-08-14: 한 저장소의 Swift 파일 92% 가 이렇게 조용히 죽어 있었다.
--    같은 파일에 루트만 buildServer.json 쪽으로 바꾸니 hover 가 6초 만에 나왔다.)
--
--   반대 방향은 안전하다. 패키지가 여러 개인 모노레포에는 buildServer.json 이
--   애초에 없으므로 이 규칙에 걸리지 않고 각자 Package.swift 로 붙는다.
--
--   남는 구멍 하나: Xcode 가 **빌드하지 않는** 독립 SwiftPM 패키지를 Xcode 저장소
--   안에 둔 경우, 그 패키지도 BSP 루트로 붙어 플래그가 없다. 그때는 그 패키지
--   디렉터리를 따로 체크아웃하거나 패키지에 buildServer.json 을 두면 된다.
local function project_root(path, top)
  local function has(dir, file)
    return vim.fn.filereadable(dir .. "/" .. file) == 1
  end
  local function has_glob(dir, pat)
    return #vim.fn.glob(dir .. "/" .. pat, true, true) > 0
  end

  local dir = vim.fs.dirname(path)
  local bsp -- buildServer.json 을 본 가장 가까운 디렉터리 (최우선)
  local pkg -- Package.swift 를 본 가장 가까운 디렉터리
  local xcode -- .xcworkspace/.xcodeproj 를 본 가장 가까운 디렉터리 (fallback)

  while dir do
    if not bsp and has(dir, "buildServer.json") then
      bsp = dir
    end
    if not pkg and has(dir, "Package.swift") then
      pkg = dir
    end
    if not xcode and (has_glob(dir, "*.xcworkspace") or has_glob(dir, "*.xcodeproj")) then
      xcode = dir
    end

    if dir == top then
      break -- 경계. 체크아웃 밖으로는 절대 안 나간다.
    end
    local parent = vim.fs.dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end

  if bsp then
    return bsp, true
  end
  if pkg then
    return pkg, true
  end

  -- 설정 전 Xcode 프로젝트면 그 디렉터리를 준다 — 경고가 `xcode-build-server config` 를
  -- 실제로 돌려야 할 곳을 가리키게 된다(모노레포에서는 git 루트가 아니다).
  return xcode or top, false
end

-- buildServer.json 이 **이 트리를 가리키는지** 확인한다.
--
-- 워크트리를 새로 만들 때 buildServer.json 을 복사해 오면(또는 워크트리 생성
-- 스크립트가 untracked 파일을 같이 옮기면) 파일은 존재하니까 위의 "없음" 경고는
-- 안 뜨는데, 안에 적힌 workspace/build_root 는 **원래 체크아웃의 절대경로**다.
-- 그러면 LSP 가 조용히 다른 트리의 빌드 정보로 동작한다. 파일 유무로는 못 잡는다.
local checked = {}
local function check_points_here(root)
  if checked[root] then
    return
  end
  checked[root] = true

  local ok, lines = pcall(vim.fn.readfile, root .. "/buildServer.json")
  if not ok then
    return
  end
  local decoded, cfg = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not decoded or type(cfg) ~= "table" then
    return
  end
  local ws = cfg.workspace
  if type(ws) == "string" and ws ~= "" and ws:sub(1, #root + 1) ~= root .. "/" then
    vim.notify(
      ("sourcekit: buildServer.json in %s points at another checkout (%s) — regenerate it here"):format(root, ws),
      vim.log.levels.ERROR
    )
  end
end

-- 이 루트의 컴파일 플래그가 **다른 체크아웃에서 이식된 것**인지 알려준다.
--
-- 워크트리마다 풀빌드를 돌리는 건 현실적이지 않아서(수십 분 + DerivedData 수 GB),
-- 메인 체크아웃의 플래그 캐시를 경로 치환해 이식하는 방식을 쓴다. 이식한 쪽이
-- 캐시 디렉터리에 원본 체크아웃 경로를 `seed-source` 로 남기고, 아래 remap 이 읽는다.
local function seed_source(root)
  if seed_sources[root] == nil then
    local ok, lines = pcall(vim.fn.readfile, cache_dir(root) .. "/seed-source")
    local src = (ok and lines[1]) and vim.trim(lines[1]) or ""
    seed_sources[root] = (src ~= "" and src ~= root) and src or false
  end
  return seed_sources[root] or nil
end

-- ★ 이식된 플래그의 유일한 대가: **크로스모듈 정의가 원본 체크아웃으로 샌다.**
--
-- 모듈 내부 점프는 정상이다(이식할 때 모듈의 소스 목록을 이 트리 경로로 다시 썼다).
-- 하지만 다른 모듈의 심볼은 원본 DerivedData 의 .swiftmodule / 인덱스 스토어에서
-- 해석되므로 결과 위치가 원본 체크아웃 파일을 가리킨다. 그대로 두면 워크트리를
-- 편집하는 줄 알고 **원본을 편집하게 된다.** 조용해서 더 나쁘다.
--   (실측 2026-08-14: 모듈 내부 DeviceCapacityChecker → 워크트리 ✅ /
--    크로스모듈 KMServerConfig → 메인 체크아웃 ❌)
--
-- 같은 저장소이므로 상대경로는 그대로다. 이 트리에 같은 파일이 있으면 되돌린다.
-- 없으면(원본에만 있는 파일) 원본을 그대로 두되 한 번은 알린다.
local remap_warned = {}
local function remap_path(p, src, root)
  if p:sub(1, #src + 1) ~= src .. "/" then
    return nil
  end
  local cand = root .. p:sub(#src + 1)
  if vim.fn.filereadable(cand) == 1 then
    return cand
  end
  if not remap_warned[p] then
    remap_warned[p] = true
    vim.notify(
      ("sourcekit: %s exists only in %s (flags seeded from there)"):format(vim.fs.basename(p), src),
      vim.log.levels.WARN
    )
  end
  return nil
end

local function remap_locations(result, src, root)
  local function fix(loc)
    for _, key in ipairs({ "uri", "targetUri" }) do
      local uri = loc[key]
      if type(uri) == "string" and uri:sub(1, 7) == "file://" then
        local mapped = remap_path(vim.uri_to_fname(uri), src, root)
        if mapped then
          loc[key] = vim.uri_from_fname(mapped)
        end
      end
    end
  end

  if type(result) ~= "table" then
    return result
  end
  if result.uri or result.targetUri then
    fix(result) -- 단일 Location
  else
    for _, loc in ipairs(result) do
      if type(loc) == "table" then
        fix(loc)
      end
    end
  end
  return result
end

local REMAPPED = {
  ["textDocument/definition"] = true,
  ["textDocument/declaration"] = true,
  ["textDocument/typeDefinition"] = true,
  ["textDocument/implementation"] = true,
  ["textDocument/references"] = true,
}

-- ★ 후킹 지점이 `handlers` 가 아니라 **client.request** 인 이유.
--   `vim.lsp.buf.definition` 은 `handlers` 테이블을 아예 보지 않는다. get_locations
--   (runtime/lua/vim/lsp/buf.lua)가 `buf_request_all` 에 콜백을 직접 넘기기 때문에
--   설정의 handlers 항목은 조용히 무시된다. 실측 2026-08-14: handlers 로 붙였을 때
--   리맵이 한 번도 실행되지 않았다.
--   client.request 를 감싸면 buf.definition, request_sync, 픽커 플러그인까지 전부
--   같은 경로로 지나가므로 한 곳에서 끝난다(Client:request_sync 도 self:request 호출).
local function wrap_request(client)
  local src = seed_source(client.root_dir or "")
  if not src then
    return -- 이식된 루트가 아니면 아무것도 하지 않는다
  end
  local root = client.root_dir
  local orig = client.request
  client.request = function(self, method, params, handler, bufnr)
    if REMAPPED[method] then
      local ok, resolved = pcall(function()
        return handler or self:_resolve_handler(method)
      end)
      local inner = ok and resolved or handler
      if inner then
        handler = function(err, result, ctx, config)
          return inner(err, remap_locations(result, src, root), ctx, config)
        end
      end
    end
    return orig(self, method, params, handler, bufnr)
  end
end

---@type vim.lsp.Config
return {
  -- xcrun 을 거치면 `xcode-select` 가 가리키는 툴체인을 따라간다. Xcode 를 여러
  -- 개 두고 전환하는 기기에서 중요하다. xcrun 이 없는 환경(Linux)에서는 툴체인이
  -- PATH 에 올려둔 바이너리를 직접 쓴다.
  cmd = vim.fn.executable("xcrun") == 1 and { "xcrun", "sourcekit-lsp" } or { "sourcekit-lsp" },

  filetypes = { "swift", "objc", "objcpp", "c", "cpp" },

  root_dir = function(bufnr, on_dir)
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == "" then
      return
    end

    local top = git_toplevel(name)
    if not top then
      return
    end

    local root, configured = project_root(name, top)
    if configured then
      check_points_here(root)
      return on_dir(root)
    end

    -- BSP 도 SwiftPM 도 없으면 fallback 인자로 돌아 import 가 전부 깨진다.
    -- 조용히 반쯤 동작하게 두지 말고 한 번은 알린다.
    if not warned[root] then
      warned[root] = true
      vim.notify(
        ("sourcekit: no buildServer.json in %s — run `xcode-build-server config`"):format(root),
        vim.log.levels.WARN
      )
    end
    return on_dir(root)
  end,

  -- cmd_cwd 는 **주지 않는다.** 예전에는 "xcode-build-server 가 에디터가 연 경로로
  -- 플래그 캐시를 키잉하므로 프로젝트 루트로 고정해야 한다"고 적혀 있었는데 틀렸다.
  -- 서버는 cwd 를 전혀 보지 않고 BSP `build/initialize` 의 **rootUri** 만 본다
  -- (server.py build_initialize: root_path = rootUri / cache_path = root_path 치환 /
  --  config_path = root_path/buildServer.json). rootUri 는 sourcekit-lsp 의 워크스페이스
  -- 루트, 즉 위 root_dir 이다.
  --   실측 2026-08-14: nvim 의 cwd 를 메인 체크아웃에 둔 채 워크트리 파일을 열어
  --   cwd 와 root 를 어긋나게 해도 hover 가 2초에 나왔다.
  -- 게다가 cmd_cwd 는 설정 로드 시점에 한 번 계산되는 **단일 값**이라, 한 세션에서
  -- 체크아웃을 여러 개 열면 어차피 대부분의 클라이언트와 어긋난다. 지우는 게 맞다.
  --
  -- 따라오는 귀결: buildServer.json 은 root_dir **바로 그 디렉터리**에 있어야 한다.
  -- 조상에 있으면 읽히지 않는다. 위 project_root 가 BSP 를 최우선으로 두는 이유다.

  on_init = wrap_request,

  -- 기본 get_language_id 는 Neovim 의 filetype 을 그대로 넘긴다. sourcekit-lsp 는
  -- LSP 표준 id 를 원한다.
  get_language_id = function(_, ft)
    return ({ objc = "objective-c", objcpp = "objective-cpp" })[ft] or ft
  end,
}
