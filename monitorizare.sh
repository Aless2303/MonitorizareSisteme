#!/bin/bash

INTERVAL=1

MAX_RAM_USAGE=80  
MAX_CPU_USAGE=80  

#intervalul la care verific ~/.bashrc
BASHRC_CHECK_INTERVAL=60
LAST_BASHRC_CHECK=0

#aici iau toti utilizatorii folosind comanda who si exclud pe aless ( cel de pe server)
get_connected_users() {
    who | awk '$1 != "aless" && $1 != "root" && $5 != "(:0)" {print $1 "@" $5}'
}

#ma asigur ca fisierul ~/.bashrc are configuratia corecta pentru a afisa istoricul cum am nevoie
ensure_bashrc_configuration() {
    local user_host=$1

    user=$(echo $user_host | cut -d'@' -f1)
    host=$(echo $user_host | cut -d'@' -f2 | tr -d '()')

    ssh $user@$host "
    if ! grep -q 'shopt -s histappend' ~/.bashrc; then
        echo 'shopt -s histappend' >> ~/.bashrc
    fi
    if ! grep -q 'PROMPT_COMMAND=\"history -a; history -n; \$PROMPT_COMMAND\"' ~/.bashrc; then
        echo 'export PROMPT_COMMAND=\"history -a; history -n; \$PROMPT_COMMAND\"' >> ~/.bashrc
    fi
    if ! grep -q 'export HISTTIMEFORMAT=\"%F %T \"' ~/.bashrc; then
        echo 'export HISTTIMEFORMAT=\"%F %T \"' >> ~/.bashrc
    fi
    if ! grep -q 'export HISTSIZE=10000' ~/.bashrc; then
        echo 'export HISTSIZE=10000' >> ~/.bashrc
    fi
    if ! grep -q 'export HISTFILESIZE=20000' ~/.bashrc; then
        echo 'export HISTFILESIZE=20000' >> ~/.bashrc
    fi
    source ~/.bashrc
    "
}

get_resources() {
    local user_host=$1
    echo "Monitorizare pentru $user_host"

    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    user=$(echo $user_host | cut -d'@' -f1)
    host=$(echo $user_host | cut -d'@' -f2 | tr -d '()')
    folder="${user}.${host}"

    mkdir -p $folder

    ram_usage=$(ssh $user@$host "free | awk '/^Mem:/ {printf \"%.0f\", \$3/\$2 * 100.0}'")
    cpu_usage=$(ssh $user@$host "top -bn1 | grep 'Cpu(s)' | awk '{printf \"%.0f\", \$2 + \$4}'")

    RESOURCES="RAM Usage: $ram_usage%\nCPU Usage: $cpu_usage%"

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

#aici monitorizez procesele si dispozitivele hardware care s-au conectat/deconectat
monitor_additional_resources() {
    local user_host=$1
    echo "Monitorizare procese și hardware pentru $user_host"

    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    user=$(echo $user_host | cut -d'@' -f1)
    host=$(echo $user_host | cut -d'@' -f2 | tr -d '()')
    folder="${user}.${host}"

    mkdir -p $folder

    #procese:
    ssh $user@$host "ps -eo pid,comm,lstart" > ${folder}/processes_current.txt
    if [ -f ${folder}/processes_previous.txt ]; then
        echo "[$TIMESTAMP] Diferențe procese:" >> ${folder}/processes_diff.txt
        diff ${folder}/processes_previous.txt ${folder}/processes_current.txt >> ${folder}/processes_diff.txt
    fi
    mv ${folder}/processes_current.txt ${folder}/processes_previous.txt

    #hardware:
    ssh $user@$host "lsusb" > ${folder}/hardware_current.txt
    if [ -f ${folder}/hardware_previous.txt ]; then
        echo "[$TIMESTAMP] Diferențe hardware:" >> ${folder}/hardware_diff.txt
        diff ${folder}/hardware_previous.txt ${folder}/hardware_current.txt >> ${folder}/hardware_diff.txt
    fi
    mv ${folder}/hardware_current.txt ${folder}/hardware_previous.txt

    ssh $user@$host "history -a"
    ssh $user@$host "tail -n 1000 ~/.bash_history" > ${folder}/commands.txt
}

while true; do
    #iau toti utilizatorii conectati prin ssh
    connected_users=$(get_connected_users)

    #configurez ~/.bashrc pentr toti utilizatorii ca sa fiu sigur ca este ok
    current_time=$(date +%s)
    if (( current_time - LAST_BASHRC_CHECK >= BASHRC_CHECK_INTERVAL )); then
        for user_host in $connected_users; do
            ensure_bashrc_configuration $user_host
        done
        LAST_BASHRC_CHECK=$current_time
    fi

    for user_host in $connected_users; do
        get_resources $user_host
        monitor_additional_resources $user_host
    done

    sleep $INTERVAL
done

