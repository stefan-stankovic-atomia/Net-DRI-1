#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;
use Encode;

use Test::More tests => 10;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd" xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xmlns:contact-ext="http://www.eurid.eu/xml/epp/contact-ext-1.2">';
our $E2='</epp>';
our $TRID='<trID><clTRID>TRID-0001</clTRID><svTRID>eurid-488059</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10});
$dri->{trid_factory}=sub { return 'TRID-0001'; };
$dri->add_registry('EURid');
$dri->target('EURid')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$s,$d,$co,$toc,$cs,$h,$dh,@c);

########################################################################################################
## Process greetings to select namespace versions
# This greeting was taken off release_notes_march_2019
$R2=$E1.'<greeting><svID>eurid.eu</svID><svDate>2019-03-06T16:42:53.543Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>http://www.eurid.eu/xml/epp/dnsQuality-2.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>http://www.eurid.eu/xml/epp/registrarFinance-1.0</objURI><objURI>http://www.eurid.eu/xml/epp/registrarHitPoints-1.0</objURI><objURI>http://www.eurid.eu/xml/epp/registrationLimit-1.1</objURI><objURI>http://www.eurid.eu/xml/epp/nsgroup-1.1</objURI><objURI>http://www.eurid.eu/xml/epp/keygroup-1.1</objURI><objURI>http://www.eurid.eu/xml/epp/dnssecEligibility-1.0</objURI><svcExtension><extURI>http://www.eurid.eu/xml/epp/contact-ext-1.2</extURI><extURI>http://www.eurid.eu/xml/epp/contact-ext-1.2</extURI><extURI>http://www.eurid.eu/xml/epp/domain-ext-2.2</extURI><extURI>http://www.eurid.eu/xml/epp/domain-ext-2.2</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>http://www.eurid.eu/xml/epp/idn-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/authInfo-1.1</extURI><extURI>http://www.eurid.eu/xml/epp/poll-1.2</extURI><extURI>http://www.eurid.eu/xml/epp/homoglyph-1.0</extURI></svcExtension></svcMenu><dcp><access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/><public/></recipient><retention><stated/></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{'secDNS'}->[0],'urn:ietf:params:xml:ns:secDNS-1.1','secDNS 1.1 for server announcing 1.0 + 1.1');
is($dri->protocol()->ns()->{'idn'}->[0],'http://www.eurid.eu/xml/epp/idn-1.0','idn 1.0 for server announcing 1.0');
is($dri->protocol()->ns()->{'domain-ext'}->[0],'http://www.eurid.eu/xml/epp/domain-ext-2.2','domain-ext 2.2 for server announcing 2.1 + 2.2');
is($dri->protocol()->ns()->{'contact-ext'}->[0],'http://www.eurid.eu/xml/epp/contact-ext-1.2','contact-ext 1.2 for server announcing 1.1 + 1.2');
is($dri->protocol()->ns()->{'poll'}->[0],'http://www.eurid.eu/xml/epp/poll-1.2','poll 1.2 for server announcing 1.1 + 1.2');
is($dri->protocol()->ns()->{'authInfo'}->[0],'http://www.eurid.eu/xml/epp/authInfo-1.1','authInfo 1.1 for server announcing 1.1');
is($dri->protocol()->ns()->{'nsgroup'}->[0],'http://www.eurid.eu/xml/epp/nsgroup-1.1','nsgroup-1.1 for server announcing 1.1');
is($dri->protocol()->ns()->{'keygroup'}->[0],'http://www.eurid.eu/xml/epp/keygroup-1.1','keygroup 1.1 for server announcing 1.1');
is($dri->protocol()->ns()->{'homoglyph'}->[0],'http://www.eurid.eu/xml/epp/homoglyph-1.0','homoglyph-1.0 for server announcing 1.0');
is($dri->protocol()->ns()->{'dns_quality'}->[0],'http://www.eurid.eu/xml/epp/dnsQuality-2.0','dnsQuality-2.0 for server announcing 2.0');

exit 0;
