#ifndef BUFFER_H_
#define BUFFER_H_

#define BUFFER_SIZEOF_DESIRED 48

typedef struct Buffer {
    unsigned int pos;
    unsigned int size;
    char* data;
    char fixed[BUFFER_SIZEOF_DESIRED - 2*sizeof(unsigned int) - 1*sizeof(char*)];
} Buffer;

Buffer* buffer_init(Buffer* buffer, unsigned int size);
Buffer* buffer_fini(Buffer* buffer);

Buffer* buffer_wrap(Buffer* buffer, const char* data, unsigned int length);

Buffer* buffer_ensure_total(Buffer* buffer, unsigned int size);
Buffer* buffer_ensure_delta(Buffer* buffer, unsigned int size);

Buffer* buffer_reset(Buffer* buffer);
Buffer* buffer_rewind(Buffer* buffer);
Buffer* buffer_terminate(Buffer* buffer);

Buffer* buffer_append(Buffer* buffer, const char* source, unsigned int length);

#endif
