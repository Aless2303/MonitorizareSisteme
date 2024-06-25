#!/bin/bash

while true; do
    clear
    echo "Bun venit in meniu (mereu cand alegeti o optiune, puneti indexul optiunii)."
    echo "Alegeti un sistem:"
    
    users=$(who | awk '$1 != "aless" && $5 != "(:0)" {print $1 "@" $5}' | sort | uniq)
    
    if [ -z "$users" ]; then
        echo "Nu există utilizatori conectați."
        exit 1
    fi

    PS3="Selectati un utilizator: "
    select user_host in $users; do
        if [ -n "$user_host" ]; then
            echo "Ați selectat utilizatorul $user_host."
            user=$(echo $user_host | cut -d'@' -f1)
            host=$(echo $user_host | cut -d'@' -f2 | tr -d '()')
            break
        else
            echo "Selecție invalidă. Încercați din nou."
        fi
    done

    echo "Ce doriti sa faceti? (tastati 1, 2 sau 3)"
    echo "1. Oprire/pornire servicii/procese"
    echo "2. Copiere fisiere"
    echo "3. Instalare aplicatii/servicii"
    read -p "Ce alegeti: " action

    case $action in
        1)
            echo "Ati selectat oprire/pornire servicii/procese."
            echo "Doriti opriti/porniti un proces sau un serviciu?:"
            echo "1. Proces"
            echo "2. Serviciu"
            read -p "Ce doriti sa alegeti: " subaction

            if [ "$subaction" -eq 1 ]; then
                echo "Doriti sa porniti sau sa opriti un proces?"
                echo "1. Pornesc"
                echo "2. Opreste"
                read -p "Ce doriti sa alegeti: " proc_action

                if [ "$proc_action" -eq 1 ]; then
                    read -p "Introduceti comanda pentru a porni procesul: " command
                    if [[ $command != *"&"* ]]; then
                        command="nohup $command > /dev/null 2>&1 &"
                    fi
                    ssh $user@$host "$command"
                elif [ "$proc_action" -eq 2 ]; then
                    ssh $user@$host "ps aux"
                    read -p "Alegeti PID-ul procesului pe care vreti sa il opriti: " pid
                    ssh $user@$host "kill $pid"
                else
                    echo "Optiune invalida."
                fi
            elif [ "$subaction" -eq 2 ]; then
                echo "Doriti sa porniti sau sa opriti un serviciu?"
                echo "1. Pornesc"
                echo "2. Opreste"
                read -p "Ce doriti sa alegeti: " serv_action

                if [ "$serv_action" -eq 1 ]; then
                    read -p "Introduceti comanda pentru a porni serviciul: " service_command
                    if [[ $service_command != *"&"* ]]; then
                        service_command="nohup $service_command > /dev/null 2>&1 &"
                    fi
                    ssh $user@$host "$service_command"
                elif [ "$serv_action" -eq 2 ]; then
                    ssh $user@$host "systemctl list-units --type=service"
                    read -p "Introduceti numele serviciului pe care vreti sa il opriti: " service
                    ssh $user@$host "sudo systemctl stop $service"
                else
                    echo "Optiune invalida."
                fi
            else
                echo "Optiune invalida."
            fi
            ;;
        2)
            echo "Ati selectat copiere fisiere."
            read -p "Introduceti calea fisierului sursa de pe client: " sursa
            read -p "Introduceti calea destinatie pe server: " destination
            ;;
        3)
            echo "Ati selectat instalare aplicatii/servicii."
            read -p "Introduceti numele aplicatiei/serviciului pe care doriti sa il instalati: " package
            ssh $user@$host "sudo apt-get install $package"
            ;;
        *)
            echo "Optiune invalida."
            ;;
    esac

    read -p "Apasati Enter pentru a reveni la meniu..."
done

