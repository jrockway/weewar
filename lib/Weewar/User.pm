# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Weewar::User;
use strict;
use warnings;

use Carp;
require Weewar;
require Weewar::Game;
use DateTime;

# my own mini WSDL, i guess
my @ATTRIBUTES = qw/name id/;
my @ELEMENTS   = qw/points profile
                    draws victories losses
                    accountType readyToPlay gamesRunning lastLogin
                    basesCaptured creditsSpent/;
my %LISTS = ( favoriteUnits    => ['unit',   'Weewar::Unit' => 'code',      ],
              preferredPlayers => ['player', 'Weewar::User' => 'name',      ],
              preferredBy      => ['player', 'Weewar::User' => 'name',      ],
              games            => ['game',   'Weewar::Game' => ''    , 'id' ],
            );

use base 'Class::Accessor';
__PACKAGE__->mk_ro_accessors('rating',
    map { 
        my $a = $_; 
        $a =~ s/([a-z])([A-Z])/$1.'_'.(lc $2)/eg;
        $a; 
    } (@ATTRIBUTES, @ELEMENTS, keys %LISTS));

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
    for (@ATTRIBUTES){
        $self->{$_} = $user->getAttributeNode($_)->value;
    }

    # get stuff that's text in a unique element (<points>1502</points>)
    for (@ELEMENTS){
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
    
}

{ package Weewar::Unit;
  sub new { return $_[1]->{code} }
}

1;


__END__

=head1 NAME

Weewar::User - a user of weewar

=head1 SYNOPSIS

   # make a user
   my $user = WeeWar::User->new({ name => 'jrockway' });

   # then get her data
   my $points = $user->points;
   my @units = $user->favorite_units
   my @games = $user->games;
   
=head1 METHODS

=head2 name

=head2 id

=head2 points

=head2 rating


my @ELEMENTS   = qw/points profile
                    draws victories losses
                    accountType readyToPlay gamesRunning lastLogin
                    basesCaptured creditsSpent
=cut
