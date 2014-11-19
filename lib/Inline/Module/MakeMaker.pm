use strict;
use warnings;
package Inline::Module::MakeMaker;

use Exporter;
our @EXPORT_OK = qw/postamble/;
sub import {
    my ($class, @args) = @_;
    if (@args == 1 and $args[0] eq '-global') {
        no warnings 'once';
        *MY::postamble = \&postamble;
    }
    else {
        goto &Exporter::import;
    }
}

use Carp;

our @EXPORT = qw(FixMakefile);

#                     use XXX;

sub default_args {
    my ($self, $args) = @_;
    $args->{module} = $self->{NAME} unless $args->{module};
    $args->{module} = [ $args->{module} ] unless ref $args->{module};
    $args->{inline} ||= [ map "${_}::Inline", @{$args->{module}} ];
    $args->{inline} = [ $args->{inline} ] unless ref $args->{inline};
    $args->{ILSM} ||= 'Inline::C';
    return $args;
}

sub postamble {
    my ($self, %args) = @_;
    my $inline = default_args($self, \%args);
    my $code_modules = $inline->{module};
    my $inlined_modules = $inline->{inline};
    my @included_modules = included_modules($inline->{ILSM});

    my $section = <<"...";
distdir : distdir_inline

distdir_inline : create_distdir
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

sub included_modules {
    my $ilsm = shift
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
