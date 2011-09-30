package CGI::Test::Form::Widget::Box::Check;
use strict;
##################################################################
# $Id: Check.pm 411 2011-09-26 11:19:30Z nohuhu@nohuhu.org $
# $Name: cgi-test_0-104_t1 $
##################################################################
#
#  Copyright (c) 2001, Raphael Manfredi
#
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#

#
# This class models a FORM checkbox button.
#

use CGI::Test::Form::Widget::Box;
use base qw(CGI::Test::Form::Widget::Box);

use Log::Agent;

#
# Attribute access
#

sub gui_type
{
    return "checkbox";
}

#
# Defined predicates
#

sub is_radio
{
    return 0;
}

1;

=head1 NAME

CGI::Test::Form::Widget::Box::Check - A checkbox widget

=head1 SYNOPSIS

 # Inherits from CGI::Test::Form::Widget::Box
 # $form is a CGI::Test::Form

 use Log::Agent;    # logdie below

 my ($agree, $ads) = $form->checkbox_by_name(qw(i_agree ads));

 logdie "expected a standalone checkbox" unless $agree->is_standalone;
 $agree->check;
 $ads->uncheck_tagged("spam OK");

=head1 DESCRIPTION

This class represents a checkbox widget, which may be checked or unchecked
at will by users.

The interface is the same as the one described
in L<CGI::Test::Form::Widget::Box>.

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

CGI::Test::Form::Widget::Box(3), CGI::Test::Form::Widget::Box::Radio(3).

=cut

