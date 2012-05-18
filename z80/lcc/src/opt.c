/*
 * Optimizer
 */

#define EQUALS(s1,s2)  (s1 == s2 || (s1 != NULL && s2 != NULL && strcasecmp(s1, s2) == 0))

#define NB_RULES 16

typedef struct op_ {
  char *label;
  char *opc;
  char *arg1;
  char *arg2;
  char *comment;
  struct op_ *next;
  struct op_ *prev;
} op;

typedef struct blk_ {
  char *addr;
  struct blk_ *next;
} blk;

void add_op(char *label, char *opc, char *arg1, char *arg2, char *comment);
void label(char *label);
void op0(char *opc);
void op1(char *opc, char *arg1);
void op2(char *opc, char *arg1, char *arg2);
void comment(char *comment);
char *str_alloc(const char *fmt, ...);
op *next_op(op *o);
void remove_op(op *o);
int optimize_op(op *o);
void generate();

static blk *root_blk = NULL, *last_blk = NULL;
static op *root_op = NULL, *last_op = NULL;
static int rules[NB_RULES];
static int nb_rules = NB_RULES;

void add_op(char *label, char *opc, char *arg1, char *arg2, char *comment)
{
  if(root_op == NULL) {
    root_op = last_op = (op *)malloc(sizeof(op));
    last_op->prev = NULL;
  } else {
    last_op->next = (op *)malloc(sizeof(op));
    last_op->next->prev = last_op;
    last_op = last_op->next;
  }
  last_op->label = label;
  last_op->opc = opc;
  last_op->arg1 = arg1;
  last_op->arg2 = arg2;
  last_op->comment = comment;
  last_op->next = NULL;

  if(label != NULL)
    generate();
}

void label(char *label)
{
  add_op(label, NULL, NULL, NULL, NULL);
}

void op0(char *opc)
{
  add_op(NULL, opc, NULL, NULL, NULL);
}

void op1(char *opc, char *arg1)
{
  add_op(NULL, opc, arg1, NULL, NULL);
}

void op2(char *opc, char *arg1, char *arg2)
{
  add_op(NULL, opc, arg1, arg2, NULL);
}

void comment(char *comment)
{
  add_op(NULL, NULL, NULL, NULL, comment);
}

char *str_alloc(const char *fmt, ...)
{
  char s[128];
  va_list ap;

  va_start(ap, fmt);
  vsprintf(s, fmt, ap);
  va_end(ap);
  if(root_blk == NULL) {
    root_blk = last_blk = (blk *)malloc(sizeof(blk));
  } else {
    last_blk->next = (blk *)malloc(sizeof(blk));
    last_blk = last_blk->next;
  }
  last_blk->addr = (char *)malloc(strlen(s) + 1);
  last_blk->next = NULL;
  strcpy(last_blk->addr, s);
  return last_blk->addr;
}

op *next_op(op *o)
{
  op *next;

  if(o == NULL)
    return NULL;
  next = o->next;
  while(next) {
    if(next->opc != NULL)
      break;
    next = next->next;
  }
  return next;
}

void remove_op(op *o)
{
  if(o == root_op)
    root_op = o->next;
  if(o == last_op)
    last_op = o->prev;
  if(o->next != NULL)
    o->next->prev = o->prev;
  if(o->prev != NULL)
    o->prev->next = o->next;
  free(o);
}

int optimize_op(op *o)
{
  /* Optimize unnecessary moves */
  if(EQUALS(o->opc, "LD")) {
    if(EQUALS(o->arg1, o->arg2)) {
      /*
       * E.g.
       *     LD  B,B
       */
      remove_op(o);
      rules[1]++;
      return 1;
    }
    {
      op *next;

      next = next_op(o);
      if(next != NULL &&
#ifdef GAMEBOY
	 !EQUALS(o->arg1, "(HL+)") &&
	 !EQUALS(o->arg1, "(HL-)") &&
	 !EQUALS(o->arg2, "(HL+)") &&
	 !EQUALS(o->arg2, "(HL-)") &&
#endif
	 EQUALS(next->arg1, o->arg2) &&
	 EQUALS(next->arg2, o->arg1)) {
	/*
	 * E.g.
	 *     LD  B,C
	 *     LD  C,B
	 * or
	 *     LD  (IX+1),C
	 *     LD  C,(IX+1)
	 */
	remove_op(next);
	rules[2]++;
	return 1;
      }
    }
    {
      op *next1, *next2, *next3;

      next1 = next_op(o);
      next2 = next_op(next1);
      next3 = next_op(next2);

      if(next1 != NULL &&
	 next2 != NULL &&
	 next3 != NULL &&
#ifdef GAMEBOY
	 !EQUALS(o->arg1, "(HL+)") &&
	 !EQUALS(o->arg1, "(HL-)") &&
	 !EQUALS(o->arg2, "(HL+)") &&
	 !EQUALS(o->arg2, "(HL-)") &&
#endif
	 EQUALS(next2->opc, o->opc) &&
	 EQUALS(next2->arg1, o->arg2) &&
	 EQUALS(next2->arg2, o->arg1) &&

	 EQUALS(next1->opc, "LD") &&
#ifdef GAMEBOY
	 !EQUALS(next1->arg1, "(HL+)") &&
	 !EQUALS(next1->arg1, "(HL-)") &&
	 !EQUALS(next1->arg2, "(HL+)") &&
	 !EQUALS(next1->arg2, "(HL-)") &&
#endif
	 EQUALS(next3->opc, next1->opc) &&
	 EQUALS(next3->arg1, next1->arg2) &&
	 EQUALS(next3->arg2, next1->arg1)) {
	/*
	 * E.g.
	 *     LD  B,D
	 *     LD  C,E
	 *     LD  D,B
	 *     LD  E,C
	 * or
	 *     LD  (IX+1),C
	 *     LD  (IX+2),B
	 *     LD  C,(IX+1)
	 *     LD  B,(IX+2)
	 */
	remove_op(next2);
	remove_op(next3);
	rules[3]++;
	return 1;
      }
    }
#ifdef GAMEBOY
    if(EQUALS(o->arg1, "A") &&
       !strncmp(o->arg2, "(0xff", 5)) {
	/*
	 * E.g.
	 *     LD  A,(0xFF??)
	 */
	o->opc = "LDH";
	o->arg2 = str_alloc("(0x%s", &o->arg2[5]);
	rules[4]++;
	return 1;
    }
    if(EQUALS(o->arg2, "A") &&
       !strncmp(o->arg1, "(0xff", 5)) {
	/*
	 * E.g.
	 *     LD  (0xFF??),A
	 */
	o->opc = "LDH";
	o->arg1 = str_alloc("(0x%s", &o->arg1[5]);
	rules[5]++;
	return 1;
    }
#endif
  }
  if(EQUALS(o->opc, "INC") ||
     EQUALS(o->opc, "DEC")) {
    op *next;

    next = next_op(o);
    if(next != NULL &&
       EQUALS(next->arg1, o->arg1) &&
       ((EQUALS(next->opc, "INC") &&
	 EQUALS(o->opc, "DEC")) ||
	(EQUALS(next->opc, "DEC") &&
	 EQUALS(o->opc, "INC")))) {
      /*
       * E.g.
       *     INC  B
       *     DEC  B
       */
      remove_op(o);
      remove_op(next);
      rules[6]++;
      return 1;
    }
  }
#ifdef GAMEBOY
  if(EQUALS(o->opc, "LDA") &&
     EQUALS(o->arg1, "HL")) {
    op *next1, *next2, *next3;

    next1 = next_op(o);
    next2 = next_op(next1);
    next3 = next_op(next2);

    if(next1 != NULL &&
       next2 != NULL &&
       next3 != NULL &&

       EQUALS(next2->opc, o->opc) &&
       EQUALS(next2->arg1, o->arg1) &&
       EQUALS(next2->arg2, o->arg2) &&

       EQUALS(next1->opc, "LD") &&
       (EQUALS(next1->arg1, "(HL)") ||
	EQUALS(next1->arg2, "(HL)")) &&
       !(EQUALS(next1->arg1, "H") ||
	 EQUALS(next1->arg1, "L") ||
	 EQUALS(next1->arg2, "H") ||
	 EQUALS(next1->arg2, "L")) &&

       EQUALS(next3->opc, next1->opc) &&
       EQUALS(next3->arg1, next1->arg2) &&
       EQUALS(next3->arg2, next1->arg1)) {
      /*
       * E.g.
       *     LDA HL,2(SP)
       *     LD  B,(HL)
       *     LDA HL,2(SP)
       *     LD  (HL),B
       * or
       *     LDA HL,2(SP)
       *     LD  (HL),B
       *     LDA HL,2(SP)
       *     LD  B,(HL)
       */
      remove_op(next2);
      remove_op(next3);
      rules[7]++;
      return 1;
    }
    if(next1 != NULL &&
       next2 != NULL &&
       next3 != NULL &&

       ((EQUALS(next1->opc, "LD") &&
	 EQUALS(next1->arg1, "A") &&
	 (EQUALS(next1->arg2, "(HL+)") ||
	  EQUALS(next1->arg2, "(HL-)")) &&

	 EQUALS(next2->opc, "LD") &&
	 EQUALS(next2->arg2, "(HL)") &&

	 EQUALS(next3->opc, "LD") &&
	 !(EQUALS(next3->arg1, "(HL+)") ||
	   EQUALS(next3->arg1, "(HL-)")) &&
	 EQUALS(next3->arg2, "A"))

	||

	(EQUALS(next1->opc, "LD") &&
	 EQUALS(next1->arg1, "A") &&
	 !(EQUALS(next1->arg2, "(HL+)") ||
	   EQUALS(next1->arg2, "(HL-)")) &&

	 EQUALS(next2->opc, "LD") &&
	 (EQUALS(next2->arg1, "(HL+)") ||
	  EQUALS(next2->arg1, "(HL-)")) &&
	 EQUALS(next2->arg2, "A") &&

	 EQUALS(next3->opc, "LD") &&
	 EQUALS(next3->arg1, "(HL)")))) {
      op *next4, *next5, *next6, *next7;

      next4 = next_op(next3);
      next5 = next_op(next4);
      next6 = next_op(next5);
      next7 = next_op(next6);

      if(next4 != NULL &&
	 next5 != NULL &&
	 next6 != NULL &&
	 next7 != NULL &&

	 EQUALS(next4->opc, o->opc) &&
	 EQUALS(next4->arg1, o->arg1) &&
	 EQUALS(next4->arg2, o->arg2) &&

	 EQUALS(next5->opc, next2->opc) &&
	 EQUALS(next5->arg1, next2->arg2) &&
	 EQUALS(next5->arg2, next2->arg1) &&

	 EQUALS(next6->opc, next3->opc) &&
	 EQUALS(next6->arg1, next3->arg2) &&
	 EQUALS(next6->arg2, next3->arg1) &&

	 EQUALS(next7->opc, next1->opc) &&
	 EQUALS(next7->arg1, next1->arg2) &&
	 EQUALS(next7->arg2, next1->arg1)) {
	/*
	 * E.g.
	 *     LDA HL,2(SP)
	 *     LD  A,(HL+)
	 *     LD  B,(HL)
	 *     LD  C,A
	 *     LDA HL,2(SP)
	 *     LD  A,C
	 *     LD  (HL+),A
	 *     LD  (HL),B
	 * or
	 *     LDA HL,2(SP)
	 *     LD  A,C
	 *     LD  (HL+),A
	 *     LD  (HL),B
	 *     LDA HL,2(SP)
	 *     LD  A,(HL+)
	 *     LD  B,(HL)
	 *     LD  C,A
	 */
	remove_op(next4);
	remove_op(next5);
	remove_op(next6);
	remove_op(next7);
	rules[8]++;
	return 1;
      }
    }
  }
#endif
  return 0;
}

void generate()
{
  op *o, *next;
  blk *b;
  unsigned nb;

  if(optimize) {
    do {
      nb = 0;
      o = root_op;
      while(o != NULL) {
	/* Necessary since 'o' may be removed in 'optimize_op()' */
	next = o->next;
	nb += optimize_op(o);
	o = next;
      }
    } while (nb > 0);
  }

  o = root_op;
  while(o != NULL) {
    if(o->label != NULL)
      print(o->label);
    if(o->opc != NULL) {
      print("\t%s", o->opc);
      if(o->arg1 != NULL) {
	print("\t%s", o->arg1);
	if(o->arg2 != NULL)
	  print(",%s", o->arg2);
      }
    }
    if(o->comment != NULL && comments)
      print("\t;; %s", o->comment);
    if(o->label != NULL ||
       o->opc != NULL ||
       (o->comment != NULL && comments))
      print("\n");
    root_op = o;
    o = o->next;
    free(root_op);
  }
  root_op = last_op = NULL;

  b = root_blk;
  while(b != NULL) {
    free(b->addr);
    root_blk = b;
    b = b->next;
    free(root_blk);
  }
  root_blk = last_blk = NULL;
}

