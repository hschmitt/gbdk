/*
fish  MACRO args
label:
label:   opcode   argument1,argument2
         opcode   argument1,argument2
         .directive  arguments
         macroname args
; Comment

So:
Having detected a space, enter 'scan for opcode or directive' mode
A ; , ' ' or '\n' can end anything
*/
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

#define RST                   0
#define SOPCODE_OR_DIRECTIVE  1
#define SOPCODE               2
#define SDIRECTIVE            3
#define SLABEL_OR_MACRO       4
#define SCOMMENT              5
#define SMACRO                6
#define SLABEL                7
#define SMACRO_WS             8
#define SMACRO_ARGS           9
#define SMACRO_ARGS_WS        10
#define SLABEL_WS             11
#define SOPCODE_ARGS          12
#define SOPCODE_ARGS_WS       13
#define SOPCODE_ARGS_SPECIAL	14
#define SOPCODE_ARGS_STRING	15
#define SOPCODE_COMMA		16
#define SOPCODE_ARGS_ENDSTRING	17
char state_names[][22] = {
   "RST", "SOPCODE_OR_DIRECTIVE", "SOPCODE", "SDIRECTIVE",
	"SLABEL_OR_MACRO", "SCOMMENT", "SMACRO", "SLABEL", "SMACRO_WS",
   "SMACRO_ARGS", "SMACRO_ARGS_WS", "SLABEL_WS", "SOPCODE_ARGS",
   "SOPCODE_ARGS_WS", "SOPCODE_ARGS_SPECIAL", "SOPCODE_ARGS_STRING",
	"SOPCODE_COMMA", "SOPCODE_ARGS_ENDSTRING"
};

char prepend[][3] = {
   "", "", "\t", "\t",
   "", "", "", "", "",
	" ", "", "", "",
	"", "", "",
	"", ""
};

char postpend[][3] = {
   "", "", "\t", "\t",
   ":", "", "", "", "",
   "", "", "", "",
	"", "", "",
	"", ""
};

int remotely_interesting[] = {
   1, 0, 1, 1,
   1, 0, 1, 0, 0,
   1, 0, 0, 1,
   0, 1, 1,
	1, 1
};

#define TDEFAULT              0
#define TWHITESPACE           1
#define TALPHA                2
#define TCOMMENT              3
#define TDOT                  4
#define TEOL                  5
#define TCOLON                6
#define TCOMMA						7
#define TSPECIAL					8
#define TSPEECHMK					9
#define TNUMBER					10

typedef struct sstate mstate;
typedef struct sstate *pmstate;

struct sstate {
   int current;
   int tokenclass;
   int next;
};

typedef struct stoken mtoken;
typedef struct stoken *pmtoken;

struct stoken {
   int state;
   char text[100];
   pmtoken next;
   pmtoken previous;
};

typedef struct sdefine mdefine;
typedef struct sdefine *pmdefine;

struct sdefine {
	char find[100];
	char replace[100];
	pmdefine next;
};

typedef struct smacro mmacro;
typedef struct smacro *pmmacro;

struct smacro {
   char name[100];
   pmtoken macro;
   pmdefine args;
   pmmacro next;
};

mstate states[] = {
   {  RST,							TWHITESPACE,   SOPCODE_OR_DIRECTIVE },
   {  RST,                    TALPHA,        SLABEL_OR_MACRO },
   {  RST,                    TCOMMENT,      SCOMMENT },
   {  RST,                    TEOL,          RST },
   {  SOPCODE_OR_DIRECTIVE,   TWHITESPACE,   SOPCODE_OR_DIRECTIVE },
   {  SOPCODE_OR_DIRECTIVE,   TDOT,          SDIRECTIVE },
   {  SOPCODE_OR_DIRECTIVE,   TALPHA,        SOPCODE },
	{  SOPCODE_OR_DIRECTIVE,	TCOMMENT,		SCOMMENT },
	{	SOPCODE_OR_DIRECTIVE,	TEOL,				RST },
	{  SOPCODE,                TEOL,          RST },
   {  SOPCODE,                TWHITESPACE,   SOPCODE_ARGS_WS },
   {  SOPCODE,                TDEFAULT,      SOPCODE },
   {  SOPCODE_ARGS_WS,        TWHITESPACE,   SOPCODE_ARGS_WS },
   {  SOPCODE_ARGS_WS,        TEOL,          RST },
   {  SOPCODE_ARGS_WS,        TALPHA,        SOPCODE_ARGS },
   {  SOPCODE_ARGS_WS,        TNUMBER,       SOPCODE_ARGS },
	{  SOPCODE_ARGS_WS,			TSPECIAL,		SOPCODE_ARGS_SPECIAL },
	{  SOPCODE_ARGS_WS,			TCOMMENT,		SCOMMENT },
	{	SOPCODE_ARGS_WS,			TSPEECHMK,		SOPCODE_ARGS_STRING },
	{  SOPCODE_ARGS,           TEOL,          RST },
	{	SOPCODE_ARGS,				TCOMMA,			SOPCODE_COMMA },
	{  SOPCODE_ARGS,				TSPECIAL,		SOPCODE_ARGS_SPECIAL },
	{	SOPCODE_ARGS,				TWHITESPACE,	SOPCODE_ARGS_WS },	/* xxx not really */
	{  SOPCODE_ARGS,           TDEFAULT,      SOPCODE_ARGS },
	{	SOPCODE_COMMA,				TWHITESPACE,	SOPCODE_ARGS_WS },
	{	SOPCODE_COMMA,				TSPECIAL,		SOPCODE_ARGS_SPECIAL },
	{	SOPCODE_COMMA,				TALPHA,			SOPCODE_ARGS },
	{	SOPCODE_COMMA,				TNUMBER,			SOPCODE_ARGS },
	{	SOPCODE_COMMA,				TSPEECHMK,		SOPCODE_ARGS_STRING },
	{  SOPCODE_ARGS_SPECIAL,	TEOL,				RST },
	{  SOPCODE_ARGS_SPECIAL,	TDEFAULT,		SOPCODE_ARGS },
	{	SOPCODE_ARGS_STRING,		TSPEECHMK,		SOPCODE_ARGS_ENDSTRING },
	{	SOPCODE_ARGS_STRING,		TEOL,				RST },
	{	SOPCODE_ARGS_STRING,		TDEFAULT,		SOPCODE_ARGS_STRING },
	{	SOPCODE_ARGS_ENDSTRING,	TCOMMA,			SOPCODE_COMMA },
	{	SOPCODE_ARGS_ENDSTRING,	TEOL,				RST },
	{	SOPCODE_ARGS_ENDSTRING,	TDEFAULT,		SOPCODE_ARGS },
   {  SDIRECTIVE,             TEOL,          RST },
   {  SDIRECTIVE,             TWHITESPACE,   SOPCODE_ARGS_WS },
   {  SDIRECTIVE,             TDEFAULT,      SDIRECTIVE },
   {  SLABEL_OR_MACRO,        TWHITESPACE,   SMACRO_WS },
   {  SLABEL_OR_MACRO,        TCOLON,        SLABEL },
   {  SLABEL_OR_MACRO,        TALPHA,        SLABEL_OR_MACRO },
   {  SLABEL_OR_MACRO,        TNUMBER,       SLABEL_OR_MACRO },
   {  SCOMMENT,               TEOL,          RST },
   {  SCOMMENT,               TDEFAULT,      SCOMMENT },
   {  SLABEL,                 TWHITESPACE,   SLABEL_WS },
   {  SLABEL,                 TEOL,          RST },
   {  SLABEL_WS,              TEOL,          RST },
   {  SLABEL_WS,              TWHITESPACE,   SLABEL_WS },
   {  SLABEL_WS,              TALPHA,        SOPCODE },
   {  SLABEL_WS,					TDOT,          SDIRECTIVE },
	{  SLABEL_WS,					TCOMMENT,		SCOMMENT },
   {  SMACRO_WS,              TWHITESPACE,   SMACRO_WS },
   {  SMACRO_WS,              TALPHA,        SMACRO },
   {  SMACRO,                 TEOL,          RST },
   {  SMACRO,                 TWHITESPACE,   SMACRO_ARGS_WS },
   {  SMACRO,                 TDEFAULT,      SMACRO },
   {  SMACRO_ARGS_WS,         TWHITESPACE,   SMACRO_ARGS_WS },
   {  SMACRO_ARGS_WS,         TALPHA,        SMACRO_ARGS },
   {  SMACRO_ARGS_WS,         TNUMBER,       SMACRO_ARGS },
	{  SMACRO_ARGS_WS,			TCOMMENT,		SCOMMENT },
   {  SMACRO_ARGS,            TEOL,          RST },
	{	SMACRO_ARGS,				TCOMMA,			SMACRO_ARGS_WS },
   {  SMACRO_ARGS,            TDEFAULT,      SMACRO_ARGS },
   {  -1,                     -1,            -1 }
};

void record_error( char *text )
{
   printf("%s\n", text );
};

void debug( char *function, char *msg )
{
	printf("%s: %s\n", function, msg );
}

int get_token_class( char token )
{
   if ((token == ' ')||(token == '\t'))
      return TWHITESPACE;
   if (token == ';')
      return TCOMMENT;
   if (token == '.')
      return TDOT;
   if ((token == '\n')||(token=='\0'))
      return TEOL;
   if (token == ':')
      return TCOLON;
	if (token == ',')
		return TCOMMA;
	if (token == '\"') 
		return TSPEECHMK;
   if (strchr( "=+-()/*", token )!=NULL)
		return TSPECIAL;
	if (isdigit( token ))
		return TNUMBER;
	if (isprint( token ))
      return TALPHA;
   return TDEFAULT;
};

pmstate find_rule( int state, int tokenclass )
{
   int search;
   search = 0;

   while (states[search].current!=-1) {
      if (states[search].current == state) {
         if ((states[search].tokenclass == tokenclass)
            || (states[search].tokenclass == TDEFAULT)) {
            return &states[search];
         }
      }
      search++;
   }
   return NULL;
}

pmmacro create_macro( pmtoken start_token, pmmacro current_macro )
{
   pmtoken token, token_copy;
	pmdefine arg;
   int first;

   current_macro->next = malloc( sizeof(mmacro));
   current_macro = current_macro->next;
   current_macro->next = NULL;

   strcpy( current_macro->name, start_token->text );

   /* Find the token after the next RST and copy off the args */
   token = start_token->next->next;
	first = 1;
	current_macro->args = NULL;
	
   while ((token)&&(token->state != RST)) {
		/* Add an arg to the list */
		if (first) {
			current_macro->args = malloc( sizeof(mdefine));
			first = 0;
			arg = current_macro->args;
		}
		else {
			arg->next = malloc(sizeof(mdefine));
			arg = arg->next;
		}
		strcpy( arg->find, token->text );
      arg->next = NULL;
			
      token = token->next;
	}

   if (token) {
      token = token->next;       /* Start of macro body */
      if (token) {               /* ...potentially null */
         /* Copy from here into the macro */
         first = 1;

         while ((token)&&(strcmp(token->text, "ENDM"))) {
            if (first) {
               current_macro->macro = malloc(sizeof(mtoken));
               first = 0;
               token_copy = current_macro->macro;
               token_copy->next = NULL;
            }
            else {
               token_copy->next = malloc(sizeof(mtoken));
               token_copy = token_copy->next;
            }

            memcpy( token_copy, token, sizeof(mtoken));
            token_copy->next = NULL;

            token = token->next;
         }
         /* Strip out all the tokens that describe the macro */
         start_token->previous->next = token->next;
         return current_macro;
      }
      record_error( "Improperly terminated macro" );
      return NULL;
   }
   record_error( "Improperly terminated macro" );
   return NULL;
};

int linkcount = 0;

int add_macros( pmtoken current_token, pmmacro first_macro )
{
   pmmacro current_macro, scan_macro;

	current_macro = first_macro;

      while (current_token) {
            if (current_token->state == SLABEL_OR_MACRO) {
               if (current_token->next->state == SMACRO) {
                  /* We have a new macro ! */
						if (strcmp(current_token->next->text, "MACRO")) {
								record_error("malformed macro line");
						}
						else { 
							/* Add current_token to macro list */
							current_macro = create_macro( current_token, current_macro );
						}
               }
            }
         current_token = current_token->next;
      }
}

int build_macro_args( pmmacro macro, pmtoken first_token )
{
	/* the first arg is at first_token->next.  Scan until end of line */
	pmtoken token;
	pmdefine current_define;

	current_define = macro->args;
	token = first_token->next;

	while ((token)&&(token->state != RST)) {
		if ((token->state == SOPCODE_ARGS)||(token->state == SOPCODE_ARGS_ENDSTRING)) {
			printf("%s %s\n", state_names[token->state], token->text );
			strcpy(current_define->replace, token->text );
			current_define = current_define->next;
		}
		token = token->next;
	}
	return 0;
};
	
void print_token_chain( pmtoken current_token, pmmacro first_macro, pmdefine first_define )
{
	int dont_print = 0, replaced = 0;
	pmdefine scan_defines;

   pmmacro current_macro, scan_macro;
   current_macro = first_macro;

      while (current_token) {
         if (current_token->state == RST) {
				if (current_token->next!=NULL) {
					if (current_token->next->state!=RST)
						printf("\n");
				}
            dont_print = 0;
         }
         else {
#define USE_MACROS
#ifdef USE_MACROS
            if (current_token->state == SOPCODE) {
               /* Check to see if it's a macro */
               scan_macro = first_macro->next;
               while (scan_macro) {
                  if (!strcmp(scan_macro->name, current_token->text)) {
                     dont_print = 1;
							build_macro_args( scan_macro, current_token );
                     print_token_chain( scan_macro->macro, first_macro, scan_macro->args );
                  }
                  scan_macro = scan_macro->next;
               }
            }
				/* Handle link opcodes */
				if (!strcmp(current_token->text, "link")) {
					if (!strcmp(current_token->next->text,"DEFL")) {
						sprintf(current_token->text, "link%u", ++linkcount);
					}
					else
						sprintf(current_token->text, "link%u", linkcount );
				}
/*            printf("[%s] %s\n", state_names[current_token->state], current_token->text );*/
#endif
            if (!dont_print) {
					/* Check to see if a define has been made requiring a substitution */
#define USE_DEFINES
#ifdef USE_DEFINES
					scan_defines = first_define;
					while ((scan_defines)&&(!replaced)) {
						if (!strcmp(scan_defines->find, current_token->text)) {
							/* Found it */
							printf("%s%s%s", prepend[current_token->state], scan_defines->replace, postpend[current_token->state]);
							replaced = 1;
						}
						scan_defines = scan_defines->next;
					}
#endif
					if (!replaced) {
						printf("%s%s%s", prepend[current_token->state], current_token->text, postpend[current_token->state]);
/*							if ((current_token->state == SOPCODE_ARGS)
								 &&((current_token->next->state == SOPCODE_ARGS)||(current_token->next->state == SOPCODE_ARGS_SPECIAL))) {
								printf(",");
						}*/
					}
					replaced = 0;
				}
							 
         }
         current_token = current_token->next;
      }
}



int main()
{
   FILE *source;
   int state;
   char line[100], current_text[100];
   char *current, *store;
   pmstate rule;
   mtoken first_token;
   pmtoken current_token;
   mmacro first_macro;
   pmmacro current_macro;
	pmdefine current_define;

   int tokenclass;

   source = fopen( "test.S", "r" );
   if (source) {
      state = RST;

      current_text[0] = '\0';
      store = current_text;
      current_token = &first_token;
      current_token->next = NULL;
      current_macro = &first_macro;
      current_macro->next = NULL;

      while (!feof(source)) {
         fgets( line, 100, source );
         current = line;
         while (*current != '\0') {
            tokenclass = get_token_class( *current );
            rule = find_rule( state, tokenclass );
            if (rule!=NULL) {
               if ((rule->current != rule->next)) {
						if (!((rule->next ==SOPCODE_ARGS_ENDSTRING)&&(rule->current==SOPCODE_ARGS_STRING))) {
                  /* Print what was scanned and what rule it falls under */
                  *store = '\0';
                  if (remotely_interesting[state]) {
/*                     printf("[%s] %s\n", state_names[state], current_text );*/
                     /* Add it on to the list of tokens */
                     current_token->next = malloc( sizeof( mtoken ));
                     current_token->next->previous = current_token;
                     current_token = current_token->next;
                     current_token->next = NULL;

                     current_token->state = state;
                     strcpy( current_token->text, current_text );
						}
                  store = current_text;
                  *store = '\0';
						}
                  state = rule->next;
               }
/*               else
                  printf("%s -> %s %c\n", state_names[rule->current], state_names[rule->next], *current );*/
               *store = *current;
               store++;
            }
            else 
               printf("%s -> ??? \'%c\' %s\n", state_names[state], *current, line );
            current++;
         }
      }

      add_macros( first_token.next, &first_macro );

      /* Print out the token list */
      current_token = first_token.next;
      print_token_chain( first_token.next, &first_macro, NULL );

      current_macro = first_macro.next;
      printf("\nDefined macros:\n");
      while (current_macro) {
         printf("  [%s]", current_macro->name );
			current_define = current_macro->args;
			while (current_define) {
				printf(" %s", current_define->find);
				current_define = current_define->next;
			}
			printf("\n");
         current_macro = current_macro->next;
      }
      return 0;

   }
   return -1;
};
