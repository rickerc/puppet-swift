#
# ==Add a raw disk to swift==
#
# pass in the device (e.g. sdb), and we'll label it, partition it to the $size) defined,
# and create an XFS file system on it.
#
# =Parameters=
# $device = device name, required
# $base_dir = '/dev', assumes local disk devices
# $mnt_base_dir = '/srv/node', location where a $device named director will be created
# $byte_size = '1024', block size for the disk.  For very large partitions, this should be larger
# $size = '100M', Really shoudl be discovered as a fact (e.g. with Razor), but for now, we pass it
#
# =Example=
#
# swift::storage:disk { "sdb":
#   $device => 'sdb',
#   $size => '500GB'
#}
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
      require => User['swift'],
    }
  }

  exec { "create_partition_label-${name}":
    command => "parted ${base_dir}/${device} mklabel msdos",
    path => ['/sbin','/bin'],
    unless => "parted ${base_dir}/${device} print",
  }
  exec { "create_partition-${name}":
    command => "parted ${base_dir}/${device} mkpart primary ext2 2048kB ${size}",
    path => ['/sbin','/bin'],
    unless => "parted ${base_dir}/${device} print | grep '^[[:space:]]*1.*primary.*'",
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
