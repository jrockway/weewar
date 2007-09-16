# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Weewar::Base;
use strict;
use warnings;
use Carp;
use DateTime;

require Weewar;
require Weewar::User;
require Weewar::Game;

use base 'Class::Accessor';

sub get {
    my ($self, $what) = @_;
    $what =~ s/_([a-z])/uc $1/ge; # perl_style to javaStyle

    # dumbness in their API
    return $self->{rating} if($self->{rating} && $what eq 'points');
    return $self->{points} if($self->{points} && $what eq 'rating');
    
    if(exists $self->{$what}){
        my $retval = $self->{$what};
        return @$retval if(ref $retval && ref $retval eq 'ARRAY');
        return $retval;
    }

    
    # data hasn't been loaded yet, so load it
    my $name = $self->{name};
    croak "This user ($self) has no name" unless $name;
    
    my $xml  = Weewar->_request("user/$name");
    my $user = [$xml->getElementsByTagName('user')]->[0];

    # get stuff that's in the root tag (<user name="..." id="...">)
    for ($self->_ATTRIBUTES){
        $self->{$_} = $user->getAttributeNode($_)->value;
    }

    # get stuff that's text in a unique element (<points>1502</points>)
    for ($self->_ELEMENTS){
        eval {
            $self->{$_} = [$user->getElementsByTagName($_)]->[0]->textContent;
            $self->{$_} = undef if($self->{$_} eq 'false'); # make 'false' false
        };
        carp "We needed a $_ tag, but didn't see one" if $@;

        # turn date-like things into DateTime objects
        # XXX: weewar appears to be using an invalid pseudo iso8601 format
        # so we'll just parse it ourselves
        if($self->{$_} && $self->{$_} =~  
           /^(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d(?:[.]\d+)?)$/){
            $self->{$_} = DateTime->new( year => $1,
                                         month => $2,
                                         day => $3,
                                         hour => $4,
                                         minute => $5,
                                         second => $6,
                                       );
        }
    }

    # get stuff that's a list (<preferredPlayers><player ...>...</preferred>)
    my %LISTS = $self->_LISTS;
    for my $key (keys %LISTS){
        my ($name, $class, $attribute, $initname) = @{$LISTS{$key}};
        # name is the name of the element we're inspecting (preferredPlayers)
        # class is the class of the sub-elements (Weewar::User)
        # attribute is what we pass to class's constructor (undef = nodetext)
        # initname is the key that we pass to the constructor
        $initname ||= $attribute; # defaults to the attribute name
        
        my $handler = $attribute ? # if attribute is defined
          sub { $_[0]->getAttributeNode($attribute)->value }:# get the attribute
          sub { $_[0]->textContent }; # otherwise get the text content

        my @children = [$user->getElementsByTagName($key)]->[0]
                                    ->getElementsByTagName($name);
        $self->{$key} = [map {$class->new({$initname => $handler->($_)}) } 
                         @children];
        
    }

    return $self->{$what};
}

1;
