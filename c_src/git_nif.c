/* kmxgit
 * Copyright 2022 kmx.io <contact@kmx.io>
 *
 * Permission is hereby granted to use this software granted
 * the above copyright notice and this permission paragraph
 * are included in all copies and substantial portions of this
 * software.
 *
 * THIS SOFTWARE IS PROVIDED "AS-IS" WITHOUT ANY GUARANTEE OF
 * PURPOSE AND PERFORMANCE. IN NO EVENT WHATSOEVER SHALL THE
 * AUTHOR BE CONSIDERED LIABLE FOR THE USE AND PERFORMANCE OF
 * THIS SOFTWARE.
 */
#include <stdlib.h>
#include <string.h>
#include <erl_nif.h>
#include <git2.h>
#include <enif.h>

static int check_repo_dir (const char *s);
static ERL_NIF_TERM push_string (ErlNifEnv *env, const char *str,
                                 const ERL_NIF_TERM acc);

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

static ErlNifFunc funcs[] = {
        {"branches_nif", 1, branches_nif, 0},
        {"content_nif",  2, content_nif,  0},
        {"create_nif",   1, create_nif,   0},
        {"diff_nif",     3, diff_nif,     0},
        {"files_nif",    3, files_nif,    0},
        {"log_nif",      5, log_nif,      0},
        {"tags_nif",     1, tags_nif,     0}
};

static ERL_NIF_TERM g_ok = 0;
static ERL_NIF_TERM g_error = 0;

ERL_NIF_TERM branches_nif (ErlNifEnv *env, int argc,
                           const ERL_NIF_TERM argv[])
{
  ERL_NIF_TERM acc;
  const char *branch = NULL;
  ERL_NIF_TERM branches = 0;
  git_branch_iterator *i = NULL;
  git_reference *ref = NULL;
  git_branch_t ref_type = 0;
  git_repository *repo = NULL;
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
  if (check_repo_dir(repo_dir)) {
    res = enif_make_atom(env, "repo_dir");
    goto error;
  }
  if (git_repository_open_bare(&repo, repo_dir)) {
    res = enif_make_atom(env, "git_repository_open_bare");
    goto error;
  }
  git_branch_iterator_new(&i, repo, GIT_BRANCH_ALL);
  acc = enif_make_list(env, 0);
  while (!git_branch_next(&ref, &ref_type, i)) {
    git_branch_name(&branch, ref);
    acc = push_string(env, branch, acc);
    git_reference_free(ref);
  }
  if (! enif_make_reverse_list(env, acc, &branches)) {
    res = enif_make_atom(env, "enif_make_reverse_list");
    goto error;
  }
  res = enif_make_tuple2(env, g_ok, branches);
  goto ok;
 error:
  res = enif_make_tuple2(env, g_error, res);
  enif_fprintf(stderr, "%T\n", res);
 ok:
  git_branch_iterator_free(i);
  git_repository_free(repo);
  free(repo_dir);
  return res;
}

int check_repo_dir (const char *s)
{
  return !s || !s[0] || s[0] == '.' || strstr(s, "/.");
}

ERL_NIF_TERM content_nif (ErlNifEnv *env, int argc,
                          const ERL_NIF_TERM argv[])
{
  git_blob *blob = NULL;
  ERL_NIF_TERM content;
  const void *data = NULL;
  git_oid oid = {0};
  git_repository *repo = NULL;
  char *repo_dir = NULL;
  ERL_NIF_TERM res;
  char *sha = NULL;
  git_object_size_t size = 0;
  if (argc != 2 || !argv || !argv[0] || !argv[1]) {
    res = enif_make_atom(env, "badarg");
    goto error;
  }
  repo_dir = enif_term_to_string(env, argv[0]);
  if (!repo_dir || !repo_dir[0]) {
    res = enif_make_atom(env, "repo_dir");
    goto error;
  }
  if (check_repo_dir(repo_dir)) {
    res = enif_make_atom(env, "repo_dir");
    goto error;
  }
  sha = enif_term_to_string(env, argv[1]);
  if (!sha || !sha[0]){
    res = enif_make_atom(env, "sha");
    goto error;
  }
  if (git_repository_open_bare(&repo, repo_dir)) {
    res = enif_make_atom(env, "git_repository_open_bare");
    goto error;
  }
  if (git_oid_fromstr(&oid, sha)) {
    res = enif_make_atom(env, "git_oid_fromstr");
    goto error;
  }
  if (git_blob_lookup(&blob, repo, &oid)) {
    res = enif_make_atom(env, "git_blob_lookup");
    goto error;
  }
  size = git_blob_rawsize(blob);
  data = git_blob_rawcontent(blob);
  content = enif_string_to_term_len(env, data, size);
  res = enif_make_tuple2(env, g_ok, content);
  goto ok;
 error:
  res = enif_make_tuple2(env, g_error, res);
  enif_fprintf(stderr, "%T\n", res);
 ok:
  git_blob_free(blob);
  git_repository_free(repo);
  free(repo_dir);
  free(sha);
  return res;
}

ERL_NIF_TERM create_nif (ErlNifEnv *env, int argc,
                         const ERL_NIF_TERM argv[])
{
  git_repository *repo = NULL;
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
  if (check_repo_dir(repo_dir)) {
    res = enif_make_atom(env, "repo_dir");
    goto error;
  }
  if (git_repository_init(&repo, repo_dir, 1)) {
    res = enif_make_atom(env, "git_repository_init");
    goto error;
  }
  res = g_ok;
  goto ok;
 error:
  res = enif_make_tuple2(env, g_error, res);
  enif_fprintf(stderr, "%T\n", res);
 ok:
  git_repository_free(repo);
  free(repo_dir);
  return res;
}

ERL_NIF_TERM diff_nif (ErlNifEnv *env, int argc,
                       const ERL_NIF_TERM argv[])
{
  git_buf buf = {NULL, 0, 0};
  git_commit *commit[2] = {NULL, NULL};
  git_diff *diff = NULL;
  char *from = NULL;
  git_object *obj = NULL;
  git_repository *repo = NULL;
  char *repo_dir = NULL;
  ERL_NIF_TERM res;
  char *to = NULL;
  git_tree *tree[2] = {NULL, NULL};
  if (argc != 3 || !argv || !argv[0] || !argv[1] ||
      !argv[2]) {
    res = enif_make_atom(env, "badarg");
    goto error;
  }
  repo_dir = enif_term_to_string(env, argv[0]);
  if (!repo_dir || !repo_dir[0]) {
    res = enif_make_atom(env, "repo_dir_missing");
    goto error;
  }
  if (check_repo_dir(repo_dir)) {
    res = enif_make_atom(env, "repo_dir");
    goto error;
  }
  from = enif_term_to_string(env, argv[1]);
  if (!from || !from[0]) {
    res = enif_make_atom(env, "from_missing");
    goto error;
  }
  to = enif_term_to_string(env, argv[2]);
  if (!to || !to[0]) {
    res = enif_make_atom(env, "to_missing");
    goto error;
  }
  if (git_repository_open_bare(&repo, repo_dir)) {
    res = enif_make_atom(env, "git_repository_open_bare");
    goto error;
  }
  if (git_revparse_single(&obj, repo, from)) {
    res = enif_make_atom(env, "from__git_revparse_single");
    goto error;
  }
  if (git_commit_lookup(commit, repo, git_object_id(obj))) {
    res = enif_make_atom(env, "from__git_commit_lookup");
    goto error;
  }
  if (git_commit_tree(tree, commit[0])) {
    res = enif_make_atom(env, "from__git_commit_tree");
    goto error;
  }
  git_object_free(obj);
  if (git_revparse_single(&obj, repo, to)) {
    res = enif_make_atom(env, "to__git_revparse_single");
    goto error;
  }
  if (git_commit_lookup(commit + 1, repo, git_object_id(obj))) {
    res = enif_make_atom(env, "to__git_commit_lookup");
    goto error;
  }
  if (git_commit_tree(tree + 1, commit[1])) {
    res = enif_make_atom(env, "to__git_commit_tree");
    goto error;
  }
  if (git_diff_tree_to_tree(&diff, repo, tree[0], tree[1], NULL)) {
    res = enif_make_atom(env, "git_diff_tree_to_tree");
    goto error;
  }
  if (git_diff_to_buf(&buf, diff, GIT_DIFF_FORMAT_PATCH)) {
    res = enif_make_atom(env, "git_diff_to_buf");
    goto error;
  }
  res = enif_string_to_term_len(env, buf.ptr, buf.size);
  res = enif_make_tuple2(env, g_ok, res);
  goto ok;
 error:
  res = enif_make_tuple2(env, g_error, res);
  enif_fprintf(stderr, "%T\n", res);
 ok:
  git_buf_dispose(&buf);
  git_commit_free(commit[0]);
  git_commit_free(commit[1]);
  git_diff_free(diff);
  git_object_free(obj);
  git_repository_free(repo);
  git_tree_free(tree[0]);
  git_tree_free(tree[1]);
  free(to);
  free(from);
  free(repo_dir);
  return res;
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
  git_oid_tostr(sha, sizeof(sha), git_tree_entry_id(entry));
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
  enif_make_map_from_arrays(env, k, v, 4, &file);
  return file;
}

ERL_NIF_TERM files_nif (ErlNifEnv *env, int argc,
                        const ERL_NIF_TERM argv[])
{
  size_t count;
  git_tree_entry *entry = NULL;
  ERL_NIF_TERM files;
  git_object *obj = NULL;
  char *path = NULL;
  git_repository *repo = NULL;
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
  if (check_repo_dir(repo_dir)) {
    res = enif_make_atom(env, "repo_dir");
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
  if (git_repository_open_bare(&repo, repo_dir)) {
    res = enif_make_atom(env, "git_repository_open_bare");
    goto error;
  }
  if (git_revparse_single(&obj, repo, rev)) {
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
      res = enif_make_tuple2(env, g_ok, files);
      goto ok;
    case GIT_OBJECT_TREE:
      if (git_tree_lookup(&subtree, repo, git_tree_entry_id(entry))) {
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
  res = enif_make_tuple2(env, g_ok, files);
  goto ok;
 error:
  res = enif_make_tuple2(env, g_error, res);
  enif_fprintf(stderr, "%T\n", res);
 ok:
  if (subtree != (git_tree*) obj)
    git_tree_free(subtree);
  git_object_free(obj);
  git_repository_free(repo);
  free(repo_dir);
  free(tree_name);
  free(path);
  free(rev);
  git_tree_entry_free(entry);
  return res;
}

int load (ErlNifEnv *env, void **a, ERL_NIF_TERM b)
{
  (void) env;
  (void) a;
  (void) b;
  (void) funcs;
  fprintf(stderr, "git_nif load\n");
  g_ok = enif_make_atom(env, "ok");
  g_error = enif_make_atom(env, "error");
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
  return res;
}

static int log_add_revision(struct log_state *s,
                            const char *revstr)
{
  git_revspec revs = {0};
  int hide = 0;
  int res = 0;
  if (!revstr)
    return log_push_rev(s, NULL, hide);
  if (*revstr == '^') {
    revs.flags = GIT_REVSPEC_SINGLE;
    hide = !hide;
    if (git_revparse_single(&revs.from, s->repo, revstr + 1) < 0) {
      res = -1;
      goto error;
    }
  }
  else if (git_revparse(&revs, s->repo, revstr) < 0) {
    res = -2;
    goto error;
  }
  if ((revs.flags & GIT_REVSPEC_SINGLE) != 0)
    log_push_rev(s, revs.from, hide);
  else {
    log_push_rev(s, revs.to, hide);
    if ((revs.flags & GIT_REVSPEC_MERGE_BASE) != 0) {
      git_oid base;
      if (git_merge_base(&base, s->repo,
                         git_object_id(revs.from),
                         git_object_id(revs.to))) {
        res = -3;
        goto error;
      }
      if (git_object_lookup(&revs.to, s->repo, &base,
                            GIT_OBJECT_COMMIT)) {
        res = -4;
        goto error;
      }
      if (log_push_rev(s, revs.to, hide)) {
        res = -5;
        goto error;
      }
    }
    if (log_push_rev(s, revs.from, !hide)) {
      res = -6;
      goto error;
    }
  }
 error:
  git_object_free(revs.from);
  git_object_free(revs.to);
  return res;
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
  git_tree *tree[2] = {NULL, NULL};
  git_diff *diff = NULL;
  int ndeltas = 0;
  int res = 0;
  if (git_commit_parent(&parent, commit, (size_t) i)) {
    res = -1;
    goto error;
  }
  if (git_commit_tree(&tree[0], parent)) {
    res = -2;
    goto error;
  }
  if (git_commit_tree(&tree[1], commit)) {
    res = -3;
    goto error;
  }
  if (git_diff_tree_to_tree(&diff, git_commit_owner(commit),
                            tree[0], tree[1], opts)) {
    res = -4;
    goto error;
  }
  ndeltas = (int) git_diff_num_deltas(diff);
  res = ndeltas > 0;
 error:
  git_diff_free(diff);
  git_tree_free(tree[0]);
  git_tree_free(tree[1]);
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
  ERL_NIF_TERM k[7] = {
    enif_make_atom(env, "author_email"),
    enif_make_atom(env, "message"),
    enif_make_atom(env, "author"),
    enif_make_atom(env, "parents"),
    enif_make_atom(env, "hash"),
    enif_make_atom(env, "date"),
    enif_make_atom(env, "ci_status")
  };
  ERL_NIF_TERM v[7];
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
  v[6] = enif_make_atom(env, "nil");
  enif_make_map_from_arrays(env, k, v, 7, &res);
  return enif_make_list_cell(env, res, (ERL_NIF_TERM) acc);
}

ERL_NIF_TERM log_nif (ErlNifEnv *env, int argc,
                      const ERL_NIF_TERM argv[])
{
  char *branch_name = NULL;
  git_commit *commit = NULL;
  int count = 0;
  git_diff_options diffopts = {GIT_DIFF_OPTIONS_VERSION, 0, GIT_SUBMODULE_IGNORE_UNSPECIFIED, {NULL, 0}, NULL, NULL, NULL, 3, 0, 0, 0, 0, 0};
  int i = 0;
  git_oid oid = {0};
  struct log_options opt = {0};
  int parents = 0;
  char *path = NULL;
  int printed = 0;
  git_pathspec *ps = NULL;
  char *repo_dir = NULL;
  ERL_NIF_TERM log;
  ERL_NIF_TERM res;
  struct log_state s = {0};
  if (argc != 5 || !argv || !argv[0] || !argv[1] ||
      !argv[2] || !argv[3] || !argv[4]) {
    res = enif_make_atom(env, "badarg");
    goto error;
  }
  repo_dir = enif_term_to_string(env, argv[0]);
  if (!repo_dir || !repo_dir[0]) {
    res = enif_make_atom(env, "repo_dir_missing");
    goto error;
  }
  if (check_repo_dir(repo_dir)) {
    res = enif_make_atom(env, "repo_dir");
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
  if (git_repository_open_bare(&s.repo, repo_dir)) {
    res = enif_make_atom(env, "git_repository_open_bare");
    goto error;
  }
  s.sorting = GIT_SORT_TIME;
  if (log_add_revision(&s, branch_name)) {
    res = enif_make_atom(env, "bad_branch");
    goto error;
  }
  opt.max_parents = -1;
  enif_get_int(env, (ERL_NIF_TERM)argv[3], &i);
  opt.skip = i;
  enif_get_int(env, (ERL_NIF_TERM)argv[4], &i);
  opt.limit = i;
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
        git_tree *tree = NULL;
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
  enif_make_reverse_list(env, log, &res);
  res = enif_make_tuple2(env, g_ok, res);
  goto ok;
 error:
  res = enif_make_tuple2(env, g_error, res);
  enif_fprintf(stderr, "%T\n", res);
 ok:
  git_pathspec_free(ps);
  git_revwalk_free(s.walker);
  git_repository_free(s.repo);
  free(repo_dir);
  free(branch_name);
  free(path);
  return res;
}

ERL_NIF_TERM tags_nif (ErlNifEnv *env, int argc,
                       const ERL_NIF_TERM argv[])
{
  git_repository *repo = NULL;
  char *repo_dir = NULL;
  git_strarray tags = {0};
  int i = 0;
  ERL_NIF_TERM acc;
  ERL_NIF_TERM tag;
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
  if (check_repo_dir(repo_dir)) {
    res = enif_make_atom(env, "repo_dir");
    goto error;
  }
  if (git_repository_open_bare(&repo, repo_dir)) {
    res = enif_make_atom(env, "git_repository_open_bare");
    goto error;
  }
  if (git_tag_list(&tags, repo)) {
    res = enif_make_atom(env, "git_tag_list");
    goto error;
  }
  acc = enif_make_list(env, 0);
  for (i = tags.count - 1; i >= 0; i--) {
    tag = enif_string_to_term(env, tags.strings[i]);
    acc = enif_make_list_cell(env, tag, acc);
  }
  res = enif_make_tuple2(env, g_ok, acc);
  goto ok;
 error:
  res = enif_make_tuple2(env, g_error, res);
  enif_fprintf(stderr, "%T\n", res);
 ok:
  git_strarray_free(&tags);
  git_repository_free(repo);
  free(repo_dir);
  return res;
}

static ERL_NIF_TERM push_string (ErlNifEnv *env, const char *str,
                                 const ERL_NIF_TERM acc)
{
  ERL_NIF_TERM term = enif_string_to_term(env, str);
  return enif_make_list_cell(env, term, (ERL_NIF_TERM)acc);
}

void unload (ErlNifEnv *env, void *a)
{
  (void) env;
  (void) a;
  git_libgit2_shutdown();
  fprintf(stderr, "git_nif unload\n");
}

int upgrade (ErlNifEnv* env, void** priv_data, void** old_priv_data,
             ERL_NIF_TERM load_info)
{
  (void) env;
  (void) priv_data;
  (void) old_priv_data;
  (void) load_info;
  fprintf(stderr, "git_nif upgrade\n");
  return 0;
}

ERL_NIF_INIT(Elixir.Kmxgit.Git, funcs, load, NULL, upgrade, unload);
