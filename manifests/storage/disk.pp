#
# ==Add a raw disk to swift==
#
define swift::storage::disk (
  $device,
  $base_dir = '/dev',
  $mnt_base_dir = '/srv/node',
  $byte_size = '1024',
  $size = '100MB',
) {

  if(!defined(File[$mnt_base_dir])) {
    file { $mnt_base_dir:
      owner  => 'swift',
      group  => 'swift',
      ensure => directory,
    }
  }

  exec { "create_partition_label-${name}":
    command => "parted ${base_dir}/${device} mklabel msdos",
    path => ['/sbin'],
    unless => "parted ${base_dir}/${device} print",
  }
  exec { "create_partition-${name}":
    command => "parted ${base_dir}/${device} mkpart primary ext2 2048kB ${size}",
    path => ['/sbin'],
    unless => "parted ${base_dir}/${device} print | grep '^[[:space:]]*1.*primary.*'"
    require => Exec["create_partition_label-${name}"],
  }

  swift::storage::xfs { "${name}":
    device => "${base_dir}/${name}1",
    mnt_base_dir => $mnt_base_dir,
    byte_size => $byte_size,
    subscribe => Exec["create_partition-${name}"],
    loopback => false
  }
}
