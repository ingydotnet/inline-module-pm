#!/usr/bin/env bash

source "`dirname $0`/test-module.sh"
source "`dirname $0`/setup"
use Test::More
BAIL_ON_FAIL

test_dir=acme-math-xs-pm
test_repo_url=$TEST_HOME/../acme-math-xs-pm/.git
test_test_runner=('prove -lv t/')
test_make_distdir=('perl Makefile.PL' 'make manifest distdir')
test_inline_build_dir=blib/Inline

test_branch=cpp
test_module

test_branch=dzil
test_make_distdir=('dzil build')
test_module

test_branch=eumm
test_make_distdir=('perl Makefile.PL' 'make manifest distdir')
test_module

test_branch='m-b'
test_make_distdir=('perl Build.PL' './Build manifest' './Build distdir')
test_module

test_branch='m-i'
test_make_distdir=('perl Makefile.PL' 'make manifest distdir')
test_module

test_branch='xs'
test_test_runner=('perl Makefile.PL' 'make' 'prove -blv t/')
test_inline_build_dir=
test_module

test_branch='zild'
test_inline_build_dir=blib/Inline
test_test_runner=('prove -lv test/')
test_make_distdir=('zild make distdir')
test_module

done_testing;
teardown

# vim: set ft=sh:
