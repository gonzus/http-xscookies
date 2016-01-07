#include <ctype.h>
#include <memory.h>
#include <stdio.h>
#include "buffer.h"
#include "uri.h"
#include "date.h"
#include "cookie.h"

static Buffer* cookie_put_value(Buffer* cookie,
                                const char* name, int nlen,
                                const char* value, int vlen,
                                int boolean, int encode)
{
    Buffer dnam;
    Buffer dval;
    buffer_wrap(&dnam, name , nlen);
    buffer_wrap(&dval, value, vlen);

    Buffer enam;
    Buffer eval;

    int size = 0;

    /* first compute how much space we will use */
    do {
        /* if the cookie is not empty, we will need space for
         * the ';' to separate from previous values */
        if (cookie->pos > 0) {
            ++size;
        }

        /* space for the name, posibly URL-encoded */
        if (!encode) {
            size += dnam.size;
        } else {
            buffer_init(&enam, 3 * dnam.size);
            url_encode(&dnam, dnam.size, &enam);
            size += enam.pos;
        }

        /* if this is a boolean value, it only has a name */
        if (boolean) {
            break;
        }

        /* space for the '=' to separate name and value */
        ++size;

        /* space for the value, posibly URL-encoded */
        if (!encode) {
            size += dval.size;
        } else {
            buffer_init(&eval, 3 * dval.size);
            url_encode(&dval, dval.size, &eval);
            size += eval.pos;
        }
    } while (0);

    /* make sure we have enough space in cookie */
    buffer_ensure_delta(cookie, size);

    /* now output each part into the cookie */
    do {
        if (cookie->pos > 0) {
            buffer_append(cookie, ";", 1);
        }

        if (!encode) {
            buffer_append(cookie, dnam.data, dnam.size);
        } else {
            buffer_append(cookie, enam.data, enam.pos);
            buffer_fini(&enam);
        }

        if (boolean) {
            break;
        }

        buffer_append(cookie, "=", 1);

        if (!encode) {
            buffer_append(cookie, dval.data, dval.size);
        } else {
            buffer_append(cookie, eval.data, eval.pos);
            buffer_fini(&eval);
        }
    } while (0);

    return buffer_terminate(cookie);
}

Buffer* cookie_put_string(Buffer* cookie,
                          const char* name, int nlen,
                          const char* value, int vlen,
                          int encode)
{
    return cookie_put_value(cookie, name, nlen, value, vlen, 0, encode);
}

Buffer* cookie_put_date(Buffer* cookie,
                        const char* name, int nlen,
                        const char* value)
{
    double date = date_compute(value);
    Buffer format;
    buffer_init(&format, 0);
    date_format(date, &format);
    cookie_put_value(cookie, name, nlen, format.data, format.pos, 0, 0);
    buffer_fini(&format);
    return cookie;
}

Buffer* cookie_put_integer(Buffer* cookie,
                           const char* name, int nlen,
                           long value)
{
    char buf[50];
    int blen = 0;
    sprintf(buf, "%ld", value);
    blen = strlen(buf);
    return cookie_put_value(cookie, name, nlen, buf, blen, 0, 0);
}

Buffer* cookie_put_boolean(Buffer* cookie,
                           const char* name, int nlen,
                           int value)
{
    if (!value) {
        return cookie;
    }

    char buf[50];
    int blen = 0;
    strcpy(buf, "1");
    blen = strlen(buf);
    return cookie_put_value(cookie, name, nlen, buf, blen, 1, 0);
}

Buffer* cookie_get_pair(Buffer* cookie,
                        Buffer* name, Buffer* value,
                        int decode)
{
    int state = 0;
    int npos = 0;
    int vpos = 0;
    int nlen = 0;
    int vlen = 0;

    while (1) {
        char c = cookie->data[cookie->pos];
        if (c == '\0' || c == ';') {
            if (state == 1) {
                nlen = cookie->pos - npos;
            } else if (state == 3) {
                vlen = cookie->pos - vpos;
            }
            state = 9;
        } else if (isspace(c)) {
            /* just skip whitespace */
        } else if (c == '=') {
            if (state != 1) {
                state = 9;
            } else {
                nlen = cookie->pos - npos;
                state = 2;
            }
        } else {
            if (state == 0) {
                npos = cookie->pos;
                state = 1;
            } else if (state == 1) {
                /* ok, keep reading name */
            } else if (state == 2) {
                vpos = cookie->pos;
                state = 3;
            } else if (state == 3) {
                /* ok, keep reading value */
            }
        }
        if (c != '\0') {
            ++cookie->pos;
        }
        if (state == 9) {
            break;
        }
    }

    do {
        if (!nlen) {
            break;
        }

        if (!decode) {
            buffer_ensure_delta(name, nlen);
            buffer_append(name, cookie->data + npos, nlen);
        } else {
            Buffer enam;
            buffer_wrap(&enam, cookie->data + npos, nlen);
            Buffer dnam;
            buffer_init(&dnam, nlen);
            url_decode(&enam, nlen, &dnam);
            buffer_append(name, dnam.data, dnam.pos);
            buffer_fini(&dnam);
        }

        if (!vlen) {
            buffer_ensure_delta(value, 1);
            strcpy(value->data + value->pos, "1");
            value->pos += 1;
            break;
        }

        if (!decode) {
            buffer_ensure_delta(value, vlen);
            buffer_append(value, cookie->data + vpos, vlen);
        } else {
            Buffer eval;
            buffer_wrap(&eval, cookie->data + vpos, vlen);
            Buffer dval;
            buffer_init(&dval, vlen);
            url_decode(&eval, vlen, &dval);
            buffer_append(value, dval.data, dval.pos);
            buffer_fini(&dval);
        }
    } while (0);

    buffer_terminate(name);
    buffer_terminate(value);
    return cookie;
}
