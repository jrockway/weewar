# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package Weewar::HQ;
use strict;
use warnings;

use Carp;

sub new {
    my ($class, $args) = @_;
    
    croak 'need hashref of args' unless ref $args eq 'HASH';
    croak 'need key'             unless $args->{key};
    croak 'need user'            unless $args->{user};

    my $self = bless $args => $class;

    # get XML
    my $xml = Weewar->_request('headquarters', { username => $args->{user}, 
                                                 password => $args->{key},
                                               });
    my @game_nodes = $xml->findnodes('/games/game');

    my @needs_attention;
    my @games;
    for my $game_node (@game_nodes){
        my $id = [$game_node->getElementsByTagName('id')]->[0]->textContent;
        my $needs_attention = eval { 
            $game_node->getAttributeNode('inNeedOfAttention')->textContent
        };

        my $game = Weewar::Game->new({ id => $id });
        push @games, $game;
        push @needs_attention, $game 
          if $needs_attention && $needs_attention eq 'true';
    }

    $self->{games} = \@games;
    $self->{inNeedOfAttention} = \@needs_attention;
    
    return $self;
}

sub games { return @{$_[0]->{games}} }
sub in_need_of_attention { return @{$_[0]->{inNeedOfAttention}} }

1;
