#include <ctype.h>
#include <string.h>
#include "uri.h"

/* This file is generated automatically with program "encode" */
#include "tables.h"

#define NIBBLE_BITS 4
#define MAKE_BYTE(nh, nl) (((nh) << NIBBLE_BITS) | (nl))

Buffer* url_decode(Buffer* src, int length,
                   Buffer* tgt)
{
    if (length < 0) {
        length = src->size;
    }

    /* check and maybe increase space in target */
    buffer_ensure_unused(tgt, length);

    int s = src->pos;
    int t = tgt->pos;
    while (s < (src->pos + length)) {
        /* if current source is not '%', just copy it to target */
        if (src->data[s] != '%') {
            tgt->data[t++] = src->data[s++];
            continue;
        }

        /* if next two characters are not valid hex digits, abort */
        if (!isxdigit(src->data[s+1]) ||
            !isxdigit(src->data[s+2])) {
            t = 0;
            break;
        }

        /* put a byte together from the next two hex digits */
        tgt->data[t++] = MAKE_BYTE(dectbl[(int)src->data[s+1]],
                                   dectbl[(int)src->data[s+2]]);

        /* we used up 3 characters (%XY) from source */
        s += 3;
    }

    /* null-terminate target and return src as was left */
    src->pos = s;
    tgt->pos = t;
    buffer_terminate(tgt);
    return src;
}

Buffer* url_encode(Buffer* src, int length,
                   Buffer* tgt)
{
    if (length < 0) {
        length = src->size;
    }

    /* check and maybe increase space in target */
    buffer_ensure_unused(tgt, 3 * length);

    int s = src->pos;
    int t = tgt->pos;
    while (s < (src->pos + length)) {
        char* v = enctbl[(int)src->data[s]];

        /* if current source character doesn't need to be encoded,
           just copy it to target*/
        if (!v) {
            tgt->data[t++] = src->data[s++];
            continue;
        }

        /* copy encoded character from our table */
        tgt->data[t+0] = '%';
        tgt->data[t+1] = v[0];
        tgt->data[t+2] = v[1];

        /* we used up 3 characters (%XY) in target
         * and 1 character from source */
        t += 3;
        ++s;
    }

    /* null-terminate target and return src as was left */
    src->pos = s;
    tgt->pos = t;
    buffer_terminate(tgt);
    return src;
}
