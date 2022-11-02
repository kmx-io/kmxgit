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
#ifndef ENIF_H
#define ENIF_H

#include <erl_nif.h>

ERL_NIF_TERM enif_string_to_term (ErlNifEnv *env,
                                  const char *str);
char *       enif_term_to_string (ErlNifEnv *env,
                                  const ERL_NIF_TERM term);
ERL_NIF_TERM enif_string_to_term_len (ErlNifEnv *env,
                                      const char *str, size_t len);
ERL_NIF_TERM enif_make_tuple2 (ErlNifEnv* env, ERL_NIF_TERM e1,
                               ERL_NIF_TERM e2);

#endif /* ENIF_H */
