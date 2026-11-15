#!/bin/bash
# fancurve: sets both MacBook fans from the hottest CPU/GPU sensor. Run as root by the
# LaunchDaemon com.local.fancurve. Modes (file /usr/local/etc/fans-mode): curve, max, auto.
#
# curve: below LOW the fans belong to macOS. From LOW to HIGH the target rises in a
# straight line from each fan's minimum to its maximum. The fans go back to macOS
# after the temperature has stayed at or under OFF for a minute.

SMC=/usr/local/bin/smc
MODE_FILE=/usr/local/etc/fans-mode
LOW=50      # deg C: the curve starts here
HIGH=70     # deg C: full speed from here
OFF=45      # deg C: hand the fans back under this
STEP=5      # seconds between readings
COOL=12     # readings at or under OFF before the fans are released

# M3 Pro/Max die sensors: efficiency cores, performance cores, GPU clusters.
KEYS="Te05 Te0L Te0P Te0S Tf04 Tf09 Tf0A Tf0B Tf0D Tf0E Tf44 Tf49 Tf4A Tf4B Tf4D Tf4E Tf14 Tf18 Tf19 Tf1A Tf24 Tf28 Tf29 Tf2A"

# smc prints "Te05  [flt ]  36 (bytes ...)": the value is the fourth field
num() { $SMC -k "$1" -r 2>/dev/null | awk '{print int($4)}'; }
hexf() { perl -e 'print unpack("H*", pack("f<", $ARGV[0]))' "$1"; }

hottest() {
    local t=0 v k
    for k in $KEYS; do
        v=$(num "$k")
        [ -n "$v" ] && [ "$v" -gt "$t" ] && [ "$v" -lt 130 ] && t=$v
    done
    echo "$t"
}

forced() { [ "$($SMC -k F0Md -r | grep -o 'bytes [0-9a-f]*' | cut -d' ' -f2)" = 01 ]; }

force() {
    if ! forced; then
        $SMC -k Ftst -w 01; sleep 3
        $SMC -k F0Md -w 01; $SMC -k F1Md -w 01
    fi
}

release() {
    forced || return 0
    $SMC -k F0Md -w 00; $SMC -k F1Md -w 00; $SMC -k Ftst -w 00
}

# set_share N: both fans at N percent of the way from minimum to maximum
set_share() {
    local i mn mx
    for i in 0 1; do
        mn=$(num "F${i}Mn"); mx=$(num "F${i}Mx")
        # a bad reading must never park a forced fan: leave the fans to macOS
        if [ -z "$mn" ] || [ -z "$mx" ] || [ "$mn" -lt 500 ] || [ "$mx" -le "$mn" ]; then release; return; fi
    done
    force
    for i in 0 1; do
        mn=$(num "F${i}Mn"); mx=$(num "F${i}Mx")
        $SMC -k "F${i}Tg" -w "$(hexf $((mn + (mx - mn) * $1 / 100)))"
    done
}

cool=0
while :; do
    mode=$(cat "$MODE_FILE" 2>/dev/null); mode=${mode:-curve}
    case "$mode" in
    max)  set_share 100 ;;
    auto) release ;;
    *)
        t=$(hottest)
        if [ "$t" -lt 5 ]; then
            release          # no sensor answered: macOS keeps control
        elif [ "$t" -ge "$LOW" ]; then
            cool=0
            share=$(( (t - LOW) * 100 / (HIGH - LOW) ))
            [ "$share" -gt 100 ] && share=100
            set_share "$share"
        elif [ "$t" -le "$OFF" ]; then
            cool=$((cool + 1))
            [ "$cool" -ge "$COOL" ] && release
        elif forced; then
            set_share 0
        fi ;;
    esac
    sleep "$STEP"
done
