package CGI::Test::Form::Widget::Box::Radio;
use strict;
##################################################################
# $Id: Radio.pm 411 2011-09-26 11:19:30Z nohuhu@nohuhu.org $
# $Name: cgi-test_0-104_t1 $
##################################################################
#
#  Copyright (c) 2001, Raphael Manfredi
#
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#

#
# This class models a FORM radio button.
#

use CGI::Test::Form::Widget::Box;
use base qw(CGI::Test::Form::Widget::Box);

use Log::Agent;

#
# ->set_is_checked		-- redefined
#
# Change checked state.
#
# A radio button can only be "clicked on", i.e. it is not otherwise
# un-checkable.  Therefore, $checked must always be true.  Furthermore,
# all related radio buttons must be cleared.
#
sub set_is_checked
{
    my $this = shift;
    my ($checked) = @_;

    return if !$checked == !$this->is_checked();    # No change

    #
    # We're checking a radio button that was cleared previously.
    # All the other radio buttons in the group are going to be cleared.
    #

    $this->_frozen_set_is_checked($checked);
    foreach my $radio ($this->group_list)
    {
        next if $radio == $this;
        $radio->_frozen_set_is_checked(0);
    }

    return;
}

sub uncheck
{
    logcarp "ignoring uncheck on radio button";
}

sub uncheck_tagged
{
    logcarp "ignoring uncheck_tagged on radio button";
}

#
# Attribute access
#

sub gui_type
{
    return "radio button";
}

#
# Defined predicates
#

sub is_radio
{
    return 1;
}

1;

=head1 NAME

CGI::Test::Form::Widget::Box::Radio - A radio button widget

=head1 SYNOPSIS

 # Inherits from CGI::Test::Form::Widget::Box
 # $form is a CGI::Test::Form

 my @title = $form->radios_named("title");
 my ($mister) = grep { $_->value eq "Mr" } @title;
 $mister->check if defined $mister;

 my $title = $form->radio_by_name("title");
 $title->check_tagged("Mr");

=head1 DESCRIPTION

This class represents a radio button widget, which may be checked at
will by users.  All other radio buttons of the same group are automatically
unchecked.

If no radio button is checked initially, C<CGI::Test> arbitrarily chooses
the first one listed and warns you via C<logwarn>.

The interface is the same as the one described
in L<CGI::Test::Form::Widget::Box>.

Any attempt to C<uncheck> a radio button will be ignored, and a warning
emitted via C<logcarp>, to help you identify the caller.

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

CGI::Test::Form::Widget::Box(3), CGI::Test::Form::Widget::Box::Check(3),
Log::Agent(3).

=cut

