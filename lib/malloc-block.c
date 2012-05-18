/** @name malloc-block
    Implementation of malloc() and free() where all block
*/

#define NUM_TYPES	4

#define NUM_TYPE_0	10
#define SIZE_TYPE_0	32

#define NUM_TYPE_1	10
#define SIZE_TYPE_1	64

#define NUM_TYPE_2	10
#define SIZE_TYPE_2	128

#define NUM_TYPE_3	10
#define SIZE_TYPE_3	256

typedef struct _MALLOC_HUNK MALLOC_HUNK;
  
struct _MALLOC_HUNK {
    MALLOC_HUNK *pNext;
    BYTE bFlags;
};

typedef struct MALLOC_SECTION {
    MALLOC_HUNK *pFirst;
};

static MALLOC_SECTION _aSections[NUM_TYPES];

#define HEADER_OVERHEAD sizeof(MALLOC_HUNK)

void *malloc(INT16 iSize)
{
    MALLOC_SECTION *pSect = NULL;
    MALLOC_HUNK *pRet;

    iSize -= HEADER_OVERHEAD;

    if (iSize <= SIZE_TYPE_0) {
	pSect = _aSections[0];
    }
    else if (iSize <= SIZE_TYPE_1) {
	pSect = _aSections[1];
    }
    else if (iSize <= SIZE_TYPE_2) {
	pSect = _aSections[2];
    }
    else if (iSize <= SIZE_TYPE_3) {
	pSect = _aSections[3];
    }
    else {
	/* Wont fit into any of the blocks */
	return NULL;
    }
    if ((pRet = pSect->pFirst)) {
	/* There's at least one block free.  Return the one from
	   the top of the list. */
	pSect->pFirst = pRet->pNext;
	return (void *)((BYTE *)pRet + HEADER_OVERHEAD);
    }
    /* No free blocks in this class */
    return NULL;
}

BYTE free(void *pToFree)
{
    MALLOC_HUNK *pHunk;
    if (pToFree) {
	/* Adjust the pointer so we get ahold of the header */
	pHunk = (MALLOC_HUNK *)((BYTE *)pToFree - HEADER_OVERHEAD);
	switch (
    }
}

