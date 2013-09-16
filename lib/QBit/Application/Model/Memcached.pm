package QBit::Application::Model::Memcached;

use qbit;

use base qw(QBit::Application::Model);

use Cache::Memcached;
use Digest::MD5 qw(md5_hex);
use Digest::SHA1 qw(sha1_hex);
use Digest::CRC qw(crc32_hex);
use MIME::Base64 qw(encode_base64);

sub set {
    my ($self, $prefix, $key, $value, $exptime) = @_;

    return $self->_memd->set($self->_make_key($key, $prefix) => $value, $exptime);
}

sub get {
    my ($self, $prefix, $key) = @_;

    return $self->_memd->get($self->_make_key($key, $prefix));
}

sub _memd {
    my ($self) = @_;

    $self->{'__MEMD__'} = Cache::Memcached->new(
        {
            map {$_ => $self->get_option($_)}
            grep {defined($self->get_option($_))} qw(servers compress_threshold no_rehash readonly namespace debug)
        }
    ) unless exists($self->{'__MEMD__'});

    return $self->{'__MEMD__'};
}

sub _make_key {
    my ($self, $key, $prefix) = @_;

    throw Exception::BadArguments gettext("Prefix should be scalar") if ref($prefix) ne "";

    if (ref($key)) {
        local $Data::Dumper::Terse  = 1;
        local $Data::Dumper::Indent = 0;
        $key = Dumper($key);
    }
    my $orig_key = $key;
    $key = join('_', md5_hex($key), sha1_hex($key), crc32_hex($key));

    $key = "${prefix}_$key" if defined($prefix);

    $key .= substr(encode_base64($orig_key, ''), 0, 200 - length($key));

    return $key;
}

TRUE;
