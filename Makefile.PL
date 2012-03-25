#
# $Id$
#
#  Copyright (c) 2001, Raphael Manfredi
#
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
#
use ExtUtils::MakeMaker;

# Munge test CGI scripts so that they run under current Perl
my @cgi_files = do {
    my $cgi_dir = 't/cgi';
    opendir my $dh, $cgi_dir;
    map { "$cgi_dir/$_" } grep { !/^\.\.?/ } readdir $dh;
};

for my $file ( @cgi_files ) {
    my $text = do {
        open my $fin, '<', $file or die "Can't open $file for reading: $!";
        local $/ = undef;
        <$fin>;
    };

    $text =~ s{exec perl -S}{exec $^X -S};
    $file =~ s{\.in}{};

    open my $fout, '>', $file or die "Can't open $file for writing: $!";
    print $fout $text;
    close $fout;

    chmod 0755, $file;
};

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CGI::Test',
    VERSION_FROM      => 'lib/CGI/Test.pm', # finds $VERSION
    PREREQ_PM         => {
        'CGI'               => '0',
        'Digest::MD5'       => '0',
        'Getargs::Long'     => '0.103',
        'Log::Agent'        => '0.207',
        'URI'               => '1.10',
        ($] >= 5.008                   # HTTP::Status is now in
         ? ('HTTP::Message' => '0', )  # HTTP::Message bundle which
         : ('LWP'           => '0', )  # requires 5.8+
        ),
        'HTML::TreeBuilder' => '0',
        'File::Temp'        => '0',
        'File::Spec'        => '0',
        'Storable'          => '1.000',
    },

    ABSTRACT => 'CGI regression test framework',
    AUTHOR   => 'Raphael Manfredi <Raphael_Manfredi@pobox.com>',
    LICENSE  => 'perl',

    META_MERGE => {
        resources   => {
            bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Test',
            repository  => 'http://github.com/nohuhu/CGI-Test',
        },
    },

    clean => {
        FILES => 't/cgi/dumpargs t/cgi/getform t/cgi/printenv',
    },
);

