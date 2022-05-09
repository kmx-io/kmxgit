#include <erl_nif.h>
#include <git2.h>
#include <stdlib.h>
#include <string.h>

char * enif_term_to_string (ErlNifEnv *env, const ERL_NIF_TERM term)
{
  ErlNifBinary bin;
  unsigned len;
  char *str;
  switch (enif_term_type(env, term)) {
  case ERL_NIF_TERM_TYPE_BITSTRING:
    enif_inspect_binary(env, term, &bin);
    len = bin.size;
    str = malloc(len + 1);
    memcpy(str, bin.data, len);
    str[len] = 0;
    return str;
  case ERL_NIF_TERM_TYPE_LIST:
    enif_get_list_length(env, term, &len);
    str = malloc(len + 1);
    enif_get_string(env, term, str, len + 1, ERL_NIF_LATIN1);
    return str;
  default:
    return NULL;
  }
}

ERL_NIF_TERM enif_string_to_term (ErlNifEnv *env, const char *str)
{
  size_t len = strlen(str);
  ErlNifBinary bin;
  enif_alloc_binary(len, &bin);
  memcpy(bin.data, str, len);
  return enif_make_binary(env, &bin);
}

ERL_NIF_TERM push_string (ErlNifEnv *env, const char *str, const ERL_NIF_TERM acc)
{
  ERL_NIF_TERM term = enif_string_to_term(env, str);
  return enif_make_list_cell(env, term, acc);
}

static ERL_NIF_TERM branches (ErlNifEnv *env, int argc,
                              const ERL_NIF_TERM argv[])
{
  git_repository *r = NULL;
  git_branch_iterator *i = NULL;
  git_reference *ref = NULL;
  git_branch_t ref_type = 0;
  const char *branch = NULL;
  char *repo = NULL;
  ERL_NIF_TERM acc;
  ERL_NIF_TERM branches;
  ERL_NIF_TERM ok;
  if (argc != 1 || !argv || !argv[0])
    goto error;
  repo = enif_term_to_string(env, argv[0]);
  if (!repo || !repo[0])
    goto error;
  if (git_repository_open(&r, repo))
    goto error;
  git_branch_iterator_new(&i, r, GIT_BRANCH_ALL);
  acc = enif_make_list(env, 0);
  while (!git_branch_next(&ref, &ref_type, i)) {
    git_branch_name(&branch, ref);
    acc = push_string(env, branch, acc);
  }
  git_branch_iterator_free(i);
  ok = enif_make_atom(env, "ok");
  if (! enif_make_reverse_list(env, acc, &branches))
    goto error;
  git_repository_free(r);
  free(repo);
  return enif_make_tuple2(env, ok, branches);
 error:
  git_repository_free(r);
  free(repo);
  return enif_make_atom(env, "error");
}

static ERL_NIF_TERM content (ErlNifEnv *env, int argc,
                             const ERL_NIF_TERM argv[])
{
  ErlNifBinary bin;
  git_blob *blob = NULL;
  ERL_NIF_TERM content;
  const void *data = NULL;
  git_oid oid = {0};
  ERL_NIF_TERM ok;
  git_repository *r = NULL;
  char *repo = NULL;
  char *sha = NULL;
  git_object_size_t size = 0;
  if (argc != 2 || !argv || !argv[0] || !argv[1])
    goto error;
  repo = enif_term_to_string(env, argv[0]);
  if (!repo || !repo[0])
    goto error;
  sha = enif_term_to_string(env, argv[1]);
  if (!sha || !sha[0])
    goto error;
  if (git_repository_open(&r, repo))
    goto error;
  if (git_oid_fromstr(&oid, sha))
    goto error;
  if (git_blob_lookup(&blob, r, &oid))
    goto error;
  size = git_blob_rawsize(blob);
  data = git_blob_rawcontent(blob);
  enif_alloc_binary(size, &bin);
  memcpy(bin.data, data, size);
  content = enif_make_binary(env, &bin);
  ok = enif_make_atom(env, "ok");
  git_repository_free(r);
  free(repo);
  free(sha);
  return enif_make_tuple2(env, ok, content);
 error:
  git_repository_free(r);
  free(repo);
  free(sha);
  return enif_make_atom(env, "error");
}

static ErlNifFunc funcs[] = {
  {"branches_nif", 1, branches, 0},
  {"content_nif", 2, content, 0},
};

int load (ErlNifEnv *env, void **a, ERL_NIF_TERM b)
{
  (void) env;
  (void) a;
  (void) b;
  fprintf(stderr, "git_nif load\n");
  git_libgit2_init();
  return 0;
}

void unload (ErlNifEnv *env, void *a)
{
  (void) env;
  (void) a;
  git_libgit2_shutdown();
  fprintf(stderr, "git_nif unload\n");
}

ERL_NIF_INIT(Elixir.Kmxgit.Git, funcs, load, NULL, NULL, unload);
