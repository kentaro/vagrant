require 'optparse'

require "vagrant"

require File.expand_path("../start_mixins", __FILE__)

module VagrantPlugins
  module CommandUp
    class Command < Vagrant.plugin("2", :command)
      include StartMixins

      def execute
        options = {}
        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant up [vm-name] [--[no-]provision] [--provider provider] [-h] [-- extra ssh args]"
          o.separator ""

          build_start_options(o, options)

          o.on("--provider provider", String,
               "Back the machine with a specific provider.") do |provider|
            options[:provider] = provider
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        # Parse out the extra args to send to SSH, which is everything
        # after the "--"
        ssh_args = ARGV.drop_while { |i| i != "--" }
        ssh_args = ssh_args[1..-1]
        options[:ssh_args] = ssh_args

        # If the remaining arguments ARE the SSH arguments, then just
        # clear it out. This happens because optparse returns what is
        # after the "--" as remaining ARGV, and Vagrant can think it is
        # a multi-vm name (wrong!)
        argv = [] if argv == ssh_args

        # Go over each VM and bring it up
        @logger.debug("'Up' each target VM...")
        with_target_vms(argv, :provider => options[:provider]) do |machine|
          @env.ui.info(I18n.t(
            "vagrant.commands.up.upping",
            :name => machine.name,
            :provider => machine.provider_name))
          machine.action(:up, options)
        end

        # Success, exit status 0
        0
      end
    end
  end
end
