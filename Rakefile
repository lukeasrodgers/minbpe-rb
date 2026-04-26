# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/test_*.rb"]
end

task default: :test

desc "Run benchmarks (optional: VOCAB_SIZE=256)"
task :bench do
  exec "bundle exec ruby bench/benchmark.rb #{ENV["VOCAB_SIZE"]}"
end
