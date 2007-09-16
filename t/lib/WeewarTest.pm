# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

package t::lib::WeewarTest;
use strict;
use warnings;

use Weewar;
my %TEST_DATA;
my $key = 'OOPS';
for my $line (<DATA>){
    if ($line =~ /^__(.+)__$/m) {
        $key = $1;
        next;
    }
    $TEST_DATA{$key} .= $line;
}

# override the LWP part of Weewar; return the test XML
{ no warnings 'redefine';
  sub Weewar::_get {
      my $self = shift;
      my $path = shift;
      return qq{<?xml version="1.0" ?>\n$TEST_DATA{$path}\n};
  }
}

1;

__DATA__
__users/all__
<users>
 <user name="jrockway" id="1" rating="1337" />
 <user name="test" id="2" rating="1238" />
</users>
__user/jrockway__
<user name="jrockway" id="18407">
<points>1502</points>
<profile>http://weewar.com/user/jrockway</profile>
<draws>0</draws>
<victories>1</victories>
<losses>2</losses>
<accountType>Basic</accountType>
<readyToPlay>false</readyToPlay>
<gamesRunning>2</gamesRunning>
<lastLogin>2007-09-16 07:28:35.0</lastLogin>
<basesCaptured>12</basesCaptured>
<creditsSpent>38225</creditsSpent>
<favoriteUnits>
<unit code="lightInfantry"/>
<unit code="lighttank"/>
<unit code="heavyInfantry"/>
</favoriteUnits>
<preferredPlayers>
<player name="marcusramberg" id="11143"/>
<player name="chumphries" id="16392"/>
<player name="jshirley" id="18406"/>
<player name="nick.rockway" id="18779"/>
</preferredPlayers>
<preferredBy>
<player name="jshirley" id="18406"/>
<player name="chumphries" id="16392"/>
</preferredBy>
<games>
<game>25828</game>
<game>27008</game>
<game>27054</game>
<game>27055</game>
</games>
</user>
