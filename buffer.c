#include <stdlib.h>
#include <string.h>
#include "gmem.h"
#include "buffer.h"

#define BUFFER_SIZE_INIT   32
#define BUFFER_SIZE_FACTOR 2

static void buffer_zero(Buffer* buffer)
{
    buffer->size = 0;
    buffer->pos = 0;
    buffer->data = 0;
}

Buffer* buffer_init(Buffer* buffer, unsigned int size)
{
    buffer_zero(buffer);

    unsigned int target = size > 0 ? size+1 : BUFFER_SIZE_INIT;

    if (size > sizeof(buffer->fixed)) {
        GMEM_NEW(buffer->data, char*, target);
        buffer->size = target;
    } else {
        buffer->data = buffer->fixed;
        buffer->size = sizeof(buffer->fixed);
    }

    return buffer_reset(buffer);
}

Buffer* buffer_fini(Buffer* buffer)
{
    if (buffer->data &&
        buffer->data != buffer->fixed) {
        GMEM_DEL(buffer->data, char*, buffer->size);
    }

    buffer_zero(buffer);

    return buffer;
}

Buffer* buffer_reset(Buffer* buffer)
{
    buffer_rewind(buffer);
    buffer_terminate(buffer);
    return buffer;
}

Buffer* buffer_rewind(Buffer* buffer)
{
    buffer->pos = 0;
    return buffer;
}

Buffer* buffer_terminate(Buffer* buffer)
{
    if (buffer->pos < buffer->size) {
        buffer->data[buffer->pos] = '\0';
    }
    return buffer;
}

Buffer* buffer_wrap(Buffer* buffer, const char* data, unsigned int length)
{
    buffer_zero(buffer);

    if (length == 0 && data[0] != '\0') {
        length = strlen(data) + 1;
    }
    buffer->size = length;
    buffer->data = (char*) data;

    return buffer;
}

Buffer* buffer_ensure_total(Buffer* buffer, unsigned int size)
{
    unsigned int needed = size + 1;
    if (buffer->size >= needed) {
        return buffer;
    }

    unsigned int target = BUFFER_SIZE_INIT;
    while (target < needed) {
        target *= BUFFER_SIZE_FACTOR;
    }

    if (buffer->data == buffer->fixed) {
        GMEM_NEW(buffer->data, char*, target);
        memcpy(buffer->data, buffer->fixed, buffer->size);
    } else {
        GMEM_REALLOC(buffer->data, char*, buffer->size, target);
    }
    buffer->size = target;

    return buffer;
}

Buffer* buffer_ensure_delta(Buffer* buffer, unsigned int size)
{
    unsigned int needed = size + 1;
    unsigned int left = buffer->size - buffer->pos;
    if (needed <= left) {
        return buffer;
    }

    return buffer_ensure_total(buffer, buffer->pos + size);
}

Buffer* buffer_append(Buffer* buffer, const char* source, unsigned int length)
{
    buffer_ensure_delta(buffer, length);
    memcpy(buffer->data + buffer->pos, source, length);
    buffer->pos += length;
    return buffer;
}
