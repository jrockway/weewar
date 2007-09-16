#!/usr/bin/env perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;

use t::lib::WeewarTest;
use Test::TableDriven (
  scalars => { in_need_of_attention  => 1,
             },
);

my $hq = Weewar->hq(jrockway => 'some made up API key what do i care');
sub scalars {
    my $method = shift;
    return $hq->$method;
}

runtests;
