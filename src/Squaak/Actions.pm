class Squaak::Actions is HLL::Actions;

method begin_TOP ($/) {
    our $?BLOCK := PAST::Block.new(:blocktype<declaration>, :node($/),
                                   :hll<squaak>);
    our @?BLOCK;
    @?BLOCK.unshift($?BLOCK);
}

method TOP($/) {
    our @?BLOCK;
    my $past := @?BLOCK.shift();
    $past.push($<statementlist>.ast);
    make $past;
}

method statementlist($/) {
    my $past := PAST::Stmts.new( :node($/) );
    for $<stat_or_def> { $past.push( $_.ast ); }
    make $past;
}

method stat_or_def($/) {
    if $<statement> { 
        make $<statement>.ast;
    } else { # Must be a def
        make $<sub_definition>.ast;
    }
}

method sub_definition($/) {
     our $?BLOCK;
     our @?BLOCK;
     my $past := $<parameters>.ast;
     my $name := $<identifier>.ast;

     # set the sub's name
     $past.name($name.name);

     # add all statements to the sub's body
     for $<statement> {
         $past.push($_.ast);
     }

     # and remove the block from the scope stack and restore the current block
     @?BLOCK.shift();
     $?BLOCK := @?BLOCK[0];
     make $past;
}

method parameters($/) {
    our $?BLOCK;
    our @?BLOCK;
    my $past := PAST::Block.new( :blocktype('declaration'), :node($/) );

    # now add all parameters to this block
    for $<identifier> {
        my $param := $_.ast;
        $param.scope('parameter');
        $past.push($param);

        # register the parameter as a local symbol
        $past.symbol($param.name(), :scope('lexical'));
    }

    # now put the block into place on the scope stack
    $?BLOCK := $past;
    @?BLOCK.unshift($past);

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
    my $past := PAST::Op.new( $cond, $<then>.ast,
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
    my $past := $<identifier>.ast;
    make $past;
}

method statement:sym<var>($/) {
    our $?BLOCK;
    # get the PAST for the identifier
    my $past := $<identifier>.ast;

    # this is a local (it's being defined)
    $past.scope('lexical');

    # set a declaration flag
    $past.isdecl(1);

    # check for the initialization expression
    if $<expression> {
        # use the viviself clause to add a
        # an initialization expression
        $past.viviself($<expression>[0].ast);
    }
    else { # no initialization, default to "Undef"
        $past.viviself('Undef');
    }

    my $name := $past.name();

    if $?BLOCK.symbol( $name ) {
        # symbol is already present
        $/.panic("Error: symbol " ~ $name ~ " was already defined.\n");
    }
    else {
        $?BLOCK.symbol( $name, :scope('lexical') );
    }
    make $past;
}

method statement:sym<while>($/) {
    my $cond := $<expression>.ast;
    my $body := $<block>.ast;
    make PAST::Op.new( $cond, $body, :pasttype('while'), :node($/) );
}

method begin_block($/) {
    our $?BLOCK;
    our @?BLOCK;
    $?BLOCK := PAST::Block.new(:blocktype('immediate'),
                                   :node($/));
    @?BLOCK.unshift($?BLOCK);
}

method block($/) {
    our $?BLOCK;
    our @?BLOCK;
    my $past := @?BLOCK.shift();
    $?BLOCK  := @?BLOCK[0];

    for $<statement> {
        $past.push($_.ast);
    }
    make $past;
}

method primary($/) {
    make $<identifier>.ast;
}

method identifier($/) {
     our @?BLOCK;
     my $name  := ~$<ident>;
     my $scope := 'package'; # default value
     # go through all scopes and check if the symbol
     # is registered as a local. If so, set scope to
     # local.
     for @?BLOCK {
         if $_.symbol($name) {
             $scope := 'lexical';
         }
     }

     make PAST::Var.new( :name($name),
                         :scope($scope),
                         :viviself('Undef'),
                         :node($/) );
}

method expression($/) {
    make $<integer_constant> ?? $<integer_constant>.ast !! $<string_constant>.ast;
}

method integer_constant($/) { make $<integer>.ast; }
method string_constant($/) { make $<quote>.ast; }

method quote:sym<'>($/) { make $<quote_EXPR>.ast; }
method quote:sym<">($/) { make $<quote_EXPR>.ast; }
