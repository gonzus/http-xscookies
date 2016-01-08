#ifndef BUFFER_H_
#define BUFFER_H_

/*
 * An implementation of a byte buffer with the following characteristics:
 *
 * + Can be used to wrap an existing char* and give it the semantics of
 *   a buffer.
 * + Can be used a a newly allocated memory buffer; if the needed size is
 *   small (see below), it will use a stack array and will not allocate
 *   any memory.
 * + Can grow as needed, using realloc (and moving the data from the stack
 *   array if needed).
 */

/*
 * How big we want our struct to be, total size, in bytes.
 */
#define BUFFER_SIZEOF_DESIRED 64

/*
 * Definition for a Buffer. Fields are:
 *
 * + pos: current position in buffer
 * + size: maximum size for buffer
 * + data: pointer to the underlying memory
 * + fixed: array for small buffers, whose size is adjusted so that
 *          it will make the Buffer be BUFFER_SIZEOF_DESIRED bytes.
 */
typedef struct Buffer {
    unsigned int pos;
    unsigned int size;
    char* data;
    char fixed[  BUFFER_SIZEOF_DESIRED
               - 2*sizeof(unsigned int)
               - 1*sizeof(char*)];
} Buffer;

/*
 * Initialize / finalize a buffer that could either use the
 * internal stack array or dynamically allocate memory.
 */
Buffer* buffer_init(Buffer* buffer, unsigned int size);
Buffer* buffer_fini(Buffer* buffer);

/*
 * Wrap an existing char* to be used as a buffer.
 */
Buffer* buffer_wrap(Buffer* buffer, const char* data, unsigned int length);

/*
 * Make sure the total size of the buffer is at least size.
 */
Buffer* buffer_ensure_total(Buffer* buffer, unsigned int size);

/*
 * Make sure the unused space in the buffer is at least size.
 */
Buffer* buffer_ensure_unused(Buffer* buffer, unsigned int size);

/*
 * Set buffer position to 0.
 */
Buffer* buffer_rewind(Buffer* buffer);

/*
 * Put a '\0' in the current position of buffer.
 */
Buffer* buffer_terminate(Buffer* buffer);

/*
 * Rewind and terminate buffer.
 */
Buffer* buffer_reset(Buffer* buffer);

/*
 * Append a given char* (with indicated, optional length) to the buffer.
 * If length is 0, compute it using strlen(source);
 * If necessary, grow the buffer before appending.
 */
Buffer* buffer_append(Buffer* buffer, const char* source, unsigned int length);

#endif
