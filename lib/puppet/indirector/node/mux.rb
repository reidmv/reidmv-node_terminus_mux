require 'puppet/node'
require 'puppet/indirector/plain'
require 'hocon/config_factory'
require 'deep_merge'

class Puppet::Node::Mux < Puppet::Indirector::Plain
  desc "Multiplexes node information from multiple other node terminii."

  # Just return an empty node.
  def find(request)
    # Create a variable to hold the node object to be built
    node = nil

    # Note the originally set terminus class
    original_terminus = indirection.terminus_class

    begin
      environment = nil

      # The first terminus specified in the config takes precedence. Evaluate
      # the configured terminii in reverse order, overriding any conflicts with
      # the most recently evaluated terminus' values.
      mux = terminii.reverse.inject({}) do |memo,terminus_name|
        begin
          Puppet::Indirector::Indirection.instance(:node).terminus_class = terminus_name.to_sym
          found_node = Puppet::Indirector::Indirection.instance(:node).find(request.key, request.options)

          # Note the node's environment, if one was assigned. The environment
          # assigned by the highest-priority node terminus will be used for the
          # final node object's environment value.
          environment = found_node.environment if found_node.environment

          memo.deep_merge(found_node.to_data_hash)
        rescue Exception => e
          Puppet.err "Mux attempt to use \"#{terminus_name}\" node terminus has failed!"
          raise e
        end
      end

      node = Puppet::Node.from_data_hash(mux)
      node.environment = environment
    ensure
      # Restore the originally set terminus class
      indirection.terminus_class = original_terminus
    end

    # Return the mux-built node object
    node
  end

  def terminii
    config['terminii']
  end

  def strategy
    config['strategy'] || :merge
  end

  def config
    return @config if @config
    config_file = File.join(Puppet.settings[:confdir], 'mux.conf')
    @config = Hocon::ConfigFactory.parse_file(config_file).root.unwrapped
  end
end
