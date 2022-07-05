#include <stdlib.h>
#include <string.h>
#include "enif.h"

ERL_NIF_TERM enif_string_to_term (ErlNifEnv *env,
                                  const char *str)
{
  size_t len = strlen(str);
  return enif_string_to_term_len(env, str, len);
}

ERL_NIF_TERM enif_string_to_term_len (ErlNifEnv *env,
                                      const char *str, size_t len)
{
  ErlNifBinary bin;
  enif_alloc_binary(len, &bin);
  memcpy(bin.data, str, len);
  return enif_make_binary(env, &bin);
}

char * enif_term_to_string (ErlNifEnv *env,
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
