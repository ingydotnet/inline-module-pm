#!/bin/bash

source "`dirname $0`/setup"
use Test::More
BAIL_ON_FAIL

# lib must exist (Sanity check)
mkdir lib

# Generate a stub
perl -MInline::Module=makestub,Foo::Inline
ok "`[ -f lib/Foo/Inline.pm ]`" "The stub file exists in lib"
rm -fr lib/Foo

# Auto-generate a stub
(
  export PERL5OPT=-MInline::Module=autostub
  perl -e 'use Foo::Inline'
)
ok "`[ -f lib/Foo/Inline.pm ]`" "The stub file exists in lib"
rm -fr lib/Foo

# Generate into blib
perl -MInline::Module=makestub,Foo::Inline,blib
ok "`[ -f blib/lib/Foo/Inline.pm ]`" "The stub file exists in blib"
rm -fr blib

# Auto-generate into blib
(
  export PERL5OPT=-MInline::Module=autostub,blib
  perl -e 'use Foo::Inline'
)
ok "`[ -f blib/lib/Foo/Inline.pm ]`" "The stub file exists in blib"
rm -fr blib

done_testing
teardown

# vim: set ft=sh:
