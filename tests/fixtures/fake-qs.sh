#!/bin/bash
# Stand-in for `qs` in the sleep hook tests.
# FAKE_QS_INSTANCES: "pid:targets ..." e.g. "11:lock,notifs 33:notifs".
# FAKE_QS_HANG: pid whose IPC never answers (show or call).
# Every ipc call is appended to FAKE_QS_LOG.
if [[ "$1" == "list" ]]; then
  for entry in $FAKE_QS_INSTANCES; do
    printf 'Instance x%s:\n  Process ID: %s\n  Shell ID: abc\n\n' "${entry%%:*}" "${entry%%:*}"
  done
  exit 0
fi
if [[ "$1" == "ipc" && "$2" == "--pid" ]]; then
  pid="$3"
  shift 3
  [[ "$pid" == "$FAKE_QS_HANG" ]] && echo "ipc --pid $pid $*" >>"$FAKE_QS_LOG" && sleep 30
  if [[ "$1" == "show" ]]; then
    for entry in $FAKE_QS_INSTANCES; do
      [[ "${entry%%:*}" == "$pid" ]] || continue
      IFS=, read -ra targets <<<"${entry#*:}"
      for target in "${targets[@]}"; do
        printf 'target %s\n  function x(): void\n' "$target"
      done
    done
    exit 0
  fi
  echo "ipc --pid $pid $*" >>"$FAKE_QS_LOG"
  exit 0
fi
exit 1
