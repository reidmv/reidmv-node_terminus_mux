# MUX Node Terminus

Multiplexes together node information from multiple other node terminii.

Multiplexes node information from multiple other node terminii. Configured using a file called $confdir/mux.conf. Format is HOCON. Should have a single key, 'terminii', set to a list of values. Each value should be the name of a valid node terminus. Example:

/etc/puppetlabs/puppet/mux.conf:
```
terminii: [
  exec,
  console,
]
```

The first terminus listed will determine a node's environment. Parameters and classes may be supplied by any terminus, with all such values being merged together. In the event of a conflict, terminii listed earlier in the list take precedence over those listed later.

## Configuration

1. Install the module
2. Create a `mux.conf` file per the description above
3. Enable by setting node\_terminus in puppet.conf to mux

        [master]
          node_terminus = mux
