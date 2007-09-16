# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Weewar::Game;
use strict;
use warnings;

use Carp;
require Weewar;
use base 'Weewar::Base';

sub _ATTRIBUTES { qw/id/ }
sub _ELEMENTS { 
    qw/name round state pendingInvites pace type url
       map mapUrl creditsPerBase initialCredits playingSince
      /;
}
sub _LISTS {
    ( players => ['player', 'Weewar::User' => '', 'name'] )
}

sub _TRANSFORMS {
    ( playingSince   => __PACKAGE__->_TRANSFORM_DATE(),
      pendingInvites => __PACKAGE__->_TRANSFORM_BOOLEAN(),
    )
}

sub _get_xml {
    my $self = shift;
    my $id = $self->{id};
    croak "This game ($self) has no id" unless $id;
    return Weewar->_request("game/$id");
}

sub _root_tag { 'game' }

__PACKAGE__->mk_weewar_accessors;

1;
