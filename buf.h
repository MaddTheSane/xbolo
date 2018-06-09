/*
 *  buf.h
 *  XBolo
 *
 *  Created by Robert Chrzanowski on 10/15/09.
 *  Copyright 2009 Robert Chrzanowski. All rights reserved.
 *
 */

#ifndef __BUF__
#define __BUF__

#include "errchk.h"

#include <unistd.h>

struct Buf {
  void *ptr;
  size_t nbytes;
  size_t size;
} ;

/** Initializes and allocates a buffer.  Returns \c -1 on error and sets <code>errno</code>. */
int initbuf(struct Buf *buf);

/** Frees a buffer. */
void freebuf(struct Buf *buf);

/** Writes to the end of a buffer and returns the number of bytes written.  Returns \c -1 on error and sets <code>errno</code>. */
ssize_t writebuf(struct Buf *buf, const void *data, size_t nbytes);

/** Writes the first \c nbytes from the buffer to data and shifts the remaining bytes.  
    If data is \c NULL no bytes are written.
    Returns the number of bytes removed.  Returns \c -1 on error and sets <code>errno</code>. */
ssize_t readbuf(struct Buf *buf, void *data, size_t nbytes);

/** Attempts nonblocking \c send() of buf to descriptor <code>d</code>.  
    Returns the number of bytes written or \c 0 if no bytes are sent.
    Returns \c -1 on error and sets <code>errno</code>. */
ssize_t sendbuf(struct Buf *buf, int d);

/** Attempts nonblocking \c recv() of descriptor \c d to the end of the buffer.  
    Returns the number of bytes received or \c 0 if no data is ready or if the 
    socket has been closed by the distent end.  \c Select() returns with it 
    is ready for reading in that case.
    Returns \c -1 on error and sets <code>errno</code>. */
ssize_t recvbuf(struct Buf *buf, int d);

int selectreadwrite(int readsock, int writesock);
int selectreadread(int readsock1, int readsock2);
int cntlsend(int cntlsock, int sock, struct Buf *buf);
int cntlrecv(int cntlsock, int sock, struct Buf *buf, size_t nbytes);

#endif  /* __BUF__ */
