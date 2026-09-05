# RX 6750 XT local AI setup record

Last updated: 2026-08-19

This file records measured results from implementing `AGENTS.md`. Values marked
pending have not been inferred from model size or configured limits.

## Host and Vulkan

| Item | Measured value |
| --- | --- |
| NixOS | 26.05.20260811.70cc455 (Yarara) |
| Kernel | 6.12.103 |
| CPU | AMD Ryzen 7 5700X, 8 cores / 16 threads |
| RAM | 46.97 GiB |
| GPU | AMD Radeon RX 6750 XT (RADV NAVI22) |
| Kernel driver | amdgpu |
| Vulkan driver | Mesa RADV (`radv`) |
| Mesa | 26.1.5 |
| Vulkan loader | 1.4.341 |
| Vulkan device API | 1.4.354 |
| Vulkan device-local heap | 11.75 GiB |
| Physical VRAM reported by sysfs | 11.984 GiB |
| `vkcube` | Ran for a five-second Wayland validation window |
| `nvtop` | 3.3.2 |
| `clinfo` | 3.0.25.02.14; no OpenCL platform listed (not required for Vulkan) |

## Reproducible configuration

The system configuration adds `vulkan-tools`, `mesa-demos`, `clinfo`,
`nvtopPackages.amd`, and `appimage-run`. The resulting NixOS closure builds and
`nix flake check ./system --no-build` passes. The user successfully activated
the change with `sudo nixos-rebuild test --flake ./system#yejashi`; the tested
closure is
`/nix/store/zfdh1pgdf5d7nmfq7k0g7f2ykhffm2ca-nixos-system-yejashi-26.05.20260811.70cc455`.

Home Manager provides:

- `lm-studio`, a wrapper that removes the IDE's `ELECTRON_RUN_AS_NODE` variable
  and launches the pinned AppImage through `appimage-run`;
- `lms`, a wrapper for LM Studio's installed CLI (the app cannot edit the
  Home-Manager-owned `.bashrc` symlink itself);
- an LM Studio desktop entry;
- OpenCode 1.15.10 from the pinned nixpkgs revision.

Home Manager activation completed successfully.

## LM Studio

| Item | Value |
| --- | --- |
| Version | 0.4.21 build 2 |
| File | `/home/yejashi/HDD/AI/apps/LM-Studio-0.4.21-2-x64.AppImage` |
| Official URL | `https://lmstudio.ai/download/latest/linux/x64?format=AppImage` |
| SHA-512 | `9ae62759864eeaf0bdafbe98a9b70541e81f902c62e3189449e49f4b69a1c7709561bdbd80193f9d19cd39436f6773c3ba54b8ad7382e8f5f73298c1fd6bb7d6` |
| Selected runtime | `llama.cpp-linux-x86_64-vulkan-avx2@2.28.2` |
| Surveyed accelerator | RX 6750 XT, Vulkan, discrete, 12.00 GiB |
| API | `http://127.0.0.1:1234/v1` |
| `/v1/models` | Verified successfully; server must be restarted after closing the GUI |

The first launch initially exited because VS Code exported
`ELECTRON_RUN_AS_NODE=1`. Removing that variable fixed the launch. A bundled
Python Tix file emitted a `TabError` during optional post-install bytecode
compilation; Vulkan runtime selection and LM Studio startup still completed.
LM Studio's attempt to add its CLI to `.bashrc` was denied because Home Manager
owns that file as an immutable symlink; the declarative `lms` wrapper replaces
that imperative setup step.

## Memory baselines

| State | VRAM used | VRAM free |
| --- | ---: | ---: |
| GNOME desktop before LM Studio | 3.372 GiB | 8.612 GiB |
| GNOME + LM Studio, no LLM loaded | 3.413 GiB | 8.571 GiB |

Major applications open included GNOME Wayland, VS Code/Codex, and the normal
desktop session. The LM Studio idle delta observed in this run was about
0.041 GiB.

## OpenCode harness

`opencode.json` defines the `lmstudio` OpenAI-compatible provider at the local
API endpoint. Its baseline repository-comprehension policy allows reading,
globbing, searching, and LSP use while denying edits, subagents, external
directories, and web access. Shell commands require approval except for a
small read-only Git/search allowlist. `opencode debug config` validates the
configuration.

`tools/local-ai-benchmark.py` drives LM Studio's native streaming chat API and
records actual input/output token counts, the elapsed interval between native
prompt-processing start/end events, generation throughput, average whole-system
CPU use, and 100 ms samples of VRAM and system RAM. This prevents a configured
context limit from being reported as a validated context limit.

## Qwen filename correction

The original Qwen Q5_K_M and Q6_K URLs in `AGENTS.md` returned HTTP 404 at
upstream repository commit
`182be2fd6c7bc44887d88a91cb03ff009cc9f549`.

The current repository names include an additional `Qwen_` prefix:

- documented: `Qwen3.5-9B-Q5_K_M.gguf`
- upstream: `Qwen_Qwen3.5-9B-Q5_K_M.gguf`
- documented: `Qwen3.5-9B-Q6_K.gguf`
- upstream: `Qwen_Qwen3.5-9B-Q6_K.gguf`

The user explicitly accepted this upstream filename correction, and
`AGENTS.md` now points at the current artifacts.

The corrected Q5_K_M artifact was verified before download:

| Item | Value |
| --- | --- |
| Repository commit | `182be2fd6c7bc44887d88a91cb03ff009cc9f549` |
| Exact size | 7,111,487,520 bytes |
| Expected SHA-256 | `a686d88ec1e6881f9bf161526826cd6d6874b7f0e80e0f79acf6144a132c5d7e` |

The listed Gemma Q4_K_M, Gemma Q4_K_S, and Devstral IQ3_M URLs were checked and
still resolve successfully.

## Qwen3.5 9B Q5_K_M

| Item | Measured value |
| --- | --- |
| File | `/home/yejashi/HDD/AI/models/Qwen_Qwen3.5-9B-Q5_K_M.gguf` |
| Size | 7,111,487,520 bytes |
| SHA-256 | `a686d88ec1e6881f9bf161526826cd6d6874b7f0e80e0f79acf6144a132c5d7e` |
| LM Studio key / instance | `qwen_qwen3.5-9b` / `qwen3.5-9b-q5-k-m` |
| Quantization | Q5_K_M, 5 bits/weight reported by LM Studio |
| GPU offload | `max`; strict VRAM cap enabled |
| Flash Attention | enabled |
| K/V cache | Q8_0 / Q8_0, GPU-resident |
| Eval batch / parallel slots | 128 / 1 |
| Speculation | MTP off, simple draft off, no draft model |
| Post-load VRAM (16K) | 9.463 GiB used, about 2.52 GiB free |
| Warm-cache exact-profile load | 3.184 seconds |
| Cold-ish CLI no-MTP load | 11.35 seconds |

LM Studio's SDK initially enabled Qwen's embedded MTP draft by default. The
effective v1 model configuration exposed this, so that probe was discarded.
`tools/load-lmstudio-profile.py` adds the two current server keys missing from
SDK 1.5.0's typed schema and loads the complete profile atomically. The v1 API
then independently confirmed MTP off, one parallel slot, context, batch, Flash
Attention, and GPU KV placement. Runtime logs show the MTP tensors being ignored
and maximum GPU layers being requested. The runtime also warned that a 1.44 GiB
buffer could not be `mlock`ed under the current limit; inference remained stable
and no elevated privilege workaround was applied.

### Qwen measured benchmarks

| Metric | 16K near-limit | 32K near-limit |
| --- | ---: | ---: |
| Configured context | 16,384 | 32,768 |
| Actual input tokens | 14,030 | 26,978 |
| Unique source files | 15 | 25 |
| Prompt-processing time | 148.265 s | 231.478 s |
| Prompt processing | 94.628 tok/s | 116.547 tok/s |
| Generation | 23.693 tok/s | 23.905 tok/s |
| Peak VRAM | 9.468 GiB | 9.397 GiB |
| GTT start / peak | 1.156 / 1.200 GiB | 1.150 / 1.209 GiB |
| System RAM start / peak | 24.287 / 24.995 GiB | 22.876 / 23.639 GiB |
| Average whole-machine CPU | 6.64% | 6.55% |
| Peak GPU utilization | 99% | 99% |
| Peak temperature | 68 C | 71 C |
| Peak board power | 160 W | 160 W |
| Result | stable | stable |

Both tests used meaningful, non-repeating Nix source assembled by
`tools/build-context-prompt.py`, followed by 256 generated tokens. The small GTT
changes (about 45--60 MiB) are not material model spill. The 32K profile is
proven usable, though 16K has substantially lower time to first token for daily
interactive use.

A short reasoning-off C++ smoke run measured 24.373 generation tok/s, 9.496 GiB
peak VRAM, 99% GPU utilization, 62 C, and 152 W. Its 512-token answer was still
truncated because the model was verbose; final quality tasks therefore use a
1,024-token output cap.

Qwen's 1,024-token LRU answer compiled and ran successfully under C++17 with
one unused-variable warning. Its fixed debugging task was poor: it found the
pop-before-map-erase problem but missed multiple independent iterator,
`operator[]`, capacity, and zero-capacity bugs. Reasoning-on improved discovery
but still made API errors and used the full 2,048-token budget without a final
patch. Its LLVM response mixed the legacy and new pass managers, used the wrong
store operand, iterated basic blocks as instructions, and misstated AMDGPU
address spaces. The 16K OpenCode run exhausted its context after reading files
without producing an answer. Continuing that same session at 32K produced a
useful repository summary, but incorrectly implied the separate Home Manager
output is activated as part of the NixOS rebuild.

## Gemma 4 12B Instruct Q4_K_M

| Item | Measured value |
| --- | --- |
| File | `/home/yejashi/HDD/AI/models/gemma-4-12B-it-Q4_K_M.gguf` |
| Size | 7,662,533,088 bytes |
| SHA-256 | `3962624dcd25b947d889dc9ae1bf275b61db6cd4dbe694057f34fffef1671509` |
| LM Studio key / instance | `gemma-4-12b-it` / `gemma-4-12b-q4-k-m` |
| Quantization | Q4_K_M, 4 bits/weight reported by LM Studio |
| GPU offload | `max`; strict VRAM cap enabled |
| Flash Attention | enabled |
| K/V cache | Q8_0 / Q8_0, GPU-resident |
| Eval batch / parallel slots | 128 / 1 |
| Speculation | MTP off, simple draft off, no draft model |
| Cold load (16K) | 30.183 seconds |

### Gemma measured context benchmarks

| Metric | 16K near-limit | 32K near-limit |
| --- | ---: | ---: |
| Configured context | 16,384 | 32,768 |
| Actual input tokens | 14,176 | 27,859 |
| Unique source files | 13 | 23 |
| Prompt-processing time | 194.905 s | 373.081 s |
| Prompt processing | 72.733 tok/s | 74.673 tok/s |
| Generation | 14.326 tok/s | 16.242 tok/s |
| Peak VRAM | 9.974 GiB | 10.224 GiB |
| GTT start / peak | 1.664 / 1.778 GiB | 1.511 / 1.661 GiB |
| System RAM start / peak | 19.659 / 19.944 GiB | 18.920 / 19.521 GiB |
| Average whole-machine CPU | 7.05% | 7.45% |
| Peak GPU utilization | 99% | 99% |
| Peak temperature | 71 C | 72 C |
| Peak board power | 144 W | 157 W |
| Result | stable | stable |

Gemma Q4_K_M retains about 2.0 GiB physical VRAM at the measured 16K peak and
about 1.76 GiB at 32K. The Q4_K_S fallback is therefore not needed. Both context
profiles are stable, but Gemma has materially slower prefill and generation
than Qwen on this GPU.
