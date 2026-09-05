#!/usr/bin/env python3
"""Load an exact llama.cpp profile through the official LM Studio SDK."""

from __future__ import annotations

import argparse
import json
import time


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", required=True)
    parser.add_argument("--identifier", required=True)
    parser.add_argument("--context", required=True, type=int)
    parser.add_argument("--batch", required=True, type=int)
    parser.add_argument("--cache", choices=("q8_0", "q4_0"), required=True)
    parser.add_argument("--api-host", default="127.0.0.1:1234")
    args = parser.parse_args()

    import lmstudio as lms
    import lmstudio._kv_config as kv

    # LM Studio 0.4.21 accepts these current fields, while SDK 1.5.0 does not
    # yet expose them in LlmLoadModelConfig. Reuse two compatible scalar values
    # to add the missing fields to the SDK-generated API override layer.
    kv.TO_SERVER_LOAD_LLM["seed"].append(
        ("llm.load.numParallelSessions", kv.ConfigField("seed"))
    )
    kv.TO_SERVER_LOAD_LLM["useFp16ForKVCache"].append(
        (
            "llm.load.llama.speculativeDecoding.draftMtp",
            kv.ConfigField("useFp16ForKVCache"),
        )
    )

    client = lms.get_default_client(args.api_host)
    for loaded in client.llm.list_loaded():
        loaded.unload()

    config = {
        "gpu": {"ratio": "max"},
        "gpuStrictVramCap": True,
        "contextLength": args.context,
        "evalBatchSize": args.batch,
        "flashAttention": True,
        "offloadKVCacheToGpu": True,
        "llamaKCacheQuantizationType": args.cache,
        "llamaVCacheQuantizationType": args.cache,
        "useFp16ForKVCache": False,
        "keepModelInMemory": True,
        "tryMmap": True,
        "seed": 1,
    }
    started = time.monotonic()
    model = client.llm.load_new_instance(
        args.model,
        args.identifier,
        config=config,
    )
    print(
        json.dumps(
            {
                "identifier": model.identifier,
                "load_time_seconds": round(time.monotonic() - started, 3),
                "load_config": model.get_load_config().to_dict(),
                "compatibility_fields": {
                    "maxParallelPredictions": 1,
                    "speculativeDraftMtp": False,
                },
            },
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
