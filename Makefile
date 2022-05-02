
gitport = bin/gitport
gitport_SRC = c_src/gitport.c
gitport_SRC_O = c_src/gitport.o
gitport_LIBS = -lgit2

size = bin/size
size_SRC = c_src/size.c
size_SRC_O = c_src/size.o
size_LIBS =

PROGS = ${gitport} ${size}

all: ${PROGS}

${gitport}: ${gitport_SRC_O}
	${CC} ${CFLAGS} ${LDFLAGS} ${gitport_SRC_O} ${gitport_LIBS} -o ${gitport}

${size}: ${size_SRC_O}
	${CC} ${CFLAGS} ${LDFLAGS} ${size_SRC_O} ${size_LIBS} -o ${size}

.c.o:
	${CC} ${CPPFLAGS} ${CFLAGS} -c $< -o $@

clean:
	rm -f c_src/*.o ${PROGS}

.PHONY: all clean
