#ifndef BUFFER_H_
#define BUFFER_H_

typedef struct Buffer {
    char* data;
    int pos;
    unsigned int size;
} Buffer;

Buffer* buffer_init(Buffer* buffer, unsigned int size);
Buffer* buffer_fini(Buffer* buffer);

Buffer* buffer_wrap(Buffer* buffer, const char* data, int length);

Buffer* buffer_ensure_total(Buffer* buffer, int size);
Buffer* buffer_ensure_delta(Buffer* buffer, int size);

Buffer* buffer_reset(Buffer* buffer);
Buffer* buffer_rewind(Buffer* buffer);
Buffer* buffer_terminate(Buffer* buffer);

Buffer* buffer_append(Buffer* buffer, const char* source, int length);

#endif
