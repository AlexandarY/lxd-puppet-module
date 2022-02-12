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