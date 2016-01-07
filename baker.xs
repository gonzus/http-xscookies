#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "buffer.h"
#include "cookie.h"

MODULE = Devel::Cookie        PACKAGE = Devel::Cookie
PROTOTYPES: DISABLE

#################################################################

const char*
bake_cookie(SV* name, SV* value)
  PREINIT:
    const char* cname = 0;
    STRLEN nlen = 0;
    const char* cvalue = 0;
    STRLEN vlen = 0;

    Buffer cookie;
    buffer_init(&cookie, 0);

  CODE:
    if (SvOK(name) && SvOK(value) && SvPOK(name)) {
        cname = SvPV_const(name, nlen);

        if (SvPOK(value)) {
            cvalue = SvPV_const(value, vlen);
            cookie_put_string(&cookie, cname, nlen, cvalue, vlen, 1);
        } else if (SvRV(value) && SvTYPE(SvRV(value)) == SVt_PVHV) {
            HV* values = (HV*) SvRV(value);
            SV** nval = 0;

            /* need value for name first */
            nval = hv_fetch(values, "value", strlen("value"), 0);
            if (nval) {
                cvalue = SvPV_const(*nval, vlen);
                cookie_put_string(&cookie, cname, nlen, cvalue, vlen, 1);
            }

            hv_iterinit(values);
            while (nval) {
                SV* val = 0;
                I32 klen = 0;
                char* key = 0;
                HE* entry = hv_iternext(values);
                if (!entry) {
                  break;
                }

                key = hv_iterkey(entry, &klen);
                if (!key || klen <= 0) {
                    continue;
                }

                cvalue = 0;
                vlen = 0;
                val = hv_iterval(values, entry);
                if (SvOK(val) && SvPOK(val)) {
                    cvalue = SvPV_const(val, vlen);
                }

                if (strcmp(key, "value") == 0) {
                    continue;
                } else if (strcmp(key, "domain" ) == 0 ||
                           strcmp(key, "path"   ) == 0 ||
                           strcmp(key, "max-age") == 0) {
                    cookie_put_string(&cookie, key  , klen, cvalue, vlen, 0);
                } else if (strcmp(key, "expires") == 0) {
                    cookie_put_date(&cookie, key  , klen, cvalue);
                } else if (strcmp(key, "secure"  ) == 0 ||
                           strcmp(key, "HttpOnly") == 0) {
                    cookie_put_boolean(&cookie, key  , klen, 1);
                }
            }
        }
    }
    RETVAL = cookie.data;

  OUTPUT: RETVAL

  CLEANUP:
    buffer_fini(&cookie);

HV*
crush_cookie(SV* str)
  PREINIT:
    const char* cstr = 0;
    STRLEN slen = 0;
    HV* hv = 0;
    SV* pval;
    Buffer cookie;
    Buffer name;
    Buffer value;

  CODE:
    hv = newHV();
    if (SvOK(str) && SvPOK(str)) {
        cstr = SvPV_const(str, slen);
        buffer_wrap(&cookie, cstr, slen);

        buffer_init(&name , 0);
        buffer_init(&value, 0);
        while (1) {
            buffer_reset(&name);
            buffer_reset(&value);
            cookie_get_pair(&cookie, &name, &value, 1);
            if (name.pos == 0) {
                break;
            }

            if (hv_exists(hv, name.data, name.pos)) {
                printf("Ignoring duplicate value [%s] for [%s]\n", value.data, name.data);
            } else {
                pval = newSVpv(value.data, value.pos);
                hv_store(hv, name.data, name.pos, pval, 0);
            }
        }
        buffer_fini(&value);
        buffer_fini(&name );
    }
    RETVAL = hv;

  OUTPUT: RETVAL
