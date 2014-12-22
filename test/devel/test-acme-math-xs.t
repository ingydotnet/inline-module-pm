#!/usr/bin/env bash

source "`dirname $0`/test-module.sh"
source "`dirname $0`/setup"
use Test::More
BAIL_ON_FAIL

# Default testing values:
test_dir=acme-math-xs-pm
test_repo_url=$TEST_HOME/../acme-math-xs-pm/.git
test_test_runner=('prove -lv t/')
test_make_distdir=('perl Makefile.PL' 'make manifest distdir')
test_inline_build_dir=blib/Inline
test_dist=Alt-Acme-Math-XS
test_dist_files=(
  MANIFEST
  lib/Acme/Math/XS.pm
  inc/Acme/Math/XS/Inline.pm
)

t() {
  local test_branch=cpp
  test_module
};t

t() {
  local test_branch=dzil
  local test_make_distdir=('dzil build')
  test_module
};t

t() {
  local test_branch=eumm
  test_module
};t

t() {
  local test_branch='m-b'
  local test_make_distdir=('perl Build.PL' './Build manifest' './Build distdir')
  test_module
};t

t() {
  local test_branch='m-i'
  test_module
};t

t() {
  local test_branch='xs'
  local test_test_runner=('perl Makefile.PL' 'make' 'prove -blv t/')
  local test_inline_build_dir=
  local test_dist=Acme-Math-XS
  test_module
};t

t() {
  local test_branch='zild'
  local test_inline_build_dir=blib/Inline
  local test_test_runner=('prove -lv test/')
  local test_make_distdir=('zild make distdir')
  test_module
};t

t() {
  local test_dir=Math-Prime-FastSieve
  local test_repo_url=$TEST_HOME/../Math-Prime-FastSieve/.git
  local test_dist=Alt-$test_dir
  local test_branch='alt-inline'
  local test_dist_files=(
    MANIFEST
    lib/Math/Prime/FastSieve.pm
    inc/Math/Prime/FastSieve/Inline.pm
  )
  test_module
};t

done_testing;
teardown

# vim: set ft=sh:
