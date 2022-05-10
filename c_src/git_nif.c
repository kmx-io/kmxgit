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

static ERL_NIF_TERM branches_nif (ErlNifEnv *env, int argc,
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

static ERL_NIF_TERM content_nif (ErlNifEnv *env, int argc,
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

ERL_NIF_TERM git_tree_entry_file_map (ErlNifEnv *env,
                                      const git_tree_entry *entry,
                                      const char *name)
{
  git_object_t type;
  git_filemode_t mode;
  char sha[41];
  ERL_NIF_TERM k[4];
  ERL_NIF_TERM v[4];
  ERL_NIF_TERM file;
  if (!name) {
    fprintf(stderr, "name\n");
    name = git_tree_entry_name(entry);
  }
  fprintf(stderr, "type\n");
  type = git_tree_entry_type(entry);
  fprintf(stderr, "mode\n");
  mode = git_tree_entry_filemode(entry);
  fprintf(stderr, "git_oid_tostr\n");
  git_oid_tostr(sha, 41, git_tree_entry_id(entry));
  k[0] = enif_make_atom(env, "name");
  v[0] = enif_string_to_term(env, name);
  k[1] = enif_make_atom(env, "type");
  if (type == GIT_OBJECT_TREE)
    v[1] = enif_make_atom(env, "tree");
  else
    v[1] = enif_make_atom(env, "blob");
  k[2] = enif_make_atom(env, "mode");
  v[2] = enif_make_int64(env, mode);
  k[3] = enif_make_atom(env, "sha1");
  v[3] = enif_string_to_term(env, sha);
  fprintf(stderr, "enif_make_map_from_arrays\n");
  enif_make_map_from_arrays(env, k, v, 4, &file);
  return file;
}

static ERL_NIF_TERM files_nif (ErlNifEnv *env, int argc,
                               const ERL_NIF_TERM argv[])
{
  size_t count;
  git_tree_entry *entry = NULL;
  ERL_NIF_TERM files;
  git_object *obj = NULL;
  ERL_NIF_TERM ok;
  char *path = NULL;
  git_repository *r = NULL;
  char *repo_dir = NULL;
  ERL_NIF_TERM res;
  char *rev = NULL;
  size_t rev_size = 0;
  git_tree *subtree = NULL;
  git_tree *tree = NULL;
  char *tree_name = NULL;
  git_object_t type = 0;
  ERL_NIF_TERM file;
  if (argc != 3 || !argv || !argv[0] || !argv[1] || !argv[2]) {
    res = enif_make_atom(env, "badarg");
    goto error;
  }
  repo_dir = enif_term_to_string(env, argv[0]);
  if (!repo_dir || !repo_dir[0]) {
    res = enif_make_atom(env, "repo_dir_missing");
    goto error;
  }
  tree_name = enif_term_to_string(env, argv[1]);
  if (!tree_name || !tree_name[0]) {
    res = enif_make_atom(env, "tree_name_missing");
    goto error;
  }
  path = enif_term_to_string(env, argv[2]);
  if (!path) {
    res = enif_make_atom(env, "path_missing");
    goto error;
  }
  rev_size = strlen(tree_name) + 8;
  rev = malloc(rev_size);
  strlcpy(rev, tree_name, rev_size);
  strlcat(rev, "^{tree}", rev_size);
  fprintf(stderr, "files_nif '%s' '%s' '%s'\n", repo_dir, rev, path);
  ok = enif_make_atom(env, "ok");
  if (git_repository_open(&r, repo_dir)) {
    res = enif_make_atom(env, "git_repository_open");
    goto error;
  }
  if (git_revparse_single(&obj, r, rev)) {
    res = enif_make_atom(env, "git_revparse_single");
    goto error;
  }
  tree = (git_tree*) obj;
  fprintf(stderr, "tree: %p\nentry\n", tree);
  if (!path[0] || !strcmp(path, "."))
    subtree = tree;
  else {
    if (git_tree_entry_bypath(&entry, tree, path)) {
      res = enif_make_atom(env, "git_tree_entry_bypath");
      goto error;
    }
    fprintf(stderr, "type\n");
    type = git_tree_entry_type(entry);
    switch (type) {
    case GIT_OBJECT_BLOB:
      file = git_tree_entry_file_map(env, entry, path);
      files = enif_make_list(env, 1, file);
      fprintf(stderr, "free blob\n");
      git_repository_free(r);
      free(repo_dir);
      free(tree_name);
      free(path);
      git_tree_entry_free(entry);
      return enif_make_tuple2(env, ok, files);
    case GIT_OBJECT_TREE:
      fprintf(stderr, "subtree\n");
      if (git_tree_lookup(&subtree, r, git_tree_entry_id(entry))) {
        res = enif_make_atom(env, "git_tree_lookup");
        goto error;
      }
      break;
    default:
      res = enif_make_atom(env, "git_tree_entry_type_invalid");
      goto error;
    }
  }
  fprintf(stderr, "loop\n");
  files = enif_make_list(env, 0);
  count = git_tree_entrycount(subtree);
  while (count--) {
    const git_tree_entry *sub_entry;
    fprintf(stderr, "sub_entry\n");
    sub_entry = git_tree_entry_byindex(subtree, count);
    file = git_tree_entry_file_map(env, sub_entry, NULL);
    files = enif_make_list_cell(env, file, files);
    enif_fprintf(stderr, "files = %T\n", files);
  }
  fprintf(stderr, "free\n");
  git_repository_free(r);
  free(repo_dir);
  free(tree_name);
  free(path);
  git_tree_entry_free(entry);
  return enif_make_tuple2(env, ok, files);
 error:
  res = enif_make_tuple2(env, enif_make_atom(env, "error"), res);
  enif_fprintf(stderr, "%T\n", res);
  git_repository_free(r);
  free(repo_dir);
  free(tree_name);
  free(path);
  git_tree_entry_free(entry);
  return res;
}

static ErlNifFunc funcs[] = {
  {"branches_nif", 1, branches_nif, 0},
  {"content_nif", 2, content_nif, 0},
  {"files_nif", 3, files_nif, 0},
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
