#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "gmem.h"
#include "buffer.h"

#define BUFFER_SIZE_INIT   32
#define BUFFER_SIZE_FACTOR 2

Buffer* buffer_init(Buffer* buffer, unsigned int size)
{
    int target = size > 0 ? size : BUFFER_SIZE_INIT;

    GMEM_NEW(buffer->data, char*, target);
    buffer->size = target;

    return buffer_reset(buffer);
}

Buffer* buffer_fini(Buffer* buffer)
{
    if (buffer->data) {
        GMEM_DEL(buffer->data, char*, buffer->size);
    }
    buffer->size = 0;
    buffer->pos = 0;
    buffer->data = 0;

    return buffer;
}

Buffer* buffer_wrap(Buffer* buffer, const char* data, int length)
{
    buffer->data = (char*) data;
    buffer->pos = 0;
    if (length < 0) {
        length = strlen(data);
    }
    buffer->size = length;

    return buffer;
}

Buffer* buffer_ensure_total(Buffer* buffer, int size)
{
    int needed = size + 1;
    if (buffer->size >= needed) {
        return buffer;
    }

    int target = BUFFER_SIZE_INIT;
    while (target < needed) {
        target *= BUFFER_SIZE_FACTOR;
    }

    GMEM_REALLOC(buffer->data, char*, buffer->size, target);
    buffer->size = target;

    return buffer;
}

Buffer* buffer_ensure_delta(Buffer* buffer, int size)
{
    int needed = size + 1;
    int left = buffer->size - buffer->pos;
    if (needed <= left) {
        return buffer;
    }

    return buffer_ensure_total(buffer, buffer->pos + size);
}

#if 0
int buffer_left(const Buffer* buffer)
{
    return buffer->size - buffer->pos;
}
#endif

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
    if (buffer->size > buffer->pos) {
        buffer->data[buffer->pos] = '\0';
    }
    return buffer;
}

Buffer* buffer_append(Buffer* buffer, const char* source, int length)
{
    memcpy(buffer->data + buffer->pos, source, length);
    buffer->pos += length;
    return buffer;
}
