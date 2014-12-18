#!/usr/bin/env bash

source "`dirname $0`/setup"
use Test::More
BAIL_ON_FAIL

{
  perl -MInline::Module=makestub,Foo::Bar
  ok "`[ -f lib/Foo/Bar.pm ]`" "Stub file was generated into lib"
  rm -fr lib
}

{
  (
    export PERL5OPT=-MInline::Module=autostub,Foo::Bar
    perl -e 'use Foo::Bar'
  )
  pass "Stub was auto-generated as IO::String object"
  # ok "`[ ! -e lib ] && [ ! -e blib ]`" "Neither lib nor blib exist"
}

done_testing
teardown

# vim: set ft=sh:
