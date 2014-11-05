use strict;
use warnings;
package Inline::Module::MakeMaker;

use Exporter 'import';
use ExtUtils::MakeMaker();
use Carp;

our @EXPORT = qw(WriteMakefile WriteInlineMakefile);

use XXX;

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
    $_[0] =~ s/^(distdir\s*:)/$1:/m;
}

sub add_postamble {
    my $inline_section = make_distdir_section();

    $_[0] .= <<"...";

# Inline::Module::MakeMaker is adding this section:

# --- MakeMaker Inline::Module sections:

$inline_section

# The End is here.
...
}

sub make_distdir_section {
    my $section = "distdir ::\n";
    for my $module (included_modules()) {
        my ($path, $inc_path, $inc_dir) = include_module($module);
        my $find =
            qq!\$(ABSPERLRUN) -e 'require $module;print \$\$INC{"$path"}'!;
        $section .= "\t\$(NOECHO) \$(MKPATH) \$(DISTVNAME)/$inc_dir\n";
        $section .= "\t\$(NOECHO) \$(CP) `$find` \$(DISTVNAME)/$inc_path\n";
    }
    my $module = $INLINE->{module};
    $section .= qq!\t\$(NOECHO) \$(ABSPERLRUN) -MInline::Module=dist -e 1 -- $module!;
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
        or croak "XXX";
    return (
        'Inline',
        $ilsm,
        'Inline::Module',
        'Inline::Module::MakeMaker',
    );
}

1;
