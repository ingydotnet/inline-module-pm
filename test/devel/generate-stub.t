#!/bin/bash

source "`dirname $0`/setup"
use Test::More
BAIL_ON_FAIL

# lib must exist (Sanity check)
mkdir lib

# Generate a Foo::Inline stub
perl -MInline::Module=blib -MFoo::Inline -e1

ok "`[ -d blib ]`" "The blib directory exists"

done_testing
teardown

# vim: set ft=sh:
