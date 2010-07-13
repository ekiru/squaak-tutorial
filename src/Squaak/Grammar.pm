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
    | <assignment>   #= assignment
    | <if_statement> #= if_statement
}

rule assignment { 
    <primary> '=' <expression>
}

rule if_statement {
    'if' <expression 'then' <block>
    ['else' $<else>=<block> ]?
    'end'
}

rule block {
    <statement>*
}

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
