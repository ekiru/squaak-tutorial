class Squaak::Actions is HLL::Actions;

method TOP($/) {
    make PAST::Block.new( $<statementlist>.ast , :hll<squaak>, :node($/) );
}

method statementlist($/) {
    my $past := PAST::Stmts.new( :node($/) );
    for $<statement> { $past.push( $_.ast ); }
    make $past;
}

method statement:sym<assignment>($/) {
    my $lhs := $<primary>.ast;
    my $rhs := $<expression>.ast;
    $lhs.lvalue(1);
    make PAST::Op.new($lhs, $rhs, :pasttype<bind>, :node($/));
}

method statement:sym<if>($/) {
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

method statement:sym<throw>($/) {
    make PAST::Op.new( $<expression>.ast,
                       :pirop('throw'),
                       :node($/) );
}

method statement:sym<try>($/) {
    ## get the try block
    my $try := $<try>.ast;

    ## create a new PAST::Stmts node for
    ## the catch block; note that no
    ## PAST::Block is created, as this
    ## currently has problems with the
    ## exception object. For now this will
    ## do.
    my $catch := PAST::Stmts.new( :node($/) );
    $catch.push($<catch>.ast);

    ## get the exception identifier;
    ## set a declaration flag, the scope,
    ## and clear the viviself attribute.
    my $exc := $<exception>.ast;
    $exc.isdecl(1);
    $exc.scope('lexical');
    $exc.viviself(0);
    ## generate instruction to retrieve the exception object (and the
    ## exception message, that is passed automatically in PIR, this is stored
    ## into $S0 (but not used).
    my $pir := "    .get_results (\%r, \$S0)\n"
             ~ "    store_lex '" ~ $exc.name()
             ~ "', \%r";

    $catch.unshift( PAST::Op.new( :inline($pir), :node($/) ) );

    ## do the declaration of the exception object as a lexical here:
    $catch.unshift( $exc );
    make PAST::Op.new( $try, $catch, :pasttype('try'), :node($/) );
}

method exception($/) {
    our $?BLOCK;
    my $past := $<identifier>.ast;
    $?BLOCK.symbol( $past.name(), :scope('lexical') );
    make $past;
}

method statement:sym<while>($/) {
    my $cond := $<expression>.ast;
    my $body := $<block>.ast;
    make PAST::Op.new( $cond, $body, :pasttype('while'), :node($/) );
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
