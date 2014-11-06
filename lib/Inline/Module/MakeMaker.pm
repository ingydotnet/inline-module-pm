use strict;
use warnings;
package Inline::Module::MakeMaker;

use Exporter 'import';
use ExtUtils::MakeMaker();
use Carp;

our @EXPORT = qw(WriteMakefile WriteInlineMakefile);

#                     use XXX;

# TODO This should probably become OO, rather than a package lexical:
my $INLINE;

sub WriteMakefile {
    my %args = @_;
    croak "'inc' must be in \@INC. Add 'use lib \"inc\";' to Makefile.PL.\n"
        unless grep /^inc$/, @INC;
    $INLINE = delete $args{INLINE} or croak
        "INLINE keyword required. See: perldoc Inline::Module::MakeMaker";
    &ExtUtils::MakeMaker::WriteMakefile(%args);
    my $makefile = read_makefile();
    fixup_makefile($makefile);
    add_postamble($makefile);
    write_makefile($makefile);
}

sub read_makefile {
    open MF_IN, '<', 'Makefile'
        or croak "Can't open 'Makefile' for input:\n$!";
    my $makefile = do {local $/; <MF_IN>};
    close MF_IN;
    return $makefile;
}

sub write_makefile {
    my $makefile = shift;
    open MF_OUT, '>', 'Makefile'
        or croak "Can't open 'Makefile' for output:\n$!";
    print MF_OUT $makefile;
    close MF_OUT;
}

sub fixup_makefile {
    $_[0] =~ s/^(distdir\s+):(\s+)/$1::$2/m;
    $_[0] =~ s/^(pure_all\s+):(\s+)/$1::$2/m;
}

sub add_postamble {
    my $inline_section = make_distdir_section();

    $_[0] .= <<"...";

# Inline::Module::MakeMaker is adding this section:

# --- MakeMaker Inline::Module sections:

$inline_section
...
}

sub make_distdir_section {
    my $code_modules = $INLINE->{module};
    $code_modules = [ $code_modules ] unless ref $code_modules;
    my $inlined_modules = $INLINE->{inline};
    $inlined_modules = [ $inlined_modules ] unless ref $inlined_modules;
    my @included_modules = included_modules();

    my $section = <<"...";
distdir ::
\t\$(NOECHO) \$(ABSPERLRUN) -MInline::Module=distdir -e 1 -- \$(DISTVNAME) @$inlined_modules -- @included_modules

pure_all ::
...

    for my $module (@$code_modules) {
        $section .=
            "\t\$(NOECHO) \$(ABSPERLRUN) -Iinc -Ilib -e 'use $module'\n";
    }
    $section .=
        "\t\$(NOECHO) \$(ABSPERLRUN) -Iinc -MInline::Module=fixblib -e 1";

    return $section;
}

sub include_module {
    my $module = shift;
    eval "require $module; 1" or die $@;
    my $path = $module;
    $path =~ s!::!/!g;
    my $source_path = $INC{"$path.pm"}
        or die "Can't locate $path.pm in %INC";
    my $inc_path = "inc/$path.pm";
    my $inc_dir = $path;
    $inc_dir =~ s!(.*/).*!$1! or
        $inc_dir = '';
    $inc_dir = "inc/$inc_dir";
    return ("$path.pm", $inc_path, $inc_dir);
}

sub included_modules {
    my $ilsm = $INLINE->{ILSM}
        or croak "INLINE section requires 'ILSM' key in Makefile.PL";
    $ilsm = [ $ilsm ] unless ref $ilsm;
    return (
        'Inline',
        'Inline::denter',
        @$ilsm,
        'Inline::C::Parser::RegExp',
        'Inline::Module',
        'Inline::Module::MakeMaker',
    );
}

1;
