package Net::IPA::Lite;

use 5.006;
use strict;
use warnings;

use REST::Client;
use JSON;
use Data::Dumper;
use MIME::Base64;
use IO::Socket::SSL qw( SSL_VERIFY_NONE );

=head1 NAME

Net::IPA::Lite - a wrapper around the JSON-RPC API provided by FreeIPA.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    use Net::IPA::Lite;

    my $ipa = Net::IPA::Lite->new();

    $ipa->version('2.156');
    $ipa->hostname('ipa.foo.com');

    # login
    my $success = $ipa->login(
        username => 'your_username',
        password => 'your_password',
    );

    # deal with failed login
    unless ($success) {
        my $rc = $ipa->responseCode();
        my $msg = $ipa->responseContent();
        die "login got $rc\n$msg\n";
    }

    # add an A record
    $success = $ipa->dnsrecord_add(
        dnszoneidnsname => 'example.com',
        idnsname => 'test01',
        a_part_ip_address => '8.8.8.8',
    );

    # remove the A record
    $success = $ipa->dnsrecord_add(
        dnszoneidnsname => 'example.com',
        idnsname => 'test01',
        arecord => ['8.8.8.8'],
    );
    ...

=head1 PUBLIC METHODS

=head2 new

Create new instance of interface.

    use Net::IPA::Lite;

    my $ipa = Net::IPA::Lite->new();

WARNING: this module currently ignores SSL certificate verification.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my %args = @_;

	my $self = {};
	$self->{client} = REST::Client->new();
	$self->{client}->getUseragent()->cookie_jar({}); # empty internal cookie jar

	# don't verify SSL certs
	$self->{client}->getUseragent()->ssl_opts(verify_hostname => 0);
	$self->{client}->getUseragent()->ssl_opts(SSL_verify_mode => SSL_VERIFY_NONE);

	bless($self, $class);
	return $self;
}

=head2 hostname

Set the API hostname to pass to use to talk to FreeIPA.
There is no default so this is required for login or any JSON-API calls.

    $ipa->hostname('ipa.foo.com');

=cut

sub hostname {
	my $self = shift;
	my $hostname = shift;

	# validate arguments
	die "IPA:hostname():no hostname" unless defined $hostname;
	die "IPA:hostname():empty hostname" unless length $hostname;

	$self->{hostname} = $hostname;

	my $url = "https://$hostname";

	unless ($self->{referer}) {
		$self->{referer} = $url;
		$self->{client}->setHost($url);
	}

	return 1;
}

=head2 login

Login to IPA.  Currently only username/password authentication is supported.

    my $success = $ipa->login(
        username => 'your_username',
        password => 'your_password',
    );

So the two arguments are C<username> and C<password> in hash-style.

=cut

sub login {
	my $self = shift;
	my %args = @_;

	my $client = $self->{client};

	# validate arguments
	die "IPA:login():no username" unless defined $args{username};
	die "IPA:login():no password" unless defined $args{password};
	die "IPA:login():empty username" unless length $args{username};
	die "IPA:login():empty password" unless length $args{password};

	my $username = $args{username};
	my $password = $args{password};

	my $headers =  {
		'Accept' => 'text/plain',
		'referer' => $self->{referer},
		'Content-Type' => 'application/x-www-form-urlencoded',
	};

	my $body = {
		'user' => $username,
		'password' => $password,
	};

	my $params = $client->buildQuery($body);
	$client->POST("/ipa/session/login_password", substr($params, 1), $headers);
	my $auth_rc = $client->responseCode();
	unless ($auth_rc eq '200') {
		die "login rc=$auth_rc for $username\n";
	}


	# fix referer
	my $hostname = $self->{hostname};
	my $url = "https://$hostname/ipa";
	$self->{referer} = $url;

	return $auth_rc;
}

=head2 version

Set the API version to pass to use in JSON-RPC calls -- so this applies to everything
after C<login()>.  There is no default so this is required (other than for login).

    $ipa->version('2.156');

=cut

sub version {
	my $self = shift;
	my $version = shift;

	die "IPA:version():no version" unless defined $version;
	die "IPA:version():empty version" unless length $version;
	die "IPA:version():bad version '$version'" unless $version =~ /^[.0-9]+$/;

	$self->{version} = $version;

	return 1;
}

=head1 INTERNAL METHODS

=head1 AUTHOR

Christopher Hicks, C<< <chicks.net at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests through
the web interface at L<https://github.com/chicks-net/p5-net-ipa-lite/issues>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::IPA::Lite


You can also look for information at:

=over 4

=item * github issues (report bugs here)

L<https://github.com/chicks-net/p5-net-ipa-lite/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-IPA-Lite>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-IPA-Lite>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-IPA-Lite/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Christopher Hicks.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Net::IPA::Lite
