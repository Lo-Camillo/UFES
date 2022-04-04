## Lohayne Malavasi Camillo
## T2 - Projeto de programação de sockets - UDP Pinger
## Redes de Computadores

import statistics

def statisticNumbers(list, total, check, count):
    list.sort()

    pcktloss = ((count -  total)*100)/count
    pckterros = (total - check)

    print(f"{count} packets transmitted, {total} packets received, {pcktloss}% packet loss, {pckterros} packets with errors")
    print("time  %.1fms" % sum(list))

    print(f"rtt min -> {list[0]}ms")
    print(f"rtt avg -> %.1fms" % statistics.mean(list))
    print(f"rtt max -> {list[-1]}ms")
    print(f"rtt mdev -> %.1fms" % statistics.pstdev(list))

    return

def treatErrors(msgServer, msgClient, elapseTime):

    print(f"Enviada: {msgClient}")
    print(f"Resposta do servidor: {msgServer.decode()} \t Elapsed time = {elapseTime}ms", end="")
    #Tratamento de sequencia errada
    if msgServer.decode()[0:4] != msgClient[0:4]:
        print(" -> Erro no numero de sequência")

    #Tratamento de ping/pong errado
    elif msgServer.decode()[5] != "1":
        print(" -> Erro no controle ping/pong")

    #Tratamento de time errado
    elif msgServer.decode()[6:9] != msgClient[6:9]:
        print(" -> Erro no timestamp")

    #Tratamento mensagem errada
    elif msgServer.decode()[10:] != msgClient[10:]:
        print(" -> Erro na mensagem")
        
    else:
        print("", end="\n")
        return 0
    return 1
