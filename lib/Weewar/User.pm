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

   # then get their data
   my $points = $user->points;
   my @units = $user->favorite_units
   my @games = $user->games;
   # etc.
   
=head1 METHODS

=head2 name

Returns the user's username.

=head2 id

Returns the user's id.

=head2 points

=head2 rating

Returns the player's score, usually around 1500.

=head2 profile

Returns the URL of the user's profile page.

=head2 draws

Returns the number of times the user has ended a game with a draw.

=head2 victories

Returns the number of times the user has won.

=head2 losses

Returns the number of times the user has lost.

=head2 account_type

Returns the user's account type.

=head2 ready_to_play

Returns a boolean (undef or "true) indicating whether or not the
user is "ready to play".

=head2 games_running

Returns the number of games the user is currently playing.

=head2 last_login

Returns a DateTime object representing the last time the user logged in.

=head2 bases_captured

Returns the number of basses the user has captured.

=head2 credits_spent

Returns the number of credits the user has spent.

=head2 favoriteUnits

Returns a list of the user's favorite units.

=head2 preferred_players

Returns a list of C<Weewar::User> objects representing the user's
preferred players.

=head2 preferred_by

Returns a list of C<Weewar::User> objects representing players that
prefer this user.

=head2 games

Returns a list of C<Weewar::Game> objects representing games that the
user has played or is playing.

=head1 SEE ALSO

See L<Weewar> for the main docs.

