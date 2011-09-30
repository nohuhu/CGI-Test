package CGI::Test::Form::Widget::Button::Plain;
use strict;
##################################################################
# $Id: Plain.pm 411 2011-09-26 11:19:30Z nohuhu@nohuhu.org $
# $Name: cgi-test_0-104_t1 $
##################################################################
#
#  Copyright (c) 2001, Raphael Manfredi
#
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#

#
# This class models a FORM plain <BUTTON>.
#

require CGI::Test::Form::Widget::Button;
use base qw(CGI::Test::Form::Widget::Button);

use Log::Agent;

#
# Attribute access
#

sub gui_type
{
    return "plain button";
}

#
# Button predicates
#

sub is_plain
{
    return 1;
}

1;

=head1 NAME

CGI::Test::Form::Widget::Button::Plain - A button with client-side processing

=head1 SYNOPSIS

 # Inherits from CGI::Test::Form::Widget::Button

=head1 DESCRIPTION

This class models a plain button, which probably has some client-side
processing attached to it.  Unfortunately, C<CGI::Test> does not support
this, so there's not much you can do with this button, apart from making
sure it is present.

The interface is the same as the one described in
L<CGI::Test::Form::Widget::Button>.

=head1 WEBSITE

You can find information about CGI::Test and other related modules at:

   http://cgi-test.sourceforge.net

=head1 PUBLIC CVS SERVER

CGI::Test now has a publicly accessible CVS server provided by
SourceForge (www.sourceforge.net).  You can access it by going to:

    http://sourceforge.net/cvs/?group_id=89570

=head1 AUTHORS

The original author is Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>. 

Send bug reports, hints, tips, suggestions to Steven Hilton at <mshiltonj@mshiltonj.com>

=head1 SEE ALSO

CGI::Test::Form::Widget::Button(3).

=cut

