
PROG = size
SRC = size.c
SRC_O = size.o

all: ${PROG}

${PROG}: ${SRC_O}
	${CC} ${CFLAGS} ${LDFLAGS} ${SRC_O} ${LIBS} -o ${PROG}

.c.o:
	${CC} ${CPPFLAGS} ${CFLAGS} -c $< -o $@

clean:
	rm -f ${SRC_O} ${PROG}

.PHONY: all clean
