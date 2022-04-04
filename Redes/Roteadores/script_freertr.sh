#!/bin/bash

## Este script serve para rodar varias instancias do freertr que esteja num mesmo diretorio usando tmux...
## Eh possivel configurar o diretorio dos arquivos, do freertr.jar, alem de prefixo e sufixo dos arquivos de configuracao
## Entretanto os arquivos devem obdecer a numeracao... por exemplo: r1-hw.txt e r1-sw.txt
## Outro exemplo : h10-hardware.txt e s10-software.txt ....
## by Heitor Schulz


##Default RTR and HWSW, uncomment to set 
RTR=rtr.jar
HWSW=dynamic/
##HWSW=static/
HW_prefix="r"
SW_prefix="r"
HW_suffix="-hw.txt"
SW_suffix="-sw.txt"

Clock=0

usage() { echo "Usage: $0 [-r <FreeRouter JAR path>] [-d <HW and SW Files path/dir> ]" 1>&2;
echo "Usage: $0 [-h ] for more help" 1>&2; exit 1; }

kill_routers(){
    tmux kill-session -t FREERTR;
    # or use tmux kill-server (but this will kill all tmux sessions)
    exit 0;
}

help_script(){
    echo "Usage:" 1>&2;
    echo "  $0 [no args/param] will run with default JAR and HW/SW path in script" 1>&2;
    echo "  $0 [-r <FreeRouter JAR path>] Set FreeRTR Path " 1>&2;
    echo "  $0 [-d <HW and SW Files path/dir>] Set HW and SW router path to load" 1>&2;
    echo "  $0 [-c] Enable a clock on terminal" 1>&2;
    echo "  $0 [-k] kill tmux session / All Routers." 1>&2;
    echo "  $0 [-h] show more info." 1>&2;
    exit 0;
}

set_clock_true(){
    echo "Clock enabled..."
    Clock=$((1))
}

check_hw_sw_files(){

    HW_file=$1
    SW_file=$2

    if [ ! -f $HW_file ];
    then
        echo "HW conf file not found... :$HW_file"
        tmux kill-session -t FREERTR;
        exit 3
    fi

    if [ ! -f $SW_file ];
    then
        echo "SW conf file not found... :$HW_file"
        tmux kill-session -t FREERTR;
        exit 3
    fi
}

# Read flags
# Example: https://stackoverflow.com/questions/11279423/bash-getopts-with-multiple-and-mandatory-options
options='r:d:chk'
while getopts $options flag
do
    case "${flag}" in
        r) RTR=${OPTARG};;
        d) HWSW=${OPTARG};;
        c) set_clock_true;;
        h) help_script;;
        k) kill_routers;;
        *) usage;;
    esac
done

HW_files_count=$(ls $HWSW | grep -e $HW_suffix | wc -l) 
SW_files_count=$(ls $HWSW | grep -e $SW_suffix | wc -l)

initial_conf() {
    echo "Initial configuration and verification..."
    #Verify if RTR and HWSW are set
    if [ -z "${RTR}" ] || [ -z "${HWSW}" ]; then
        usage
    fi

    #Testing HW/SW dir and rtr path...
    if [ ! -d $HWSW ];
    then
        echo "HW / SW dir not found..."
        echo "HW / SW path: $HWSW";
        exit 3
    fi

    if [ ! -f $RTR ];
    then
        echo "RTR jar not found..."
        echo "RTR path: $RTR";
        exit 3
    fi

    #Verify if all HW conf files have an SW conf file.
    if (( $HW_files_count != $SW_files_count ))
    then
        echo "Error: HW_files_count:$HW_files_count != SW_files_count: $SW_files_count"
        exit 3
    else
        echo "Ok, HW_files_count: $HW_files_count == SW_files_count: $SW_files_count"
       
    fi
}

start_routers(){
    echo "Creating tmux panels..."
    if (($Clock))
    then
        #run tmux
        tmux new-session -d -s FREERTR >/dev/null

        tmux rename-window -t FREERTR:0 'main'
        tmux splitw -h -p 90 -t FREERTR:0.0
        
        let n=$HW_files_count
        for ((i = 1; i < $HW_files_count; i++ ));
        do
            let divisor=$((100 - 100/n))
            n=$((n-1))
            tmux splitw -v -p $(($divisor)) -t FREERTR:0.$(($i));
        done

        #echo "----------------------------------------"
        echo "Starting routers..."
        for ((i = 1; i <= $HW_files_count; i++ )); 
        do
            HW_file="$HWSW$HW_prefix$i$HW_suffix"
            SW_file="$HWSW$SW_prefix$i$SW_suffix"

            check_hw_sw_files $HW_file $SW_file

            tmux send-keys -t FREERTR:0.$(($i)) "java -jar $RTR routersc $HW_file $SW_file" Enter;
        done

        tmux send-keys -t FREERTR:0.0 'tmux clock -t FREERTR:0.0' Enter;
        tmux select-pane -t FREERTR:0.$(($HW_files_count));

    else
        #run tmux
        tmux new-session -d -s FREERTR >/dev/null
        tmux rename-window -t FREERTR:0 'main'

        let n=$HW_files_count
        for ((i = 0; i < $HW_files_count-1; i++ ));
        do
            let divisor=$((100 - 100/n))
            n=$((n-1))
            tmux splitw -v -p $(($divisor)) -t FREERTR:0.$(($i));
        done

        echo "Starting routers..."
        for ((i = 1; i <= $HW_files_count; i++ )); 
        do 
            HW_file="$HWSW$HW_prefix$i$HW_suffix"
            SW_file="$HWSW$SW_prefix$i$SW_suffix"

            check_hw_sw_files $HW_file $SW_file

            tmux send-keys -t FREERTR:0.$(($i-1)) "java -jar $RTR routersc $HW_file $SW_file" Enter;
        done
    fi

    # if (($HW_files_count > 5))
    # then
    #     tmux select-layout tiled
    # fi

    tmux select-layout tiled

    echo "Done."
}

open_tmux(){
    echo -ne "Opening tmux in 3.."
    sleep 1
    echo -ne "2.."
    sleep 0.6
    echo -ne "1.."
    sleep 0.6
    tmux a -t FREERTR
}

initial_conf
start_routers
open_tmux
