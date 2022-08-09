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
#include "mstr.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <err.h>

typedef struct mstr_list_cell s_mstr_list_cell;

struct mstr_list_cell
{
  char *str;
  s_mstr_list_cell *next;
};

s_mstr_list_cell *g_mstr = 0;

void libmstr_init ()
{
  g_mstr = 0;
}

void libmstr_shutdown ()
{
  mstr_delete_all();
}

s_mstr_list_cell * mstr_list_cell_new (char *str,
                                       s_mstr_list_cell *next)
{
  s_mstr_list_cell *cell;
  cell = malloc(sizeof(s_mstr_list_cell));
  if (cell) {
    cell->str = str;
    cell->next = next;
  }
  return cell;
}

s_mstr_list_cell * mstr_list_cell_delete (s_mstr_list_cell *cell)
{
  if (cell) {
    s_mstr_list_cell *next = cell->next;
    free(cell->str);
    free(cell);
    return next;
  }
  return NULL;
}

char * mstr_new (const char *str, size_t len)
{
  s_mstr_list_cell *cell;
  char *n;
  n = malloc(len + 1);
  if (n) {
    memcpy(n, str, len);
    n[len] = 0;
    cell = mstr_list_cell_new(n, g_mstr);
    if (cell)
      g_mstr = cell;
    else
      err(1, "mstr_list_cell_new");
  }
  return n;
}

void mstr_delete_all ()
{
  while (g_mstr)
    g_mstr = mstr_list_cell_delete(g_mstr);
}

char * mstr_find (const char *str, size_t len)
{
  s_mstr_list_cell *i;
  i = g_mstr;
  while (i) {
    if (strncmp(i->str, str, len) == 0)
      return i->str;
    i = i->next;
  }
  return NULL;
}

char * mstr (const char *fmt, ...)
{
  va_list ap;
  size_t len = 0;
  char *s = NULL;
  char *s2 = NULL;
  va_start(ap, fmt);
  int r = 0;
  r = vasprintf(&s, fmt, ap);
  va_end(ap);
  if (r < 0)
    return NULL;
  len = r + 1;
  s2 = mstr_len(s, len);
  free(s);
  return s2;
}

char * mstr1 (const char *str)
{
    size_t len = strlen(str) + 1;
    return mstr_len(str, len);
}


char * mstr_len (const char *str, size_t len)
{
  char *found = 0;
  found = mstr_find(str, len);
  if (found)
    return found;
  return mstr_new(str, len);
}
