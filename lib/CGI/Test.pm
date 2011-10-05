package CGI::Test;
use strict;
use warnings;
################################################################
# $Id: Test.pm 412 2011-09-26 13:15:02Z nohuhu@nohuhu.org $
# $Name: cgi-test_0-104_t1 $
#################################################################
#  Copyright (c) 2001, Raphael Manfredi
#
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#

use Carp;
use Getargs::Long;
use Log::Agent;
use HTTP::Status;
use URI;
use File::Temp qw(mkstemp);
use File::Spec;
use File::Basename;

require Exporter;
use vars qw($VERSION @ISA @EXPORT);

$VERSION = '0.2.1';
@ISA     = qw(Exporter);
@EXPORT  = qw(ok);

#############################################################################
#
# ->new
#
# Creation routine
#
# Arguments:
#    base_url		URL to cgi-bin, e.g. http://foo:18/cgi-bin
#    cgi_dir		physical location of base_url
#    tmp_dir		(optional) temporary directory to use
#    cgi_env		(optional) default CGI environment
#    doc_dir		(optional) physical location of docs, for path translation
#
#############################################################################
sub new
{
    my $this = bless {}, shift;
    my ($ubase, $dir, $doc, $tmp, $env) =
      xgetargs(@_,
               -base_url => 's',
               -cgi_dir  => 's',
               -doc_dir  => [ 's', "/var/www" ],
               -tmp_dir  => [ 's', $ENV{TMPDIR} || "/tmp" ],
               -cgi_env  => [ 'HASH' ],
               );

    my $uri = URI->new($ubase);
    croak "-base_url $ubase is not within the http scheme"
        unless $uri->scheme eq 'http';

    my ($server, $path) = $this->split_uri($uri);
    $this->{host_port} = $server;
    $this->{base_path} = $path;
    $this->{cgi_dir}   = $dir;
    $this->{tmp_dir}   = $tmp;
    $env = {} unless defined $env;
    $this->{cgi_env} = $env;
    $this->{doc_dir} = $doc;

    #
    # The following default settings will apply unless alternatives given
    # by user via the -cgi_env parameter.
    #

    my %dflt = (AUTH_TYPE           => "Basic",
                GATEWAY_INTERFACE   => "CGI/1.1",
                HTTP_ACCEPT         => "*/*",
                HTTP_CONNECTION     => "Close",
                HTTP_USER_AGENT     => "CGI::Test",
                HTTP_ACCEPT_CHARSET => "iso-8859-1",
                REMOTE_HOST         => "localhost",
                REMOTE_ADDR         => "127.0.0.1",
                SERVER_NAME         => $uri->host,
                SERVER_PORT         => $uri->port,
                SERVER_PROTOCOL     => "HTTP/1.1",
                SERVER_SOFTWARE     => "CGI::Test",
                );

    while (my ($key, $value) = each %dflt)
    {
        $env->{$key} = $value unless exists $env->{$key};
    }

    #
    # Object types to create depending on returned content-type.
    # If not listed here, "Other" is assummed.
    #

    $this->{_obj_type} = {'text/plain' => 'Text',
                          'text/html'  => 'HTML',
                          };

    return $this;
}

######################################################################
#
######################################################################
sub make
{    #
    my $class = shift;
    return $class->new(@_);
}

#
# Attribute access
#

######################################################################
sub host_port
{
    my $this = shift;
    return $this->{host_port};
}

######################################################################
sub base_path
{
    my $this = shift;
    return $this->{base_path};
}

######################################################################
sub cgi_dir
{
    my $this = shift;
    return $this->{cgi_dir};
}

######################################################################
sub doc_dir
{
    my $this = shift;
    return $this->{doc_dir};
}

######################################################################
sub tmp_dir
{
    my $this = shift;
    return $this->{tmp_dir};
}

######################################################################
sub cgi_env
{
    my $this = shift;
    return $this->{cgi_env};
}

######################################################################
sub _obj_type
{
    my $this = shift;
    return $this->{_obj_type};
}

######################################################################
sub http_headers {
    my ($self) = @_;

    return $self->{http_headers};
}

######################################################################
#
# ->_dpath
#
# Returns direct path to final component of argument,
# i.e. the original path with . and .. items removed.
#
# Will probably only work on Unix (possibly Win32 if paths given with "/").
#
######################################################################
sub _dpath
{
    my $this  = shift;
    my ($dir) = @_;
    my $root  = ($dir =~ s|^/||) ? "/" : "";
    my @cur;
    foreach my $item (split(m|/|, $dir))
    {
        next if $item eq '.';
        if ($item eq '..')
        {
            pop(@cur);
        }
        else
        {
            push(@cur, $item);
        }
    }
    my $path = $root . join('/', @cur);
    $path =~ tr|/||s;
    return $path;
}

######################################################################
#
# ->split_uri
#
# Split down URI into (server, path, query) components.
#
######################################################################
sub split_uri
{
    my $this = shift;
    my ($uri) = @_;
    return ($uri->host_port, $this->_dpath($uri->path), $uri->query);
}

######################################################################
#
# ->GET
#
# Perform an HTTP GET request on a CGI URI by running the script directly.
# Returns a CGI::Test::Page object representing the returned page, or the
# error.
#
# Optional $user provides the name of the "authenticated" user running
# this script.
#
######################################################################
sub GET
{
    my $this = shift;
    my ($uri, $user) = @_;

    return $this->_cgi_request($uri, $user, undef);
}

######################################################################
#
# ->POST
#
# Perform an HTTP POST request on a CGI URI by running the script directly.
# Returns a CGI::Test::Page object representing the returned page, or the
# error.
#
# Data to send to the script are held in $input, a CGI::Test::Input object.
#
# Optional $user provides the name of the "authenticated" user running
# this script.
#
######################################################################
sub POST
{
    my $this = shift;
    my ($uri, $input, $user) = @_;

    return $this->_cgi_request($uri, $user, $input);
}

######################################################################
#
# ->_cgi_request
#
# Common routine to handle GET and POST.
#
######################################################################
sub _cgi_request
{
    my $this = shift;
    my ($uri, $user, $input) = @_;    # $input defined for POST

    my $u = URI->new($uri);
    croak "URI $uri is not within the http scheme"
        unless $u->scheme eq 'http';

    require CGI::Test::Page::Error;
    my $error = "CGI::Test::Page::Error";

    my ($userver, $upath, $uquery) = $this->split_uri($u);
    my $server    = $this->host_port;
    my $base_path = $this->base_path . "/";

    croak "URI $uri is not located on server $server"
        unless $userver eq $server;

    croak "URI $uri is not located under the $base_path directory"
        unless substr($upath, 0, length $base_path) eq $base_path;

    substr($upath, 0, length $base_path) = '';

    logdbg 'info', "uri $uri -> script+path $upath";

    #
    # We have script + path_info in the $upath variable.  To determine where
    # the path_info starts, we have to walk through the components and
    # compare, at each step, the current walk-through path with one on the
    # filesystem under cgi_dir.
    #

    my $cgi_dir = $this->cgi_dir;
    my @components = split(m|/|, $upath);
    my @script;

    while (@components)
    {
        my $item = shift @components;
        if (-e File::Spec->catfile($cgi_dir, @script, $item))
        {
            push(@script, $item);
        }
        else
        {
            unshift @components, $item;
            last;
        }
    }

    my $script      = File::Spec->catfile($cgi_dir, @script);        # Real
    my $script_name = $base_path . join("/",        @script);        # Virtual
    my $path        = "/" . join("/",               @components);    # Virtual

    logdbg 'info', "script=$script, path=$path";

    return $error->new(RC_NOT_FOUND,    $this) unless -f $script;
    return $error->new(RC_UNAUTHORIZED, $this) unless -x $script;

    #
    # Prepare input for POST requests.
    #

    my @post = ();
    local $SIG{PIPE} = 'IGNORE';
    local (*PREAD, *PWRITE);
    if (defined $input)
    {
        unless (pipe(PREAD, PWRITE))
        {
            logerr "can't open pipe: $!";
            return $error->new(RC_INTERNAL_SERVER_ERROR, $this);
        }

        @post = (-in    => \*PREAD,
                 -input => $input,);
    }

    #
    # Prepare temporary file for storing output, which we'll parse once
    # the script is done.
    #

    my ($fh, $fname) =
      mkstemp(File::Spec->catfile($this->tmp_dir, "cgi_out.XXXXXX"));

    select((select(STDOUT), $| = 1)[ 0 ]);
    print STDOUT "";    # Flush STDOUT before forking

    #
    # Fork...
    #

    my $pid = fork;
    logdie "can't fork: $!" unless defined $pid;

    #
    # Child will run the CGI program with no input if it's a GET and
    # output stored to $fh.  When issuing a POST, data will be provided
    # by the parent through a pipe.
    #

    if ($pid == 0)
    {
        close PWRITE if defined $input;    # Writing side of the pipe
        $this->_run_cgi(
            -script_file => $script,         # Real path
            -script_name => $script_name,    # Virtual path, given in URI
            -user        => $user,
            -out         => $fh,
            -uri         => $u,
            -path_info   => $path,
            @post,                           # Additional params for POST
            );
        logconfess "not reachable!";
    }

    #
    # Parent process
    #

    close $fh;
    if (defined $input)
    {                                        # Send POST input data
        close PREAD;
        syswrite PWRITE, $input->data, $input->length;
        close PWRITE or logwarn "failure while closing pipe: $!";
    }

    my $child = waitpid $pid, 0;

    if ($pid != $child)
    {
        logerr "waitpid returned with pid=$child, but expected pid=$pid";
        kill 'TERM', $pid or logwarn "can't SIGTERM pid $pid: $!";
        unlink $fname or logwarn "can't unlink $fname: $!";
        return $error->new(RC_NO_CONTENT, $this);
    }

    #
    # Get header within generated response, and determine Content-Type.
    #

    my $header = $this->_parse_header($fname);
    unless (scalar keys %$header)
    {
        logerr "script $script_name generated no valid headers";
        unlink $fname or logwarn "can't unlink $fname: $!";
        return $error->new(RC_INTERNAL_SERVER_ERROR, $this);
    }

    #
    # Store headers for later retrieval
    #

    $this->{http_headers} = $header;

    #
    # Create proper page object, which will parse the results file as needed.
    #

    my $type      = $header->{'Content-Type'};
    my $base_type = lc($type);
    $base_type =~ s/;.*//;    # Strip type parameters
    my $objtype = $this->_obj_type->{$base_type} || "Other";
    $objtype = "CGI::Test::Page::$objtype";

    eval "require $objtype";
    logdie "can't load module $objtype: $@" if chop $@;

    my $page = $objtype->new(
                        -server       => $this,
                        -file         => $fname,
                        -content_type => $type,    # raw type, with parameters
                        -user         => $user,
                        -uri          => $u,
                        );

    unlink $fname or logwarn "can't unlink $fname: $!";

    return $page;
}

######################################################################
#
# ->_run_cgi
#
# Run the specified script within a CGI environment.
#
# The -user is the name of the authenticated user running this script.
#
# The -in and -out parameters are file handles where STDIN and STDOUT
# need to be connected to.  If $in is undefined, STDIN is connected
# to /dev/null.
#
# Returns nothing.
#
######################################################################
sub _run_cgi
{
    my $this = shift;
    my ($script, $name, $user, $in, $out, $u, $path, $input) =
      cxgetargs(@_,
                -script_file => 's',
                -script_name => 's',
                -user        => [ undef ],
                -in          => [ undef ],
                -out         => undef,
                -uri         => 'URI',
                -path_info   => 's',
                -input       => [ 'CGI::Test::Input' ],
                );

    #
    # Connect file descriptors.
    #

    if (defined $in)
    {
        open(STDIN, '<&=' . fileno($in)) || logdie "can't redirect STDIN: $!";
    }
    else
    {
        my $devnull = File::Spec->devnull;
        open(STDIN, $devnull) || logdie "can't open $devnull: $!";
    }
    open(STDOUT, '>&=' . fileno($out)) || logdie "can't redirect STDOUT: $!";

    #
    # Setup default CGI environment.
    #

    while (my ($key, $value) = each %{$this->cgi_env})
    {
        $ENV{$key} = $value;
    }

    #
    # Where there is a script input, setup CONTENT_* variables.
    # If there's no input, delete CONTENT_* variables.
    #

    if (defined $in)
    {
        $ENV{CONTENT_TYPE}   = $input->mime_type;
        $ENV{CONTENT_LENGTH} = $input->length;
    }
    else
    {
        delete $ENV{CONTENT_TYPE};
        delete $ENV{CONTENT_LENGTH};
    }

    #
    # Supersede whatever they may have set for the following variables,
    # which are very request-specific:
    #

    $ENV{REQUEST_METHOD}  = defined $in ? "POST" : "GET";
    $ENV{PATH_INFO}       = $path;
    $ENV{SCRIPT_NAME}     = $name;
    $ENV{SCRIPT_FILENAME} = $script;
    $ENV{HTTP_HOST}       = $u->host_port;

    if (length $path)
    {
        $ENV{PATH_TRANSLATED} = $this->doc_dir . $path;
    }
    else
    {
        delete $ENV{PATH_TRANSLATED};
    }

    if (defined $user)
    {
        $ENV{REMOTE_USER} = $user;
    }
    else
    {
        delete $ENV{REMOTE_USER};
        delete $ENV{AUTH_TYPE};
    }

    if (defined $u->query)
    {
        $ENV{QUERY_STRING} = $u->query;
    }
    else
    {
        delete $ENV{QUERY_STRING};
    }

    #
    # Make sure the script sees the same @INC as we do currently.
    # This is very important when running a regression test suite, to
    # make sure any CGI script using the module we're testing will see
    # the files from the build directory.
    #
    # Since we're about to chdir() to the cgi-bin directory, we must anchor
    # any relative path to the current working directory.
    #

    use Cwd qw(abs_path);

    $ENV{PERL5LIB} = join(':', map {-e $_ ? abs_path($_) : $_} @INC);

    #
    # Now run the script, changing the current directory to the location
    # of the script, as a web server would.
    #

    my $directory = dirname($script);
    my $basename  = basename($script);

    chdir $directory or logdie "can't cd to $directory: $!";

    {exec "./$basename"}
    logdie "could not exec $script: $!";
    return;
}

######################################################################
#
# ->_parse_header
#
# Look for a set of leading HTTP headers in the file, and insert them
# into a hash table (we don't expect duplicates).
#
# Returns ref to hash containing the headers.
#
######################################################################
sub _parse_header
{
    my $this = shift;
    my ($file) = @_;
    my %header;
    local *FILE;
    open(FILE, $file) || logerr "can't open $file: $!";
    local $_;
    my $field;

    while (<FILE>)
    {
        last if /^\015?\012$/ || /^\015\012$/;
        s/\015?\012$//;
        if (s/^\s+/ /)
        {
            last if $field eq '';    # Cannot be a header
            $header{$field} .= $_ if $field ne '';
        }
        elsif (($field, my $value) = /^([\w-]+)\s*:\s*(.*)/)
        {
            $field =~ s/(\w+)/\u\L$1/g;    # Normalize spelling
            if (exists $header{$field})
            {
                logwarn "duplicate $field header in $file";
                $header{$field} .= " ";
            }
            $header{$field} .= $value;
        }
        else
        {
            logwarn "mangled header in $file";
            %header = ();                  # Discard what we read sofar
            last;
        }
    }
    close FILE;
    return \%header;
}

######################################################################
#
# ok
#
# Useful to print test result when using Test::Harness.
#
######################################################################
sub ok
{
    my ($num, $ok, $comment) = @_;
    print "not " unless $ok;
    print "ok $num";
    print " # $comment" if defined $comment;
    print "\n";
}

1;

=head1 NAME

CGI::Test - CGI regression test framework

=head1 SYNOPSIS

 # In some t/script.t regression test, for instance
 use CGI::Test;                 # exports ok()

 my $ct = CGI::Test->new(
    -base_url   => "http://some.server:1234/cgi-bin",
    -cgi_dir    => "/path/to/cgi-bin",
 );

 my $page = $ct->GET("http://some.server:1234/cgi-bin/script?arg=1");
 ok 1, $page->content_type =~ m|text/html\b|;

 my $form = $page->forms->[0];
 ok 2, $form->action eq "/cgi-bin/some_target";

 my $menu = $form->menu_by_name("months");
 ok 3, $menu->is_selected("January");
 ok 4, !$menu->is_selected("March");
 ok 5, $menu->multiple;

 my $send = $form->submit_by_name("send_form");
 ok 6, defined $send;

 #
 # Now interact with the CGI
 #

 $menu->select("March");        # "click" on the March label
 my $answer = $send->press;     # "click" on the send button
 ok 7, $answer->is_ok;          # and make sure we don't get an HTTP error

=head1 DESCRIPTION

The C<CGI::Test> module provides a CGI regression test framework which
allows you to run your CGI programs offline, i.e. outside a web server,
and interact with them programmatically, without the need to type data
and click from a web browser.

If you're using the C<CGI> module, you may be familiar with its offline
testing mode.  However, this mode is appropriate for simple things, and
there is no support for conducting a full session with a stateful script.
C<CGI::Test> fills this gap by providing the necessary infrastructure to
run CGI scripts, then parse the output to construct objects that can be
queried, and on which you can interact to "play" with the script's control
widgets, finally submitting data back.  And so on...

Note that the CGI scripts you can test with C<CGI::Test> need not be
implemented in Perl at all.  As far as this framework is concerned, CGI
scripts are executables that are run on a CGI-like environment and which
produce an output.

To use the C<CGI::Test> framework, you need to configure a C<CGI::Test>
object to act like a web server, by providing the URL base where
CGI scripts lie on this pseudo-server, and which physical directory
corresponds to that URL base.

From then on, you may issue GET and POST requests giving an URL, and
the pseudo-server returns a C<CGI::Test::Page> object representing the
outcome of the request.  This page may be an error, plain text, some
binary data, or an HTML page (see L<CGI::Test::Page> for details).

The latter (an HTML page) can contain one or more CGI forms (identified
by C<E<lt>FORME<gt>> tags), which are described by instances of
C<CGI::Test::Form> objects (see L<CGI::Test::Form> for details).

Forms can be queried to see whether they contain a particular type
of widget (menu, text area, button, etc...), of a particular name
(that's the CGI parameter name).  Once found, one may interact with
a widget as the user would from a browser.  Widgets are described by
polymorphic objects which conform to the C<CGI::Test::Form::Widget> type.
The specific interaction that is offered depends on the dynamic type of
the object (see L<CGI::Test::Form::Widget> for details).

An interaction with a form ends by a submission of the form data to the
server, and getting a reply back.  This is done by pressing a submit button,
and the press() routine returns a new page.  Naturally, no server is
contacted at all within the C<CGI::Test> framework, and the CGI script is
ran through a proper call to one of the GET/POST method on the
C<CGI::Test> object.

Finally, since C<CGI::Test> is meant to be used from regression test
scripts, it exports a single ok() routine which merely prints the messages
expected by C<Test::Harness>.  This is the only functional routine in this
module, all other accesses being made through a C<CGI::Test> object.

=head1 INTERFACE

=head2 Procedural Interface

There is only one such routine:

=over 4

=item C<ok> I<num>, I<boolean> [, I<comment>]

Prints the I<ok> or I<not ok> message for C<Test::Harness> depending
on whether I<boolean> is respectively I<true> or I<false>.  An optional
I<comment> string may be supplied as well and will be printed after a
'#' sign:

    ok 1, 2+2 == 4, "trivial arithmetic";

will print:

    ok 1 # trivial arithmetic

since the test trivially succeeds.

=back

=head2 Creation Interface

The creation routine C<new()> takes the following mandatory parameters:

=over 4

=item C<-base_url> => I<URL of the cgi-bin directory>

Defines the URL domain which is handled by C<CGI::Test>.
This is the URL of the C<cgi-bin> directory.

Note that there is no need to have something actually running on the
specified host or port, and the server name can be any host name,
whether it exists or not.  For instance, if you say:

    -base_url => "http://foo.example.com:70/cgi-bin"

you simply declare that the C<CGI::Test> object will know how to handle
a GET request for, say:

    http://foo.example.com:70/cgi-bin/script

and it will do so I<internally>, without contacting C<foo.example.com>
on port 70...

=item C<-cgi_dir> => I<path to the cgi-bin directoru>

Defines the physical path corresponding to the C<cgi-bin> directory defined
by the C<-base_url> parameter.

For instance, given the settings:

    -base_url => "http://foo.example.com:70/cgi-bin",
    -cgi_dir  => "/home/ram/cgi/test"

then requesting

    http://foo.example.com:70/cgi-bin/script

will actually run

    /home/ram/cgi/test/script

Those things are really easier to understand via examples than via
formal descriptions, aren't they?

=back

The following optional arguments may also be provided:

=over 4

=item C<-cgi_env> => I<HASH ref>

Defines additional environment variables that must be set, or changes
hardwirted defaults.  Some variables like C<CONTENT_TYPE> really depend
on the request and will be dynamically computed by C<CGI::Test>.

For instance:

    -cgi_env => {
        HTTP_USER_AGENT     => "Mozilla/4.76",
        AUTH_TYPE           => "Digest",
    }

See L<CGI ENVIRONMENT VARIABLES> for more details on which environment
variables are defined, and which may be superseded.

=item C<-doc_dir> => I<path to document tree>

This defines the root directory of the HTTP server, for path translation.
It defaults to C</var/www>.

B<NOTE>: C<CGI::Test> only serves CGI scripts for now, so this setting
is not terribly useful, unless you care about C<PATH_TRANSLATED>.

=item C<-tmp_dir> => I<path to temporary directory>

The temporary directory to use for internal files created while processing
requests.  Defaults to the value of the environment variable C<TMPDIR>,
or C</tmp> if it is not set.

=back

=head2 Object Interface

The following methods, listed in alphabetical order, are available:

=over 4

=item C<GET> I<url_string> [, I<auth_user>]

Issues an HTTP GET request of the specified URL, given as the string
I<url_string>.  It must be in the http scheme, and must lie within the
configured CGI space (i.e. under the base URL given at creation time
via C<-base_url>).

Optionally, you may specify the name of an authenticated user as the
I<auth_user> string. C<CGI::Test> will simply setup the CGI environment
variable C<REMOTE_USER> accordingly.  Since we're in a testing framework,
you can pretend to be anyone you like.  See L<CGI ENVIRONMENT VARIABLES>
for more information on environment variables, and in particular
C<AUTH_TYPE>.

C<GET> returns a C<CGI::Test::Page> polymorphic object, i.e. an object whose
dynamic type is an heir of C<CGI::Test::Page>.  See L<CGI::Test::Page> for
more information on this class hierarchy.

=item C<POST> I<url_string>, I<input_data> [, I<auth_user>]

Issues an HTTP POST request of the specified URL.  See C<GET> above for
a discussion on I<url_string> and I<auth_user>, which applies to C<POST>
as well.

The I<input_data> parameter must be a C<CGI::Test::Input> object.
It specifies the CGI parameters to be sent to the script.  Users normally
don't issue POST requests manually: they are the result of submits on
forms, which are obtained via an initial GET.  Nonetheless, you can
create your own input easily and issue a "faked" POST request, to see
how your script might react to inconsistent (and probably malicious)
input for instance.  See L<CGI::Test::Input> to learn how to construct
suitable input.

C<POST> returns a C<CGI::Test::Page> polymorphic object, like C<GET> does.

=item C<base_path>

The base path in the URL space of the base URL configured at creation time.
It's the URL with the scheme, host and port information removed.

=item C<cgi_dir>

The configured CGI root directory where scripts to be run are held.

=item C<doc_dir>

The configured document root directory.

=item C<host_port>

The host and port of the base URL you configured at creation time.

=item C<split_uri> I<URI>

Splits an URI object into server (host and port), path and query components.
The path is simplified using UNIX semantics, i.e. C</./> is ignored and
stripped, and C</../> is resolved by forgetting the path component that
immediately precedes it (no attempt is made to make sure the translated path
was indeed pointing to an existing directory: simplification happens in the
path space).

Returns the list (host, path, query).

=item C<tmp_dir>

The temporary directory that is being used.

=item C<http_headers>

Returns hashref with parsed HTTP headers received from CGI script.

=back

=head1 CGI ENVIRONMENT VARIABLES

The CGI protocol defines a set of environment variables which are to be set
by the web server before invoking the script.  The environment created by
C<CGI::Test> conforms to the CGI/1.1 specifications.

Here is a list of all the known variables.  Some of those are marked
I<read-only>.  It means you may choose to set them via the C<-cgi_env>
switch of the C<new()> routine, but your settings will have no effect and
C<CGI::Test> will always compute a suitable value.

Variables are listed in alphabetical order:

=over 4

=item C<AUTH_TYPE>

The authentication scheme used to authenticate the user given by C<REMOTE_USER>.
This variable is not present in the environment if there was no user specified
in the GET/POST requests.

By default, it is set to "Basic" when present.

=item C<CONTENT_LENGTH>

Read-only variable, giving the length of data to be read on STDIN by POST
requests (as told by C<REQUEST_METHOD>).  If is not present for GET requests.

=item C<CONTENT_TYPE>

Read-only variable, giving the MIME type of data to be read on STDIN by POST
requests (as told by C<REQUEST_METHOD>).  If is not present for GET requests.

=item C<GATEWAY_INTERFACE>

The Common Gateway Interface (CGI) version specification.
Defaults to "CGI/1.1".

=item C<HTTP_ACCEPT>

The set of Content-Type that are said to be accepted by the client issuing
the HTTP request.  Since there is no browser making any request here, the
default is set to "*/*".

It is up to your script to honour the value of this variable if it wishes to
be nice with the client.

=item C<HTTP_ACCEPT_CHARSET>

The charset that is said to be accepted by the client issuing the HTTP
request.  Since there is no browser making any request here, the
default is set to "iso-8859-1".

=item C<HTTP_CONNECTION>

Whether the connection should be kept alive by the server or closed after
this request.  Defaults to "Close", but since there's no connection and
no real client...

=item C<HTTP_HOST>

This is the host processing the HTTP request.
It is a read-only variable, set to the hostname and port parts of the
requested URL.

=item C<HTTP_USER_AGENT>

The user agent tag string.  This can be used by scripts to emit code that
can be understood by the client, and is also further abused to derive the
OS type where the user agent runs.

In order to be as neutral as possible, it is set to "CGI::Test" by default.

=item C<PATH_INFO>

Read-only variable set to the extra path information part of the requested URL.
Always present, even if empty.

=item C<PATH_TRANSLATED>

This read-only variable is only present when there is a non-empty C<PATH_INFO>
variable.  It is simply set to the value of C<PATH_INFO> with the document
rootdir path prepended to it (the value of the C<-doc_dir> creation argument).

=item C<QUERY_STRING>

This very important read-only variable is the query string present in the
requested URL.  Note that it may very well be set even for a POST request.

=item C<REMOTE_ADDR>

The IP address of the client making the requst.  Can be used to implement
an access policy from within the script.  Here, given that there's no real
client, the default is set to "127.0.0.1", which is the IP of the local
loopback interface.

=item C<REMOTE_HOST>

The DNS-translated hostname of the IP address held in C<REMOTE_ADDR>.
Here, for testing purposes, it is not computed after C<REMOTE_ADDR> but can
be freely set.  Defaults to "localhost".

=item C<REMOTE_USER>

This read-only variable is only present when making an authenticated GET or
POST request.  Its value is the name of the user we are supposed to have
successfully authenticated, using the scheme held in C<AUTH_TYPE>.

=item C<REQUEST_METHOD>

Read-only variable, whose value is either C<GET> or C<POST>.

=item C<SCRIPT_FILENAME>

Read-only variable set to the filesystem path of the CGI script being run.

=item C<SCRIPT_NAME>

Read-only variable set to the virtual  path of the CGI script being run,
i.e. the path given in the requested URL.

=item C<SERVER_NAME>

The host name running the server, which defaults to the host name present
in the base URL, provided at creation time as the C<-base_url> argument.

=item C<SERVER_PORT>

The port where the server listens, which defaults to the port present
in the base URL, provided at creation time as the C<-base_url> argument.
If no port was explicitely given, 80 is assumed.

=item C<SERVER_PROTOCOL>

The protocol which must be followed when replying to the client request.
Set to "HTTP/1.1" by default.

=item C<SERVER_SOFTWARE>

The name of the server software.  Defaults to "CGI::Test".

=back

=head1 BUGS

There are some, most probably.  Please notify me about them.

The following limitations (in decreasing amount of importance)
are known and may be lifted one day -- patches welcome:

=over 4

=item *

There is no support for cookies.  A CGI installing cookies and expecting
them to be resent on further invocations to friendly scripts is bound
to disappointment.

=item *

There is no support for testing a script in-situ, i.e. via a real web server,
whereby C<CGI::Test> would merely act as a client.  Currently, scripts are
run internally only, and therefore it is not possible to validate the
installation procedure on the server.

=item *

There is no support for plain document retrieval: only CGI scripts can
be fetched by an HTTP request for now.

=item *

There is no support for javascript (!).  Plain buttons attached to scripts
will do nothing when pressed...

=item *

There is no support for frames (!).

=item *

There is no support for Java (!).  Perhaps if I work for Sun one day...

=item *

There is no support for the <ISINDEX> tag, which is deprecated.

=back

=head1 PUBLIC REPOSITORY

CGI::Test now has a publicly accessible Git server provided by GitHub.com:
L<http://github.com/nohuhu/CGI-Test>

=head1 REPORTING BUGS

Please use CPAN RT or e-mail your bug reports, ideas, questions etc to
module's maintainer.

=head1 AUTHORS

The original author is Raphael Manfredi.

Steven Hilton was long time maintainer of this module.

Current maintainer is Alexander Tokarev F<E<lt>tokarev@cpan.orgE<gt>>.

=head1 SEE ALSO

CGI(3), CGI::Test::Page(3), CGI::Test::Form(3), CGI::Test::Input(3),
CGI::Test::Form::Widget(3), HTTP::Status(3), URI(3).

=cut

