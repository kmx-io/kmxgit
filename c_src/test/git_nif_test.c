#include <stdio.h>
#include <string.h>
#include <erl_nif.h>
#include <git2.h>
#include "mstr.h"

ERL_NIF_TERM branches_nif (ErlNifEnv *env, int argc,
                      const ERL_NIF_TERM argv[]);
ERL_NIF_TERM content_nif (ErlNifEnv *env, int argc,
                      const ERL_NIF_TERM argv[]);
ERL_NIF_TERM create_nif (ErlNifEnv *env, int argc,
                      const ERL_NIF_TERM argv[]);
ERL_NIF_TERM diff_nif (ErlNifEnv *env, int argc,
                      const ERL_NIF_TERM argv[]);
ERL_NIF_TERM files_nif (ErlNifEnv *env, int argc,
                      const ERL_NIF_TERM argv[]);
ERL_NIF_TERM log_nif (ErlNifEnv *env, int argc,
                      const ERL_NIF_TERM argv[]);
ERL_NIF_TERM tags_nif (ErlNifEnv *env, int argc,
                      const ERL_NIF_TERM argv[]);

int load (ErlNifEnv *env, void **a, ERL_NIF_TERM b);

ERL_NIF_TERM
test (const char *test_name,
      ERL_NIF_TERM (*fun) (ErlNifEnv *env,
                           int argc,
                           const ERL_NIF_TERM argv[]),
      const ERL_NIF_TERM argv[])
{
  int argc = 0;
  int i = 0;
  ERL_NIF_TERM res = 0;
  while (argv[argc])
    argc++;
  res = fun(NULL, argc, argv);
  printf("%s(", test_name);
  if (argv[i]) {
    printf("%s", argv[i++]);
    while (argv[i])
      printf(", %s", argv[i++]);
  }
  printf(") => %s\n", res);
  return res;
}

int main (int argc, char **argv)
{
  char *repo = "priv/git/kmx.io/kmxgit.git";
  char *content_sha1 = "7ad943b223f99c79746386c2b57d32ba6e889e2c";
  char *diff_from = "v0.2.0";
  char *diff_to = "v0.3.0";
  char *tree = "v0.2";
  char *revspec_single = "^edf1fbc96f1efb9b9acafa998b5b4c4a4361bf34";
  char *dir = "lib/kmxgit";
  int i = 0;
  libmstr_init();
  load(NULL, NULL, NULL);
  if (argc < 2 || !strcmp(argv[1], "branches")) {
    test("branches", branches_nif, (const char *[]) {
            repo, NULL});
  }
  if (argc < 2 || !strcmp(argv[1], "content")) {
    test("content", content_nif, (const char *[]) {
            repo, content_sha1, NULL});
  }
  if (argc < 2 || !strcmp(argv[1], "create")) {
    test("create", create_nif, (const char *[]) {
            "test_git_nif_create", NULL});
    test("create_error", create_nif, (const char *[]) {
            "..", NULL});
  }
  if (argc < 2 || !strcmp(argv[1], "diff")) {
    test("diff", diff_nif, (const char *[]) {
            repo, diff_from, diff_to, NULL});
  }
  if (argc < 2 || !strcmp(argv[1], "files")) {
    test("files", files_nif, (const char *[]) {
            repo, tree, dir, NULL});
    test("files_blob", files_nif, (const char *[]) {
            repo, tree, "README.md", NULL});
  }
  if (argc < 2 || !strcmp(argv[1], "log")) {
    test("log", log_nif, (const char *[]) {
            repo, tree, ".", "0", "100", NULL});
    test("log_revspec_single", log_nif, (const char *[]) {
            repo, revspec_single, ".", "0", "100", NULL});
  }
  if (argc < 2 || !strcmp(argv[1], "tags")) {
    test("tags", tags_nif, (const char *[]) {
            repo, NULL});
  }
  if (argc < 2 || !strcmp(argv[1], "loop")) {
    for (i = 0; i < 2; i++) {
      test("branches_loop", branches_nif, (const char *[]) {
              "priv/git/kmx.io/git-auth.git", NULL});
      test("files_loop", files_nif, (const char *[]) {
              "priv/git/kmx.io/git-auth.git", "master","", NULL});
      test("content_loop", content_nif, (const char *[]) {
              "priv/git/kmx.io/git-auth.git",
              "47232bf062f109330b6ad8cacdc329285d9d2ce3", NULL});
    }
  }
  git_libgit2_shutdown();
  libmstr_shutdown();
  fflush(stdout);
  return 0;
}
