#!/system/bin/sh
# Attaches strace to surfaceflinger as soon as it appears, so the trace
# covers the whole run up to the ~40s BOOT TIMEOUT stall. Started as a
# real init service (not init.d/sysinit) so it can never block boot.
while true; do
    for p in /proc/[0-9]*; do
        c=$(cat "$p/comm" 2>/dev/null)
        if [ "$c" = "surfaceflinger" ]; then
            pid=${p#/proc/}
            exec /system/bin/strace -f -tt -T \
                -e trace=ioctl,poll,ppoll,epoll_wait,select,futex \
                -p "$pid" -o /data/sf_strace.log
        fi
    done
    sleep 1
done
