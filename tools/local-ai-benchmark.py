#!/usr/bin/env python3
"""Measure one LM Studio prompt with phase-specific memory sampling."""

from __future__ import annotations

import argparse
import json
import threading
import time
import urllib.request
from pathlib import Path
from typing import Any


VRAM_USED = Path("/sys/class/drm/card1/device/mem_info_vram_used")
VRAM_TOTAL = Path("/sys/class/drm/card1/device/mem_info_vram_total")
GTT_USED = Path("/sys/class/drm/card1/device/mem_info_gtt_used")
GPU_BUSY = Path("/sys/class/drm/card1/device/gpu_busy_percent")
MEM_BUSY = Path("/sys/class/drm/card1/device/mem_busy_percent")
SCLK = Path("/sys/class/drm/card1/device/pp_dpm_sclk")
MCLK = Path("/sys/class/drm/card1/device/pp_dpm_mclk")
HWMON = next(
    path
    for path in Path("/sys/class/drm/card1/device/hwmon").glob("hwmon*")
    if (path / "name").read_text().strip() == "amdgpu"
)


def gib(value: int) -> float:
    return round(value / (1024**3), 3)


def memory_used_bytes() -> int:
    values: dict[str, int] = {}
    for line in Path("/proc/meminfo").read_text().splitlines():
        key, value = line.split(":", 1)
        values[key] = int(value.strip().split()[0]) * 1024
    return values["MemTotal"] - values["MemAvailable"]


def cpu_counters() -> tuple[int, int]:
    fields = [int(value) for value in Path("/proc/stat").read_text().splitlines()[0].split()[1:]]
    idle = fields[3] + fields[4]
    return sum(fields), idle


def active_clock_mhz(path: Path) -> int:
    active = next((line for line in path.read_text().splitlines() if "*" in line), "")
    value = active.split(":", 1)[-1].split("Mhz", 1)[0].strip()
    return int(value) if value.isdigit() else 0


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", required=True)
    parser.add_argument("--prompt", required=True, type=Path)
    parser.add_argument("--context", required=True, type=int)
    parser.add_argument("--max-output", type=int, default=256)
    parser.add_argument("--reasoning", choices=("off", "on"))
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--base-url", default="http://127.0.0.1:1234")
    args = parser.parse_args()

    prompt = args.prompt.read_text()
    request_body = {
        "model": args.model,
        "input": prompt,
        "system_prompt": "Analyze the supplied source accurately and answer the requested engineering task.",
        "stream": True,
        "temperature": 0,
        "max_output_tokens": args.max_output,
        "context_length": args.context,
        "store": False,
    }
    if args.reasoning is not None:
        request_body["reasoning"] = args.reasoning

    phase = {"name": "request"}
    samples: list[dict[str, Any]] = []
    stop_sampling = threading.Event()

    def sample_memory() -> None:
        while not stop_sampling.is_set():
            samples.append(
                {
                    "time": time.monotonic(),
                    "phase": phase["name"],
                    "vram_used": int(VRAM_USED.read_text()),
                    "gtt_used": int(GTT_USED.read_text()),
                    "ram_used": memory_used_bytes(),
                    "gpu_busy_percent": int(GPU_BUSY.read_text()),
                    "memory_busy_percent": int(MEM_BUSY.read_text()),
                    "gpu_clock_mhz": active_clock_mhz(SCLK),
                    "memory_clock_mhz": active_clock_mhz(MCLK),
                    "temperature_millicelsius": int((HWMON / "temp1_input").read_text()),
                    "power_microwatts": int((HWMON / "power1_average").read_text()),
                }
            )
            stop_sampling.wait(0.1)

    cpu_start = cpu_counters()
    started = time.monotonic()
    sampler = threading.Thread(target=sample_memory, daemon=True)
    sampler.start()

    events: list[dict[str, Any]] = []
    event_times: dict[str, float] = {}
    final_result: dict[str, Any] | None = None
    req = urllib.request.Request(
        f"{args.base_url}/api/v1/chat",
        data=json.dumps(request_body).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=1800) as response:
            current_event = ""
            for raw_line in response:
                line = raw_line.decode().rstrip("\r\n")
                if line.startswith("event: "):
                    current_event = line[7:]
                elif line.startswith("data: "):
                    now = time.monotonic()
                    data = json.loads(line[6:])
                    event_type = data.get("type", current_event)
                    events.append({"type": event_type, "elapsed_seconds": round(now - started, 6)})
                    if event_type == "prompt_processing.start":
                        phase["name"] = "prompt"
                        event_times["prompt_start"] = now
                    elif event_type == "prompt_processing.end":
                        event_times["prompt_end"] = now
                        phase["name"] = "generation"
                    elif event_type == "chat.end":
                        final_result = data["result"]
    finally:
        stop_sampling.set()
        sampler.join()

    finished = time.monotonic()
    cpu_end = cpu_counters()
    total_delta = cpu_end[0] - cpu_start[0]
    idle_delta = cpu_end[1] - cpu_start[1]
    cpu_percent = 100 * (total_delta - idle_delta) / total_delta if total_delta else 0

    if final_result is None:
        raise RuntimeError("LM Studio stream ended without a chat.end event")

    stats = final_result["stats"]
    prompt_seconds = event_times["prompt_end"] - event_times["prompt_start"]

    def peak(field: str, selected_phase: str | None = None) -> int:
        chosen = [sample[field] for sample in samples if selected_phase is None or sample["phase"] == selected_phase]
        return max(chosen) if chosen else 0

    def average(field: str, selected_phase: str) -> float:
        chosen = [sample[field] for sample in samples if sample["phase"] == selected_phase]
        return round(sum(chosen) / len(chosen), 2) if chosen else 0

    output = {
        "model": args.model,
        "context_configured": args.context,
        "prompt_file": str(args.prompt),
        "prompt_bytes": len(prompt.encode()),
        "input_tokens": stats["input_tokens"],
        "output_tokens": stats["total_output_tokens"],
        "prompt_processing_seconds": round(prompt_seconds, 3),
        "prompt_tokens_per_second": round(stats["input_tokens"] / prompt_seconds, 3),
        "generation_tokens_per_second": stats["tokens_per_second"],
        "time_to_first_token_seconds": stats["time_to_first_token_seconds"],
        "wall_time_seconds": round(finished - started, 3),
        "average_machine_cpu_percent": round(cpu_percent, 2),
        "vram_total_gib": gib(int(VRAM_TOTAL.read_text())),
        "vram_start_gib": gib(samples[0]["vram_used"]),
        "vram_peak_prompt_gib": gib(peak("vram_used", "prompt")),
        "vram_peak_generation_gib": gib(peak("vram_used", "generation")),
        "vram_peak_overall_gib": gib(peak("vram_used")),
        "gtt_start_gib": gib(samples[0]["gtt_used"]),
        "gtt_peak_gib": gib(peak("gtt_used")),
        "ram_start_gib": gib(samples[0]["ram_used"]),
        "ram_peak_gib": gib(peak("ram_used")),
        "gpu_busy_peak_percent": peak("gpu_busy_percent"),
        "gpu_busy_prompt_average_percent": average("gpu_busy_percent", "prompt"),
        "gpu_busy_generation_average_percent": average("gpu_busy_percent", "generation"),
        "memory_busy_peak_percent": peak("memory_busy_percent"),
        "gpu_clock_peak_mhz": peak("gpu_clock_mhz"),
        "memory_clock_peak_mhz": peak("memory_clock_mhz"),
        "temperature_peak_celsius": peak("temperature_millicelsius") / 1000,
        "power_peak_watts": peak("power_microwatts") / 1_000_000,
        "events": events,
        "result": final_result,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, indent=2) + "\n")
    print(json.dumps({key: value for key, value in output.items() if key not in {"events", "result"}}, indent=2))


if __name__ == "__main__":
    main()
