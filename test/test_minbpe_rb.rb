# frozen_string_literal: true

require "test_helper"
require "byebug"

class TestMinbpeRb < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::MinbpeRb::VERSION
  end
end

TEST_STRINGS = [
  "", # empty string
  "?", # single character
  "hello world!!!?", # simple string
  "hello world!!!? (안녕하세요!) lol123 😉", # fun small string
]

LLAMA_TEXT = <<-EOS
<|endoftext|>The llama (/ˈlɑːmə/; Spanish pronunciation: [ˈʎama] or [ˈʝama]) (Lama glama) is a domesticated South American camelid, widely used as a meat and pack animal by Andean cultures since the pre-Columbian era.
Llamas are social animals and live with others as a herd. Their wool is soft and contains only a small amount of lanolin.[2] Llamas can learn simple tasks after a few repetitions. When using a pack, they can carry about 25 to 30% of their body weight for 8 to 13 km (5–8 miles).[3] The name llama (in the past also spelled "lama" or "glama") was adopted by European settlers from native Peruvians.[4]
The ancestors of llamas are thought to have originated from the Great Plains of North America about 40 million years ago, and subsequently migrated to South America about three million years ago during the Great American Interchange. By the end of the last ice age (10,000–12,000 years ago), camelids were extinct in North America.[3] As of 2007, there were over seven million llamas and alpacas in South America and over 158,000 llamas and 100,000 alpacas, descended from progenitors imported late in the 20th century, in the United States and Canada.[5]
<|fim_prefix|>In Aymara mythology, llamas are important beings. The Heavenly Llama is said to drink water from the ocean and urinates as it rains.[6] According to Aymara eschatology,<|fim_suffix|> where they come from at the end of time.[6]<|fim_middle|> llamas will return to the water springs and ponds<|endofprompt|>
EOS

class TestBasicTokenizer < Minitest::Test
  def test_encode_decode_identity
    TEST_STRINGS.each do |str|
      basic_tokenizer = BasicTokenizer.new
      encoded = basic_tokenizer.encode(str)
      decoded = basic_tokenizer.decode(encoded)
      assert str == decoded
    end
  end

  def test_taylor_swift_encode_decode_identity
    s = File.read("test/fixtures/taylorswift.txt")
    basic_tokenizer = BasicTokenizer.new
    encoded = basic_tokenizer.encode(s)
    decoded = basic_tokenizer.decode(encoded)
    assert s == decoded
  end

  def test_wikipedia_example
    basic_tokenizer = BasicTokenizer.new
    text = "aaabdaaabac"
    basic_tokenizer.train(text, 256 + 3)
    ids = basic_tokenizer.encode(text)
    assert ids == [258, 100, 258, 97, 99]
    assert basic_tokenizer.decode(basic_tokenizer.encode(text)) == text
  end

  def test_regex_encode_decode_identity
    TEST_STRINGS.each do |str|
      regex_tokenizer = RegexTokenizer.new
      encoded = regex_tokenizer.encode(str)
      decoded = regex_tokenizer.decode(encoded)
      assert str == decoded
    end
  end

  def test_regex_taylor_swift_encode_decode_identity
    s = File.read("test/fixtures/taylorswift.txt")
    regex_tokenizer = RegexTokenizer.new
    encoded = regex_tokenizer.encode(s)
    decoded = regex_tokenizer.decode(encoded)
    assert s == decoded
  end

  def test_regex_wikipedia_example
    regex_tokenizer = RegexTokenizer.new
    text = "aaabdaaabac"
    regex_tokenizer.train(text, 256 + 3)
    ids = regex_tokenizer.encode(text)
    assert ids == [258, 100, 258, 97, 99]
    assert regex_tokenizer.decode(regex_tokenizer.encode(text)) == text
  end

  def test_regex_special_tokens_none
  end

  def test_regex_special_tokens
    special_tokens = {
      "<|endoftext|>" => 100257,
      "<|fim_prefix|>" => 100258,
      "<|fim_middle|>" => 100259,
      "<|fim_suffix|>" => 100260,
      "<|endofprompt|>" => 100276
    }

    text = LLAMA_TEXT
    regex_tokenizer = RegexTokenizer.new
    regex_tokenizer.train(text, 256 + 64)
    regex_tokenizer.register_special_tokens(special_tokens)

    assert regex_tokenizer.decode(regex_tokenizer.encode(text, allowed_special: "all")) == text

    ids = regex_tokenizer.encode(text, allowed_special: "all")

    # TODO implement save/load
    regex_tokenizer.save("test_tokenizer_tmp")
    regex_tokenizer = RegexTokenizer.new
    regex_tokenizer.load("test_tokenizer_tmp.model")
    assert regex_tokenizer.decode(ids) == text
    assert regex_tokenizer.decode(regex_tokenizer.encode(text, allowed_special: "all")) == text
    assert regex_tokenizer.encode(text, allowed_special: "all") == ids
    ["test_tokenizer_tmp.model", "test_tokenizer_tmp.vocab"].each do |path|
      FileUtils.rm(path)
    end

  end
end
