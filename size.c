/* size - truncate standard input by size */

#include <err.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>

#define BUFSIZE 8192

int usage(char *argv0)
{
  fprintf(stderr, "Usage: %s SIZE COMMAND [ARGS ...]\n", argv0);
  return 1;
}

int main (int argc, char **argv)
{
  char *a;
  char cmd[BUFSIZE];
  char *c = cmd;
  char buf[BUFSIZE];
  int i = 0;
  size_t pos = 0;
  ssize_t r;
  unsigned long size;
  FILE *pipe;
  size_t len;
  if (argc < 3)
    return usage(argv[0]);
  size = strtoul(argv[1], NULL, 10);
  for (i = 2; i < argc; i++) {
    a = argv[i];
    while ((*c++ = *a++))
      ;
    c--;
    *c++ = ' ';
  }
  *c = 0;
  pipe = popen(cmd, "w");
  len = pos + BUFSIZE < size ? BUFSIZE : size - pos;
  while (pos < size && (r = fread(buf, 1, len, stdin)) > 0) {
    if (fwrite(buf, r, 1, pipe) != 1)
      err(1, "fwrite");
    pos += r;
    len = pos + BUFSIZE < size ? BUFSIZE : size - pos;
  }
  if (r < 0)
      err(1, "fread");
  pclose(pipe);
  return 0;
}
