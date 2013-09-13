#!/usr/bin/env ruby
$stdout.sync = true

# Reports the following MP statistics : user, nice, sys, iowait, irq, soft, steal, idle, intrps
#
# Compatibility
# -------------
# Requires the mpstat command, usually provided by the sysstat package.


require "rubygems"
require "bundler/setup"
require "newrelic_plugin"

#
#
# NOTE: Please add the following lines to your Gemfile:
#     gem "newrelic_plugin", git: "git@github.com:newrelic-platform/newrelic_plugin.git"
#
#
# Note: You must have a config/newrelic_plugin.yml file that
#       contains the following information in order to use
#       this Gem:
#
#       newrelic:
#         # Update with your New Relic account license key:
#         license_key: 'put_your_license_key_here'
#         # Set to '1' for verbose output, remove for normal output.
#         # All output goes to stdout/stderr.
#         verbose: 1
#       agents:
#         mpstat:
#            # The command used to display MP statistics
#            command: mpstat
#            # Report current usage as the average over this many seconds.
#            interval: 5

module MpstatAgent

  class Agent < NewRelic::Plugin::Agent::Base

    agent_guid   "com.railsware.mpstat"
    agent_config_options :command, :interval
    agent_version '0.0.2'
    agent_human_labels("Mpstat") { `hostname` }


    def poll_cycle
      # Using the second reading- avg since previous check
      output = stat_output
      values,result = parse_values(output), {}
      report_metric("mpstat/user", "%", values[:usr])
      report_metric("mpstat/sys", "%", values[:sys])
      report_metric("mpstat/wait", "%", values[:wt])
      report_metric("mpstat/idle", "%", values[:idl])
      report_metric("mpstat/intrps", "instr/sec", values[:intr])
    rescue Exception => e
      raise "Couldn't parse output. Make sure you have mpstat installed. #{e}"
    end


    private

    def stat_output()
      @command = command || 'mpstat'
      @interval = interval || 5
      stat_command = "#{command} #{interval} 2"
      `#{stat_command}`
    end

    def parse_values(output)
      # Expected output format:
      # SET minf mjf xcal  intr ithr  csw icsw migr smtx  srw syscl  usr sys  wt idl sze
      #  0 2650   0 6632 24717 5965 26033  441 1281 11458    2 41122    4  10   0  86  24

      # take the format fields
      format=output.split("\n").first.downcase.split

      # take all the stat fields
      raw_stats=output.split("\n").last.split

      stats={}
      format.each_with_index { |field,i| stats[ format[i].to_sym ]=raw_stats[i] }
      stats
    end

  end


  NewRelic::Plugin::Setup.install_agent :mpstat, MpstatAgent

  #
  # Launch the agent (never returns)
  #
  NewRelic::Plugin::Run.setup_and_run

end
