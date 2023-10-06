use warnings;
use strict;

package RT::Extension::FormTools;

our $VERSION = '0.53';

RT->AddStyleSheets('rt-extension-formtools.css');
RT->AddJavaScript('rt-extension-formtools.js');

use Time::HiRes 'time';
use Digest::SHA 'sha1_hex';

# page ids are based on current time, keep 100 recent ids in case CPU is really fast
my @recent_page_ids;

sub GeneratePageId {
    shift if ( $_[0] // '' ) eq __PACKAGE__;
    my $form = shift;
    my %current;
    if ($form) {
        %current = map { $_ => 1 } keys %{ $form->{'formtools-pages'} };
    }

    my %skip = (
        map { $_ => 1 } @recent_page_ids,
        $form && $form->{'formtools-pages'} ? keys %{ $form->{'formtools-pages'} } : ()
    );

    my $page_id = _GeneratePageId();

    for ( 1 .. 100 ) {
        if ( $skip{$page_id} ) {
            $page_id = _GeneratePageId();
        }
        else {
            push @recent_page_ids, $page_id;
            shift @recent_page_ids while @recent_page_ids > 100;
            return $page_id;
        }
    }
    RT->Logger->error("Could not generate a new page id");
    return;
}

sub _GeneratePageId {
    return substr( sha1_hex( time . int rand 10000 ), 0, 8 );
}

=head1 NAME

RT-Extension-FormTools - Help write multi-page ticket creation wizards

=head1 DESCRIPTION

This extension provides scaffolding to make it simpler to create guided
multi-page ticket creation wizards.  It merely provides useful Mason
components to accomplish this task; it does not provide any UI.
Administrators may use this extension as a base upon which to write
their own forms in Mason.

=head1 RT VERSION

Works with RT 5.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::FormTools');

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=head1 COMPONENTS

See F<ex/RT-Example-FormTools/> for an example extension written using
this module.

=head1 C</FormTools/Form>

The top-level component that most elements will call, as a wrapper:

    <&|/FormTools/Form, next => "/URI/of/next/page" &>
    (form elements)
    </&>

It requires that the next page in the wizard be passed as the C<next>
parameter; this may be empty at the end of the wizard.  It renders page
decoration (using C</Elements/Header>).  It assumes that the queue will
be stored in C<$m->notes('queue')>.

=head1 C</FormTools/Field>

Renders a field in the form.  It takes the name of a core field, or CF
name:

    <& /FormTools/Field, name => 'Requestors' &>

Valid core fields include:

=over

=item Requestors

=item Cc

=item AdminCc

=item Subject

=item Content

=item Attach

=item Due

=back

Any other argument to C<name> is assumed to be the name of a custom
field.

=head2 C</FormTools/Next>

Renders the "Next page" button.

=head2 C</FormTools/ShowChoices>

Shows the values that have already been submitted.

=head1 FUNCTIONS

In addition to the Mason components, this module provides a number of
functions which may be useful to call from Mason templates.

=head2 is_core_field C<field_name>

Checks if the given C<field_name> is is a field that we consider 'core'
to RT (subject, AdminCc, etc) rather than something which should be
treated as a Custom Field.

Naming a Custom Field Subject would cause serious pain with FormTools.

=cut

my %is_core_field = map { $_ => 1 } qw(
    Requestors
    Cc
    AdminCc
    Subject
    Content
    Attach
    Due
);

sub is_core_field {
    return $is_core_field{ $_[0] };
}

=head2 validate_cf C<CF>, C<ARGSRef>

Takes a given L<RT::CustomField> object and a hashref of query
parameters, and returns a list of a boolean of if the custom field
validates, followed by a list of errors.

=cut

sub validate_cf {
    my ($CF, $ARGSRef) = @_;
    my $NamePrefix = "Object-RT::Ticket--CustomField-";
    my $field = $NamePrefix . $CF->Id . "-Value";
    my $valid = 1;
    my $value;
    my @res;
    if ($ARGSRef->{"${field}s-Magic"} and exists $ARGSRef->{"${field}s"}) {
        $value = $ARGSRef->{"${field}s"};
        # We only validate Single Combos -- multis can never be user input
        return ($valid) if ref $value;
    }
    else {
        $value = $ARGSRef->{$field};
    }

    my @values = ();
    if ( ref $value eq 'ARRAY' ) {
        @values = @$value;
    } elsif ( $CF->Type =~ /text/i ) {
        @values = ($value);
    } else {
        @values = split /\r*\n/, ( defined $value ? $value : '');
    }
    @values = grep $_ ne '',
        map {
            s/\r+\n/\n/g;
            s/^\s+//;
            s/\s+$//;
            $_;
        }
        grep defined, @values;
    @values = ('') unless @values;

    foreach my $value( @values ) {
        next if $CF->MatchPattern($value);

        my $msg = "Input must match ". $CF->FriendlyPattern;
        push @res, $msg;
        $valid = 0;
    }
    return ($valid, @res);
}

=head2 email_is_privileged C<email_address>

Returns true if the given email address belongs to a privileged user.

=cut

sub email_is_privileged {
    my $email = shift;
    my $user = RT::User->new($RT::SystemUser);
    $user->LoadByEmail($email);
    return (1) if ($user->id && $user->Privileged);
    return (0, "Invalid account: $email");
}

=head2 has_value C<value>

Returns true if the value is defined and non-empty.

=cut

sub has_value {
    my $value = shift;
    return 1 if defined($value) && length($value) > 0;
    return (0, "You must provide a value for this field");
}

=head2 LoadFormIcon($current_user, $form_id)

Loads the form icon attribute associated with the passed form id.

Returns a tuple of attribute object or false, and a message.

=cut

sub LoadFormIcon {
    my $current_user = shift;
    my $form_id = shift;

    my $form_icon = RT::Attribute->new( $current_user );
    my ( $ok, $msg ) = $form_icon->LoadByCols(
        Name => 'FormTools Icon',
        ObjectType => 'RT::Attribute',
        ObjectId => $form_id );

    if ( $ok ) {
        return ( $form_icon, $msg );
    }
    else {
        RT->Logger->error("Unable to load icon: $msg");
        return ( 0, $msg );
    }
}

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-FormTools@rt.cpan.org|mailto:bug-RT-Extension-FormTools@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-FormTools>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2014-2022 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
