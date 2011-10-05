#
# $Id: Makefile.PL,v 1.2 2003/10/04 14:26:05 mshiltonj Exp $
#
#  Copyright (c) 2001, Raphael Manfredi
#
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
#

use ExtUtils::MakeMaker;

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
);

