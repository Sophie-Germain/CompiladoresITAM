/* File:  scanner.l
 * ----------------
 * Lex inupt file to generate the scanner for the compiler.
 */

%{

/* The text within this first region delimited by %{ and %} is assumed to
 * be C/C++ code and will be copied verbatim to the lex.yy.c file ahead
 * of the definitions of the yylex() function. Add other header file inclusions
 * or C++ variable declarations/prototypes that are needed by your code here.
 */

#include <string.h>
#include "scanner.h"
#include "utility.h" // for PrintDebug()
#include "errors.h"

/* Global variable: yylval
 * -----------------------
 * This global variable is how we get attribute information about the token
 * just scanned to the client. The scanner sets the global variable
 * appropriately and since it's global the client can just read it.  In the
 * future, this variable will be declared for us in the y.tab.c file
 * produced by Yacc, but for now, we declare it manually.
 */
YYSTYPE yylval;  // manually declared for pp1, later Yacc provides

/* Global variable: yylloc
 * -----------------------
 * This global variable is how we get position information about the token
 * just scanned to the client. (Operates similarly to yylval above)
 */
struct yyltype yylloc; // manually dclared for pp1, later Yacc provides

/* Macro: YY_USER_ACTION 
 * ---------------------
 * This flex built-in macro can be defined to provide an action which is
 * always executed prior to any matched rule's action. Basically, it is
 * a way of having a piece of code common to all actions factored out to
 * this routine.  We already defined it for you and left the empty
 * function DoBeforeEachAction ready for your use as needed. It will
 * be called once for each pattern scanned from the file, before
 * executing its action.
 */
static void DoBeforeEachAction(); 
#define YY_USER_ACTION DoBeforeEachAction();

%}

 /* The section before the first %% is the Definitions section of the lex
  * input file. Here is where you set options for the scanner, define lex
  * states, and can set up definitions to give names to regular expressions
  * as a simple substitution mechanism that allows for more readable
  * entries in the Rules section later. 
  */

/* Definitions: to make more readable
 */
DIGIT             ([0-9])
HEX_DIGIT         ([0-9a-fA-F])
HEX_INTEGER       (0[Xx]{HEX_DIGIT}+)
INTEGER           ({DIGIT}+)
EXPONENT          ([Ee][-+]?{INTEGER})
DOUBLE            ({INTEGER}"."{DIGIT}*{EXPONENT}?)
BEG_STRING        (\"[^"\n]*)
STRING            ({BEG_STRING}\")
IDENTIFIER        ([a-zA-Z][a-zA-Z_0-9]*)
OPERATOR          ([-+/*%=.,;!<>()[\]{}])
BEG_COMMENT       ("/*")
END_COMMENT       ("*/")
SINGLE_COMMENT    ("//"[^\n]*)

%%             /* BEGIN RULES SECTION */
 /* All patterns and actions should be placed between the start and stop
  * %% markers which delimit the Rules section. 
  */ 

 /* --------------------- Keywords ------------------------------- */
"void"              { return T_Void;        }  yes
"int"               { return T_Int;         }   yes
"double"            { return T_Double;      }   yes
"bool"              { return T_Bool;        }    yes
"string"            { return T_String;      }   yes
"class"             { return T_Class;       }   yes
"null"              { return T_Null;        }   yes
"extends"           { return T_Extends;     }   yes
"this"              { return T_This;        }   yes 
"interface"         { return T_Interface;   }   yes
"implements"        { return T_Implements;  }   yes
"while"             { return T_While;       }   yes
"for"               { return T_For;         }   yes
"if"                { return T_If;          }   yes
"else"              { return T_Else;        }   yes
"return"            { return T_Return;      }   yes
"break"             { return T_Break;       }   yes
"New"               { return T_New;         }   yes
"NewArray"          { return T_NewArray;    }   yes
"Print"             { return T_Print;       }   no
"ReadInteger"       { return T_ReadInteger; }   no
"ReadLine"          { return T_ReadLine;    }   no

 /* -------------------- Operators ----------------------------- */
"<="                { return T_LessEqual;   }
">="                { return T_GreaterEqual;}
"=="                { return T_Equal;       }
"!="                { return T_NotEqual;    }
"&&"                { return T_And;         }
"||"                { return T_Or;          }
{OPERATOR}          { return yytext[0];     }

"[]"                { return T_Dims;        }


 /* -------------------- Constants ------------------------------ */
"true"|"false"      { yylval.boolConstant = (yytext[0] == 't');
                         return T_BoolConstant; }
{INTEGER}           { yylval.integerConstant = strtol(yytext, NULL, 10);
                         return T_IntConstant; }
{HEX_INTEGER}       { yylval.integerConstant = strtol(yytext, NULL, 16);
                         return T_IntConstant; }
{DOUBLE}            { yylval.doubleConstant = atof(yytext);
                         return T_DoubleConstant; }
{STRING}            { yylval.stringConstant = strdup(yytext); 
                         return T_StringConstant; }
{BEG_STRING}        { ReportError::UntermString(&yylloc, yytext); }


 /* -------------------- Identifiers --------------------------- */
{IDENTIFIER}        { if (strlen(yytext) > MaxIdentLen)
                         ReportError::LongIdentifier(&yylloc, yytext);
                       strncpy(yylval.identifier, yytext, MaxIdentLen);
                       yylval.identifier[MaxIdentLen] = '\0';
                       return T_Identifier; }


 /* -------------------- Default rule (error) -------------------- */
.                   { ReportError::UnrecogChar(&yylloc, yytext[0]); }



%%
/* The closing %% above marks the end of the Rules section and the beginning
 * of the User Subroutines section. All text from here to the end of the
 * file is copied verbatim to the end of the generated lex.yy.c file.
 * This section is where you put definitions of helper functions.
 */


/* Function: InitScanner
 * ---------------------
 * This function will be called before any calls to yylex().  It is designed
 * to give you an opportunity to do anything that must be done to initialize
 * the scanner (set global variables, configure starting state, etc.). One
 * thing it already does for you is assign the value of the global variable
 * yy_flex_debug that controls whether flex prints debugging information
 * about each token and what rule was matched. If set to false, no information
 * is printed. Setting it to true will give you a running trail that might
 * be helpful when debugging your scanner. Please be sure the variable is
 * set to false when submitting your final version.
 */
void InitScanner()
{
    PrintDebug("lex", "Initializing scanner");
    yy_flex_debug = false;
}


/* Function: DoBeforeEachAction()
 * ------------------------------
 * This function is installed as the YY_USER_ACTION. This is a place
 * to group code common to all actions.
 */
static void DoBeforeEachAction()
{
}
