#
# $Id: browse.pl,v 1.2 2003/09/29 11:00:50 mshiltonj Exp $
#
#  Copyright (c) 2001, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: browse.pl,v $
# Revision 1.2  2003/09/29 11:00:50  mshiltonj
#     CGI::Test has changed ownership. The new owner is Steven Hilton
#     <mshiltonj@mshiltonj.com>.  Many thanks to Raphael Manfredi
#     and Steve Fink.
#
#     CGI::Test is now hosted as a SourceForge project. It is located
#     at <http://cgi-test.sourceforge.net>.
#
#     POD updated to reflect the above.
#
#     make() method on various objects has been deprecated, and has been
#     replaced by more conventional (for me, at least) new() method.
#     Support for make() may be removed in a later release.
#
#     Entire codebase reformatted using perltidy
#     Go to <http://perltidy.sourceforge.net/> to see how neat it is.
#
#     Self-referential object variable name standardized to '$this'
#     throughout code.
#
# Revision 1.1.1.1  2003/09/23 09:47:26  mshiltonj
# Initial Import
#
# Revision 0.1.1.1  2001/04/17 11:25:18  ram
# patch3: changed test 22 to perform explicit sorting
#
# Revision 0.1  2001/03/31 10:54:03  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use CGI::Test;
use Getargs::Long;

use Config;

#
# This is a fix for nasty Fcntl loading problem: it seems that
# custom-built Perl fails to allocate some kind of resources, or
# just tries to load wrong shared object. This results in tests
# failing miserably; considering that custom builds are very common
# among CPAN testers, it is a serious problem.
#
$ENV{PATH} = $Config{bin} . ':' . $ENV{PATH};

sub browse {
	my ($method, $enctype) = getargs(@_, [qw(method enctype)]);

	print "1..27\n";

	my $BASE = "http://server:18/cgi-bin";
	my $ct = CGI::Test->new(
		-base_url	=> $BASE,
		-cgi_dir	=> "t/cgi",
	);

	my $query = "action=/cgi-bin/dumpargs";
	$query .= "&method=$method" if defined $method;
	$query .= "&enctype=$enctype" if defined $enctype;

	my $page = $ct->GET("$BASE/getform?$query");
	my $form = $page->forms->[0];

	ok 1, $form->action eq "/cgi-bin/dumpargs";

	my $submit = $form->submit_by_name("Send");
	ok 2, defined $submit;

	my $page2 = $submit->press;
	ok 3, $page2->is_ok;

	my $args = parse_args($page2->raw_content);
	ok 4,  $args->{counter} == 1;
	ok 5,  $args->{title} eq "Mr";
	ok 6,  $args->{name} eq "";
	ok 7,  $args->{skills} eq "listening";
	ok 8,  $args->{new} eq "ON";
	ok 9,  $args->{color} eq "white";
	ok 10, $args->{note} eq "";
	ok 11, $args->{months} eq "Jul";
	ok 12, $args->{passwd} eq "";
	ok 13, $args->{Send} eq "Send";
	ok 14, $args->{portrait} eq "";

	my $r = $form->radio_by_name("title");
	$r->check_tagged("Miss");

	my $m = $form->menu_by_name("months");
	$m->select("Jan");
	$m->select("Feb");
	$m->unselect("Jul");

	$m = $form->menu_by_name("color");
	$m->select("red");

	my $b = $form->checkbox_by_name("new");
	$b->uncheck;

	my $t = $form->input_by_name("portrait");
	$t->replace("this is ix");
	$t->append(", disappointed?");
	$t->filter(sub { s/\bix\b/it/ });

	$t = $form->input_by_name("passwd");
	$t->append("bar");
	$t->prepend("foo");

	$t = $form->input_by_name("note");
	$t->replace("this\nis\nsome\ntext");

	$page2 = $submit->press;
	my $args2 = parse_args($page2->raw_content);

	ok 15, $args2->{counter} == 1;
	ok 16, $args2->{title} eq "Miss";
	ok 17, $args2->{name} eq "";
	ok 18, $args2->{skills} eq "listening";
	ok 19, !exists $args2->{new};			# unchecked, not submitted
	ok 20, $args2->{color} eq "red";
	ok 21, $args2->{note} eq "this is some text";
	ok 22, join(" ", sort split(' ', $args2->{months})) eq "Feb Jan";
	ok 23, $args2->{passwd} eq "foobar";
	ok 24, $args2->{Send} eq "Send";
	ok 25, $args2->{portrait} eq "this is it, disappointed?";

	# Ensure we tested what was requested
	$method = "GET" unless defined $method;
	ok 26, $form->method eq $method;
	ok 27, substr($form->enctype, 0, 5) eq
		(defined $enctype ? "multi" : "appli");
}

# Rebuild parameter list from the output of dumpargs into a HASH
sub parse_args {
	my ($content) = @_;
	my %params;
	foreach my $line (split(/\r?\n/, $content)) {
		my ($name, $values) = split(/\t/, $line);
		$params{$name} = $values;
	}
	return \%params;
}

1;

