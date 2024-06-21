#!/bin/bash

INTERVAL=1

MAX_RAM_USAGE=80  # în procente
MAX_CPU_USAGE=80  # în procente

#aceasta functie imi ia toti utilizatorii, fara utilizatorul curent (aless)
get_connected_users() {
    who | awk '$1 != "aless" && $1 != "root" && $5 != "(:0)" {print $1 "@" $5}'
}

get_resources() {
    local user_host=$1
    echo "Monitorizare pentru $user_host"

    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    
    #extrag numele utilizatorului si ip-ul
    user=$(echo $user_host | cut -d'@' -f1)
    host=$(echo $user_host | cut -d'@' -f2 | tr -d '()')
    folder="${user}.${host}"

    mkdir -p $folder

    #calculez procentul de utilizare ram si CPU din pc-ul monitorizat
    ram_usage=$(ssh $user@$host "free | awk '/^Mem:/ {printf \"%.0f\", \$3/\$2 * 100.0}'")
    cpu_usage=$(ssh $user@$host "top -bn1 | grep 'Cpu(s)' | awk '{printf \"%.0f\", \$2 + \$4}'")

    RESOURCES="\nRAM Usage: $ram_usage%\nCPU Usage: $cpu_usage%"

    if [ "$ram_usage" -gt "$MAX_RAM_USAGE" ]; then
        ALERT_RAM="[$TIMESTAMP] ALERTĂ: Utilizarea RAM-ului este peste $MAX_RAM_USAGE% pentru $user_host. RAM-ul era utilizat $ram_usage%."
        echo "$ALERT_RAM" >> ${folder}/alerts.txt
        ssh -o BatchMode=yes -o ConnectTimeout=2 $user@$host "DISPLAY=:0 notify-send 'ALERTĂ: Utilizarea RAM' '$ALERT_RAM'"
    fi

    if [ "$cpu_usage" -gt "$MAX_CPU_USAGE" ]; then
        ALERT_CPU="[$TIMESTAMP] ALERTĂ: Utilizarea CPU-ului este peste $MAX_CPU_USAGE% pentru $user_host. CPU-ul era utilizat $cpu_usage%."
        echo "$ALERT_CPU" >> ${folder}/alerts.txt
        ssh -o BatchMode=yes -o ConnectTimeout=2 $user@$host "DISPLAY=:0 notify-send 'ALERTĂ: Utilizarea CPU' '$ALERT_CPU'"
    fi

    echo -e "[$TIMESTAMP] $RESOURCES" >> ${folder}/resources.txt
}

while true; do
    connected_users=$(get_connected_users)

    for user_host in $connected_users; do
        get_resources $user_host
    done

    sleep $INTERVAL
done

