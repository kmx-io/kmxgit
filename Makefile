CFLAGS = -std=c89 -W -Wall -Werror -O0 -ggdb -fPIC
CPPFLAGS = -I./c_src -I/usr/local/lib/erlang24/usr/include -DDEBUG
LDFLAGS = -shared

git_nif = priv/libgit_nif.so
git_nif_SRC = \
	c_src/git_nif.c \
	c_src/enif.c
git_nif_SRC_O = \
	c_src/git_nif.o \
	c_src/enif.o

PROGS = ${git_nif}

all: ${PROGS}

${git_nif}: ${git_nif_SRC_O}
	${CC} ${CFLAGS} ${LDFLAGS} ${git_nif_SRC_O} -o ${git_nif} ${LIBS}

.c.o:
	${CC} ${CPPFLAGS} ${CFLAGS} -c $< -o $@

clean:
	rm -f c_src/*.o ${PROGS}
	${MAKE} -C c_src/test/ clean
	rm -rf test_git_nif_create

test:
	${MAKE} -C c_src/test/

.PHONY: all clean test

include config.mk
