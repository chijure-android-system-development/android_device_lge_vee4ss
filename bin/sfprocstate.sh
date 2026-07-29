#!/system/bin/sh
# Diagnostic (2026-07-29): dumps surfaceflinger's own /proc state every 2s
# instead of using strace, which segfaults unconditionally on this kernel/
# ABI (verified via direct reproduction under TWRP against a trivial
# target, not specific to surfaceflinger). Captures, per thread: stat
# (state field), wchan (blocking kernel function, if the kernel exposes
# it) and syscall (blocked syscall + args, if exposed) — none of these
# need ptrace, just /proc read access. Started as a real init service so
# it can never block boot.
OUT=/data/sf_procstate.log
: > "$OUT"
while true; do
    for p in /proc/[0-9]*; do
        c=$(cat "$p/comm" 2>/dev/null)
        if [ "$c" = "surfaceflinger" ]; then
            pid=${p#/proc/}
            while [ -d "$p" ]; do
                echo "=== $(cat /proc/uptime) pid=$pid ===" >> "$OUT"
                for t in "$p"/task/*; do
                    tid=${t#$p/task/}
                    echo "-- tid=$tid --" >> "$OUT"
                    cat "$t/stat" 2>/dev/null >> "$OUT"
                    echo >> "$OUT"
                    if [ -f "$t/wchan" ]; then
                        printf 'wchan: ' >> "$OUT"
                        cat "$t/wchan" 2>/dev/null >> "$OUT"
                        echo >> "$OUT"
                    fi
                    if [ -f "$t/syscall" ]; then
                        printf 'syscall: ' >> "$OUT"
                        cat "$t/syscall" 2>/dev/null >> "$OUT"
                        echo >> "$OUT"
                    fi
                done
                sleep 2
            done
            exit 0
        fi
    done
    sleep 1
done
