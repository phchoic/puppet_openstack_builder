# Globals
# Role may be set by using external facts, or can
# fall back to using the first word in the clientcert
if ! $::role {
  $role = regsubst($::clientcert, '([a-zA-Z]+)[^a-zA-Z].*', '\1')
}

$scenario = hiera('scenario', "")
$cinder_backend = hiera('cinder_backend', "")
$glance_backend = hiera('glance_backend', "")
$rpc_type = hiera('rpc_type', "")
$db_type = hiera('db_type', "")
$tenant_network_type = hiera('tenant_network_type', "")
$network_type = hiera('network_type', "")
$network_plugin = hiera('network_plugin', "")
$network_service = hiera('network_service', "")
$storage = hiera('storage', "")
$networking = hiera('networking', "")
$monitoring = hiera('monitoring', "")
$password_management = hiera('password_management', "")
$compute_type = hiera('compute_type', "")

node default {
  notice("my scenario is ${scenario}")
  notice("my role is ${role}")
  $node_class_groups = hiera('class_groups', undef)
  notice("class groups: ${node_class_groups}")
  if $node_class_groups {
    class_group { $node_class_groups: }
  }

  $node_classes = hiera('classes', undef)
  if $node_classes {
    include $node_classes
    $s = join($node_classes, ' ')
    notice("Including node classes : ${s}")
  }
}

define class_group {
  include hiera($name)
  $x = join(hiera($name), ' ')
  notice( "including ${x}" )
}

define contrib_group {
  include hiera("${name}_classes")
  $x = hiera("${name}_classes")
  notice( "including ${x}" )
}
