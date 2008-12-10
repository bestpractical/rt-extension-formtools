use warnings;
use strict;

package RT::Extension::FormTools;

our $VERSION = '0.03';

=head2 is_core_field

passed one argument (field name) and checks if
that is a field that we consider 'core' to
RT (subject, AdminCc, etc) rather than something
which should be treated as a Custom Field.

Naming a Custom Field Subject would cause
serious pain with FormTools

=cut

sub is_core_field {
   return $_[0] =~ /^(Requestors|Cc|AdminCc|Subject|UpdateContent|Attach)$/;
}

1;
