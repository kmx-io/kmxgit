# 1
Use after free in libgit2 `git_config_parse` :

```
(gdb) bt
#0  thrkill () at /tmp/-:3
#1  0x0000004c6c60d2ae in _libc_abort ()
    at /usr/src/lib/libc/stdlib/abort.c:51
#2  0x0000004c6c636757 in wrterror (d=Variable "d" is not available.
)
    at /usr/src/lib/libc/stdlib/malloc.c:324
#3  0x0000004c6c637c9f in ofree (argpool=0x4d1ec85300, p=Variable "p" is not available.
)
    at /usr/src/lib/libc/stdlib/malloc.c:718
#4  0x0000004c6c6372f3 in free (ptr=0x4d66950320)
    at /usr/src/lib/libc/stdlib/malloc.c:1584
#5  0x0000004c3ee1f75f in stdalloc__free (ptr=0x4d66950320)
    at /home/dx/c/libgit2/libgit2/src/util/allocators/stdalloc.c:135
#6  0x0000004c3ee7c70e in parse_variable (reader=0x4d1ec85488,
    var_name=0x4d1ec85420, var_value=0x4d1ec85418,
    line_len=0x4d1ec85400)
    at /home/dx/c/libgit2/libgit2/src/libgit2/config_parse.c:475
#7  0x0000004c3ee7bfcb in git_config_parse (parser=0x4d1ec85488,
    on_section=0, on_variable=0x4c3ee78e40 <read_on_variable>,
    on_comment=0, on_eof=0, payload=0x4d1ec854c8)
    at /home/dx/c/libgit2/libgit2/src/libgit2/config_parse.c:561
#8  0x0000004c3ee78e09 in config_file_read_buffer (
    entries=0x4d66949280, repo=0x4d6693fa00, file=0x4d6693cfa0,
    level=GIT_CONFIG_LEVEL_LOCAL, depth=0,
    buf=0x4d6693d900 "[core]\n\trepositoryformatversion = 0\n\tfilemode = true\n\tbare = true\n", buflen=66)
    at /home/dx/c/libgit2/libgit2/src/libgit2/config_file.c:858
#9  0x0000004c3ee78cc8 in config_file_read (entries=0x4d66949280,
    repo=0x4d6693fa00, file=0x4d6693cfa0,
    level=GIT_CONFIG_LEVEL_LOCAL, depth=0)
    at /home/dx/c/libgit2/libgit2/src/libgit2/config_file.c:887
#10 0x0000004c3ee78184 in config_file_open (cfg=0x4d6693c4b0,
    level=GIT_CONFIG_LEVEL_LOCAL, repo=0x4d6693fa00)
    at /home/dx/c/libgit2/libgit2/src/libgit2/config_file.c:124
#11 0x0000004c3ee72af9 in git_config_add_backend (
    cfg=0x4d6696a880, backend=0x4d6693c4b0,
    level=GIT_CONFIG_LEVEL_LOCAL, repo=0x4d6693fa00, force=0)
    at /home/dx/c/libgit2/libgit2/src/libgit2/config.c:325
#12 0x0000004c3ee729ae in git_config_add_file_ondisk (
    cfg=0x4d6696a880,
    path=0x4d6693d700 "/home/dx/erlang/kmx.io/kmxgit/priv/git/kmx.io/git-auth.git/config", level=GIT_CONFIG_LEVEL_LOCAL,
    repo=0x4d6693fa00, force=0)
    at /home/dx/c/libgit2/libgit2/src/libgit2/config.c:123
#13 0x0000004c3ef1d425 in load_config (out=0x4d1ec85848,
    repo=0x4d6693fa00,
    global_config_path=0x4d66950180 "/home/dx/.gitconfig",
    xdg_config_path=0x0, system_config_path=0x0,
    programdata_path=0x0)
    at /home/dx/c/libgit2/libgit2/src/libgit2/repository.c:1134
#14 0x0000004c3ef1d239 in git_repository_config__weakptr (
    out=0x4d1ec858f8, repo=0x4d6693fa00)
    at /home/dx/c/libgit2/libgit2/src/libgit2/repository.c:1203
#15 0x0000004c3ee7723b in git_repository__configmap_lookup (
    out=0x4d1ec85944, repo=0x4d6693fa00,
    item=GIT_CONFIGMAP_FSYNCOBJECTFILES)
    at /home/dx/c/libgit2/libgit2/src/libgit2/config_cache.c:124
#16 0x0000004c3eed5853 in git_odb__set_caps (odb=0x4d6694c700,
    caps=-1) at /home/dx/c/libgit2/libgit2/src/libgit2/odb.c:742
#17 0x0000004c3ef1d9c2 in git_repository_odb__weakptr (
    out=0x4d1ec85a18, repo=0x4d6693fa00)
    at /home/dx/c/libgit2/libgit2/src/libgit2/repository.c:1276
#18 0x0000004c3eed2010 in git_object_lookup_prefix (
    object_out=0x4d1ec85b38, repo=0x4d6693fa00, id=0x4d1ec85b10,
    len=40, type=GIT_OBJECT_BLOB)
    at /home/dx/c/libgit2/libgit2/src/libgit2/object.c:192
#19 0x0000004c3eed234e in git_object_lookup (
    object_out=0x4d1ec85b38, repo=0x4d6693fa00, id=0x4d1ec85b10,
    type=GIT_OBJECT_BLOB)
    at /home/dx/c/libgit2/libgit2/src/libgit2/object.c:262
#20 0x0000004c3eed3947 in git_blob_lookup (out=0x4d1ec85b38,
    repo=0x4d6693fa00, id=0x4d1ec85b10)
    at /home/dx/c/libgit2/libgit2/src/libgit2/object_api.c:122
#21 0x0000004cb8929131 in content_nif (env=0x4d1ec869f0, argc=2,
    argv=0x4c4fd18300) at c_src/git_nif.c:134
#22 0x0000004a28c2173e in process_main (esdp=0x4c95a2e900)
    at beam_cold.h:177
#23 0x0000004a28bce2e3 in sched_thread_func (vesdp=0x4c95a2e900)
    at beam/erl_process.c:8656
#24 0x0000004a28fdfe9c in thr_wrapper (vtwd=0x7f7ffffc2b08)
    at pthread/ethread.c:122
#25 0x0000004d17d2ef01 in _rthread_start (v=Unhandled dwarf expression opcode 0xa3
)
    at /usr/src/lib/librthread/rthread.c:96
#26 0x0000004c6c5fd9ca in __tfork_thread ()
    at /usr/src/lib/libc/arch/amd64/sys/tfork_thread.S:84
#27 0x0000004c6c5fd9ca in __tfork_thread ()
    at /usr/src/lib/libc/arch/amd64/sys/tfork_thread.S:84
Previous frame identical to this frame (corrupt stack?)
```

```
[info] GET /kmx.io/git-auth
{:branches, "kmx.io/git-auth"}
{:branches_nif, "priv/git/kmx.io/git-auth.git"}
{:files, "kmx.io/git-auth", "master", "", "."}
{:files_nif, "priv/git/kmx.io/git-auth.git", "master", ""}
{:content, "kmx.io/git-auth", "47232bf062f109330b6ad8cacdc32              9285d9d2ce3"}
{:content_nif, "priv/git/kmx.io/git-auth.git",
 "47232bf062f109330b6ad8cacdc329285d9d2ce3"}
beam.smp(79169) in free(): write after free 0x119e2d08980
Abort trap (core dumped)

$ gdb /usr/local/lib/erlang24/erts-12.3.2.2/bin/beam.smp beam.smp.core
(gdb) bt
#0  thrkill () at /tmp/-:3
#1  0x00000119451c12ae in _libc_abort ()
    at /usr/src/lib/libc/stdlib/abort.c:51
#2  0x00000119451ea757 in wrterror (d=Variable "d" is not available.
)
    at /usr/src/lib/libc/stdlib/malloc.c:324
#3  0x00000119451ebc9f in ofree (argpool=0x1198fb07760, p=Variable "p" is not available.
)
    at /usr/src/lib/libc/stdlib/malloc.c:718
#4  0x00000119451eb2f3 in free (ptr=0x119ad7e8230)
    at /usr/src/lib/libc/stdlib/malloc.c:1584
#5  0x00000119c93212cf in stdalloc__free (ptr=0x119ad7e8230)
    at /home/dx/c/libgit2/libgit2/src/util/allocators/stdalloc.c:135
#6  0x00000119c937dee9 in parse_section_header (reader=0x1198fb078b8,
    section_out=0x1198fb07858)
    at /home/dx/c/libgit2/libgit2/src/libgit2/config_parse.c:216
#7  0x00000119c937d9bb in git_config_parse (parser=0x1198fb078b8,
    on_section=0, on_variable=0x119c937a900 <read_on_variable>,
    on_comment=0, on_eof=0, payload=0x1198fb078f8)
    at /home/dx/c/libgit2/libgit2/src/libgit2/config_parse.c:536
#8  0x00000119c937a8c9 in config_file_read_buffer (
    entries=0x11962309840, repo=0x11962301a00, file=0x11962304fa0,
    level=GIT_CONFIG_LEVEL_LOCAL, depth=0,
    buf=0x119e2cda000 "[core]\n\trepositoryformatversion = 0\n\tfilemode = true\n\tbare = true\n", buflen=66)
    at /home/dx/c/libgit2/libgit2/src/libgit2/config_file.c:858
#9  0x00000119c937a788 in config_file_read (entries=0x11962309840,
    repo=0x11962301a00, file=0x11962304fa0,
    level=GIT_CONFIG_LEVEL_LOCAL, depth=0)
    at /home/dx/c/libgit2/libgit2/src/libgit2/config_file.c:887
#10 0x00000119c9379c44 in config_file_open (cfg=0x119623044b0,
    level=GIT_CONFIG_LEVEL_LOCAL, repo=0x11962301a00)
    at /home/dx/c/libgit2/libgit2/src/libgit2/config_file.c:124
#11 0x00000119c93745f9 in git_config_add_backend (cfg=0x119623340c0,
    backend=0x119623044b0, level=GIT_CONFIG_LEVEL_LOCAL,
    repo=0x11962301a00, force=0)
    at /home/dx/c/libgit2/libgit2/src/libgit2/config.c:325
#12 0x00000119c93744ae in git_config_add_file_ondisk (cfg=0x119623340c0,
    path=0x119e2cf3b80 "/home/dx/erlang/kmx.io/kmxgit/priv/git/kmx.io/git-auth.git/config", level=GIT_CONFIG_LEVEL_LOCAL, repo=0x11962301a00,
    force=0) at /home/dx/c/libgit2/libgit2/src/libgit2/config.c:123
#13 0x00000119c941dec5 in load_config (out=0x1198fb07c78,
    repo=0x11962301a00,
    global_config_path=0x11a001cbd20 "/home/dx/.gitconfig",
    xdg_config_path=0x0, system_config_path=0x0, programdata_path=0x0)
    at /home/dx/c/libgit2/libgit2/src/libgit2/repository.c:1134
#14 0x00000119c941dcd9 in git_repository_config__weakptr (
    out=0x1198fb07d28, repo=0x11962301a00)
    at /home/dx/c/libgit2/libgit2/src/libgit2/repository.c:1203
#15 0x00000119c9378d2b in git_repository__configmap_lookup (
    out=0x1198fb07d74, repo=0x11962301a00,
    item=GIT_CONFIGMAP_FSYNCOBJECTFILES)
    at /home/dx/c/libgit2/libgit2/src/libgit2/config_cache.c:124
#16 0x00000119c93d7123 in git_odb__set_caps (odb=0x119e2d08c80, caps=-1)
    at /home/dx/c/libgit2/libgit2/src/libgit2/odb.c:742
#17 0x00000119c941e432 in git_repository_odb__weakptr (
    out=0x1198fb07e48, repo=0x11962301a00)
    at /home/dx/c/libgit2/libgit2/src/libgit2/repository.c:1276
#18 0x00000119c93d3980 in git_object_lookup_prefix (
    object_out=0x1198fb07f68, repo=0x11962301a00, id=0x1198fb07f40,
    len=40, type=GIT_OBJECT_BLOB)
    at /home/dx/c/libgit2/libgit2/src/libgit2/object.c:192
#19 0x00000119c93d3cbe in git_object_lookup (object_out=0x1198fb07f68,
    repo=0x11962301a00, id=0x1198fb07f40, type=GIT_OBJECT_BLOB)
    at /home/dx/c/libgit2/libgit2/src/libgit2/object.c:262
#20 0x00000119c93d52a7 in git_blob_lookup (out=0x1198fb07f68,
    repo=0x11962301a00, id=0x1198fb07f40)
    at /home/dx/c/libgit2/libgit2/src/libgit2/object_api.c:122
#21 0x00000119bd498131 in content_nif (env=0x1198fb08e20, argc=2,
    argv=0x119c4f10240) at c_src/git_nif.c:134
#22 0x0000011707dcc73e in process_main (esdp=0x1194d8085c0)
    at beam_cold.h:177
#23 0x0000011707d792e3 in sched_thread_func (vesdp=0x1194d8085c0)
    at beam/erl_process.c:8656
#24 0x000001170818ae9c in thr_wrapper (vtwd=0x7f7ffffdac18)
    at pthread/ethread.c:122
#25 0x00000119d3864f01 in _rthread_start (v=Unhandled dwarf expression opcode 0xa3
)
    at /usr/src/lib/librthread/rthread.c:96
#26 0x00000119451b19ca in __tfork_thread ()
    at /usr/src/lib/libc/arch/amd64/sys/tfork_thread.S:84
#27 0x00000119451b19ca in __tfork_thread ()
    at /usr/src/lib/libc/arch/amd64/sys/tfork_thread.S:84
Previous frame identical to this frame (corrupt stack?)
```
