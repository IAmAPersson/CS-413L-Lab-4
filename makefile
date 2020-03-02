ASM=as
LNK=gcc

lab1: source.s
	$(ASM) -o lab4.o source.s
	$(LNK) -o lab4 lab4.o -lwiringPi
