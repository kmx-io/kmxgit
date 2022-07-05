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
