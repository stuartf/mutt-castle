#!/usr/bin/perl -w
#
# mutt_ldap_query.pl 
# version 1.2

# Copyright (C) 4/14/98 Marc de Courville <marc@courville.org>
#       but feel free to redistribute it however you like.
#
# mutt_ldap_query.pl: perl script to parse the outputs of ldapsearch
# (ldap server query tool present in ldap-3.3 distribution
# http://www.umich.edu/~rsug/ldap) in order to pass the required
# formatted data to mutt (mail client http://www.mutt.org/)
# using Brandon Long's the "External Address Query" patch
# (http://www.fiction.net/blong/programs/mutt/#query).
#
# Warren Jones <wjones@tc.fluke.com> 2-10-99
#    o Instead of just matching "sn", I try to match these fields
#      in the LDAP database: "cn", "mail", "sn" and "givenname".
#      A wildcard is used to make a prefix match.  (I borrowed
#      this query from pine.)
#
#    o Commas separating command line arguments are optional.
#      (Does mutt really start up $query_command with comma
#      separated args?)
#
#    o Streamlined the perl here and there.  In particular,
#      I used paragraph mode to read in each match in a single
#      chunk.
#
#    o Added "use strict" and made the script "-w" safe.
#
#    o Returned non-zero exit status for errors or when there
#      is no match, as specified by the mutt docs.
#
#    o Explicitly close the pipe from ldapsearch and check
#      error status.
#  

use strict;

# Please change the following 2 lines to match your site configuration
#
my $ldap_server = "whitepages.gatech.edu";
my $BASEDN = "dc=whitepages,dc=gatech,dc=edu";           

# Fields to search in the LDAP database:
#
my @fields = qw(uid cn mail);

die "Usage: $0 <name_to_query>, [[<other_name_to_query>], ...]\n"
    if ! @ARGV;

$/ = '';	# Paragraph mode for input.
my @results;

foreach my $askfor ( @ARGV ) {

    $askfor =~ s/,$//;	# Remove optional trailing comma.

    my $query = join '', map { "($_=$askfor*)" } @fields;
    my $command = "ldapsearch -x -h $ldap_server -b '$BASEDN' '(|$query)'" .
                  " displayName mail telephoneNumber uid";

    open( LDAPQUERY, "$command |" ) or die "LDAP query error: $!"; 

    while ( <LDAPQUERY> ) {
	next if ! /^mail:(.*)$/im;
	my $email = $1;
	my $phone = /^telephoneNumber:(.*)$/im ? $1 : '';
	my $uid = /^uid:(.*)$/im ? $1 : '';
	my $name =  /^displayName:(.*)$/im ? $1 : '' ;
	push @results, "$email\t$name\t$phone $uid\n";
    }

    close( LDAPQUERY ) or die "ldapsearch failed: $!\n";
}

print "LDAP query: found ", scalar(@results), "\n", @results;
exit 1 if ! @results;
