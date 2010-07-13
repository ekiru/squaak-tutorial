class Squaak::Actions is HLL::Actions;

method TOP($/) {
    make PAST::Block.new( $<statementlist>.ast , :hll<squaak>, :node($/) );
}

method statementlist($/) {
    my $past := PAST::Stmts.new( :node($/) );
    for $<statement> { $past.push( $_.ast ); }
    make $past;
}

method statement($/, $key) {
    # get the field stored in key from the $/ object,
    # and retrieve the result object from that field.
    make $/{$key}.ast;
}

method assignment($/) {
    my $lhs := $<primary>.ast;
    my $rhs := $<expression>.ast;
    $lhs.lvalue(1);
    make PAST::Op.new($lhs, $rhs, :pasttype<bind>, :node($/));
}

method block($/) {
    # create a new block, set its type to 'immediate',
    # meaning it is potentially executed immediately
    # (as opposed to a declaration, such as a
    # subroutine definition).
    my $past := PAST::Block.new( :blocktype('immediate'),
                                 :node($/) );

    # for each statement, add the result
    # object to the block
    for $<statement> {
        $past.push($_.ast) ;
    }
    make $past;
}

    method if_statement($/) {
        my $cond := $<expression>.ast;
        my $then := $<block>.ast;
        my $past := PAST::Op.new( $cond, $then,
                                  :pasttype('if'),
                                  :node($/) );
        if $<else> {
            $past.push($<else>[0].ast);
        }
        make $past;
    }

method primary($/) {
    make $<identifier>.ast;
}

method identifier($/) {
    make PAST::Var.new(:name(~$/), :scope<package>, :node($/));
}

method expression($/) {
    make $<integer_constant> ?? $<integer_constant>.ast !! $<string_constant>.ast;
}

method integer_constant($/) { make $<integer>.ast; }
method string_constant($/) { make $<quote>.ast; }

method quote:sym<'>($/) { make $<quote_EXPR>.ast; }
method quote:sym<">($/) { make $<quote_EXPR>.ast; }
