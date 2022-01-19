#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
# Copyright 2020 The LXD Puppet module Authors. All rights reserved.
#
# @summary Basic configuration of LXD
#
# @api private
#
class lxd::config{
    lxd_config { 'global_images.auto_update_interval':
        ensure => $lxd::auto_update_interval_ensure,
        config => ['images.auto_update_interval'],
        value  => $lxd::auto_update_interval,
    }

    lxd_config { 'global_core.https_address':
        ensure => $lxd::core_https_address_ensure,
        config => ['core.https_address'],
        value  => $lxd::core_https_address
    }

    lxd_config { 'global_core.trust_password':
        ensure => $lxd::core_trust_password_ensure,
        config => ['core.trust_password'],
        value  => $lxd::core_trust_password
    }
}
