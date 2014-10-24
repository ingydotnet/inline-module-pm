use strict; use warnings;
package Inline::Module;
our $VERSION = '0.02';

use File::Path;
use Inline();

# use XXX;

###
# The purpose of this module is to support:
#
#   perl-inline-module create lib/Foo/Inline.pm
###

sub new {
    my $class = shift;
    return bless {@_}, $class;
}

sub run {
    my ($self) = @_;
    $self->get_opts;
    my $method = "do_$self->{command}";
    die usage() unless $self->can($method);
    $self->$method;
}

sub do_create {
    my ($self) = @_;
    my @modules = @{$self->{args}};
    die "The 'create' command requires at least on module name to create\n"
        unless @modules >= 1;
    for my $module (@modules) {
        $self->create_module($module);
    }
}

sub create_module {
    my ($self, $module) = @_;
    die "Invalid module name '$module'"
        unless $module =~ /^[A-Za-z]\w*(?:::[A-Za-z]\w*)*$/;
    my $filepath = $module;
    $filepath =~ s!::!/!g;
    $filepath = "lib/$filepath.pm";
    my $dirpath = $filepath;
    if (-e $filepath) {
        warn "'$filepath' already exists\n";
#         return;
    }
    $dirpath =~ s!(.*)/.*!$1!;
    File::Path::mkpath($dirpath);
    open OUT, '>', $filepath
        or die "Can't open '$filepath' for output:\n$!";
    print OUT $self->proxy_module($module);
    print "Inline module '$module' created as '$filepath'\n";
}

sub proxy_module {
    my ($self, $module) = @_;
    return <<"...";
use strict;
use warnings;
package $module;

# TODO: Make sure this is latest version (self-check).
our \$INLINE_VERSION = '$Inline::VERSION';

use File::Path;
BEGIN { File::Path::mkpath('./blib') unless -d './blib' }
use Inline Config => directory => './blib';

sub import {
    splice(\@_, 0, 1, 'Inline');
    goto &Inline::import;
}

1;
...
}

sub get_opts {
    my ($self) = @_;
    my $argv = $self->{argv};
    die usage() unless @$argv >= 1;
    my ($command, @args) = @$argv;
    $self->{command} = $command;
    $self->{args} = \@args;
    delete $self->{argv};
}

sub usage {
    <<'...';
Usage:
        perl-inline-module <command> [<arguments>]

Commands:
        perl-inline-module create Module::Name::Inline

...
}

1;
