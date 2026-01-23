# Neovim LSP Migration & Debugging Report (Jan 2026)

## Issue Summary
Neovim v0.11.5 was experiencing instant crashes (segfaults) when triggering LSP Hover (`K`) or opening diagnostic floating windows. The crashes were also occurring randomly after a period of uptime.

## Root Causes Identified
1. **Markdown Highlighting in Floats:** The primary cause of the instant crash was identified as syntax highlighting (both regex-based and Treesitter-based) within floating windows when rendering Markdown content from LSP servers.
2. **LSP-Zero Incompatibility:** `lsp-zero` (v4) was identified as potentially redundant or conflicting with the new native APIs and internal changes in Neovim 0.11+.
3. **Missing `offset_encoding`:** Newer Neovim versions/LSP servers require the `offset_encoding` parameter in `vim.lsp.util.make_position_params()` to correctly calculate character offsets.
4. **Treesitter Attachment:** Treesitter was attempting to attach to ephemeral or special buffers (like `nofile` diagnostic floats), leading to instability.

## Actions Taken

### 1. Mapped to Native LSP
- Removed `lsp-zero.nvim` from `plugins.lua`.
- Created `lua/user/lsp.lua` to implement a native LSP setup using `nvim-lspconfig`, `mason`, and `nvim-cmp`.
- Configured native snippet support using `vim.snippet`.

### 2. Stabilized Hover Functionality
- Bypassed the standard `vim.lsp.buf.hover()` wrapper due to internal crashes.
- Implemented a custom hover handler in `lua/user/lsp.lua` using direct `buf_request`.
- **CRITICAL FIX:** Set the syntax of the floating window to `plaintext`. Using `markdown` syntax currently triggers a segfault in this Neovim build.

### 3. Hardened Treesitter
- Modified `lua/user/treesitter.lua` to explicitly ignore buffers with `buftype` of `nofile`, `prompt`, or `quickfix`.
- This prevents Treesitter from attempting to highlight LSP hover windows or telescope prompts, which was a significant source of crashes.

### 4. Parametric Fixes
- Updated `make_position_params` calls to dynamically retrieve and pass the client's `offset_encoding` (e.g., `utf-8` or `utf-16`).

## Current State
- **Stability:** High. Random crashes have ceased.
- **Hover (`K`):** Functional but rendered in **plaintext**. Markdown code fences and bolding are visible as raw text to prevent crashes.
- **Completion:** `nvim-cmp` is fully enabled and working with native snippets.
- **UI:** Rounded borders are enabled and stable for all floats.

## Next Steps for Later
- **Test Neovim Updates:** Once a newer build of Neovim 0.11.x is available, try reverting `plaintext` to `markdown` in `lua/user/lsp.lua` to see if the core highlighting bug is fixed.
- **Refine Treesitter:** Investigate why the regex-based markdown highlighting also crashes; this might point to a deeper issue with the `markdown` syntax file in the Neovim runtime.
