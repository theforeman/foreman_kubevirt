# frozen_string_literal: true

require 'rake/testtask'

# Tasks
namespace :foreman_kubevirt do
  namespace :example do
    desc 'Example Task'
    task task: :environment do
      # Task goes here
    end
  end
end

# Tests
namespace :test do
  desc 'Test ForemanKubevirt'
  Rake::TestTask.new(:foreman_kubevirt) do |t|
    test_dir = File.join(File.dirname(__FILE__), '../..', 'test')
    t.libs << ['test', test_dir]
    t.pattern = "#{test_dir}/**/*_test.rb"
    t.verbose = true
    t.warning = false
  end
end

namespace :foreman_kubevirt do
  task rubocop: :environment do
    begin
      require 'rubocop/rake_task'
      RuboCop::RakeTask.new(:rubocop_foreman_kubevirt) do |task|
        task.patterns = ["#{ForemanKubevirt::Engine.root}/app/**/*.rb",
                         "#{ForemanKubevirt::Engine.root}/lib/**/*.rb",
                         "#{ForemanKubevirt::Engine.root}/test/**/*.rb"]
      end
    rescue StandardError
      puts 'Rubocop not loaded.'
    end

    Rake::Task['rubocop_foreman_kubevirt'].invoke
  end
end

Rake::Task[:test].enhance ['test:foreman_kubevirt']

load 'tasks/jenkins.rake'
if Rake::Task.task_defined?(:'jenkins:unit')
  Rake::Task['jenkins:unit'].enhance ['test:foreman_kubevirt',
                                      'foreman_kubevirt:rubocop']
end
