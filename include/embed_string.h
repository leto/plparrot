/* embed_string.h
 *  Copyright (C) 2001-2008, Parrot Foundation.
 *  SVN Info
 *     $Id$
 *  Overview:
 *     This is the api header for the string subsystem
 *  Data Structure and Algorithms:
 *  History:
 *  Notes:
 *  References:
 */

#ifndef PARROT_EMBED_STRING_H_GUARD
#define PARROT_EMBED_STRING_H_GUARD

#include "parrot/compiler.h"

typedef struct parrot_string_t STRING;
typedef Parrot_UInt UINTVAL;
typedef Parrot_Int INTVAL;
typedef Parrot_Float FLOATVAL;
typedef unsigned long long UHUGEINTVAL;

PARROT_EXPORT
PARROT_WARN_UNUSED_RESULT
/* PARROT_CAN_RETURN_NULL */
STRING * Parrot_str_append(PARROT_INTERP,
    ARGMOD_NULLOK(STRING *a),
    ARGIN_NULLOK(STRING *b))
        __attribute__nonnull__(1)
        FUNC_MODIFIES(*a);

PARROT_EXPORT
PARROT_PURE_FUNCTION
UINTVAL Parrot_str_byte_length(SHIM_INTERP, ARGIN_NULLOK(const STRING *s));

PARROT_EXPORT
PARROT_WARN_UNUSED_RESULT
INTVAL Parrot_str_compare(PARROT_INTERP,
    ARGIN_NULLOK(const STRING *s1),
    ARGIN_NULLOK(const STRING *s2))
        __attribute__nonnull__(1);

PARROT_EXPORT
PARROT_CANNOT_RETURN_NULL
STRING * Parrot_str_concat(PARROT_INTERP,
    ARGIN_NULLOK(STRING *a),
    ARGIN_NULLOK(STRING *b),
    UINTVAL Uflags)
        __attribute__nonnull__(1);

PARROT_EXPORT
PARROT_CANNOT_RETURN_NULL
PARROT_WARN_UNUSED_RESULT
STRING * Parrot_str_copy(PARROT_INTERP, ARGMOD(STRING *s))
        __attribute__nonnull__(1)
        __attribute__nonnull__(2)
        FUNC_MODIFIES(*s);

PARROT_EXPORT
PARROT_WARN_UNUSED_RESULT
INTVAL Parrot_str_equal(PARROT_INTERP,
    ARGIN_NULLOK(const STRING *s1),
    ARGIN_NULLOK(const STRING *s2))
        __attribute__nonnull__(1);

PARROT_EXPORT
void Parrot_str_free_cstring(ARGIN_NULLOK(char *p));

PARROT_EXPORT
PARROT_WARN_UNUSED_RESULT
PARROT_CANNOT_RETURN_NULL
STRING * Parrot_str_from_int(PARROT_INTERP, INTVAL i)
        __attribute__nonnull__(1);

PARROT_EXPORT
PARROT_WARN_UNUSED_RESULT
PARROT_CANNOT_RETURN_NULL
STRING * Parrot_str_from_num(PARROT_INTERP, FLOATVAL f)
        __attribute__nonnull__(1);

PARROT_EXPORT
PARROT_IGNORABLE_RESULT
INTVAL /*@alt void@*/
Parrot_str_length(PARROT_INTERP, ARGMOD(STRING *s))
        __attribute__nonnull__(1)
        __attribute__nonnull__(2)
        FUNC_MODIFIES(*s);

PARROT_EXPORT
PARROT_WARN_UNUSED_RESULT
PARROT_MALLOC
PARROT_CANNOT_RETURN_NULL
STRING * Parrot_str_new(PARROT_INTERP,
    ARGIN_NULLOK(const char * const buffer),
    const UINTVAL len)
        __attribute__nonnull__(1);

PARROT_EXPORT
PARROT_WARN_UNUSED_RESULT
PARROT_CANNOT_RETURN_NULL
STRING * Parrot_str_new_constant(PARROT_INTERP, ARGIN(const char *buffer))
        __attribute__nonnull__(1)
        __attribute__nonnull__(2);

PARROT_EXPORT
PARROT_CANNOT_RETURN_NULL
STRING * Parrot_str_set(PARROT_INTERP,
    ARGIN_NULLOK(STRING *dest),
    ARGMOD(STRING *src))
        __attribute__nonnull__(1)
        __attribute__nonnull__(3)
        FUNC_MODIFIES(*src);

PARROT_EXPORT
PARROT_MALLOC
PARROT_CANNOT_RETURN_NULL
char * Parrot_str_to_cstring(PARROT_INTERP, ARGIN_NULLOK(const STRING *s))
        __attribute__nonnull__(1);

PARROT_EXPORT
PARROT_PURE_FUNCTION
PARROT_CANNOT_RETURN_NULL
const char * Parrot_string_cstring(SHIM_INTERP, ARGIN(const STRING *str))
        __attribute__nonnull__(2);

PARROT_EXPORT
INTVAL STRING_is_null(SHIM_INTERP, ARGIN_NULLOK(const STRING *s));

PARROT_WARN_UNUSED_RESULT
PARROT_CANNOT_RETURN_NULL
STRING* Parrot_str_from_uint(PARROT_INTERP,
    ARGOUT(char *tc),
    UHUGEINTVAL num,
    unsigned int base,
    int minus)
        __attribute__nonnull__(1)
        __attribute__nonnull__(2)
        FUNC_MODIFIES(*tc);

#define ASSERT_ARGS_Parrot_str_append __attribute__unused__ int _ASSERT_ARGS_CHECK = (\
       PARROT_ASSERT_ARG(interp))
#define ASSERT_ARGS_Parrot_str_byte_length __attribute__unused__ int _ASSERT_ARGS_CHECK = (0)
#define ASSERT_ARGS_Parrot_str_compare __attribute__unused__ int _ASSERT_ARGS_CHECK = (\
       PARROT_ASSERT_ARG(interp))
#define ASSERT_ARGS_Parrot_str_concat __attribute__unused__ int _ASSERT_ARGS_CHECK = (\
       PARROT_ASSERT_ARG(interp))
#define ASSERT_ARGS_Parrot_str_copy __attribute__unused__ int _ASSERT_ARGS_CHECK = (\
       PARROT_ASSERT_ARG(interp) \
    , PARROT_ASSERT_ARG(s))
#define ASSERT_ARGS_Parrot_str_equal __attribute__unused__ int _ASSERT_ARGS_CHECK = (\
       PARROT_ASSERT_ARG(interp))
#define ASSERT_ARGS_Parrot_str_free_cstring __attribute__unused__ int _ASSERT_ARGS_CHECK = (0)
#define ASSERT_ARGS_Parrot_str_from_int __attribute__unused__ int _ASSERT_ARGS_CHECK = (\
       PARROT_ASSERT_ARG(interp))
#define ASSERT_ARGS_Parrot_str_from_num __attribute__unused__ int _ASSERT_ARGS_CHECK = (\
       PARROT_ASSERT_ARG(interp))
#define ASSERT_ARGS_Parrot_str_length __attribute__unused__ int _ASSERT_ARGS_CHECK = (\
       PARROT_ASSERT_ARG(interp) \
    , PARROT_ASSERT_ARG(s))
#define ASSERT_ARGS_Parrot_str_new __attribute__unused__ int _ASSERT_ARGS_CHECK = (\
       PARROT_ASSERT_ARG(interp))
#define ASSERT_ARGS_Parrot_str_new_constant __attribute__unused__ int _ASSERT_ARGS_CHECK = (\
       PARROT_ASSERT_ARG(interp) \
    , PARROT_ASSERT_ARG(buffer))
#define ASSERT_ARGS_Parrot_str_set __attribute__unused__ int _ASSERT_ARGS_CHECK = (\
       PARROT_ASSERT_ARG(interp) \
    , PARROT_ASSERT_ARG(src))
#define ASSERT_ARGS_Parrot_str_to_cstring __attribute__unused__ int _ASSERT_ARGS_CHECK = (\
       PARROT_ASSERT_ARG(interp))
#define ASSERT_ARGS_Parrot_str_to_int __attribute__unused__ int _ASSERT_ARGS_CHECK = (\
       PARROT_ASSERT_ARG(interp))
#define ASSERT_ARGS_Parrot_str_to_num __attribute__unused__ int _ASSERT_ARGS_CHECK = (\
       PARROT_ASSERT_ARG(interp) \
    , PARROT_ASSERT_ARG(s))
#define ASSERT_ARGS_Parrot_string_cstring __attribute__unused__ int _ASSERT_ARGS_CHECK = (\
       PARROT_ASSERT_ARG(str))
#define ASSERT_ARGS_STRING_is_null __attribute__unused__ int _ASSERT_ARGS_CHECK = (0)
#define ASSERT_ARGS_Parrot_str_from_uint __attribute__unused__ int _ASSERT_ARGS_CHECK = (\
       PARROT_ASSERT_ARG(interp) \
    , PARROT_ASSERT_ARG(tc))

#endif /* PARROT_EMBED_STRING_H_GUARD */
