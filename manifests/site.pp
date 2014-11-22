node default {
   if ! $::role {
     $role = hiera('role')
   } else {
     $role = $::role
   }

   notice("Node role is ${role}")
   site::role{ $role: }
}

define site::role
{
  $node_classes = hiera("${name}_classes", '')
  if $node_classes {
    include $node_classes
    $s = join($node_classes, ' ')
    notice("Including node classes : ${s}")
  }
}
