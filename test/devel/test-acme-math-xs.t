#!/usr/bin/env bash

source "`dirname $0`/setup"
use Test::More
BAIL_ON_FAIL

git clone $TEST_HOME/../acme-math-xs-pm/.git -b eumm
cd acme-math-xs-pm

{
  perl -MInline::Module=autostub,lib,Acme::Math::XS::Inline \
    -MAcme::Math::XS::Inline -e1
  ok "`[ -f lib/Acme/Math/XS/Inline.pm ]`" "The stub file exists"
}

{
  prove -lv t &> out
  pass "Acme::Math::XS passes its tests"
}

{
  perl Makefile.PL
  ok "`[ -f Makefile ]`" "The Makefile exists after 'perl Makefile.PL'"
}

{
  make
  ok "`[ -d blib ]`" "The 'blib' dir exists after 'make'"
}

{
  make distdir
  dd=( Alt-Acme-Math-XS-EUMM-* )
  ok "`[ -e "$dd/MANIFEST" ]`" "$dd/MANIFEST exists"
  ok "`[ -e "$dd/inc/Acme/Math/XS/Inline.pm" ]`" \
    "$dd/inc/Acme/Math/XS/Inline.pm exists"
}

done_testing;
teardown
