#!/usr/bin/env jruby

require 'securerandom'
require 'fileutils'
require 'net/http'
require 'json'

$LOAD_PATH << File.dirname(__FILE__)
require 'update_simulator'

UPDATE_THREADS = 2
UPDATES_PER_THREAD = 50


def show_usage
  raise "Usage: simulator.rb <output_dir> <aspace backend URL>"
end

def main
  output_dir = ARGV.fetch(0) { show_usage }
  backend_url = ARGV.fetch(1) { show_usage }

  updates_dir = File.join(output_dir, "updates")

  FileUtils.mkdir_p(updates_dir)

  File.open(File.join(File.dirname(__FILE__), "inputs/records_to_update.txt")) do |urls|
    updates = UpdateSimulator.new(:thread_count => UPDATE_THREADS,
                                  :updates_per_thread => UPDATES_PER_THREAD,
                                  :urls => urls,
                                  :output_dir => updates_dir,
                                  :aspace_backend_url => backend_url).run
    updates.join
  end
end


main
