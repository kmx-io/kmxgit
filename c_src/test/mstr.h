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
