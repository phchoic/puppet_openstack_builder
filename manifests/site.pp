node default {
   if ! $::role {
     $role = regsubst($::clientcert, '([a-zA-Z]+)[^a-zA-Z].*', '\1')
   }

   site::role{ $role: }
}

define site::role
{
  $node_classes = hiera("${name}_classes", '')
  if $node_classes {
    include $node_classes
    $s = join($node_classes, ' ')
    debug("Including node classes : ${s}")
  }
}
