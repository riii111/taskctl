#!/bin/sh
# Mock command for the run probe; every mode only touches processes it starts itself.
# usage: child.sh MODE [PIDFILE [READYFILE]]
# term-ok creates READYFILE once the grandchild ignores SIGTERM and has written its pid.
mode=$1
pidfile=${2:-/dev/null}
readyfile=${3:-/dev/null}

case $mode in
echo)
  # Echoes stdin, writes stderr, and splits one UTF-8 character across two writes.
  cat
  printf 'err-line\n' >&2
  printf '\343\201'
  sleep 0.2
  printf '\202\n'
  exit 3
  ;;
term-ok)
  # The leader stops on SIGTERM, but leaves a grandchild that ignores SIGTERM and holds stdout.
  echo $$ > "$pidfile"
  sh -c 'trap "" TERM; echo $$ > "$1.gc"; : > "$2"; exec sleep 300' sh "$pidfile" "$readyfile" &
  trap 'echo got-term >&2; exit 143' TERM
  sleep 300 &
  wait $!
  ;;
ignore-term)
  # The leader ignores SIGTERM, so only SIGKILL after the grace stops it.
  trap '' TERM
  echo $$ > "$pidfile"
  sleep 300 &
  echo $! > "$pidfile.gc"
  wait $!
  ;;
flood)
  # Writes without end, so the output limit stops it.
  exec yes
  ;;
*)
  echo "unknown mode $mode" >&2
  exit 2
  ;;
esac
