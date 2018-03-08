#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <string.h>
#include "buffer.h"
#include "uri.h"
#include "cookie.h"

#if defined(_WIN32) || defined(_WIN64)
#define snprintf    _snprintf
#define vsnprintf   _vsnprintf
#define strcasecmp  _stricmp
#define strncasecmp _strnicmp
#else
#include <strings.h>
#endif


/*
 * Some standard field names have no value associated:
 *
 *   Secure
 *   HttpOnly
 *
 * Macro TREATMENT_FOR_NAME_WITH_NO_VALUE controls what we do:
 *
 * 0: ignore these names, as if they had not been specified
 * 1: treat these names as having a value of undef, but only for the standard
 *    names listed above
 * 2: always treat these names as having a value of undef
 */
#define TREATMENT_FOR_NAME_WITH_NO_VALUE 2

/*
 * Possible field names in a cookie.
 */
#define COOKIE_NAME_VALUE      "value"
#define COOKIE_NAME_DOMAIN     "Domain"
#define COOKIE_NAME_PATH       "Path"
#define COOKIE_NAME_MAX_AGE    "Max-Age"
#define COOKIE_NAME_EXPIRES    "Expires"
#define COOKIE_NAME_SECURE     "Secure"
#define COOKIE_NAME_HTTP_ONLY  "HttpOnly"
#define COOKIE_NAME_SAME_SITE  "SameSite"

static void get_encoded_value(pTHX_ SV* val, Buffer* encoded, int encode)
{
    SV* ref = 0;
    const char* cvalue = 0;
    STRLEN vlen = 0;
    Buffer unencoded;
    int destroy = 0;

    if (SvROK(val)) {
        buffer_init(&unencoded , 0);
        destroy = 1;
        ref = SvRV(val);
        if (SvTYPE(ref) == SVt_PVHV) {
            fprintf(stderr, "HASH\n");
        }
        if (SvTYPE(ref) == SVt_PVAV) {
            AV* values = (AV*) ref;
            int top = av_top_index(values);
            for (int j = 0; j <= top; ++j) {
                SV** elem = av_fetch(values, j, 0);
                if (!SvOK(*elem) || !SvPOK(*elem)) {
                    continue;
                }
                cvalue = SvPV_const(*elem, vlen);
                if (j > 0) {
                    buffer_append(&unencoded, "&", 1);
                }
                buffer_append(&unencoded, cvalue, vlen);
            }
            vlen = unencoded.pos;
        }
    } else {
        cvalue = SvPV_const(val, vlen);
        buffer_wrap(&unencoded, cvalue, vlen);
    }
    buffer_reset(encoded);
    if (encode) {
        buffer_rewind(&unencoded);
        url_encode(&unencoded, vlen, encoded);
    } else {
        buffer_append(encoded, unencoded.data, vlen);
    }
    if (destroy) {
        buffer_fini(&unencoded);
    }
    buffer_terminate(encoded);
}

/*
 * Given a name and a value, which can be a string or a hashref,
 * build a cookie with that data.
 */
static void build_cookie(pTHX_ SV* pname, SV* pvalue, Buffer* cookie)
{
    const char* cname = 0;
    STRLEN nlen = 0;
    const char* cvalue = 0;
    STRLEN vlen = 0;
    SV* ref = 0;
    HV* values = 0;
    SV** nval = 0;
    Buffer encoded;

    /* name not a valid string? bail out */
    if (!SvOK(pname) || !SvPOK(pname)) {
        return;
    }

    /* value not a valid scalar? bail out */
    if (!SvOK(pvalue)) {
        return;
    }

    cname = SvPV_const(pname, nlen);

    if (SvPOK(pvalue)) {
        /* value is a simple string */
        cvalue = SvPV_const(pvalue, vlen);
        cookie_put_string(cookie, cname, nlen, cvalue, vlen, 1, 1);
        return;
    }

    /* value not a valid ref? bail out */
    if (!SvROK(pvalue)) {
        return;
    }

    /* value not a valid hashref? bail out */
    ref = SvRV(pvalue);
    if (SvTYPE(ref) != SVt_PVHV) {
        return;
    }
    values = (HV*) ref;

    /* value for name not there? bail out */
    nval = hv_fetch(values, COOKIE_NAME_VALUE, sizeof(COOKIE_NAME_VALUE) -1, 0);
    if (!nval) {
        return;
    }

    buffer_init(&encoded , 0);

    /* first store cookie name and value, URL-encoding both */
    get_encoded_value(aTHX_ *nval, &encoded, 1);
    cookie_put_string(cookie, cname, nlen, encoded.data, encoded.pos, 1, 0);

    /* now iterate over all other values */
    hv_iterinit(values);
    while (nval) {
        SV* val = 0;
        I32 klen = 0;
        char* key = 0;
        HE* entry = hv_iternext(values);
        if (!entry) {
            /* no more hash keys */
            break;
        }

        key = hv_iterkey(entry, &klen);
        if (!key || klen <= 0) {
            /* invalid key */
            continue;
        }

        if (strcmp(key, COOKIE_NAME_VALUE) == 0) {
            /* name was already processed */
            continue;
        }

        val = hv_iterval(values, entry);
        if (!SvOK(val)) {
            continue;
        }

        buffer_reset(&encoded);
        get_encoded_value(aTHX_ val, &encoded, 0);
        cvalue = encoded.data;
        vlen = encoded.pos;
        if (cvalue == 0) {
            continue;
        }

        /* TODO: should we skip if cvalue is invalid / empty? */

        if        (strcasecmp(key, COOKIE_NAME_DOMAIN) == 0) {
            cookie_put_string (cookie, COOKIE_NAME_DOMAIN   , sizeof(COOKIE_NAME_DOMAIN)    - 1, cvalue, vlen, 0, 0);
        } else if (strcasecmp(key, COOKIE_NAME_PATH      ) == 0) {
            cookie_put_string (cookie, COOKIE_NAME_PATH     , sizeof(COOKIE_NAME_PATH)      - 1, cvalue, vlen, 0, 0);
        } else if (strcasecmp(key, COOKIE_NAME_MAX_AGE   ) == 0) {
            cookie_put_string (cookie, COOKIE_NAME_MAX_AGE  , sizeof(COOKIE_NAME_MAX_AGE)   - 1, cvalue, vlen, 0, 0);
        } else if (strcasecmp(key, COOKIE_NAME_EXPIRES   ) == 0) {
            cookie_put_date (cookie, COOKIE_NAME_EXPIRES    , sizeof(COOKIE_NAME_EXPIRES)   - 1, cvalue);
        } else if (strcasecmp(key, COOKIE_NAME_SECURE    ) == 0) {
            cookie_put_boolean(cookie, COOKIE_NAME_SECURE   , sizeof(COOKIE_NAME_SECURE)    - 1, SvTRUE(val));
        } else if (strcasecmp(key, COOKIE_NAME_HTTP_ONLY ) == 0) {
            cookie_put_boolean(cookie, COOKIE_NAME_HTTP_ONLY, sizeof(COOKIE_NAME_HTTP_ONLY) - 1, SvTRUE(val));
        } else if (strcasecmp(key, COOKIE_NAME_SAME_SITE ) == 0) {
            cookie_put_string (cookie, COOKIE_NAME_SAME_SITE  , sizeof(COOKIE_NAME_SAME_SITE)   - 1, cvalue, vlen, 0, 0);
        }
    }
    buffer_fini(&encoded);
}

/*
 * Given a string, parse it as a cookie into its component values
 * and return a hashref with them.
 */
static HV* parse_cookie(pTHX_ SV* pstr)
{
    /* we will always return a hashref, maybe empty */
    HV* hv = newHV();

    do {
        const char* cstr = 0;
        STRLEN slen = 0;
        Buffer cookie;
        Buffer name;
        Buffer value;

        /* string not valid? bail out */
        if (!SvOK(pstr) || !SvPOK(pstr)) {
            break;
        }

        /* empty string? bail out */
        cstr = SvPV_const(pstr, slen);
        if (!cstr || !slen) {
            break;
        }

        /* wrap a Buffer around this string, so that we can
         * more easily work with it */
        buffer_wrap(&cookie, cstr, slen);

        /* prepare memory for name / value buffers */
        buffer_init(&name , 0);
        buffer_init(&value, 0);

        while (1) {
            /* reset buffers for name / value, avoiding memory reallocation */
            buffer_reset(&name);
            buffer_reset(&value);

            int equals = cookie_get_pair(&cookie, &name, &value);

            /* got an empty name => ran out of data */
            if (name.pos == 0) {
                break;
            }

            /* only first value seen for a name is kept */
            if (hv_exists(hv, name.data, name.pos)) {
                continue;
            }

            if (!equals) {
                /* didn't see an equal sign => name with no value */
#if TREATMENT_FOR_NAME_WITH_NO_VALUE == 0
                /* skip name */
#elif TREATMENT_FOR_NAME_WITH_NO_VALUE == 1
                /* TODO: only for known names */
                /* store a name => undef pair*/
                SV* nil = newSV(0);
                hv_store(hv, name.data, name.pos, nil, 0);
#elif TREATMENT_FOR_NAME_WITH_NO_VALUE == 2
                /* store a name => undef pair*/
                SV* nil = newSV(0);
                hv_store(hv, name.data, name.pos, nil, 0);
#else
                /* huh? */
#endif
                continue;
            }

            buffer_terminate(&value);
            char* word = strchr(value.data, '&');
            if (!word) {
                /* no & chars? simple string */
                SV* str = newSVpv(value.data, value.pos);
                hv_store(hv, name.data, name.pos, str, 0);
                continue;
            }

            /* & chars => create arrayref */
            AV* array = newAV();
            int key = 0;
            for (word = strtok(value.data, "&"); word; word = strtok(0, "&")) {
                SV* str = sv_2mortal(newSVpv(word, strlen(word)));
                if (av_store(array, key, str)) {
                    SvREFCNT_inc(str);
                }
                ++key;
            }
            SV* ref = newRV_noinc((SV*) array);
            hv_store(hv, name.data, name.pos, ref, 0);
        }

        /* release memory for name / value buffers */
        buffer_fini(&value);
        buffer_fini(&name );
    } while (0);

    return hv;
}


MODULE = HTTP::XSCookies        PACKAGE = HTTP::XSCookies
PROTOTYPES: DISABLE

#################################################################

SV*
bake_cookie(SV* name, SV* value)
  PREINIT:
    Buffer cookie;
  CODE:
    buffer_init(&cookie, 0);
    build_cookie(aTHX_ name, value, &cookie);
    RETVAL = newSVpv(cookie.data, cookie.pos);
    buffer_fini(&cookie);
  OUTPUT: RETVAL

SV*
crush_cookie(SV* str)
  CODE:
    RETVAL = newRV_noinc((SV *) parse_cookie(aTHX_ str));
  OUTPUT: RETVAL
