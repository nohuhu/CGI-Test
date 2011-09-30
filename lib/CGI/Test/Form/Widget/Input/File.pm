package CGI::Test::Form::Widget::Input::File;
use strict;
##################################################################
# $Id: File.pm 411 2011-09-26 11:19:30Z nohuhu@nohuhu.org $
# $Name: cgi-test_0-104_t1 $
##################################################################
#
#  Copyright (c) 2001, Raphael Manfredi
#
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#

#
# This class models a FORM file input for uploading.
#
# It inherits from Text_Field, since the only distinction between a text field
# and a file upload field is the presence of the "browse" button displayed by
# the browser to select a file.
#

use CGI::Test::Form::Widget::Input::Text_Field;
use base qw(CGI::Test::Form::Widget::Input::Text_Field);

use Log::Agent;

#
# Attribute access
#

sub gui_type
{
    return "file upload";
}

#
# Redefined predicates
#

sub is_field
{
    return 0;
}    # not a pure text field

sub is_file
{
    return 1;
}

1;

=head1 NAME

CGI::Test::Form::Widget::Input::File - A file upload control

=head1 SYNOPSIS

 # Inherits from CGI::Test::Form::Widget::Input
 # $form is a CGI::Test::Form

 my $upload = $form->input_by_name("upload");
 $upload->replace("/tmp/file");

=head1 DESCRIPTION

This class models a file upload control, which is a text field to enter
a file name, with a little "browse" control button nearby that allows
the user to select a file via a GUI...

The interface is the same as the one described in
L<CGI::Test::Form::Widget::Input::Text_Field>.

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

CGI::Test::Form::Widget::Input(3).

=cut

