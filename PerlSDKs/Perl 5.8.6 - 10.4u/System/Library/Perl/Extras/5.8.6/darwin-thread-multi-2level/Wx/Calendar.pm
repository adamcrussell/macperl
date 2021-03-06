#############################################################################
## Name:        ext/calendar/Calendar.pm
## Purpose:     Wx::CalendarCtrl
## Author:      Mattia Barbon
## Modified by:
## Created:     05/10/2002
## RCS-ID:      $Id: Calendar.pm,v 1.4 2004/10/19 20:28:07 mbarbon Exp $
## Copyright:   (c) 2002 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::Calendar;

use Wx::DateTime;
use strict;

use vars qw($VERSION);

$VERSION = '0.01';

Wx::load_dll( 'adv' );
Wx::wx_boot( 'Wx::Calendar', $VERSION );

#
# properly setup inheritance tree
#

no strict;

package Wx::CalendarCtrl;  @ISA = 'Wx::Control';
package Wx::CalendarEvent; @ISA = 'Wx::CommandEvent';

package Wx::Event;

use strict;

# !parser: sub { $_[0] =~ m/sub (EVT_\w+)/ }
# !package: Wx::Event

sub EVT_CALENDAR($$$) { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_CALENDAR_DOUBLECLICKED, $_[2] ) }
sub EVT_CALENDAR_SEL_CHANGED($$$) { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_CALENDAR_SEL_CHANGED, $_[2] ) }
sub EVT_CALENDAR_DAY($$$) { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_CALENDAR_DAY_CHANGED, $_[2] ) }
sub EVT_CALENDAR_MONTH($$$) { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_CALENDAR_MONTH_CHANGED, $_[2] ) }
sub EVT_CALENDAR_YEAR($$$) { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_CALENDAR_YEAR_CHANGED, $_[2] ) }
sub EVT_CALENDAR_WEEKDAY_CLICKED($$$) { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_CALENDAR_WEEKDAY_CLICKED, $_[2] ) }

1;

# local variables:
# mode: cperl
# end:
