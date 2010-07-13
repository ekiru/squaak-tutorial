class Squaak::Actions is HLL::Actions;

method TOP($/) {
    make PAST::Block.new( $<statementlist>.ast , :hll<squaak>, :node($/) );
}

method statementlist($/) {
    my $past := PAST::Stmts.new( :node($/) );
    for $<statement> { $past.push( $_.ast ); }
    make $past;
}

method statement($/) {
    make $<assignment>.ast;
}

method assignment($/) {
    make PAST::Op.new(:pasttype<bind>, $<primary>.ast, $<expression>.ast);
}

method primary($/) {
    make $<identifier>.ast;
}

method identifier($/) {
    make PAST::Var.new(:name(~$/), :scope<package>);
}

method expression($/) {
    make $<integer_constant> ?? $<integer_constant>.ast !! $<string_constant>.ast;
}

method integer_constant($/) { make $<integer>.ast; }
method string_constant($/) { make $<quote>.ast; }

method quote:sym<'>($/) { make $<quote_EXPR>.ast; }
method quote:sym<">($/) { make $<quote_EXPR>.ast; }
