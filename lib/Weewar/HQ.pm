# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Weewar::HQ;
use strict;
use warnings;

use base 'Weewar::Base';

sub _ATTRIBUTES { }
sub _ELEMENTS { qw/inNeedOfAttention/ }
sub _LISTS {}

sub _get_xml {
    return Weewar->_request('headquarters'); # NOT!. hindquarters.
}

sub _root_tag { 'games' }

sub _TRANSFORMS {}

__PACKAGE__->mk_weewar_accessors;

1;
