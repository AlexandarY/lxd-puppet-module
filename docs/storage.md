# lxd::storage

This Puppet defined-type handles lxd storage create/update/delete.
The type is a wrapper for the `lxd_storage` type.

Exact parameters and what they mean can be found in [`REFERENCE.md`](../REFERENCE.md) under `lxd::storage` section.

## Examples for single node LXD server

### Create an LXD dir storage on a single node

```
lxd::storage { 'dir-storage':
  ensure      => present,
  driver      => 'dir',
  description => 'Managed by Puppet'
}
```

### Create an LXD dir storage on a single node, with some configration values.

```
lxd::storage { 'dir-storage':
  ensure      => present,
  driver      => 'dir',
  description => 'Managed by Puppet',
  config      => {
    'volume.size' => '5GB'
  }
}
```

### Create an LXD lvm storage on a single node.

```
lxd::storage { 'lvm-storage':
  ensure      => present,
  driver      => 'lvm',
  description => 'Managed by Puppet',
  source      => '/dev/sdb'
}
```

## Examples for an LXD cluster member

When setting up storage in an LXD cluster, things become more tricky. The manual process goes as this:

 1. Create the storage-pool on each LXD member via `--target` flag.
 2. Commit the storage-pool as `Created` by running the create command __without__ the `--target` flag.

This process also accepts some configuration variables during Step 1 and others on Step 2.

As such, it is expected that when running all the examples below you will first bring
each member's storage-pool into `Pending` state by running the puppet agent on each node.

Afterwards, on any of the members nodes, you need to run the puppet agent to bring
the storage-pool into a `Created` state.

### Create an LXD dir storage-pool in a cluster

```
lxd::storage { 'dir-storage':
  ensure      => present,
  driver      => 'dir',
  description => 'Managed by Puppet'
}
```

### Create an LXD lvm storage-pool in a cluster

```
lxd::storage { 'lvm-storage':
  ensure      => present,
  driver      => 'lvm',
  description => 'Managed by Puppet',
  source      => '/dev/sdb'
}
```

## Known issues & limitations

### Pool not defined on nodes: $node-name

Example error message: `returned 1: Error: Pool not defined on nodes: node02`

This error will occur when you are setting up a storage-pool in a clustered environment.
You have ran the storage creation on `node01` and then again ran puppet on the same node,
before you created the storage-pool on the other nodes.

To tackle this, run the `storage-pool` create on all cluster members, before running the agent again
to put the pool in Created stage.


### Removing a storage config value

If you have defined a `config` value that you want to remove, just excluding it from the config
has will not actually remove it from the server OR reset it to the default value.

Example:

```
# original storage
lxd::storage { 'default':
  ensure => present,
  driver => 'lvm',
  config => {
    'lvm.thinpool_name' => 'example'
  }
}

$ lxc storage get lvm.thinpool_name
example

# change storage
lxd::storage { 'default':
  ensure => present,
  driver => 'lvm',
  config => {}
}

$ lxc storage get lvm.thinpool_name
example
```

While this is inconvenient in some cases, it's implemented like this to avoid Puppet messing
up the storage-pool.
