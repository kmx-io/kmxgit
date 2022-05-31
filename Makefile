CFLAGS = -W -Wall -Werror -O0 -DDEBUG -ggdb
CPPFLAGS = -I/usr/local/include -I/usr/local/lib/erlang24/usr/include
LDFLAGS = -L/usr/local/lib

git_nif = bin/libgit_nif.so
git_nif_SRC = c_src/git_nif.c
git_nif_SRC_O = c_src/git_nif.o
git_nif_LIBS = -lgit2

PROGS = ${git_nif}

all: ${PROGS}

${git_nif}: ${git_nif_SRC_O}
	${CC} -fPIC -shared ${LDFLAGS} ${git_nif_SRC_O} ${git_nif_LIBS} -o ${git_nif}

.c.o:
	${CC} ${CPPFLAGS} ${CFLAGS} -c $< -o $@

clean:
	rm -f c_src/*.o ${PROGS}

.PHONY: all clean
