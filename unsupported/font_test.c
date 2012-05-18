#include <gb.h>

UWORD load_font( void *font );
UWORD set_font( UWORD font_handle );
void mprint_string( char *string );
void init_font();

extern char font_std[];
extern char font_batforever[];
extern char font_tennis[];

int main()
{
	UWORD font_std_handle;
	UWORD font_batman_handle;
	char message[] = "Hi There!";

	init_font();
	font_std_handle = load_font( font_std );
	font_batman_handle = load_font( font_tennis );
	
	set_font( font_std_handle );
	mprint_string( "Hi " );

	set_font( font_batman_handle );
	mprint_string( "There!" );

	return 0;
}
