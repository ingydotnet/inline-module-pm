use strict; use warnings;
package Inline::Module;
our $VERSION = '0.17';

use Config;
use File::Path;
use File::Copy;
use File::Find;
use Inline();
use Carp;

use XXX;

sub new {
    my $class = shift;
    return bless {@_}, $class;
}

#------------------------------------------------------------------------------
# This import serves multiple roles:
# - -MInline::Module=autostub
# - ::Inline module's proxy to Inline.pm
# - Makefile.PL postamble
# - Makefile rule support
#------------------------------------------------------------------------------
sub import {
    my $class = shift;

    my ($inline_module, $program) = caller;

    if ($program eq 'Makefile.PL') {
        no warnings 'once';
        *MY::postamble = \&postamble;
        return;
    }

    return unless @_;
    my $cmd = shift;

    return $class->handle_makestub(@_)
        if $cmd eq 'makestub';
    return $class->handle_autostub(@_)
        if $cmd eq 'autostub';
    return $class->handle_distdir(@_)
        if $cmd eq 'distdir';
    return $class->handle_fixblib(@_)
        if $cmd eq 'fixblib';

    if ($cmd =~ /^v[0-9]$/) {
        $class->check_api_version($inline_module, $cmd => @_);
        no strict 'refs';
        *{"${inline_module}::import"} = $class->importer($inline_module);
        return;
    }

    die "Unknown Inline::Module::import argument '$cmd'"
}

sub check_api_version {
    my ($class, $inline_module, $api_version, $inline_module_version) = @_;
    if ($api_version ne 'v1' or $inline_module_version ne $VERSION) {
        warn <<"...";
It seems that '$inline_module' is out of date.
It is using Inline::Module version '$inline_module_version'.
You have Inline::Module version '$VERSION' installed.

Make sure you have the latest version of Inline::Module installed, then run:

    perl -MInline::Module=makestub,$inline_module

...
        # XXX 'exit' is used to get a cleaner error msg.
        # Try to redo this without 'exit'.
        exit 1;
    }
}

sub importer {
    my ($class, $inline_module) = @_;
    return sub {
        require File::Path;
        File::Path::mkpath('./blib') unless -d './blib';
        require Inline;
        Inline->import(
            Config =>
            directory => './blib',
            using => 'Inline::C::Parser::RegExp',
            name => $inline_module,
        );
        my $class = shift;
        Inline->import_heavy(@_);
    };
}

#------------------------------------------------------------------------------
# The postamble methods:
#------------------------------------------------------------------------------
sub postamble {
    my ($makemaker, %args) = @_;

    my $inline = $args{inline}
        or croak "'postamble' section requires 'inline' key in Makefile.PL";
    croak "postamble 'inline' section requires 'module' key in Makefile.PL"
        unless $inline->{module};

    my $self = $Inline::Module::Self = Inline::Module->new;
    $self->default_args($inline, $makemaker);

    my $code_modules = $self->{module};
    my $inlined_modules = $self->{inline};
    my @included_modules = $self->included_modules;

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

sub default_args {
    my ($self, $args, $makemaker) = @_;
    $args->{module} = $makemaker->{NAME} unless $args->{module};
    $args->{module} = [ $args->{module} ] unless ref $args->{module};
    $args->{inline} ||= [ map "${_}::Inline", @{$args->{module}} ];
    $args->{inline} = [ $args->{inline} ] unless ref $args->{inline};
    $args->{ilsm} ||= 'Inline::C';
    $args->{ilsm} = [ $args->{ilsm} ] unless ref $args->{ilsm};
    %$self = %$args;
}

sub included_modules {
    my ($self) = @_;

    return (
        'Inline',
        'Inline::denter',
        @{$self->{ilsm}},
        'Inline::C::Parser::RegExp',
        'Inline::Module',
    );
}

#------------------------------------------------------------------------------
# Class methods.
#------------------------------------------------------------------------------
sub handle_makestub {
    my ($class, @args) = @_;

    my $dest;
    my @modules;
    for my $arg (@args) {
        if ($arg eq 'blib') {
            $dest = 'blib/lib';
        }
        elsif ($arg =~ m!/!) {
            $dest = $arg;
        }
        elsif ($arg =~ /::/) {
            push @modules, $arg;
        }
        else {
            croak "Unknown 'makestub' argument: '$arg'";
        }
    }
    $dest ||= 'lib';


    for my $module (@modules) {
        my $path = $class->write_proxy_module($dest, $module);
        print "Created stub module '$path' (Inline::Module $VERSION)\n";
    }

    exit 0;
}

sub handle_autostub {
    my ($class, @args) = @_;
    croak "The 'autostub' directive used but no './lib' dir present"
        unless -d 'lib';
    require lib;
    lib->import('lib');

    my $dest;
    my @modules;
    for my $arg (@args) {
        if ($arg eq 'blib') {
            $dest = 'blib/lib';
        }
        elsif ($arg =~ m!/!) {
            $dest = $arg;
        }
        else {
            croak "Unknown 'autostub' argument: '$arg'";
        }
    }
    $dest ||= 'lib';

    push @INC, sub {
        my ($self, $module) = @_;

        # TODO This asserts that we are really building a ::Inline stub.
        # We might need to be more forgiving on naming here at some point:
        $module =~ m!/Inline\w*\.pm$!
            or return;

        my $path = "$dest/$module";
        if (not -e $path) {
            $module =~ s!\.pm$!!;
            $module =~ s!/!::!g;
            my $path = $class->write_proxy_module($dest, $module);
            print "Created stub module '$path' (Inline::Module $VERSION)\n";
        }

        open my $fh, '<', $path or die "Can't open '$path' for input:\n$!";
        return $fh;
    }
}

sub handle_distdir {
    my ($class) = @_;
    my ($distdir, @args) = @ARGV;
    my (@inlined_modules, @included_modules);

    while (@args and ($_ = shift(@args)) ne '--') {
        push @inlined_modules, $_;
    }
    while (@args and ($_ = shift(@args)) ne '--') {
        push @included_modules, $_;
    }

    for my $module (@inlined_modules) {
        $class->write_dyna_module("$distdir/lib", $module);
        $class->write_proxy_module("$distdir/inc", $module);
    }
    for my $module (@included_modules) {
        $class->write_included_module("$distdir/inc", $module);
    }
}

sub handle_fixblib {
    my ($class) = @_;
    my $ext = $Config::Config{dlext};
    -d 'blib'
        or die "Inline::Module::fixblib expected to find 'blib' directory";
    find({
        wanted => sub {
            -f or return;
            m!^blib/(config-|\.lock$)! and unlink, return;
            if (m!^(blib/lib/auto/.*)\.$ext$!) {
                unlink "$1.inl", "$1.bs";
                # XXX this deletes:
                # -lib/auto/Acme/Math/XS/.exists
                File::Path::rmtree 'blib/arch/auto';
                File::Copy::move 'blib/lib/auto', 'blib/arch/auto';
            }
        },
        no_chdir => 1,
    }, 'blib');
}

sub write_included_module {
    my ($class, $dest, $module) = @_;
    my $code = $class->read_local_module($module);
    $class->write_module($dest, $module, $code);
}

sub read_local_module {
    my ($class, $module) = @_;
    eval "require $module; 1" or die $@;
    my $file = $module;
    $file =~ s!::!/!g;
    my $filepath = $INC{"$file.pm"};
    open IN, '<', $filepath
        or die "Can't open '$filepath' for input:\n$!";
    my $code = do {local $/; <IN>};
    close IN;
    return $code;
}

sub write_proxy_module {
    my ($class, $dest, $module) = @_;

    my $code = <<"...";
# DO NOT EDIT
#
# GENERATED BY: Inline::Module $Inline::Module::VERSION
#
# This module is for author-side development only. When this module is shipped
# to CPAN, it will be automagically replaced with content that does not
# require any Inline framework modules (or any other non-core modules).

use strict; use warnings;
package $module;
use Inline::Module 'v1' => '$VERSION';

1;
...

    $class->write_module($dest, $module, $code);
}

sub write_dyna_module {
    my ($class, $dest, $module) = @_;
    my $code = <<"...";
# DO NOT EDIT
#
# GENERATED BY: Inline::Module $Inline::Module::VERSION

use strict; use warnings;
package $module;
use base 'DynaLoader';
bootstrap $module;

1;
...

# XXX - think about this later:
# our \$VERSION = '0.0.5';
# bootstrap $module \$VERSION;

    $class->write_module($dest, $module, $code);
}

sub write_module {
    my ($class, $dest, $module, $text) = @_;

    my $filepath = $module;
    $filepath =~ s!::!/!g;
    $filepath = "$dest/$filepath.pm";
    my $dirpath = $filepath;
    $dirpath =~ s!(.*)/.*!$1!;
    File::Path::mkpath($dirpath);

    unlink $filepath;
    open OUT, '>', $filepath
        or die "Can't open '$filepath' for output:\n$!";
    print OUT $text;
    close OUT;

    return $filepath;
}

1;
