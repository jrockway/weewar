# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Weewar::Base;
use strict;
use warnings;
use Carp;
use DateTime::Format::RSS;

require Weewar;
require Weewar::User;
require Weewar::Game;

use base 'Class::Accessor';

sub mk_weewar_accessors {
    my $class = shift;
    $class->mk_ro_accessors
      ( map { 
          my $a = $_; 
          $a =~ s/([a-z])([A-Z])/$1.'_'.(lc $2)/eg;
          $a; 
      } 
        ($class->_ATTRIBUTES, $class->_ELEMENTS, keys %{{$class->_LISTS()}}));
}

sub get {
    my ($self, $what) = @_;
    $what =~ s/_([a-z])/uc $1/ge; # perl_style to javaStyle
    
    if(exists $self->{$what}){
        my $retval = $self->{$what};
        return @$retval if(ref $retval && ref $retval eq 'ARRAY');
        return $retval;
    }
    
    # data hasn't been loaded yet, so load it
    my $xml  = $self->_get_xml;
    my $root_tag = [$xml->getElementsByTagName($self->_root_tag)]->[0];



    # get stuff that's in the root tag (<user name="..." id="...">)
    $self->_set_element($_ => $root_tag->getAttributeNode($_)->value) 
      for ($self->_ATTRIBUTES);
    
    # get stuff that's text in a unique element (<points>1502</points>)
    for ($self->_ELEMENTS){
        eval {
            $self->_set_element($_ => 
                                    [$root_tag->getElementsByTagName($_)]
                                                          ->[0]->textContent,

                               );
        };
        carp "Expected a $_ tag" if $@;          
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

        my @children = [$root_tag->getElementsByTagName($key)]->[0]
                                    ->getElementsByTagName($name);
        $self->_set_element($key => 
                            [ map {$class->new({$initname => $handler->($_)}) } 
                                @children
                            ]);
    }
    
    return $self->{$what};
}

sub _set_element {
    my $self  = shift;
    my $what  = shift;
    my $value = shift; 

    $self->{$what} = $value;
    
    my %TRANSFORM = $self->_TRANSFORMS;
    my $transform = $TRANSFORM{$what};
    if($transform){
        $self->{$what} = $transform->($self->{$what});
    }

    return $self->{$what};
}

sub _TRANSFORM_BOOLEAN {
    my $self = shift;
    return sub { undef if($_[0] eq 'false') };
}

sub _TRANSFORM_DATE {
    my $self = shift;
    return sub { DateTime::Format::RSS->parse_datetime($_[0]) };
}

1;
