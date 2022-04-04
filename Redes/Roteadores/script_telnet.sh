#!/bin/bash

## Este script serve para rodar varias instancias do telnet usando tmux...
## Deve-se fazer a numeracao de portas de forma sequencial, devendo ser informado a porta inicial e a quantidade de telnets desejados...
## Exemplo com 5 roteadores: o primeiro roteador esta na porta 5001... entao a porta inicial eh 5000 e a quantidade eh 5
## nas variaveis PORT=5000; QTD = 5;
## by Heitor Schulz

##Default inital conf 
PORT=5000 #port
QTD=4 #number of routers
Address="127.0.0.1" #or localhost...
watch=0 #set 1 will run watch mode on ipv4 route table in all routers

usage() { echo "Usage: $0 [-p <Initial Port number>] [-q <quantity of routers>]" 1>&2;
echo "Usage: $0 [-h ] for more help" 1>&2; exit 1; }

kill_telnet(){
    tmux kill-session -t TELNETS;
    # or
    #tmux kill-server
    exit 0;
}

help_script(){
    echo "Usage:" 1>&2;
    echo "  $0 [no args/param] will run with default port and qtd in script" 1>&2;
    echo "  $0 [-p <Initial Port number>] Define a start port" 1>&2;
    echo "  $0 [-q <quantity of routers>] Total of routers [the ports will be the start port + n]" 1>&2;
    echo "  $0 [-w] watch ipv4 route table" 1>&2;
    echo "  $0 [-k] kill tmux session." 1>&2;
    echo "  $0 [-h] show more info." 1>&2;
    echo "          For example: Inital port:26000, QTD = 3"
    echo "          The ports will be 26000+1=26001, 26000+2=26002, ..."
    exit 0;
}

set_watch_true(){
    echo "Watch ipv4 route table enabled..."
    watch=$((1))
}

# Read flags
# Example: https://stackoverflow.com/questions/11279423/bash-getopts-with-multiple-and-mandatory-options
options='p:q:whk'
while getopts $options flag
do
    case "${flag}" in
        p) PORT=${OPTARG};;
        q) QTD=${OPTARG};;
        w) set_watch_true;;
        h) help_script;;
        k) kill_telnet;;
        *) usage;;
    esac
done

initial_conf() {
    #Verify if PORT and QTD are set
    echo "Checking initial confs..."
    if [ -z "${PORT}" ] || [ -z "${QTD}" ]; then
        usage
    fi
}

start_telnet(){

    echo "Creating tmux panels..."
    #run tmux
    tmux new-session -d -s TELNETS >/dev/null
    tmux rename-window -t TELNETS:0 'main'

    let n=$QTD
    
    for ((i = 0; i < $QTD-1; i++ ));
    do
        let divisor=$((100 - 100/n))
        n=$((n-1))
        tmux splitw -v -p $(($divisor)) -t TELNETS:0.$(($i));
    done

    echo "Starting telnets..."
    for ((i = 1; i <= $QTD; i++ )); 
    do
        let port_n=$((PORT + i))
        tmux send-keys -t TELNETS:0.$(($i-1)) "telnet "$Address" $(($port_n))" Enter;
        if (($watch))
        then
            tmux send-keys -t TELNETS:0.$(($i-1)) "watch ipv4 route v1" Enter;
        fi
    done
    
    # if (($QTD > 5))
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
    tmux a -t TELNETS
}

initial_conf
start_telnet
open_tmux
