use Test::More tests => 16;

use CGI::Test;

my $SERVER = "some-server";
my $PORT = 18;
my $BASE = "http://${SERVER}:${PORT}/cgi-bin";
my $SCRIPT = $^O =~ /win/i ? 'printenv.bat' : 'printenv';
my $SCRIPT_FNAME = $^O =~ /win/i ? "t\\cgi\\$SCRIPT" : "t/cgi/$SCRIPT";

my $ct = CGI::Test->new(
	-base_url	=> $BASE,
	-cgi_dir	=> "t/cgi",
);

ok defined $ct, "Got CGI::Test object";
isa_ok $ct, 'CGI::Test', 'isa';

my $PATH_INFO = "path/info";
my $QUERY = "query=1";
my $USER = "ram";

my $page = $ct->GET("$BASE/$SCRIPT/${PATH_INFO}?${QUERY}", $USER);
my $raw_length = length $page->raw_content;

ok !$page->is_error, "No errors in page";
ok $raw_length, "Got raw length: $raw_length";

my %V;
parse_content(\%V, $page->raw_content_ref);

cmp_ok $V{SCRIPT_NAME}, 'eq', "/cgi-bin/$SCRIPT", "SCRIPT_NAME";
cmp_ok $V{SERVER_PORT}, '==', $PORT, "SERVER_PORT";
cmp_ok $V{REQUEST_METHOD}, 'eq', "GET", "REQUEST_METHOD";
cmp_ok $V{SCRIPT_FILENAME}, 'eq', $SCRIPT_FNAME, "SCRIPT_FILENAME";
cmp_ok $V{PATH_INFO}, 'eq', "/$PATH_INFO", "PATH_INFO";
cmp_ok $V{QUERY_STRING}, 'eq', $QUERY, "QUERY_STRING";
cmp_ok $V{REMOTE_USER}, 'eq', $USER, "REMOTE_USER";
cmp_ok $V{HTTP_USER_AGENT}, 'eq', "CGI::Test", "HTTP_USER_AGENT";

my $AGENT = "LWP::UserAgent";
my $EXTRA = "is set";
$page->delete;

my $ct2 = CGI::Test->new(
	-base_url	=> $BASE,
	-cgi_dir	=> "t/cgi",
	-cgi_env	=> {
		EXTRA_IMPORTANT_VARIABLE	=> $EXTRA,
		HTTP_USER_AGENT				=> $AGENT,
		SCRIPT_FILENAME				=> "foo",
	},
);

$page = $ct2->GET("$BASE/$SCRIPT");
parse_content(\%V, $page->raw_content_ref);

cmp_ok $V{SCRIPT_NAME}, 'eq', "/cgi-bin/$SCRIPT", "SCRIPT_NAME";
cmp_ok $V{HTTP_USER_AGENT}, 'eq', $AGENT, "HTTP_USER_AGENT";
cmp_ok $V{EXTRA_IMPORTANT_VARIABLE}, 'eq', $EXTRA, "EXTRA_IMPORTANT_VARIABLE";

ok !exists $V{REMOTE_USER}, "REMOTE_USER not set";

$page->delete;

exit 0;		## DONE

sub parse_content {
	my ($h, $cref) = @_;
	%$h = ();
	foreach my $l (split /\n/, $$cref) {
		my ($k, $v) = $l =~ /^([^=]+)\s*=\s*(.*)$/;
		$h->{$k} = $v;
	}
}

