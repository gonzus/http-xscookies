first: tables.h

#-----------

CFLAGS += -Wall -I..

encode.o: encode.c
	cc $(CFLAGS) -c -o$@ $^

encode: encode.o
	cc -Wall -o$@ $^

tables.h: encode
	./encode > tables.h

clean:
	rm -f encode.o
	rm -f encode
	rm -f tables.h
