package Pod::Readme::Plugin::requires;

use Moose::Role;

use version 0.77;

use CPAN::Meta;
use Module::CoreList;
use Path::Class;

has 'requires_from_file' => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    coerce   => 1,
    default  => 'META.yml',
);

has 'requires_title' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'REQUIREMENTS',
);

sub cmd_requires {
    my ($self, @args) = @_;

    my $meta = CPAN::Meta->load_file(
        file($self->base_dir, $self->requires_from_file));

    my %prereqs;
    foreach my $type (values %{$meta->prereqs}) {
        $prereqs{$_} = $type->{requires}->{$_}
            for (keys %{$type->{requires}});
    }
    my $perl = delete $prereqs{perl};
    if ($perl) {
        foreach (keys %prereqs) {
            delete $prereqs{$_}
              if Module::CoreList->first_release($_) &&
                  Module::CoreList->first_release($_) <= $perl;
        }
    }

    if (%prereqs) {

        $self->write_head1($self->requires_title);

        if ($perl) {
            $self->write_para(sprintf('This distribution requires Perl %s.',
                                      version->parse($perl)->normal));
        }

        $self->write_para('This distribution requires the following modules:');

        $self->write_over(4);
        foreach my $module  (sort keys %prereqs) {
            $self->write_item(sprintf('* L<%s>', $module));
        }
        $self->write_back;
    }

}

use namespace::autoclean;

1;
