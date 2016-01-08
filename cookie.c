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

    /* output each part into the cookie */
    do {
        Buffer encoded;
        if (encode) {
            unsigned int size = dnam.size;
            if (size < dval.size) {
                size = dval.size;
            }
            buffer_init(&encoded, 3 * size);
        }

        if (cookie->pos > 0) {
            buffer_append(cookie, ";", 1);
        }

        if (!encode) {
            buffer_append(cookie, dnam.data, dnam.size);
        } else {
            buffer_rewind(&encoded);
            url_encode(&dnam, dnam.size, &encoded);
            buffer_append(cookie, encoded.data, encoded.pos);
        }

        if (!boolean) {
            buffer_append(cookie, "=", 1);

            if (!encode) {
                buffer_append(cookie, dval.data, dval.size);
            } else {
                buffer_rewind(&encoded);
                url_encode(&dval, dval.size, &encoded);
                buffer_append(cookie, encoded.data, encoded.pos);
            }
        }

        if (encode) {
            buffer_fini(&encoded);
        }
    } while (0);

    buffer_terminate(cookie);
    return cookie;
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
    char buf[50]; /* FIXED BUFFER OK: to format a long */
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

    char buf[50]; /* FIXED BUFFER OK: to format a boolean */
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

        Buffer encoded;
        Buffer decoded;
        if (decode) {
            unsigned int size = nlen;
            if (size < vlen) {
                size = vlen;
            }
            buffer_init(&decoded, size);
        }

        if (!decode) {
            buffer_append(name, cookie->data + npos, nlen);
        } else {
            buffer_wrap(&encoded, cookie->data + npos, nlen);
            buffer_rewind(&decoded);
            url_decode(&encoded, nlen, &decoded);
            buffer_append(name, decoded.data, decoded.pos);
        }

        if (!vlen) {
            buffer_append(value, "1", 1);
        } else {
            if (!decode) {
                buffer_append(value, cookie->data + vpos, vlen);
            } else {
                buffer_wrap(&encoded, cookie->data + vpos, vlen);
                buffer_rewind(&decoded);
                url_decode(&encoded, vlen, &decoded);
                buffer_append(value, decoded.data, decoded.pos);
            }
        }

        if (decode) {
            buffer_fini(&decoded);
        }
    } while (0);

    buffer_terminate(name);
    buffer_terminate(value);
    return cookie;
}
