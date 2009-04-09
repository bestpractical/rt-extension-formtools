use warnings;
use strict;

package RT::Extension::FormTools;

our $VERSION = '0.05';

=head2 is_core_field

passed one argument (field name) and checks if
that is a field that we consider 'core' to
RT (subject, AdminCc, etc) rather than something
which should be treated as a Custom Field.

Naming a Custom Field Subject would cause
serious pain with FormTools

=cut

my %is_core_field = map { $_ => 1 } qw(
    Requestors
    Cc
    AdminCc
    Subject
    Content
    Attach
);

sub is_core_field {
   return $is_core_field{ $_[0] };
}

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

sub email_is_privileged {
    my $email = shift;
    my $user = RT::User->new($RT::SystemUser);
    $user->LoadByEmail($email);
    return (1) if ($user->id && $user->Privileged);
    return (0, "Invalid account: $email");
}

sub has_value {
    my $value = shift;
    return 1 if defined($value) && length($value) > 0;
    return (0, "You must provide a value for this field");
}

1;
