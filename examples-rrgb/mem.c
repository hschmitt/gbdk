#include <stdlib.h>
#include <sys/malloc.h>
#include <stdio.h>
#include <string.h>

int malloc_walk_list(void)
{
	/* Print out the hunks currently present */
	pmmalloc_hunk thisHunk;

	thisHunk = malloc_first;
	while (thisHunk&&(thisHunk->magic == MALLOC_MAGIC)) {
		printf("Start: %lx\n", (UWORD)thisHunk );
		printf("  Len: %ld, ", thisHunk->size );
		switch(thisHunk->status) {
			case MALLOC_FREE:
				printf("MALLOC_FREE\n");
				break;
			case MALLOC_USED:
				printf("MALLOC_USED\n");
				break;
			default:
				printf("Invalid status.\n");
		}
		thisHunk = thisHunk->next;
	}
	if (thisHunk!=NULL)
		debug("malloc_walk_list","Corrupted malloc list found.");
	return 0;
}

int main(void)
{
	char *string, *string2;

	malloc_init();
	malloc_walk_list();

	string = malloc( 10 );
	strcpy( string, "Hi" );
	malloc_walk_list();
	string = realloc( string, 3 );
	malloc_walk_list();
	printf("%s\n", string );
	malloc_gc();
	malloc_walk_list();
	return 0;
}
