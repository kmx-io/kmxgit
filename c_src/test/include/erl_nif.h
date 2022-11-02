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
#ifndef __ERL_NIF_H__
#define __ERL_NIF_H__

#include <stdio.h>
#include <stdlib.h>

#define ErlNifEnv char*
#define ErlNifResourceType char*
#define ErlNifResource char*
#define ErlNifTuple char*
#define ErlNifTermType char*
#define ErlNifPid char*
#define ErlNifPort char*
#define ErlNifCharEncoding char
#define ERL_NIF_TERM char *
#define ErlNifSInt64 long long
#define ERL_NIF_INIT(NAME, FUNCS, LOAD, RELOAD, UPGRADE, UNLOAD)

typedef struct
{
    size_t size;
    unsigned char* data;
} ErlNifBinary;

typedef struct enif_func_t
{
    const char* name;
    unsigned arity;
    ERL_NIF_TERM (*fptr)(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]);
    unsigned flags;
}ErlNifFunc;

int enif_alloc_binary (size_t size, ErlNifBinary* bin);
ERL_NIF_TERM enif_make_int64(ErlNifEnv* env, ErlNifSInt64 val);
ERL_NIF_TERM enif_string_to_term (ErlNifEnv *env, const char *str);
ERL_NIF_TERM enif_string_to_term_len (ErlNifEnv *env,
                                      const char *str, size_t len);
ERL_NIF_TERM enif_make_atom(ErlNifEnv *env, const char *name);
ERL_NIF_TERM enif_make_tuple(ErlNifEnv *env, unsigned cnt, ...);
ERL_NIF_TERM  enif_make_list(ErlNifEnv *env, unsigned cnt, ...);
ERL_NIF_TERM enif_make_list_cell(
        ErlNifEnv* env,
        ERL_NIF_TERM head,
        ERL_NIF_TERM tail);
ERL_NIF_TERM enif_make_int(
        ErlNifEnv* env,
        int i);
ERL_NIF_TERM enif_make_tuple2(
        ErlNifEnv* env,
        ERL_NIF_TERM e1,
        ERL_NIF_TERM e2);
ERL_NIF_TERM enif_make_binary(
        ErlNifEnv* env,
        ErlNifBinary* bin);
ERL_NIF_TERM enif_make_long(
        ErlNifEnv* env,
        long int i);

int enif_fprintf(
        FILE *stream,
        const char *format,
        ...);
int enif_make_reverse_list(
        ErlNifEnv* env,
        ERL_NIF_TERM list_in,
        ERL_NIF_TERM *list_out);
int enif_get_atom(ErlNifEnv* env, ERL_NIF_TERM term, char** atom);
int enif_make_map_from_arrays(
        ErlNifEnv* env,
        ERL_NIF_TERM keys[],
        ERL_NIF_TERM values[],
        size_t cnt,
        ERL_NIF_TERM *map_out);
int enif_get_int(
        ErlNifEnv* env,
        ERL_NIF_TERM term,
        int* ip);

int enif_get_string(
        ErlNifEnv* env,
        ERL_NIF_TERM list,
        char* buf,
        unsigned size,
        ErlNifCharEncoding encode);

int enif_inspect_binary(
        ErlNifEnv* env,
        ERL_NIF_TERM bin_term,
        ErlNifBinary* bin);

int enif_get_list_length(
        ErlNifEnv* env,
        ERL_NIF_TERM term,
        unsigned* len);
char * enif_term_to_string (ErlNifEnv *env, const ERL_NIF_TERM term);
void enif_free_string(char* string);
void enif_free_env(ErlNifEnv* env);
void enif_free_term(ERL_NIF_TERM term);

#endif /* __ERL_NIF_H__ */
