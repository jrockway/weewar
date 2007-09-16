package Weewar;
use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use XML::LibXML;

use Weewar::User;

our $VERSION = '0.01';

use Readonly;
Readonly my $server => $ENV{WEEWAR_SERVER} || 'weewar.com';
Readonly my $base   => $ENV{WEEWAR_BASE} || 'api1';

=head1 NAME

Weewar - interact with the C<weewar.com> API

=head1 SYNOPSIS

   use Weewar;

   # get all users
   my @users = Weewar->all_users;     # all active players on weewar

   # get a single user
   my $me = Weewar->user('jrockway'); # one user only (as a Weewar::User)
   my $me = Weewar::User->new({ name => 'jrockway }); # lazy-loaded

   # get a game
   my $game = Weewar->game('27056');  # get game (as a Weewar::Game)
   my $game = Weewar::Game->new({ id => '27056' });
   
   # access headquarters
   my $hq = Weewar->hq('jrockway' => $jrockways_api_key);
   my $hq = Weewar::HQ->new({ user => 'jrockway',
                              key  => $jrockways_api_key,
                            });

=head1 DESCRIPTION

This module lets you interact with the
(L<Weewar|http://weewar.com/?referrer=jrockway>) API.  See
L<Weewar::User>, L<Weewar::Game>, and L<Weewar::HQ> for details about
what data you can get from the API.

=head1 METHODS

Right now, everything is a class method since the weewar API is public
for everything except the HQ.  If this changes, then this API will
change a bit.

=cut

sub _get {
    my ($class, $path) = @_;
    
    my $ua = LWP::UserAgent->new;
    my $res = $ua->get("http://$server/$base/$path");
    
    croak 'request error: '. $res->status_line if !$res->is_success;
    return $res->decoded_content;
}

sub _request {
    my ($class, $path) = @_;
    my $content = $class->_get($path);
    my $parser = XML::LibXML->new;
    return $parser->parse_string($content);
}

=head all_users

Return a list of all active Weewar users as L<Weewar::User> objects.
The objects are loaded lazily, so this method only cause

sub all_users

=cut

sub all_users {
    my $class = shift;
    my $doc = $class->_request('users/all');
    my @raw_users = $doc->getElementsByTagName('user');
    
    my @users;
    foreach my $user (@raw_users){
        my $def;
        $def->{$_} = $user->getAttributeNode($_)->value for qw/name id rating/;
        $def->{points} = $def->{rating}; # API uses 2 names for the same thing
        push @users, Weewar::User->new($def);
    }
    return @users;
}

sub user {
    my $class     = shift;
    my $username  = shift;
    my $user = Weewar::User->new({ name => $username });
    $user->draws; # force the object to be populated
    return $user;
}

sub game {
    my $class   = shift;
    my $gameid  = shift;
    my $game    = Weewar::Game->new({ id => $gameid });
    $game->name; # force the object to be populated
    return $game;   
}

1;
