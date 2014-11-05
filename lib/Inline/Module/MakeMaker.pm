use strict;
use warnings;
package Inline::Module::MakeMaker;

use Exporter 'import';
use ExtUtils::MakeMaker();
use Carp;

our @EXPORT = qw(WriteMakefile WriteInlineMakefile);

use XXX;

$SIG{__WARN__} = sub {
    warn ">>$_[0]<<" unless $_[0] =~ /INLINE/;
};

my $INLINE;
sub WriteMakefile {
    my %args = @_;
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
    my $inline_section = make_inline_section();

    $_[0] .= <<"...";

# Inline::Module::MakeMaker is adding this section:

# --- MakeMaker Inline::Module section:

$inline_section

# The End is here.
...
}

sub make_inline_section {
    my $section = "distdir ::\n";
    for my $module (included_modules()) {
        my ($source_path, $inc_path) = include_module($module);
        $section .= "\t\$(NOECHO) \$(CP) $source_path \$(DISTVNAME)/$inc_path\n";
    }
    return $section;
}

sub include_module {
    my $module = shift;
    eval "require $module; 1" or die $@;
    my $path = $module;
    $path =~ s!::!/!g;
    my $source_path = $INC{"$path.pm"}
        or die "XXX";
    my $inc_path = "inc/$path.pm";
    return ($source_path, $inc_path);
}

sub included_modules {
    my $ilsm = $INLINE->{ILSM}
        or croak "XXX";
    return (
        'Inline::Module',
        'Inline',
        $ilsm,
    );
}


1;
