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
