# @summary Handle Cluster member management
#
# @example Simple usage
#   class { 'lxd::cluster':
#     member_name => 'member01',
#     join_member => '192.168.0.10:8443',
#     members     => {
#       'member01' => {
#         'address' => '192.168.0.10:8443',
#         'enabled' => true
#       },
#       'member02' => {
#         'address' => '192.168.0.10:8443',
#         'enabled' => true
#       },
#       'member03' => {
#         'address' => '192.168.0.12:8443',
#         'enabled' => true
#       }
#     }
#   }
#
#
class lxd::cluster (
  String                    $member_name      = $lxd::cluster_member_name,
  Hash[String, Hash]        $members          = $lxd::cluster_members,
  String                    $join_member      = $lxd::cluster_join_member,
  String                    $cluster_password = $lxd::cluster_trust_password,
) {
  $current_member = $members[$member_name]

  # Retrieve `address` fields of all other members of the cluster
  $other_members = $members.filter | String $member_name, Hash $member_values | {
    $member_values['address'] != $current_member['address']
  }.map | String $member_name, Hash $member_values | {
    $member_values['address']
  }

  lxd_cluster_member { $member_name:
    ensure        => $current_member['ensure'],
    enabled       => $current_member['enabled'],
    address       => $current_member['address'],
    join_member   => $join_member,
    other_members => $other_members
  }
}
