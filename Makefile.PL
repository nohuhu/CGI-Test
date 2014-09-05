#
# $Id$
#
#  Copyright (c) 2001, Raphael Manfredi
#  Copyright (c) 2011-2014 Alexander Tokarev
#
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
#
use ExtUtils::MakeMaker;
use Config;

# /win/ won't work since it will also match Darwin (Mac OS X)
use constant WINDOWS => eval { $^O =~ /Win32|cygwin/ };

# Munge test CGI scripts so that they run under current Perl
my @cgi_files = do {
    my $cgi_dir = 't/cgi';
    opendir my $dh, $cgi_dir;
    map { "$cgi_dir/$_" } grep { /\.in$/ } readdir $dh;
};

for my $file ( @cgi_files ) {
    my $text = do {
        open my $fin, '<', $file or die "Can't open $file for reading: $!";
        local $/ = undef;
        <$fin>;
    };

    if ( WINDOWS ) {
        $file =~ s{\.in}{\.bat};
        $file =~ s{/}{\\\\}g;

        my $pl2bat = $Config{bin} . '\\pl2bat.bat';

        open my $fout, "| $pl2bat > $file" or die "Can't pipe to pl2bat: $!";
        print $fout $text;
        close $fout;
    }
    else {
        $text =~ s{#!PERL}{#!${^X}};

        $file =~ s{\.in}{};

        open my $fout, '>', $file or die "Can't open $file for writing: $!";
        print $fout $text;
        close $fout;

        chmod 0755, $file;
    };
};

WriteMakefile(
    NAME              => 'CGI::Test',
    VERSION_FROM      => 'lib/CGI/Test.pm',
    PREREQ_PM         => {
        'CGI'               => '0',
        'Digest::MD5'       => '0',
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
    AUTHOR   => 'Alex Tokarev <tokarev@cpan.org>',
    LICENSE  => 'perl',

    META_MERGE => {
        resources   => {
            bugtracker  => 'http://github.com/nohuhu/CGI-Test/issues',
            repository  => 'http://github.com/nohuhu/CGI-Test',
        },
    },

    clean => {
        FILES => q|
                    t/cgi/dumpargs t/cgi/getform t/cgi/printenv
                    t/cgi/dumpargs.bat t/cgi/getform.bat t/cgi/printenv.bat
                 |,
    },
);

