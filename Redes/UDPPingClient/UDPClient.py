## Lohayne Malavasi Camillo
## T2 - Projeto de programação de sockets - UDP Pinger
## Redes de Computadores

from socket import *
from functionsUDP import *
import sys
import datetime

IP_SERV = "200.137.66.110" # Endereco IP do Servidor
PORT_SERV = 30000 # Porta que o Servidor esta

#IP_SERV = '127.1.1.0' # Endereco IP do Servidor
#PORT_SERV = 30000 # Porta que o Servidor esta

msgClient = "LohayneCamillo" # Mensagem do cliente (max 30 char)
codPing = 0 # ping = 0; pong = 1

#Mensagem deve conter ate 30 char
if len(msgClient) > 30:
    print("Mensagem muito grande!")
    sys.exit()



#Verifica a criação do socket
try:
    udp = socket(AF_INET, SOCK_DGRAM)
except socket.error as err:
    print ("socket creation failed with error %s" %(err))
    sys.exit()

# Variaveis necessarias para contagem
counter = 10 # Limite de pings
i = 0 # Contador de pings
listTime =[] # Lista com rtts verificados
pcktsRec = 0
pcktsCheck = 0



while i < counter:
    i+=1
    #Pega o tempo inicial para envio da mensagem
    initialTime = int(str(datetime.datetime.now())[20:24]) 
    '''
    Cria a mensagem completa com com o formato:
    000XX -> número da mensagem
    0 -> byte determinando ping ou pong
    0000 -> marcacao de tempo
    Msg (0..30) -> Mensagem enviada pelo cliente
    '''
    msgComplete = f"{str(i).zfill(5)}{codPing}{str(initialTime).zfill(4)}{msgClient}"

    udp.sendto((msgComplete.encode()), (IP_SERV,PORT_SERV))

    udp.settimeout(1+initialTime/10000) #Faz um timeout aleatório entre 1 e 2

    try:
        modifiedMessage,serverAddress = udp.recvfrom(1024)

        finalTime = int(str(datetime.datetime.now())[20:24]) # Pega o tempo final
        
        if finalTime < initialTime:
            elapseTime = ((finalTime - initialTime)+10000)/10 #Caso tenha "overflow" no tempo
        else: 
            elapseTime = (finalTime - initialTime)/10 # Calcula o rtt com base nos tempos iniciais e finais

        listTime.append(elapseTime) # Adiciona o valor do tempo na lista para calculo das estatisticas

        pcktsRec+=1 # Incrementa 1 a quantidade de pacotes transmitidos

        ver = treatErrors(modifiedMessage, msgComplete, elapseTime)

        if ver == 0:
            pcktsCheck+=1

    except timeout:
        print(f"Tentativa {i} com falha de timeout!")

if pcktsRec != 0:
    statisticNumbers(listTime, pcktsRec, pcktsCheck, counter)
    print("Finish")



