use strict;
use warnings;
package Inline::Module::MakeMaker;

use Exporter 'import';
use ExtUtils::MakeMaker();
use Carp;

our @EXPORT = qw(WriteMakefile WriteInlineMakefile);
our $VERSION = '0.77';

use XXX;
sub WriteMakefile {
    &ExtUtils::MakeMaker::WriteMakefile(@_);
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
# Well, not quite. Inline::Module::MakeMaker is adding this:

# --- MakeMaker inline section:

$inline_section

# The End is here.
...
}

sub make_inline_section {
    my $distdir = 
    my $section = "distdir ::\n";
#     for my $mod (qw{
#         Inline::Module
#         Inline
#         Inline::C
#     }) {
#         eval "require $module; 1" or die $@;
#         $section .= 
#     <<'...';
# distdir ::
# 	@echo O HAIIIIIIIIII
# ...
}

1;

