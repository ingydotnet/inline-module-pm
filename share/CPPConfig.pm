# This module comes from Inline::Module share file: 'CPPConfig.pm'

use strict; use warnings;
package Inline::CPP::Config;

use Config;
# use ExtUtils::CppGuess;

our ($compiler, $libs, $iostream_fn, $cpp_flavor_defs) = cpp_guess();

my $cpp_info;
BEGIN {
    my $default_headers = <<'.';
#define __INLINE_CPP_STANDARD_HEADERS 1
#define __INLINE_CPP_NAMESPACE_STD 1
.
    my @default_info = (
        'g++ -xc++',
        '-lstdc++',
        'iostream',
        $default_headers,
    );
    $cpp_info = {
        'cygwin' => [ @default_info ],
        'darwin' => [ @default_info ],
        'linux' => [ @default_info ],
        'MSWin32' => [ @default_info ],
    };
}

sub throw;
sub cpp_guess {
    my $key = $Config::Config{osname};
    if (my $config = $cpp_info->{$key}) {
        $config->[0] .= ' -D_FILE_OFFSET_BITS=64',
            if $Config::Config{ccflags} =~ /-D_FILE_OFFSET_BITS=64/;
        return @$config;
    }

    throw "Unsupported OS/Compiler for Inline::Module+Inline::CPP '$key'";
}

sub throw {
    die "@_" unless
        $ENV{PERL5_MINISMOKEBOX} ||
        $ENV{PERL_CR_SMOKER_CURRENT};
    eval 'use lib "inc"; use Inline::Module; 1' or die $@;
    Inline::Module->smoke_system_info_dump();
}

1;
