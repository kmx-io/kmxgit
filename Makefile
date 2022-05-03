
CFLAGS = -W -Wall -Werror
CPPFLAGS = -I/usr/local/include -I/usr/local/lib/erlang24/usr/include
LDFLAGS = -L/usr/local/lib -L/usr/local/lib/erlang24/usr/lib

git_nif = bin/libgit_nif.so
git_nif_SRC = c_src/git_nif.c
git_nif_SRC_O = c_src/git_nif.o
git_nif_LIBS = -lgit2

size = bin/size
size_SRC = c_src/size.c
size_SRC_O = c_src/size.o
size_LIBS =

PROGS = ${git_nif} ${size}

all: ${PROGS}

${git_nif}: ${git_nif_SRC_O}
	${CC} -fPIC -shared ${LDFLAGS} ${git_nif_SRC_O} ${git_nif_LIBS} -o ${git_nif}

${gitport}: ${gitport_SRC_O}
	${CC} ${CFLAGS} ${LDFLAGS} ${gitport_SRC_O} ${gitport_LIBS} -o ${gitport}

${size}: ${size_SRC_O}
	${CC} ${CFLAGS} ${LDFLAGS} ${size_SRC_O} ${size_LIBS} -o ${size}

.c.o:
	${CC} ${CPPFLAGS} ${CFLAGS} -c $< -o $@

clean:
	rm -f c_src/*.o ${PROGS}

.PHONY: all clean
