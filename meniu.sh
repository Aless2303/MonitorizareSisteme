#!/bin/bash

while true; do
    clear
    echo "Bun venit in meniu (mereu cand alegeti o optiune, puneti indexul optiunii)."
    echo "Alegeti un sistem:"

    users=$(who | awk -v me=$(whoami) '$1 != me && $5 != "(:0)" {print $1 "@" $5}' | sort | uniq)

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
            echo "Alege de unde vrei sa copiezi:"
            echo "1. De pe server"
            echo "2. Alt sistem conectat"
            read -p "Selectati optiunea: " copy_option

            if [ "$copy_option" -eq 1 ]; then
                source_user=$(whoami)
                source_host=$(hostname)
                current_dir="/home/$source_user"
            elif [ "$copy_option" -eq 2 ]; then
                echo "Selectati sistemul de pe care doriti sa copiati:"

                users=$(who | awk -v me=$(whoami) -v dest_user=$user '$1 != me && $1 != dest_user && $5 != "(:0)" {print $1 "@" $5}' | sort | uniq)

                PS3="Selectati un alt utilizator: "
                select source_user_host in $users; do
                    if [ -n "$source_user_host" ]; then
                        echo "Ați selectat utilizatorul $source_user_host."
                        source_user=$(echo $source_user_host | cut -d'@' -f1)
                        source_host=$(echo $source_user_host | cut -d'@' -f2 | tr -d '()')
                        current_dir="/home/$source_user"
                        break
                    else
                        echo "Selecție invalidă. Încercați din nou."
                    fi
                done
            else
                echo "Optiune invalida."
                continue
            fi

            while true; do
                if [ "$copy_option" -eq 1 ]; then
                    ls -l $current_dir > tmp_ls_output
                else
                    ssh $source_user@$source_host "ls -l $current_dir" > tmp_ls_output
                fi

                clear
                echo "Continutul directorului $current_dir de pe $source_user@$source_host:"
                awk 'NR>1 {print NR-1 ") " $0}' tmp_ls_output
                echo ""
                echo "1) Alege din directorul curent"
                echo "2) Schimba directorul"
                echo "3) Anuleaza"
                read -p "Selectati optiunea: " file_action

                case $file_action in
                    1)
                        read -p "Introduceti numarul fisierului/directorului: " file_number
                        file=$(awk -v num=$((file_number + 1)) 'NR==num {print $NF}' tmp_ls_output)
                        if [ -n "$file" ]; then
                            if [ "$copy_option" -eq 2 ]; then
                                # Copierea de pe sursă pe server
                                if ssh $source_user@$source_host "[ -d '$current_dir/$file' ]"; then
                                    ssh $source_user@$source_host "tar czf - -C $current_dir $file" | tar xzf - -C /tmp/
                                    tar czf - -C /tmp/ $file | ssh $user@$host "tar xzf - -C /home/$user/"
                                    rm -rf /tmp/$file
                                else
                                    scp $source_user@$source_host:$current_dir/$file /tmp/
                                    scp /tmp/$file $user@$host:/home/$user/
                                    rm /tmp/$file
                                fi
                            else
                                if [ -d "$current_dir/$file" ]; then
                                    tar czf - -C "$current_dir" "$file" | ssh $user@$host "tar xzf - -C /home/$user/"
                                else
                                    scp "$current_dir/$file" $user@$host:/home/$user/
                                fi
                            fi
                            echo "Fisierul/directorul $file a fost copiat in /home/$user."
                            break
                        else
                            echo "Numar invalid."
                        fi
                        ;;
                    2)
                        echo "Directoare disponibile:"
                        awk '$1 ~ /^d/ {print NR-1 ") " $NF}' tmp_ls_output
                        last_index=$(awk 'END{print NR-1}' tmp_ls_output)
                        next_index=$((last_index + 1))
                        echo "$next_index) .."
                        read -p "Introduceti numarul directorului: " dir_number
                        if [ "$dir_number" -eq "$next_index" ]; then
                            current_dir=$(dirname "$current_dir")
                        else
                            dir=$(awk -v num=$((dir_number + 1)) '$1 ~ /^d/ && NR==num {print $NF}' tmp_ls_output)
                            if [ -n "$dir" ]; then
                                current_dir="$current_dir/$dir"
                            else
                                echo "Numar invalid."
                            fi
                        fi
                        ;;
                    3)
                        break
                        ;;
                    *)
                        echo "Optiune invalida."
                        ;;
                esac
            done
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

