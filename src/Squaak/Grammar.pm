=begin overview

This is the grammar for Squaak in Perl 6 rules.

=end overview

grammar Squaak::Grammar is HLL::Grammar;

token TOP {
    <statementlist>
    [ $ || <.panic: "Syntax error"> ]
}

## Lexer items

# This <ws> rule treats # as "comment to eol".
token ws {
    <!ww>
    [ '#' \N* \n? | \s+ ]*
}

## Statements

rule statementlist { [ <statement> | <?> ] ** ';' }

rule statement {
    <assignment>
}

proto token statement_control { <...> }

rule assignment { 
    <primary> '=' <expression>
}

rule statement_control:sym<say>   { <sym> [ <EXPR> ] ** ','  }
rule statement_control:sym<print> { <sym> [ <EXPR> ] ** ','  }

## Terms

rule primary {
    <identifier>
}

token identifier {
    <!keyword> <ident>
}

token keyword {
    ['and'|'catch'|'do'   |'else' |'end' |'for' |'if'
    |'not'|'or'   |'sub'  |'throw'|'try' |'var'|'while']>>
}

rule expression {
    | <integer_constant>
    | <string_constant>
}

token integer_constant { <integer> }
token string_constant { <quote> }

proto token quote { <...> }
token quote:sym<'> { <?[']> <quote_EXPR: ':q'> }
token quote:sym<"> { <?["]> <quote_EXPR: ':qq'> }

## Operators

INIT {
    Squaak::Grammar.O(':prec<u>, :assoc<left>',  '%multiplicative');
    Squaak::Grammar.O(':prec<t>, :assoc<left>',  '%additive');
}

token circumfix:sym<( )> { '(' <.ws> <EXPR> ')' }

token infix:sym<*>  { <sym> <O('%multiplicative, :pirop<mul>')> }
token infix:sym</>  { <sym> <O('%multiplicative, :pirop<div>')> }

token infix:sym<+>  { <sym> <O('%additive, :pirop<add>')> }
token infix:sym<->  { <sym> <O('%additive, :pirop<sub>')> }
