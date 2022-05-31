#include <stdlib.h>
#include <string.h>

#include <erl_nif.h>
#include <git2.h>

static ERL_NIF_TERM enif_string_to_term (ErlNifEnv *env,
                                         const char *str);
static char * enif_term_to_string (ErlNifEnv *env,
                                   const ERL_NIF_TERM term);
static ERL_NIF_TERM push_string (ErlNifEnv *env, const char *str,
                                 const ERL_NIF_TERM acc);

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
  if (git_repository_open_bare(&r, repo))
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
  if (git_repository_open_bare(&r, repo))
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

static ERL_NIF_TERM create_nif (ErlNifEnv *env, int argc,
                                const ERL_NIF_TERM argv[])
{
  ERL_NIF_TERM ok;
  git_repository *r = NULL;
  char *repo_dir = NULL;
  ERL_NIF_TERM res;
  if (argc != 1 || !argv || !argv[0]) {
    res = enif_make_atom(env, "badarg");
    goto error;
  }
  repo_dir = enif_term_to_string(env, argv[0]);
  if (!repo_dir || !repo_dir[0]) {
    res = enif_make_atom(env, "repo_dir_missing");
    goto error;
  }
  if (git_repository_init(&r, repo_dir, 1)) {
    res = enif_make_atom(env, "git_repository_init");
    goto error;
  }
  git_repository_free(r);
  free(repo_dir);
  ok = enif_make_atom(env, "ok");
  return ok;
 error:
  res = enif_make_tuple2(env, enif_make_atom(env, "error"), res);
  enif_fprintf(stderr, "%T\n", res);
  git_repository_free(r);
  free(repo_dir);
  return res;
}

static ERL_NIF_TERM enif_string_to_term (ErlNifEnv *env,
                                         const char *str)
{
  size_t len = strlen(str);
  ErlNifBinary bin;
  enif_alloc_binary(len, &bin);
  memcpy(bin.data, str, len);
  return enif_make_binary(env, &bin);
}

static char * enif_term_to_string (ErlNifEnv *env,
                                   const ERL_NIF_TERM term)
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

static ERL_NIF_TERM
files_make_map (ErlNifEnv *env,
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
    name = git_tree_entry_name(entry);
  }
  type = git_tree_entry_type(entry);
  mode = git_tree_entry_filemode(entry);
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
  ok = enif_make_atom(env, "ok");
  if (git_repository_open_bare(&r, repo_dir)) {
    res = enif_make_atom(env, "git_repository_open_bare");
    goto error;
  }
  if (git_revparse_single(&obj, r, rev)) {
    res = enif_make_atom(env, "git_revparse_single");
    goto error;
  }
  tree = (git_tree*) obj;
  if (!path[0] || !strcmp(path, "."))
    subtree = tree;
  else {
    if (git_tree_entry_bypath(&entry, tree, path)) {
      res = enif_make_atom(env, "git_tree_entry_bypath");
      goto error;
    }
    type = git_tree_entry_type(entry);
    switch (type) {
    case GIT_OBJECT_BLOB:
      file = files_make_map(env, entry, path);
      files = enif_make_list(env, 1, file);
      git_repository_free(r);
      free(repo_dir);
      free(tree_name);
      free(path);
      git_tree_entry_free(entry);
      return enif_make_tuple2(env, ok, files);
    case GIT_OBJECT_TREE:
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
  files = enif_make_list(env, 0);
  count = git_tree_entrycount(subtree);
  while (count--) {
    const git_tree_entry *sub_entry;
    sub_entry = git_tree_entry_byindex(subtree, count);
    file = files_make_map(env, sub_entry, NULL);
    files = enif_make_list_cell(env, file, files);
  }
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

int load (ErlNifEnv *env, void **a, ERL_NIF_TERM b)
{
  (void) env;
  (void) a;
  (void) b;
  fprintf(stderr, "git_nif load\n");
  git_libgit2_init();
  return 0;
}

struct log_state {
  int hide;
  git_repository *repo;
  const char *repodir;
  git_revwalk *walker;
  int sorting;
  int revisions;
};

static int log_push_rev(struct log_state *s,
                        git_object *obj,
                        int hide)
{
  int res = 0;
  hide ^= s->hide;
  if (!s->walker) {
    if (git_revwalk_new(&s->walker, s->repo)) {
      res = -1;
      goto error;
    }
    git_revwalk_sorting(s->walker, s->sorting);
  }
  if (!obj) {
    if (git_revwalk_push_head(s->walker)) {
      res = -2;
      goto error;
    }
  }
  else if (hide) {
    if (git_revwalk_hide(s->walker, git_object_id(obj))) {
      res = -3;
      goto error;
    }
  }
  else
    if (git_revwalk_push(s->walker, git_object_id(obj))) {
      res = -4;
      goto error;
    }
 error:
  git_object_free(obj);
  return res;
}

static int log_add_revision(struct log_state *s,
                            const char *revstr)
{
  git_revspec revs;
  int hide = 0;
  if (!revstr)
    return log_push_rev(s, NULL, hide);
  if (*revstr == '^') {
    revs.flags = GIT_REVSPEC_SINGLE;
    hide = !hide;
    if (git_revparse_single(&revs.from, s->repo, revstr + 1) < 0)
      return -1;
  }
  else if (git_revparse(&revs, s->repo, revstr) < 0)
    return -2;
  if ((revs.flags & GIT_REVSPEC_SINGLE) != 0)
    log_push_rev(s, revs.from, hide);
  else {
    log_push_rev(s, revs.to, hide);
    if ((revs.flags & GIT_REVSPEC_MERGE_BASE) != 0) {
      git_oid base;
      if (git_merge_base(&base, s->repo,
                         git_object_id(revs.from),
                         git_object_id(revs.to)))
        return -3;
      if (git_object_lookup(&revs.to, s->repo, &base,
                            GIT_OBJECT_COMMIT))
        return -4;
      if (log_push_rev(s, revs.to, hide))
        return -5;
    }
    if (log_push_rev(s, revs.from, !hide))
      return -6;
  }
  return 0;
}

struct log_options {
  int show_diff;
  int show_log_size;
  int skip, limit;
  int min_parents, max_parents;
  git_time_t before;
  git_time_t after;
  const char *author;
  const char *committer;
  const char *grep;
};

static int log_match_with_parent (git_commit *commit,
                                  int i,
                                  git_diff_options *opts)
{
  git_commit *parent = NULL;
  git_tree *a = NULL;
  git_tree *b = NULL;
  git_diff *diff = NULL;
  int ndeltas = 0;
  int res = 0;
  if (git_commit_parent(&parent, commit, (size_t) i)) {
    res = -1;
    goto error;
  }
  if (git_commit_tree(&a, parent)) {
    res = -2;
    goto error;
  }
  if (git_commit_tree(&b, commit)) {
    res = -3;
    goto error;
  }
  if (git_diff_tree_to_tree(&diff, git_commit_owner(commit),
                            a, b, opts)) {
    res = -4;
    goto error;
  }
  ndeltas = (int) git_diff_num_deltas(diff);
  res = ndeltas > 0;
 error:
  git_diff_free(diff);
  git_tree_free(a);
  git_tree_free(b);
  git_commit_free(parent);
  return res;
}

static ERL_NIF_TERM log_push_commit (ErlNifEnv *env,
                                     git_commit *commit,
                                     const ERL_NIF_TERM acc)
{
  ERL_NIF_TERM res;
  char buf[GIT_OID_HEXSZ + 1];
  int i;
  int count;
  const git_signature *sig;
  ERL_NIF_TERM k[6] = {
    enif_make_atom(env, "author_email"),
    enif_make_atom(env, "message"),
    enif_make_atom(env, "author"),
    enif_make_atom(env, "parents"),
    enif_make_atom(env, "hash"),
    enif_make_atom(env, "date")
  };
  ERL_NIF_TERM v[6];
  ERL_NIF_TERM parent_sha;
  ERL_NIF_TERM parents = enif_make_list(env, 0);
  git_oid_tostr(buf, sizeof(buf), git_commit_id(commit));
  v[1] = enif_string_to_term(env, git_commit_message(commit));
  v[4] = enif_string_to_term(env, buf);
  if ((count = (int) git_commit_parentcount(commit)) > 1) {
    for (i = 0; i < count; ++i) {
      git_oid_tostr(buf, sizeof(buf),
                    git_commit_parent_id(commit, i));
      parent_sha = enif_string_to_term(env, buf);
      parents = enif_make_list_cell(env, parent_sha, parents);
    }
  }
  v[3] = parents;
  if ((sig = git_commit_author(commit)) != NULL) {
    v[5] = enif_make_int(env, sig->when.time + (sig->when.offset * 60));
    v[2] = enif_string_to_term(env, sig->name);
    v[0] = enif_string_to_term(env, sig->email);
  }
  enif_make_map_from_arrays(env, k, v, 6, &res);
  return enif_make_list_cell(env, res, acc);
}

static ERL_NIF_TERM log_nif (ErlNifEnv *env, int argc,
                             const ERL_NIF_TERM argv[])
{
  char *branch_name = NULL;
  git_commit *commit = NULL;
  int count = 0;
  git_diff_options diffopts = {GIT_DIFF_OPTIONS_VERSION, 0, GIT_SUBMODULE_IGNORE_UNSPECIFIED, {NULL, 0}, NULL, NULL, NULL, 3, 0, 0, 0, 0, 0};
  int i = 0;
  git_oid oid = {0};
  ERL_NIF_TERM ok;
  struct log_options opt;
  int parents = 0;
  char *path = NULL;
  int printed = 0;
  git_pathspec *ps = NULL;
  git_repository *r = NULL;
  char *repo_dir = NULL;
  ERL_NIF_TERM log;
  ERL_NIF_TERM res;
  struct log_state s;
  if (argc != 3 || !argv || !argv[0] || !argv[1] || !argv[2]) {
    res = enif_make_atom(env, "badarg");
    goto error;
  }
  repo_dir = enif_term_to_string(env, argv[0]);
  if (!repo_dir || !repo_dir[0]) {
    res = enif_make_atom(env, "repo_dir_missing");
    goto error;
  }
  branch_name = enif_term_to_string(env, argv[1]);
  if (!branch_name || !branch_name[0]) {
    res = enif_make_atom(env, "branch_name_missing");
    goto error;
  }
  path = enif_term_to_string(env, argv[2]);
  if (!path) {
    res = enif_make_atom(env, "path_missing");
    goto error;
  }
  if (git_repository_open_bare(&r, repo_dir)) {
    res = enif_make_atom(env, "git_repository_open_bare");
    goto error;
  }
  bzero(&s, sizeof(s));
  s.repo = r;
  s.sorting = GIT_SORT_TIME;
  if (log_add_revision(&s, branch_name)) {
    res = enif_make_atom(env, "bad_branch");
    goto error;
  }
  bzero(&opt, sizeof(opt));
  opt.max_parents = -1;
  opt.limit = -1;
  if (path[0]) {
    diffopts.pathspec.strings = &path;
    diffopts.pathspec.count = 1;
    git_pathspec_new(&ps, &diffopts.pathspec);
  }
  log = enif_make_list(env, 0);
  for (;
       !git_revwalk_next(&oid, s.walker);
       git_commit_free(commit)) {
    if (git_commit_lookup(&commit, s.repo, &oid)) {
      res = enif_make_atom(env, "git_commit_lookup");
      goto error;
    }
    parents = git_commit_parentcount(commit);
    if (parents < opt.min_parents)
      continue;
    if (opt.max_parents > 0 && parents > opt.max_parents)
      continue;
    if (diffopts.pathspec.count > 0) {
      int unmatched = parents;
      if (parents == 0) {
        git_tree *tree;
        if (git_commit_tree(&tree, commit)) {
          res = enif_make_atom(env, "git_commit_tree");
          goto error;
        }
        if (git_pathspec_match_tree
            (NULL, tree, GIT_PATHSPEC_NO_MATCH_ERROR, ps)
            != 0)
          unmatched = 1;
        git_tree_free(tree);
      } else if (parents == 1) {
        unmatched = log_match_with_parent(commit, 0, &diffopts) ? 0 : 1;
      } else {
        for (i = 0; i < parents; ++i) {
          if (log_match_with_parent(commit, i, &diffopts))
            unmatched--;
        }
      }
      if (unmatched > 0)
        continue;
    }
    if (count++ < opt.skip)
      continue;
    if (opt.limit != -1 && printed++ >= opt.limit) {
      git_commit_free(commit);
      break;
    }
    log = log_push_commit(env, commit, log);
  }
  git_pathspec_free(ps);
  git_repository_free(r);
  free(repo_dir);
  free(branch_name);
  free(path);
  ok = enif_make_atom(env, "ok");
  enif_make_reverse_list(env, log, &res);
  res = enif_make_tuple2(env, ok, res);
  return res;
 error:
  res = enif_make_tuple2(env, enif_make_atom(env, "error"), res);
  enif_fprintf(stderr, "%T\n", res);
  git_repository_free(r);
  free(repo_dir);
  free(branch_name);
  free(path);

  return res;
}

static ERL_NIF_TERM push_string (ErlNifEnv *env, const char *str,
                                 const ERL_NIF_TERM acc)
{
  ERL_NIF_TERM term = enif_string_to_term(env, str);
  return enif_make_list_cell(env, term, acc);
}

void unload (ErlNifEnv *env, void *a)
{
  (void) env;
  (void) a;
  git_libgit2_shutdown();
  fprintf(stderr, "git_nif unload\n");
}

static ErlNifFunc funcs[] = {
  {"branches_nif", 1, branches_nif, 0},
  {"content_nif",  2, content_nif,  0},
  {"create_nif",   1, create_nif,   0},
  {"files_nif",    3, files_nif,    0},
  {"log_nif",      3, log_nif,      0},
};

ERL_NIF_INIT(Elixir.Kmxgit.Git, funcs, load, NULL, NULL, unload);
