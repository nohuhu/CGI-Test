package CGI::Test::Input::URL;
use strict;
####################################################################
# $Id: URL.pm 411 2011-09-26 11:19:30Z nohuhu@nohuhu.org $
# $Name: cgi-test_0-104_t1 $
####################################################################
#
#  Copyright (c) 2001, Raphael Manfredi
#
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
#
# POST input data to be encoded with "application/x-www-form-urlencoded".
#

require CGI::Test::Input;
use base qw(CGI::Test::Input);

use Log::Agent;

#
# ->new
#
# Creation routine
#
sub new
{
    my $this = bless {}, shift;
    $this->_init;
    return $this;
}

# DEPRECATED
sub make
{    #
    my $class = shift;
    return $class->new(@_);
}

#
# Defined interface
#

sub mime_type
{
    return "application/x-www-form-urlencoded";
}

#
# ->_build_data
#
# Rebuild data buffer from input fields.
#
sub _build_data
{
    my $this = shift;

    #
    # Note that file uploading fields get handled as any other field, meaning
    # only the file path will be transmitted.
    #

    my $data = '';

    # XXX field name encoding of special chars is the same as data?

    foreach my $tuple (@{$this->_fields()}, @{$this->_files()})
    {
        my ($name, $value) = @$tuple;
        $value =~ s/([^a-zA-Z0-9_. -])/uc sprintf("%%%02x",ord($1))/eg;
        $value =~ s/ /+/g;
        $name  =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
        $data .= '&' if length $data;
        $data .= $name . '=' . $value;
    }

    return $data;
}

1;

=head1 NAME

CGI::Test::Input::URL - POST input encoded as application/x-www-form-urlencoded

=head1 SYNOPSIS

 # Inherits from CGI::Test::Input
 require CGI::Test::Input::URL;

 my $input = CGI::Test::Input::URL->new();

=head1 DESCRIPTION

This class represents the input for HTTP POST requests, encoded
as C<application/x-www-form-urlencoded>.

Please see L<CGI::Test::Input> for interface details.

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

CGI::Test::Input(3).

=cut

