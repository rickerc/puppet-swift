class swift::keystone::auth(
  $auth_name 	      = 'swift',
  $configure_endpoint = true,
  $service_type       = 'object-store',
  $password  	      = 'swift_password',
  $tenant    	      = 'services',
  $email     	      = 'swift@localhost',
  $address   	      = '127.0.0.1',
  $region             = 'RegionOne',
  $port      	      = '8080'
) {

  keystone_user { $auth_name:
    ensure   => present,
    password => $password,
    email    => $email,
    tenant   => $tenant,
  }
  keystone_user_role { "${auth_name}@${tenant}":
    ensure  => present,
    roles   => 'admin',
    require => Keystone_user[$auth_name]
  }

  keystone_service { $auth_name:
    ensure      => present,
    type        => $service_type,
    description => 'Openstack Object-Store Service',
  }
  if $configure_endpoint {
    keystone_endpoint { "${region}/$auth_name":
      ensure       => present,
      public_url   => "http://${address}:${port}/v1/AUTH_%(tenant_id)s",
      admin_url    => "http://${address}:${port}/",
      internal_url => "http://${address}:${port}/v1/AUTH_%(tenant_id)s",
    }
  }
  keystone_service { "${auth_name}_s3":
    ensure      => present,
    type        => 's3',
    description => 'Openstack S3 Service',
  }
  if $configure_endpoint {
    keystone_endpoint { "${region}/${auth_name}_s3":
      ensure       => present,
      public_url   => "http://${address}:${port}",
      admin_url    => "http://${address}:${port}",
      internal_url => "http://${address}:${port}",
    }
  }
}
