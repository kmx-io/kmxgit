CFLAGS = -std=c89 -W -Wall -Werror -DDEBUG -ggdb
ASAN_CFLAGS = ${CFLAGS} -fsanitize=address -O1 -fno-omit-frame-pointer -g
COV_CFLAGS = ${CFLAGS} -ftest-coverage -fprofile-arcs

CPPFLAGS = -I.. -I./include -D _GNU_SOURCE

LDFLAGS =
ASAN_LDFLAGS = ${LDFLAGS} -fsanitize=address -O1 -fno-omit-frame-pointer -g
COV_LDFLAGS = ${LDFLAGS}

git_nif_test_SRC = \
	enif_fake_src.c \
	git_nif_test.c \
	git_nif.c \
	mstr.c

git_nif_test = git_nif_test
git_nif_test_OBJ = $(git_nif_test_SRC:.c=.o)

git_nif_test_asan = git_nif_test_asan
git_nif_test_asan_OBJ = $(git_nif_test_SRC:.c=.asan.o)

git_nif_test_cov = git_nif_test_cov
git_nif_test_cov_OBJ = $(git_nif_test_SRC:.c=.cov.o)

PROGS = ${git_nif_test} ${git_nif_test_cov} ${git_nif_test_asan}
CLEANFILES = *.o ${PROGS}

all: ${PROGS}

.SUFFIXES: .asan.o .cov.o

.c.asan.o:
	${CC} ${CPPFLAGS} ${ASAN_CFLAGS} -c $< -o $@

.c.cov.o:
	${CC} ${CPPFLAGS} ${COV_CFLAGS} -c $< -o $@

${git_nif_test}: ${git_nif_test_OBJ}
	${CC} ${CFLAGS} ${CPPFLAGS} ${LDFLAGS} ${git_nif_test_OBJ} ${LIBS} -o ${git_nif_test}

${git_nif_test_asan}: ${git_nif_test_asan_OBJ}
	${CC} ${ASAN_CFLAGS} ${CPPFLAGS} ${ASAN_LDFLAGS} ${git_nif_test_asan_OBJ} ${LIBS} -o ${git_nif_test_asan}

${git_nif_test_cov}: ${git_nif_test_cov_OBJ}
	${CC} ${CFLAGS} ${COV_CFLAGS} ${CPPFLAGS} ${COV_LDFLAGS} ${git_nif_test_cov_OBJ} ${LIBS} -o ${git_nif_test_cov}

CLEANFILES += coverage.* *.gcda *.gcno *.gcov *.gcov.txt *.gcov.html

clean:
	rm -f ${CLEANFILES}

.PHONY: all clean

include ../../config.mk
