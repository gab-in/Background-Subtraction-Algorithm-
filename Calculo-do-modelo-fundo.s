.data
    entrada:    
        .asciiz "file00026.pgm"
        .asciiz "file00031.pgm"
        .asciiz "file00036.pgm"
        .asciiz "file00041.pgm"
        .asciiz "file00046.pgm"
        .asciiz "file00051.pgm"
        .asciiz "file00056.pgm"
        .asciiz "file00061.pgm"
        .asciiz "file00066.pgm"
        .asciiz "file00071.pgm"
        .asciiz "file00076.pgm"
        .asciiz "file00081.pgm"
        .asciiz "file00086.pgm"
        .asciiz "file00091.pgm"
        .asciiz "file00096.pgm"
        .asciiz "file00101.pgm"
        .asciiz "file00106.pgm"
        .asciiz "file00111.pgm"
        .asciiz "file00116.pgm"
        .asciiz "file00121.pgm"
        .asciiz "file00126.pgm"
        .asciiz "file00131.pgm"
        .asciiz "file00136.pgm"
        .asciiz "file00141.pgm"
        .asciiz "file00146.pgm"
        .asciiz "file00151.pgm"
        .byte 0                 		#Determina que acabou os arquivos

    saida:      .asciiz "saida.pgm"		#Arquivo de saída
    buffer:     .space 85000     		#Ponteiro para o arquivo, com espaço de sobra para o cabeçalho
    
    .align 2					#Garantia de alinhamento para o acumulador (Não questione, já deu problema antes)
    acumulador: .space 337920    		#(352x240)*4 porque queremos que cada pixel seja visto como uma palavra de 4 bytes
    cabecalho:     .ascii "P5\n352 240\n255\n"  	#Cabeçalho fixo, 15 bytes nesse caso

.text
#Inicialização de coisas básicas
la $t0, acumulador		#Endereço do Acumulador  (A base de tudo
li $t1, 0			#Inicializa o contador com 0
li $t2, 84480        		#Guarda o tamanho total do arquivo (352x240)

#Inicializa o vetor de acumualação com 0 em todos os espaços
acumuladorLimpo:
    sw $zero, 0($t0)		#$t0 guarda o espaço de memória onde fica o vetor de acumulação
    addi $t0, $t0, 4		#4 bytes para 1 palavra de máquina
    addi $t1, $t1, 1		#Soma 1 no contador para comparar depois com o tanto de pixels tem afinal de contas
    blt $t1, $t2, acumuladorLimpo#Começa o loop de novo

    la $s0, entrada        	#Pega o endereço dos arquivos
    li $s2, 0              	#Contador de arquivos

#Aqui começa a história que surgiu lá atrás de abrir os arquivos 1 a 1, mas em loop
loopArquivos:
    lb $t0, 0($s0)		#Endereço do arquivo em especifico
    beqz $t0, preparaSaida	#CASO BASE: Todos os arquivos foram lidos e encontramos o 0 presente no final de "entrada"

    #Abre o arquivo
    li $v0, 13			#13 (faz o L) abre o arquivo
    move $a0, $s0		#Endereço do arquivo a ser aberto
    li $a1, 0              	#0 Modo de leitura
    syscall			#executa
    bltz $v0, proximoArquivo  	#syscall 13 retorna -1 se der erro na abertura, então aqui ele pula para o próximo arquivo se 1 der problema
    move $s3, $v0		#$s3 recebe o endereço com o conteúdo do arquivo aberto

    #Ler arquivo!!!!
    li $v0, 14			#14 Codigo de leitura
    move $a0, $s3		#Endereço do conteúdo
    la $a1, buffer		#Fala para colocar tudo no buffer
    li $a2, 85000		#Fala o tamanho que dá para por
    syscall			#executa

    #Fecha o arquivo
    li $v0, 16			#16 Codigo para fechar o arquivo
    move $a0, $s3		#Endereço do arquivo para fechar
    syscall			#executa

#Vamos pular o cabeçalho agora, ele vai tentar achar 3 "\n"
la $t1, buffer			#$t1 acessa o buffer
li $t5, 0              		#Contador de \n
pularCabecalho:
    lb $t2, 0($t1)		#Carrega o byte atual
    addi $t1, $t1, 1		#Vai para o próximo byte já
    bne $t2, 10, pularCabecalho	#byte 10 = "\n" em binário
    addi $t5, $t5, 1		#Se for "\n" mesmo tem que adicionar de volta, mas ainda podem ter mais depois
    blt $t5, 3, pularCabecalho	#São 3 "\n" no total desse cabeçalho

#Começa a somar os valores encontrador
la $t2, acumulador		#Endereço do acumulador
li $t3, 0              		#Contador de pixel
addi $t1, $t1, -1      		#A última função desloca 1 a mais do que o necessário nas verificações, isso aqui corrige isso
lerSomarPixels:
    bge $t3, 84480, proximoArquivo  	#352x240=84480 pixels, é a condição de parada do loop
    lb $t4, 0($t1)         	#Le o byte atual para $t4
    andi $t4, $t4, 0xFF    	# Unsigned extend // Ainda não sei o que diabos isso aqui faz
    lw $t5, 0($t2)         	#Pega o valor total da soma 
    add $t5, $t5, $t4      	#Soma o valor total até agora com o byte atual
    sw $t5, 0($t2)         	#Guarda de volta
    addi $t1, $t1, 1       	#Pega o próximo byte
    addi $t2, $t2, 4       	#Pega a próxima soma acumulada
    addi $t3, $t3, 1       	#Conta +1 pixel
    j lerSomarPixels		#Reinicia o Loop

#De Facto vai para o próximo arquivo
proximoArquivo:
    lb $t0, 0($s0)		#lê o endereço do arquivo atual primeiramente, e vai incrementando
    addi $s0, $s0, 1		#Vê o próximo BYTE
    bnez $t0, proximoArquivo	#Se não é 0 (Ou seja, não terminou o nome do arquivo atual porque os arquivos estão sendo separados invisivelmente por 0's) vai para o próximo byte
    addi $s2, $s2, 1		#Eu confundi MEIA HORA essa merda com $t2 EU ODEIO O MIPS MARS EU ODEIO O MIPS MARS EU ODEIO O MIPS MARS, enfim isso aqui é a conta de quantos arquivos já foi
    j loopArquivos		#Começa o processo da soma de novo, pixel a pixel no novo arquivo

#Final do código yippieee
preparaSaida:
    beqz $s2, terminar       	 #Se $s2 tá em 0, nem carregou arquivo algum, então só fehca o programa
    #Arquivo de saída
    li $v0, 13			#Se o arquivo de saída ainda não existe, cria ele 
    la $a0, saida		#Endereço do arquivo
    li $a1, 1             	#Modo de escrita, se já existia arquivo antes só sobrescreve completamente
    syscall			#executa
    move $s3, $v0		#Salva o endereço do arquivo de saída
    #Escreve o cabeçalho
    li $v0, 15			#Se 13 abre, 14 lê, isso aqui certamente deve ser para escrever
    move $a0, $s3		#Anyway, ele pega o endereço do arquivo de saída
    la $a1, cabecalho		#Único lugar do código que a variável cabecalho é usada btw
    li $a2, 15            	#Cabeçalho tem 15 bytes de tamanho, então é isso que ele define aqui
    syscall

#Calcular médias e guarda finalmente
la $t0, acumulador		#Endereço do ACUMULADOR colocado em $t0
li $t1, 0             		#Contador dos pixels para usar em condição de saída de loop
la $t2, buffer        		#Reusa o buffer para colocar o output
calculaGuardaMedia:
    bge $t1, 84480, escreve	#Quando o contador chega ao valor máximo de pixels, sai do loop
    lw $t3, 0($t0)		#$t3 recebe pixel a pixel do acumulador que agora foi atualizado com todas as somas
    div $t3, $s2         	#Calcula média (Divide a soma acumulado pelo total de arquivos abertos)
    mflo $t3			#$t1 recebe o resultado dessa divisão
    
    #Garanatia do valor entre 0-256
    slti $t4, $t3, 0		#Teste de $t3 ser menor que 0
    beqz $t4, maiorQue256	#Se não for menor, vê se não passa de 256
    li $t3, 0			#Se for menor, deixa como 0
    maiorQue256:			
    	slti $t4, $t3, 256	#Teste se é menor que 256
    	bnez $t4, guardarValor	#Se for menor que 256, guarda
    	li $t3, 255
    #Guarda o valor hurdur
    guardarValor:
    	sb $t3, 0($t2)        	#Guarda o byte do valor 
    	addi $t0, $t0, 4	#Próxima palavra de byte do acumulador
    	addi $t2, $t2, 1	#Próximo byte do buffer
    	addi $t1, $t1, 1	#Incrementa contador
    	j calculaGuardaMedia	#Recomeça loop

#Escreve a média no arquivo
escreve:
    #Escreve o buffer modificado com as médias no arquivo
    li $v0, 15			#15 código de escrita
    move $a0, $s3		#Passa o endereço do arquivo de saida
    la $a1, buffer		#Endereço do buffer(Conteúdo a ser escrito)
    li $a2, 84480         	#Tamanho total de pixels que tem que escrever (352x240)
    syscall			#executa

    #Fecha o arquivo
    li $v0, 16			#16 código de fechar arquivo
    move $a0, $s3		#Endereço do arquivo para fechar
    syscall			#executa

#O programa terminou
terminar:
    li $v0, 10			#Codigo de saída
    syscall			#executa
