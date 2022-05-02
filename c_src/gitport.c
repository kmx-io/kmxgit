#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <git2.h>

typedef int (*f_fun) (int argc, const char **argv);

typedef struct fun {
  const char *name;
  f_fun fun;
} s_fun;

int branches (int argc, const char **argv)
{
  const char *path;
  git_repository **r = malloc(sizeof(void*));
  git_branch_iterator **i = malloc(sizeof(void*));
  git_reference **ref = malloc(sizeof(void*));
  git_branch_t *ref_type = malloc(sizeof(git_branch_t));
  const char **branch = malloc(sizeof(void*));
  fprintf(stderr, "branches %d\n", argc);
  if (argc != 1 || !argv || !argv[1])
    goto error;
  path = argv[1];
  if (git_repository_open(r, path))
    goto error;
  git_branch_iterator_new(i, *r, GIT_BRANCH_ALL);
  while (!git_branch_next(ref, ref_type, *i)) {
    git_branch_name(branch, *ref);
    fprintf(stderr, " %s", *branch);
    printf(" %s", *branch);
  }
  git_branch_iterator_free(*i);
  free(i);
  free(r);
  free(ref);
  free(ref_type);
  free(branch);
  fprintf(stderr, "\n");
  printf("\n");
  fflush(stdout);
  return 0;
 error:
  fprintf(stderr, "error\n");
  printf("error\n");
  free(i);
  free(r);
  free(ref);
  free(ref_type);
  free(branch);
  return 1;
}

s_fun g_fun[] = {
  {"branches", branches},
  {NULL, NULL}
};

f_fun find_fun (const char *name)
{
  s_fun *f = g_fun;
  while (f->name && strcmp(name, f->name))
    f++;
  if (f->name)
    return f->fun;
  return NULL;
}

int repl (FILE *in)
{
  int ret = 0;
  int run = 1;
  ssize_t size = 1024;
  char *line = malloc(size);
  int argc;
  char **argv = malloc(sizeof(char*) * 16);
  char *argvp;
  f_fun f = NULL;
  if (!line)
    return -1;
  while (1) {
    size = getline(&line, &size, in);
    if (size < 0)
      break;
    if (size == 0)
      continue;
    line[size - 1] = 0;
    argvp = line;
    argc = 0;
    while ((argv[argc] = strsep(&argvp, " ")))
      argc++;
    argc--;
    if ((f = find_fun(argv[0]))) {
      f(argc, (const char **) argv);
    }
  }
  free(line);
  return ret;
}

int main (int argc, char **argv)
{
  fprintf(stderr, "gitport started\n");
  git_libgit2_init();
  repl(stdin);
  git_libgit2_shutdown();
  fprintf(stderr, "gitport exiting\n");
  return 0;
}
