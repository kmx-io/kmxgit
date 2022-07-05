#ifndef MSTR_H
#define MSTR_H

#include <stdlib.h>

/**
 * Memory strings.
 *
 * All strings are malloc'd and stored in an index.
 * Easy to allocate, easy to free.
 */

void libmstr_init ();
void libmstr_shutdown ();

char * mstr_new (const char *str, size_t len);
void mstr_delete_all ();
char * mstr_find (const char *str, size_t len);
char * mstr (const char *fmt, ...);
char * mstr_len (const char *str, size_t len);
char * mstr1 (const char *str);

#endif /* MSTR_H */
