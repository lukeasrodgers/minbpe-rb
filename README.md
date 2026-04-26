# minbpe-rb

Minimal Byte Pair Encoding implementation in Ruby.

This is a fairly close port of Andrej Karpathy's [minbpe](https://github.com/karpathy/minbpe/) from python to ruby.

- it is not "production grade"
- I did it as a learning project
- its tests pass, but I suspect there are some bugs, esp in the model load/save code, some parts of which I specifically skipped over

Benchmarking code was written with assistance from claude, all other code written by me.

## Installation

Add this line to your application's Gemfile:

```ruby
jk don't add this to your application
```

## Usage

```sh
bundle exec rake test
bundle exec rake bench
```

## Contributing

You can file bug reports and PRs but I will probably ignore them, no offense.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Benchmarking

Part of the reason I did this was to understand the original code and specifically Karpathy's claim in his [intro to nanochat](https://github.com/karpathy/nanochat/discussions/1) that the python code was "way too slow".

Turns out this (entirely unoptimized) ruby version is even slower.

From a 2020 mac mini M1.

First, the python code:

```sh
➜  minbpe git:(master) uname -a
Darwin Macmini 24.6.0 Darwin Kernel Version 24.6.0: Mon Jul 14 11:30:34 PDT 2025; root:xnu-11417.140.69~1/RELEASE_ARM64_T8103 arm64
➜  minbpe git:(master) uv run bench/benchmark.py
Training RegexTokenizer for encode/decode fixtures (vocab_size=320)...
Done.

Inputs:
  plain:        557304 bytes / 374538 tokens
  with special: 571812 bytes / 376149 tokens

=== Encode / Decode (5 runs) ===
  encode:plain                    min= 0.511s  mean= 0.532s  max= 0.570s
  encode:special_tokens           min= 0.517s  mean= 0.528s  max= 0.554s
  decode:plain                    min= 0.024s  mean= 0.026s  max= 0.033s
  decode:special_tokens           min= 0.025s  mean= 0.028s  max= 0.032s

=== Training (3 runs) ===
  train:320                       min= 2.506s  mean= 2.521s  max= 2.550s
  train:512                       min= 8.363s  mean= 8.374s  max= 8.392s

Saved: /Users/luke/code/minbpe/bench/results/20260426_124113.json
➜  minbpe git:(master)
```

Now, this ruby code:

```sh
➜  minbpe-rb git:(main) ✗ bundle exec rake bench
Training RegexTokenizer for encode/decode fixtures (vocab_size=320)...
Done.

Inputs:
  plain:        557304 bytes / 374628 tokens
  with special: 571812 bytes / 387417 tokens

=== Encode / Decode (5 runs) ===
  encode:plain                    min= 1.034s  mean= 1.049s  max= 1.067s
  encode:special_tokens           min= 1.046s  mean= 1.054s  max= 1.063s
  decode:plain                    min= 0.035s  mean= 0.035s  max= 0.037s
  decode:special_tokens           min= 0.036s  mean= 0.036s  max= 0.038s

=== Training (3 runs) ===
  train:320                       min= 5.722s  mean= 5.883s  max= 5.982s
  train:512                       min=16.642s  mean=16.707s  max=16.805s
```

As you can see, the ruby code is roughly 2x slower. This could be because of errors in my implementation, or maybe just runtime differences.
