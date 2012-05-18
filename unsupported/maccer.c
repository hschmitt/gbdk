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
/*#define DEBUG*/
#define VERSION 0.0.11
#define VERSION_STRING "0.0.12"

#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

/* List of states */
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
#define SOPCODE_ARGS_SPECIAL2	18
#define SERROR					19

/* List of the textual names of the states for debugging */
char state_names[][23] =
{
    "RST", "SOPCODE_OR_DIRECTIVE", "SOPCODE", "SDIRECTIVE",
    "SLABEL_OR_MACRO", "SCOMMENT", "SMACRO", "SLABEL", 
	"SMACRO_WS", "SMACRO_ARGS", "SMACRO_ARGS_WS", "SLABEL_WS",
	"SOPCODE_ARGS", "SOPCODE_ARGS_WS", "SOPCODE_ARGS_SPECIAL", "SOPCODE_ARGS_STRING",
    "SOPCODE_COMMA", "SOPCODE_ARGS_ENDSTRING", "SOPCODE_ARGS_SPECIAL2", "SERROR"
};

/* String to prepend to the output for a given state */
char prepend[][3] =
{
    "", "", "\t", "\t",
    "", "", "", "", 
	"", " ", "", "", 
	"", "", "", "",
    "", "", "", ""
};

/* String to postpend to the output */
char postpend[][3] =
{
    "", "", "\t", "\t",
    "", "", "", "", 
	"", "", "", "", 
	"", "", "", "",
    "", "", "", ""
};

/* 1 is the corresponding state should be kept, 0 to drop it */
int remotely_interesting[] =
{
    1, 0, 1, 1,
    1, 0, 1, 1, 
	0, 1, 0, 0, 
	1, 0, 1, 1,
    1, 1, 1, 0
};

/* The various character classes for state transitions */
#define TDEFAULT            0
#define TWHITESPACE         1
#define TALPHA              2
#define TCOMMENT            3
#define TDOT                4
#define TEOL                5
#define TCOLON              6
#define TCOMMA				7
#define TSPECIAL			8
#define TSPEECHMK			9
#define TNUMBER				10

typedef struct sstate mstate;
typedef struct sstate *pmstate;

/* A mstate contains the edges to the state transition table
   eg if the current state is current and the character calss is tokenclass
   then go to state next */
struct sstate {
    int current;
    int tokenclass;
    int next;
};

typedef struct stoken mtoken;
typedef struct stoken *pmtoken;

/* A token is a sequence of characters.  The list is doubly so that I can
   do evil things to it 
   Note that a list of tokens is not cicrular - the first token has previous
   set to NULL and the last has next set to NULL
*/
struct stoken {
    int state;
    char text[100];
    pmtoken next;
    pmtoken previous;
};

/* A mdefine is a token based search and replace.  If the tokens text equals
   find then the text replace is printed instead 
*/
typedef struct sdefine mdefine;
typedef struct sdefine *pmdefine;

struct sdefine {
    char find[100];
    char replace[100];
    pmdefine next;
};

/* A macro is a name and a list of tokens that should be printed instead
   of the macro token
*/
typedef struct smacro mmacro;
typedef struct smacro *pmmacro;

struct smacro {
    char name[100];
    pmtoken macro;
    pmdefine args;
    pmmacro next;
};

/* An error is a state, character class and string which describes what type of
    error has occured when your in state state and you try to follow the non-existant
    edge described by character class
*/
typedef struct serror merror;
typedef struct serror *pmerror;

struct serror {
	int	state;
	int charclass;
	char description[100];
};

/* states is a list of all the state transitions
   Note that currently there's alot of duplication
   Note that a default action _must_ be last in the transitions for that state
*/
mstate states[] =
{
    {RST,						TWHITESPACE,	SOPCODE_OR_DIRECTIVE},
    {RST,						TALPHA,			SLABEL_OR_MACRO},
    {RST,						TNUMBER,		SLABEL_OR_MACRO},
    {RST,						TCOMMENT,		SCOMMENT},
    {RST,						TEOL,			RST},
	{RST,						TDOT,			SLABEL_OR_MACRO },
    {SOPCODE_OR_DIRECTIVE,		TWHITESPACE,	SOPCODE_OR_DIRECTIVE},
    {SOPCODE_OR_DIRECTIVE,		TDOT,			SDIRECTIVE},
    {SOPCODE_OR_DIRECTIVE,		TALPHA,			SOPCODE},
    {SOPCODE_OR_DIRECTIVE,		TCOMMENT,		SCOMMENT},
    {SOPCODE_OR_DIRECTIVE,		TEOL,			RST},
    {SOPCODE,					TEOL,			RST},
    {SOPCODE,					TWHITESPACE,	SOPCODE_ARGS_WS},
	{SOPCODE,					TCOMMENT,		SCOMMENT},
    {SOPCODE,					TDEFAULT,		SOPCODE},
    {SOPCODE_ARGS_WS,			TWHITESPACE,	SOPCODE_ARGS_WS},
    {SOPCODE_ARGS_WS,			TEOL,			RST},
    {SOPCODE_ARGS_WS,			TALPHA,			SOPCODE_ARGS},
    {SOPCODE_ARGS_WS,			TNUMBER,		SOPCODE_ARGS},
    {SOPCODE_ARGS_WS,			TDOT,			SOPCODE_ARGS},
    {SOPCODE_ARGS_WS,			TSPECIAL,		SOPCODE_ARGS_SPECIAL},
    {SOPCODE_ARGS_WS,			TCOMMENT,		SCOMMENT},
    {SOPCODE_ARGS_WS,			TSPEECHMK,		SOPCODE_ARGS_STRING},
    {SOPCODE_ARGS,				TEOL,			RST},
    {SOPCODE_ARGS,				TCOMMA,			SOPCODE_COMMA},
    {SOPCODE_ARGS,				TSPECIAL,		SOPCODE_ARGS_SPECIAL},
    {SOPCODE_ARGS,				TWHITESPACE,	SOPCODE_ARGS_WS},	/* xxx not really */
	{SOPCODE_ARGS,				TCOMMENT,		SCOMMENT },
	{SOPCODE_ARGS,				TALPHA,			SOPCODE_ARGS },
	{SOPCODE_ARGS,				TNUMBER,		SOPCODE_ARGS },
/*    {SOPCODE_ARGS,				TDEFAULT,		SOPCODE_ARGS},*/
    {SOPCODE_COMMA,				TWHITESPACE,	SOPCODE_ARGS_WS},
    {SOPCODE_COMMA,				TSPECIAL,		SOPCODE_ARGS_SPECIAL},
    {SOPCODE_COMMA,				TALPHA,			SOPCODE_ARGS},
    {SOPCODE_COMMA,				TNUMBER,		SOPCODE_ARGS},
    {SOPCODE_COMMA,				TSPEECHMK,		SOPCODE_ARGS_STRING},
    {SOPCODE_ARGS_SPECIAL,		TEOL,			RST},
	{SOPCODE_ARGS_SPECIAL,		TSPECIAL,		SOPCODE_ARGS_SPECIAL2 },
	{SOPCODE_ARGS_SPECIAL,		TCOMMENT,		SCOMMENT},
	{SOPCODE_ARGS_SPECIAL,		TDEFAULT,		SOPCODE_ARGS},
    {SOPCODE_ARGS_SPECIAL2,		TEOL,			RST},
	{SOPCODE_ARGS_SPECIAL2,		TCOMMENT,		SCOMMENT},
	{SOPCODE_ARGS_SPECIAL2,		TSPECIAL,		SOPCODE_ARGS_SPECIAL },
    {SOPCODE_ARGS_SPECIAL2,		TDEFAULT,		SOPCODE_ARGS},
    {SOPCODE_ARGS_STRING,		TSPEECHMK,		SOPCODE_ARGS_ENDSTRING},
    {SOPCODE_ARGS_STRING,		TEOL,			SERROR},
    {SOPCODE_ARGS_STRING,		TDEFAULT,		SOPCODE_ARGS_STRING},
    {SOPCODE_ARGS_ENDSTRING,	TCOMMA,			SOPCODE_COMMA},
    {SOPCODE_ARGS_ENDSTRING,	TEOL,			RST},
    {SOPCODE_ARGS_ENDSTRING,	TDEFAULT,		SOPCODE_ARGS},
    {SDIRECTIVE,				TEOL,			RST},
    {SDIRECTIVE,				TWHITESPACE,	SOPCODE_ARGS_WS},
	{SDIRECTIVE,				TCOMMENT,		SCOMMENT},
	{SDIRECTIVE,				TALPHA,			SDIRECTIVE},
    {SLABEL_OR_MACRO,			TWHITESPACE,	SMACRO_WS},
    {SLABEL_OR_MACRO,			TCOLON,			SLABEL},
    {SLABEL_OR_MACRO,			TALPHA,			SLABEL_OR_MACRO},
    {SLABEL_OR_MACRO,			TNUMBER,		SLABEL_OR_MACRO},
    {SLABEL_OR_MACRO,			TSPECIAL,		SLABEL_OR_MACRO},
    {SCOMMENT,					TEOL,			RST},
    {SCOMMENT,					TDEFAULT,		SCOMMENT},
    {SLABEL,					TCOLON,			SLABEL},
    {SLABEL,					TWHITESPACE,	SLABEL_WS},
	{SLABEL,					TCOMMENT,		SCOMMENT},
    {SLABEL,					TEOL,			RST},
    {SLABEL_WS,					TEOL,			RST},
    {SLABEL_WS,					TWHITESPACE,	SLABEL_WS},
    {SLABEL_WS,					TALPHA,			SOPCODE},
    {SLABEL_WS,					TDOT,			SDIRECTIVE},
    {SLABEL_WS,					TCOMMENT,		SCOMMENT},
    {SMACRO_WS,					TWHITESPACE,	SMACRO_WS},
    {SMACRO_WS,					TALPHA,			SMACRO},
    {SMACRO,					TEOL,			RST},
    {SMACRO,					TWHITESPACE,	SMACRO_ARGS_WS},
	{SMACRO,					TALPHA,			SMACRO},
	{SMACRO,					TNUMBER,		SMACRO},
    {SMACRO_ARGS_WS,			TWHITESPACE,	SMACRO_ARGS_WS},
    {SMACRO_ARGS_WS,			TALPHA,			SMACRO_ARGS},
    {SMACRO_ARGS_WS,			TNUMBER,		SMACRO_ARGS},
    {SMACRO_ARGS_WS,			TCOMMENT,		SCOMMENT},
    {SMACRO_ARGS,				TEOL,			RST},
    {SMACRO_ARGS,				TCOMMA,			SMACRO_ARGS_WS},
	{SMACRO_ARGS,				TALPHA,			SMACRO_ARGS},
	{SMACRO_ARGS,				TNUMBER,		SMACRO_ARGS},
	{-1, -1, -1}
};

merror errors[] = {
	{SOPCODE_ARGS_STRING,	TEOL,		"Unterminated string" },
	{SMACRO_ARGS,			TDEFAULT,	"Only alphanumberics are allowed in a macro argument name."},
	{SMACRO_ARGS_WS,		TDEFAULT,	"A macro argument must start with a letter or number"},
	{SMACRO,				TDEFAULT,	"Unexpected character in second field."},
	{RST,					TDEFAULT,	"Unexpected character at start of line."},
	{SOPCODE_OR_DIRECTIVE,	TDEFAULT,	"Unexpected character before start of opcode."},
	{SOPCODE_ARGS_WS,		TDEFAULT,	"Weird character present."},
	{SOPCODE_ARGS_WS,		TDEFAULT,	"Weird character present in argument."},
	{SDIRECTIVE,			TDEFAULT,	"Only letters can be used in a .directive."},
	{SLABEL_OR_MACRO,		TDEFAULT,	"Unexpected character in label."},
	{SLABEL,				TDEFAULT,	"Unexpected character following label."},
	{-1,					-1,			""}
};
	
/* Holder for something clever later */
void record_error(char *function, char *text)
{
    fprintf( stderr, "%s: %s\n", function, text);
};


void debug(char *function, char *msg)
{
#ifdef DEBUG
    printf("%s: %s\n", function, msg);
#endif
}

/* Return the character class of the current character */
int get_token_class(char token)
{
    if ((token == ' ') || (token == '\t'))
		return TWHITESPACE;
    if (token == ';')
		return TCOMMENT;
    if (token == '.')
		return TDOT;
    if ((token == '\n') || (token == '\0'))
		return TEOL;
    if (token == ':')
		return TCOLON;
    if (token == ',')
		return TCOMMA;
    if (token == '\"')
		return TSPEECHMK;
    if (strchr("$#<>=+-()/*", token) != NULL)
		return TSPECIAL;
    if (isdigit(token))
		return TNUMBER;
    if (isprint(token))
		return TALPHA;
	return TDEFAULT;
};

/* Find the corresponding transition for the current character and state */
pmstate find_rule(int state, int tokenclass)
{
	int search;
    search = 0;

	debug("find_rule", "entered");
	while (states[search].current != -1) {
		if (states[search].current == state) {
			if ((states[search].tokenclass == tokenclass)
				|| (states[search].tokenclass == TDEFAULT)) {
				debug("find_rule", "Found a rule");
				return &states[search];
			}
		}
		search++;
    }
	debug("find_rule", "No rule found.");
	return NULL;
}

/* Create a macro from the current place in the token list
	Delete the macro definition tokens once the macro is defined
*/	
pmmacro *create_macro(pmtoken start_token, pmmacro *current_macro)
{
    pmtoken token, token_copy;
    pmdefine arg;
    int first;

	
    (*current_macro) = malloc(sizeof(mmacro));
    (*current_macro)->next = NULL;

    strcpy((*current_macro)->name, start_token->text);

    /* Find the token after the next RST and copy off the args */
    token = start_token->next->next;
    first = 1;
    (*current_macro)->args = NULL;

    while ((token) && (token->state != RST)) {
		/* Add an arg to the list */
		if (first) {
			(*current_macro)->args = malloc(sizeof(mdefine));
			first = 0;
			arg = (*current_macro)->args;
		}
		else {
			arg->next = malloc(sizeof(mdefine));
			arg = arg->next;
		}
		strcpy(arg->find, token->text);
		arg->next = NULL;

		token = token->next;
	}

    if (token) {
		token = token->next;	/* Start of macro body */
		if (token) {		/* ...potentially null */
			/* Copy from here into the macro */
			first = 1;

			while ((token) && (strcmp(token->text, "ENDM"))) {
				if (first) {
					(*current_macro)->macro = malloc(sizeof(mtoken));
					first = 0;
					token_copy = (*current_macro)->macro;
					token_copy->next = NULL;
				}
				else {
					token_copy->next = malloc(sizeof(mtoken));
					token_copy = token_copy->next;
				}

				memcpy(token_copy, token, sizeof(mtoken));
				token_copy->next = NULL;

				token = token->next;
			}
			/* Strip out all the tokens that describe the macro */
			start_token->previous->next = token->next;
			return &(*current_macro)->next;
		}
		record_error("create_macro", "Improperly terminated macro.");
		return NULL;
    }
    record_error("create_macro", "Improperly terminated macro.");
    return NULL;
};

int linkcount = 0;

/* Scan the given token list and parse in any macros */
int add_macros(pmtoken current_token, pmmacro *first_macro)
{
    pmmacro *current_macro;

    current_macro = first_macro;

    while (current_token) {
		if (current_token->state == SLABEL_OR_MACRO) {
			if (current_token->next!=NULL) {
				if (current_token->next->state == SMACRO) {
					/* We have a new macro ! */
					if (strcmp(current_token->next->text, "MACRO")) {
						record_error("add_macros", "Malformed macro line");
					} 
					else {
						/* Add current_token to macro list */
						current_macro = create_macro(current_token, current_macro);
					}
				}
			}
		}
		current_token = current_token->next;
    }
}

/* Scan the current list of defines and make any required replacements 
	Return the original text if no changes were made
*/
char *replace_defines( char *text, pmdefine first_define )
{
	int found = 0;
	pmdefine scan_defines;
	
	scan_defines = first_define;
	while (scan_defines) {
	    if (!strcmp(scan_defines->find, text)) {
			/* Found it */
			return scan_defines->replace;
		}
	    scan_defines = scan_defines->next;
	}
	return text;
}

/* Create a list of defines from the macro args */
int build_macro_args(pmmacro macro, pmtoken first_token, pmdefine first_define )
{
    /* the first arg is at first_token->next.  Scan until end of line */
    pmtoken token;
    pmdefine current_define;

    current_define = macro->args;
    token = first_token->next;

    while ((token) && (token->state != RST)) {
		if ((token->state == SOPCODE_ARGS) || (token->state == SOPCODE_ARGS_ENDSTRING)) {
			strcpy(current_define->replace, replace_defines(token->text, first_define));
			current_define = current_define->next;
		}
		token = token->next;
    }
    return 0;
};

int include_binary_file( pmtoken current_token )
{
	FILE *included;
	char filename[100];
	int count = 0;
	int byte;
	
	if (current_token->next) {
		current_token = current_token->next;
		if (current_token->state==SOPCODE_ARGS_ENDSTRING) {
			/* Sofar so good */
			strcpy( filename, &current_token->text[1] );
			filename[strlen(filename)-1]='\0';
			included = fopen( filename, "rb" );
			if (included) {
				while ((byte=fgetc(included))!=EOF) {
					if (count==0) {
						printf("\n\t.db ");
					}
					else
						printf(",");
					printf("0x%02X", byte );
					count++;
					if (count==8)
						count = 0;
				}
				
				fclose( included );
			}
			else {
				record_error("include_binary_file", "Cant open include file for reading.");
			}
		}
		else
			record_error("include_binary_file", "Argument to INCBIN is not a string.");
	}
	return -1;
};

/* Recursivly print the token list processing any macros as they appear */
void print_token_chain(pmtoken current_token, pmmacro first_macro, pmdefine first_define)
{
    int dont_print = 0, replaced = 0;
    pmdefine scan_defines;

    pmmacro current_macro, scan_macro;
    current_macro = first_macro;

    while (current_token) {
	if (current_token->state == RST) {
	    if (current_token->next != NULL) {
		if (current_token->next->state != RST)
		    printf("\n");
	    }
	    dont_print = 0;
	} else {
#define USE_MACROS
#ifdef USE_MACROS
	    if (current_token->state == SOPCODE) {
			/* Check to see if it's a macro */
			scan_macro = first_macro;
			while (scan_macro) {
				if (!strcmp(scan_macro->name, current_token->text)) {
					dont_print = 1;
					build_macro_args(scan_macro, current_token, first_define);
					print_token_chain(scan_macro->macro, first_macro, scan_macro->args);
				}
				scan_macro = scan_macro->next;
			}
			/* Check to see if it's an INCBIN */
			if (!strcmp( current_token->text, "INCBIN")) {
				include_binary_file( current_token );
				dont_print = 1;
			}
	    }
	    /* Handle link opcodes */
	    if (!strcmp(current_token->text, "link")) {
			if (!strcmp(current_token->next->text, "DEFL")) {
				sprintf(current_token->text, "link%u", ++linkcount);
			}
			else
				sprintf(current_token->text, "link%u", linkcount);
	    }

#endif
	    if (!dont_print) {
		    printf("%s%s%s", prepend[current_token->state], replace_defines(current_token->text, first_define), postpend[current_token->state]);
	    }
	}
	current_token = current_token->next;
    }
}

void handle_error( int line_number, int state, int charclass, char *file_name)
{
	int search, done;

	search = 0;
	done = 0;

	debug("handle_error", "entered");
	fflush(stdout);
	while ((errors[search].state !=-1)&&(!done)) {
		debug("handle_error", state_names[errors[search].state]);
		if (errors[search].state == state) {
			if ((errors[search].charclass == TDEFAULT)||(errors[search].charclass==charclass)) {
				fprintf(stderr, "%s:%u:%s\n", file_name, line_number, errors[search].description);
				done = 1;
			}
		}
		search++;
	}
	if (!done)
		fprintf(stderr, "%u:Unexpected error due to transition from %s -> ??? Class = %u.\n", line_number, state_names[state], charclass);
}

/* Read the source file from stdin */
int parse_in( pmtoken *first_token, char *file_name )
{
    int state;
    char line[100], current_text[100];
    char *current, *store;
    pmstate rule;
    pmtoken current_token;
    int tokenclass;
	int line_number, errors_found;

	state = RST;
	line_number = 0;
	errors_found = 0;

	current_text[0] = '\0';
	store = current_text;

	while (fgets(line,100,stdin)!=NULL) {

	    current = line;
		line_number++;

		while ((*current != '\0')&&(state!=SERROR)) {
			tokenclass = get_token_class(*current);
			rule = find_rule(state, tokenclass);
#ifdef DEBUG
			printf("[%s, %c] ", state_names[state], *current);
#endif
			fflush(stdout);
			
			if ((rule != NULL)&&(rule->next!=SERROR)) {
				if ((rule->current != rule->next)) {
					if (!((rule->next == SOPCODE_ARGS_ENDSTRING) && (rule->current == SOPCODE_ARGS_STRING))) {
						/* Print what was scanned and what rule it falls under */
						*store = '\0';
						if (remotely_interesting[state]) {
							/* Add it on to the list of tokens */

							if (*first_token == NULL) {
								/* First in the list */
								*first_token = malloc( sizeof( mtoken ));
								current_token = *first_token;
								current_token->previous = NULL;
							}
							else {
								current_token->next = malloc(sizeof(mtoken));
								current_token->next->previous = current_token;
								current_token = current_token->next;
							}
							current_token->next = NULL;

							current_token->state = state;
							strcpy(current_token->text, current_text);
						}
						store = current_text;
						*store = '\0';
					}
					state = rule->next;
				}
				*store = *current;
				store++;
			}
			else {
				handle_error( line_number, state, tokenclass, file_name );
				state = RST;
				errors_found++;
			}
			current++;
		}
	}

	return errors_found;
};

int print_macros( pmmacro current_macro )
{
	pmdefine current_define;

	printf("\nDefined macros:\n");
	while (current_macro) {
	    printf("  [%s]", current_macro->name);
	    current_define = current_macro->args;
	    while (current_define) {
			printf(" %s", current_define->find);
			current_define = current_define->next;
	    }
	    printf("\n");
	    current_macro = current_macro->next;
	}
}

void useage( char *program )
{
	printf(	"maccer - macro pre-processor for asz80, M. Hope 1998.\n"
			"Version " VERSION_STRING ", built " __DATE__ ".\n"
			"Useage:\n"
			"  %s [-o output file] [input file]\n"
			"  Will read from stdin and write to stdout otherwise.\n"
			, program );
}

int main( int argc, char **argv )
{
    pmtoken first_token;
    pmmacro first_macro;
	pmmacro	current_macro;
	pmdefine current_define;
	char file_name[100] = "<stdin>";
	int i, output_set, input_set;

	first_token = NULL;
	first_macro = NULL;
	output_set = 0;
	input_set = 0;

	/* Handle command line arguments */
	for (i=1; i<argc; i++) {
		if ((!strcmp("-h", argv[i]))||(!strcmp("--help", argv[i]))) {
			useage( argv[0] );
			return 0;
		}
		if (!strcmp("-o", argv[i])) {
			if ((i+1)<argc) {
				if (!output_set) {
					output_set = 1;
					
					if (freopen( argv[i+1], "w", stdout )==NULL) {
						record_error( argv[0], "error: cannot open file for writing." );
						return -1;
					}
				}
				else {
					record_error( argv[0], "warning: extra -o ignored.");
				}
				i++;
			}
			else {
				record_error( argv[0], "warning: -o without an argument.");
			}
		}
		else {
			if (!input_set) {
				if (freopen( argv[i], "r", stdin )==NULL) {
					record_error( argv[0], "error: cannot open file for reading.");
					return -2;
				}
				input_set = 1;
				strcpy( file_name, argv[i] );
			}
			else {
				record_error( argv[0], "warning: second input file ignored.");
			}
		}
	}
				
			
			
		
	debug("main", "calling parse_in");
	if (parse_in( &first_token, file_name )) {
		return -1;
	}

	/* Print out the token list */
	debug("main", "calling add_macros");
	add_macros(first_token, &first_macro);
	debug("main", "calling print_token_chain");
	print_token_chain(first_token, first_macro, NULL);

	printf("\n");
/*	print_macros( first_macro );*/
	return 0;

}
