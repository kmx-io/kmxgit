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
#include "include/erl_nif.h"
#ifdef HAVE_ALLOCA_H
# include <alloca.h>
#endif
#include <err.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <git2.h>
#include "mstr.h"

ERL_NIF_TERM enif_make_int64 (ErlNifEnv* env, ErlNifSInt64 i)
{
  (void) env;
  return mstr("%ld", i);
}

ERL_NIF_TERM enif_make_atom (ErlNifEnv *env, const char *name)
{
  (void) env;
  /*printf("enif_make_atom: :%s\n", name);*/
  return mstr(":%s", name);
}

ERL_NIF_TERM enif_make_tuple (ErlNifEnv *env, unsigned cnt, ...)
{
  (void) env;
  return mstr("{<enif_make_tuple %d ...>}", cnt);
}

ERL_NIF_TERM enif_make_list (ErlNifEnv *env, unsigned cnt, ...)
{
  (void) env;
  if (cnt == 0)
    return mstr1("[]");
  return mstr("[<%d>]", cnt);
}

ERL_NIF_TERM enif_string_to_term (ErlNifEnv *env, const char *str)
{
  (void) env;
  return mstr("\"%s\"", str);
}

ERL_NIF_TERM enif_string_to_term_len (ErlNifEnv *env, const char *str,
                                      size_t len)
{
  (void) env;
  char * res = mstr_len(str, len);
  /*printf("res = %s\n", res);*/
  return enif_string_to_term(env, res);
}

ERL_NIF_TERM enif_make_list_cell (ErlNifEnv* env, ERL_NIF_TERM head,
                                  ERL_NIF_TERM tail)
{
  (void) env;
  return mstr("[%s | %s]", head, tail);
}

ERL_NIF_TERM enif_make_int (ErlNifEnv* env, int i)
{
  (void) env;
  return mstr("%d", i);
}

ERL_NIF_TERM enif_make_tuple2 (ErlNifEnv* env, ERL_NIF_TERM e1,
                               ERL_NIF_TERM e2)
{
  (void) env;
  /*printf("enif_make_tuple2 : {%s, %s}\n", e1, e2);*/
  return mstr("{%s, %s}", e1, e2);
}

ERL_NIF_TERM enif_make_binary (ErlNifEnv* env, ErlNifBinary* bin)
{
  (void) env;
  (void) bin;
  err(1, "enif_make_binary");
  return 0;
}

ERL_NIF_TERM enif_make_long (ErlNifEnv* env, long int i)
{
  (void) env;
  return mstr("%ld", i);
}

ERL_NIF_TERM enif_term_type (ErlNifEnv *env, ERL_NIF_TERM term)
{
  (void) env;
  (void) term;
  err(1, "enif_term_type");
  return 0;
}

int enif_make_reverse_list (ErlNifEnv* env, ERL_NIF_TERM list_in,
                            ERL_NIF_TERM *list_out)
{
  (void) env;
  (void) list_in;
  (void) list_out;
  *list_out = list_in;
  return 0;
}

int enif_get_atom (ErlNifEnv* env, ERL_NIF_TERM term, char** atom)
{
  (void) env;
  *atom = term + 1;
  return 0;
}

int enif_fprintf (FILE *stream, const char *format, ...)
{
  va_list ap;
  char *fmt;
  int i = 0;
  size_t len;
  va_start(ap, format);
  len = strlen(format);
  fmt = alloca(len + 1);
  fmt[i] = format[i];
  i++;
  while (format[i]) {
    if (format[i - 1] == '%' && format[i] == 'T')
      fmt[i] = 's';
    else
      fmt[i] = format[i];
    i++;
  }
  fmt[i] = 0;
  vfprintf(stream, fmt, ap);
  return 0;
}

int enif_get_list_length (ErlNifEnv* env, ERL_NIF_TERM term,
                          unsigned* len)
{
  (void) env;
  (void) term;
  (void) len;
  err(1, "enif_get_list_length");
  return 0;
}

int enif_get_string(ErlNifEnv* env, ERL_NIF_TERM list, char* buf,
                    unsigned size, ErlNifCharEncoding encode)
{
  (void) env;
  (void) list;
  (void) buf;
  (void) size;
  (void) encode;
  err(1, "enif_get_string");
  return 0;
}

int enif_make_map_from_arrays (ErlNifEnv* env,
                               ERL_NIF_TERM keys[],
                               ERL_NIF_TERM values[],
                               size_t cnt,
                               ERL_NIF_TERM *map_out)
{
  size_t i = 0;
  char **lines = 0;
  (void) env;
  if (cnt == 0) {
    *map_out = mstr("%{}");
    return 0;
  }
  lines = alloca(sizeof(char*) * cnt);
  lines[0] = mstr("%{%s => %s", keys[0], values[0]);
  i = 1;
  while (i < cnt) {
    lines[i] = mstr("%s, %s => %s", lines[i - 1], keys[i], values[i]);
    i++;
  }
  *map_out = lines[cnt - 1];
  return 0;
}

int enif_get_int (ErlNifEnv* env, ERL_NIF_TERM term, int* ip)
{
  (void) env;
  *ip = atoi(term);
  /*printf("enif_get_int: %d\n", *ip);*/
  return 0;
}

int enif_inspect_binary (ErlNifEnv* env, ERL_NIF_TERM bin_term,
                         ErlNifBinary* bin)
{
  (void) env;
  bin->size = strlen(bin_term);
  bin->data = ( unsigned char *)bin_term;
  return 0;
}

int enif_alloc_binary (size_t size, ErlNifBinary* bin)
{
  (void) size;
  (void) bin;
  return 0;
}

char * enif_term_to_string (ErlNifEnv *env, const ERL_NIF_TERM term)
{
  (void) env;
  char *res = malloc(sizeof(char) * (strlen(term) + 1));
  strlcpy(res, term, (size_t)res);
  /*printf("enif_term_to_string: %s\n", res);*/
  return res;
}

void enif_free_string (char* string)
{
  (void) string;
  return;
}

void enif_free_env (ErlNifEnv* env)
{
  (void) env;
  return;
}

void enif_free_term (ERL_NIF_TERM term)
{
  (void) term;
  return;
}
