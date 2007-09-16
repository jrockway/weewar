# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Weewar::User;
use strict;
use warnings;

use Carp;
require Weewar;

# my own mini WSDL, i guess
my @ATTRIBUTES = qw/name id/;
my @ELEMENTS   = qw/points rating profile
                    draws victories losses
                    accountType readyToPlay gamesRunning lastLogin
                    basesCaptured creditsSpent/;
my %LISTS = ( favoriteUnits    => 'unit',
              preferredPlayers => ['player', { 'Weewar::User' => 'name' } ],
              preferredBy      => ['player', { 'Weewar::User' => 'name' } ],
              games            => ['game',   { 'Weewar::Game' => 'game' } ],
            );

use base 'Class::Accessor';
__PACKAGE__->mk_ro_accessors(@ATTRIBUTES, @ELEMENTS, keys %LISTS);


sub get {
    my ($self, $what) = @_;
    $what =~ s/_([a-z])/uc $1/ge; # perl_style to javaStyle

    # dumbness in their API
    return $self->{points} if($self->{rating} && $what eq 'points');
    return $self->{rating} if($self->{points} && $what eq 'rating');
    
    return $self->{$what} if $self->{$what};
    
    # data hasn't been loaded yet, so load it
    my $name = $self->{name};
    croak "This user ($self) has no name" unless $name;
    
    my $xml = Weewar->_request("user/$name");
    
    
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
