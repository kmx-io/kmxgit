/*
 * Copyright 2022 Thomas de Grivel <thoxdg@gmail.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
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
