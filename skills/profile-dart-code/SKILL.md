---
name: profile-dart-code
description: |-
  Profile Dart command-line applications using the VM Service protocol to
  capture CPU samples and identify performance bottlenecks. Helps agents
  automate CPU profiling, generate function call breakdown summaries, and
  export JSON profiles without a browser or DevTools.
key_features:
  - Automated VM Service WebSocket connection
  - CPU sampling and top-function call summary
  - JSON trace export for further analysis
---

# Dart CPU Profiling

Guidelines and automated tools for capturing CPU profiles and identifying
bottlenecks in Dart command-line applications.

## When to use this skill
- When asked to profile, optimize, or benchmark CPU execution of a Dart script
  or CLI tool.
- When investigating hot loops, heavy function calls, or unexpected execution
  overhead.

## Workflow
1. **Ensure clean compilation**: Make sure the target Dart script runs cleanly
   (`dart run <script.dart>`).
2. **Run Profiler Script**: Use the automated profiling helper script inside
   this skill directory to launch the target app with VM Service observability
   enabled, capture CPU samples, and output top-consuming functions.
3. **Analyze & Optimize**: Review the self and total sample percentages
   reported by the tool to pinpoint bottlenecks (e.g., excessive object
   allocation, costly hashing, virtual dispatch overhead).

## Running the Profiler Helper Script

This repository includes a zero-dependency (using only official `vm_service`)
profiling script that launches any Dart file, connects to the VM Service, waits
for execution to complete (`--pause-isolates-on-exit`), retrieves CPU samples,
and prints a clean summary while exporting the full JSON profile.

Run it from any working directory:
```bash
dart run <dash_skills_repo>/skills/profile-dart-code/scripts/bin/profile.dart --out=cpu_profile.json -- <path_to_target.dart> [target_arguments...]
```

### Script Arguments
- `-o, --out=<file>`: Output file path to save the raw JSON CPU profile
  (default: `cpu_profile.json`).
- `-p, --period=<micros>`: Sampling interval in microseconds (default: `1000`µs
  = 1ms). Minimum `50`µs.
- `-- <target.dart> [args...]`: The Dart script to profile, followed by any
  arguments passed to `main()`.

> [!WARNING]
> **Potential Hangs**: When profiling or debugging Dart targets using VM services,
> target exceptions or connection issues can cause the process to hang
> indefinitely. Ensure your target script handles timeouts, and monitor the
> process output.

### Example Output
```
Connecting to VM service at ws://127.0.0.1:8181/ws...
Target execution paused at exit. Retrieving CPU profile samples...

=== Top CPU Functions (Self Samples) ===
 1. _PuzzleSmart._shiftSlice (self: 34.2%, total: 41.0%)
 2. _countInversions (self: 18.5%, total: 18.5%)
 3. shortestPaths (self: 12.1%, total: 98.4%)

Saved complete JSON profile to: cpu_profile.json
```

## Best Practices for Interpreting Profiles
1. **Focus on Self % vs. Total %**: High `self %` indicates where CPU time is
   spent directly inside a function's own body (math, loop branching, array
   indexing). High `total %` with low `self %` indicates a dispatcher or outer
   orchestration loop.
2. **Look for Hidden Overhead**: Watch out for implicit object allocations
   (`_copyData`, iterator wrappers, closure creation) inside tight loops.
3. **Verify Optimizations Empirically**: Always record baseline sample counts
   and execution duration (`time -v`) before and after applying optimizations.
