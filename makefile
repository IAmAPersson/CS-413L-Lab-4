ASM=as
LNK=gcc

lab1: source.s
	$(ASM) -o lab3.o source.s
	$(LNK) -o lab3 lab3.o -lwiringPi
