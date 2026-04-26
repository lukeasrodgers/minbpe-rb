#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "fileutils"

$LOAD_PATH.unshift(File.join(__dir__, "../lib"))
require "minbpe_rb"

ENCODE_DECODE_RUNS = 5
TRAINING_RUNS      = 3
TRAINING_VOCAB_SIZES = [256 + 64, 512].freeze
FIXTURE_PATH = File.join(__dir__, "../test/fixtures/taylorswift.txt")
RESULTS_DIR  = File.join(__dir__, "results")

SPECIAL_TOKENS = {
  "<|endoftext|>"   => 100257,
  "<|fim_prefix|>"  => 100258,
  "<|fim_middle|>"  => 100259,
  "<|fim_suffix|>"  => 100260,
  "<|endofprompt|>" => 100276,
}.freeze

def bench(label, runs)
  times = runs.times.map do
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0
  end
  min  = times.min
  max  = times.max
  mean = times.sum / times.size
  puts "  %-30s  min=%6.3fs  mean=%6.3fs  max=%6.3fs" % [label, min, mean, max]
  { label: label, runs: runs, times_s: times, min_s: min, mean_s: mean, max_s: max }
end

fixture = File.read(FIXTURE_PATH)

# --- Encode/decode setup ---

default_vocab_size = TRAINING_VOCAB_SIZES.first
puts "Training RegexTokenizer for encode/decode fixtures (vocab_size=#{default_vocab_size})..."
trained = RegexTokenizer.new
trained.train(fixture, default_vocab_size)
trained.register_special_tokens(SPECIAL_TOKENS)
puts "Done.\n\n"

plain_text   = fixture * 3
special_text = (+"").tap { |s| fixture.chars.each_slice(500) { |c| s << c.join << "<|endoftext|>" } } * 3
plain_ids    = trained.encode(plain_text)
special_ids  = trained.encode(special_text, allowed_special: "all")

puts "Inputs:"
puts "  plain:        #{plain_text.bytesize} bytes / #{plain_ids.size} tokens"
puts "  with special: #{special_text.bytesize} bytes / #{special_ids.size} tokens"
puts

results = []

# --- Encode / Decode ---

puts "=== Encode / Decode (#{ENCODE_DECODE_RUNS} runs) ==="
results << bench("encode:plain",          ENCODE_DECODE_RUNS) { trained.encode(plain_text) }
results << bench("encode:special_tokens", ENCODE_DECODE_RUNS) { trained.encode(special_text, allowed_special: "all") }
results << bench("decode:plain",          ENCODE_DECODE_RUNS) { trained.decode(plain_ids) }
results << bench("decode:special_tokens", ENCODE_DECODE_RUNS) { trained.decode(special_ids) }

# --- Training ---

puts "\n=== Training (#{TRAINING_RUNS} runs) ==="
TRAINING_VOCAB_SIZES.each do |vocab_size|
  results << bench("train:#{vocab_size}", TRAINING_RUNS) { RegexTokenizer.new.train(fixture, vocab_size) }
end

# --- Save ---

FileUtils.mkdir_p(RESULTS_DIR)
git_sha = `git -C #{File.dirname(__dir__)} rev-parse --short HEAD 2>/dev/null`.strip

output = {
  metadata: {
    timestamp:           Time.now.strftime("%Y-%m-%dT%H:%M:%S%z"),
    ruby_version:        RUBY_VERSION,
    ruby_platform:       RUBY_PLATFORM,
    git_sha:             git_sha.empty? ? nil : git_sha,
    fixture_bytes:       fixture.bytesize,
    plain_text_bytes:    plain_text.bytesize,
    plain_token_count:   plain_ids.size,
    special_text_bytes:  special_text.bytesize,
    special_token_count: special_ids.size,
  },
  results: results,
}

output_path = File.join(RESULTS_DIR, "#{Time.now.strftime("%Y%m%d_%H%M%S")}.json")
File.write(output_path, JSON.pretty_generate(output))
puts "\nSaved: #{output_path}"
