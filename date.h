#ifndef DATE_H_
#define DATE_H_

#include "buffer.h"

double date_compute(const char *date);

int date_format(double date, char* format);

#endif
