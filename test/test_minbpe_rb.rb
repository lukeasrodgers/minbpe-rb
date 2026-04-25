# frozen_string_literal: true

require "test_helper"
require "byebug"

class TestMinbpeRb < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::MinbpeRb::VERSION
  end

  def test_encode_decode_identity
    test_strings = [
      "", # empty string
      "?", # single character
      "hello world!!!?", # simple string
      "hello world!!!? (안녕하세요!) lol123 😉", # fun small string
    ]
    test_strings.each do |str|
      basic_tokenizer = BasicTokenizer.new
      encoded = basic_tokenizer.encode(str)
      decoded = basic_tokenizer.decode(encoded)
      assert str == decoded
    end
  end

  def test_wikipedia_example
    basic_tokenizer = BasicTokenizer.new
    text = "aaabdaaabac"
    basic_tokenizer.train(text, 256 + 3)
    ids = basic_tokenizer.encode(text)
    assert ids == [258, 100, 258, 97, 99]
    assert basic_tokenizer.decode(basic_tokenizer.encode(text)) == text
  end
end
