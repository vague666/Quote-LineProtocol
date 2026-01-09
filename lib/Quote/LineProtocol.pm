package Quote::LineProtocol;

use v5.26;
use warnings;
use Time::Moment;
use Syntax::Keyword::Match;

use Exporter 'import';
our @EXPORT_OK = qw(measurement tags fields timestamp);

our $VERSION = "0.1.0";

my $qr = qr{([,=\s])};    # Match tag and field keys, and tag values
my $qs = qr{(["\\,=\s])}; # Match field string values

sub measurement {
  my $str = shift;
  return $str =~ s{([,\s])}{\Q$1\E}gr;
}

sub tags {
  my (%tags) = ref $_[0] && @_ == 1 ? $_[0]->@* : @_;
  my @r;

  for my $key (keys %tags) {
    my $val = $tags{$key};
    push @r, sprintf(qq(%s=%s), $key =~ s{$qr}{\Q$1\E}gr, $val =~ s{$qr}{\Q$1\E}gr);
  }

  return @r;
}

sub fields {
  my (%fields) = ref $_[0] && @_ == 1 ? $_[0]->@* : @_;
  my @r;

  for my $key (sort keys %fields) {
    my $val = $fields{$key};
    my $type;

    if(ref $val) {
      die "Type missing or invalid for field '$key'" unless exists $val->{type} && $val->{type} =~  /^[fisb]\z/;
      $type = $val->{type};
      $val = $val->{value};
    }
    else {
      match($val : =~) {
        case(/^-?[0-9]+\.[0-9]+$/) {
          $type = 'f';
        }
        case(/^-?[0-9]+$/) {
          $type = 'i';
        }
        case(/\w+/) {
          $type = 's';
        }
      }
    }

    match($type : eq) {
      case('f') {
        push @r, sprintf(qq(%s=%s),   $key =~ s{$qr}{\Q$1\E}gr, $val);
      }
      case('i') {
        push @r, sprintf(qq(%s=%di),  $key =~ s{$qr}{\Q$1\E}gr, $val);
      }
      case('s') {
        push @r, sprintf(qq)%s="%s"), $key =~ s{$qr}{\Q$1\E}gr, $val =~ s{$qs}{\Q$1\E}gr);
      }
      case('b') {
        push @r, sprintf(qq(%s=%s),   $key =~ s{$qr}{\Q$1\E}gr, $val);
      }
      default {
        push @r, sprintf(qq(%s="%s"), $key =~ s{$qr}{\Q$1\E}gr, $val =~ s{$qs}{\Q$1\E}gr);
      }
    }
  }

  return @r;
}

sub timestamp {
  my ($unit, $utc) = @_;
  my $now = $utc ? Time::Moment->now_utc : Time::Moment->now;
  return sprintf("%d", sprintf("%d%d", $now->epoch, $unit eq 'ns' ? $now->nanosecond
                                                  : $unit eq 'us' ? $now->microsecond
                                                  : $unit eq 'ms' ? $now->millisecond
                                                  : ""));
}

1;
__END__

=encoding utf-8

=head1 NAME

Quote::LineProtocol - It's new $module

https://docs.influxdata.com/influxdb/v2/reference/syntax/line-protocol/#special-characters
=head1 SYNOPSIS

    use Quote::LineProtocol;

=head1 DESCRIPTION

Quote::LineProtocol is ...

=head1 LICENSE

Copyright (C) vague666.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

vague E<lt>vague@cpan.orgE<gt>

=cut

