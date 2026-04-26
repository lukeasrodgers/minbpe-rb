GPT2_SPLIT_PATTERN = /(?:[sdmt]|ll|ve|re)| ?\p{L}+| ?\p{N}+| ?[^\s\p{L}\p{N}]+|\s+(?!\S)|\s+/
GPT4_SPLIT_PATTERN = /(?i:[sdmt]|ll|ve|re)|[^\r\n\p{L}\p{N}]?+\p{L}+|\p{N}{1,3}| ?[^\s\p{L}\p{N}]++[\r\n]*|\s*[\r\n]|\s+(?!\S)|\s+/

class RegexTokenizer < Tokenizer
  def initialize(pattern: nil)
    super
    @pattern ||= GPT4_SPLIT_PATTERN
    # doesn't seem necessary?
    # @compiled_pattern = 
    @special_tokens = {}
    @inverse_special_tokens = {}
  end

  def train(text, vocab_size, verbose: false)
    raise ArgumentError unless vocab_size >= 256
    num_merges = vocab_size - 256

    text_chunks = text.scan(@pattern)
    ids = text_chunks.map(&:bytes)
    merges = {}
    a = (0..255).to_a
    vocab = a.zip(a.map {[_1].pack("C*")}).to_h

    num_merges.times do |i|
      stats = Hash.new(0)
      ids.each {|chunk_ids| get_stats(chunk_ids, counts: stats) }
      pair = stats.max_by{|k, v| v}[0]
      idx = 256 + i 
      ids = ids.map{|chunk_ids| merge(chunk_ids, pair, idx)}
      merges[pair] = idx
      vocab[idx] = vocab[pair[0]] + vocab[pair[1]]
      if verbose
        puts "merge #{i+1}/#{num_merges}: #{pair} -> #{idx} (#{vocab[idx]}) had #{stats[pair]} occurrences"
      end
    end
    @merges = merges
    @vocab = vocab
  end

  def decode(ids)
    part_bytes = []
    ids.each do |idx|
      if @vocab[idx]
        part_bytes << @vocab[idx]
      elsif @inverse_special_tokens[idx]
        # TODO force-encoding maybe not necessary
        part_bytes << @inverse_special_tokens[idx].dup.force_encoding("utf-8")
      else
        raise "Invalid token: #{idx}"
      end
    end
    part_bytes.join("").force_encoding("utf-8")
  end

  def encode(text, allowed_special: "none_raise")
    special = nil
    if allowed_special == "all"
      special = @special_tokens
    elsif allowed_special == "none"
      special = {}
    elsif allowed_special == "none_raise"
      special = {}
      raise "Found special token but `none` specified" if  @special_tokens.keys.any?{|t| text.include?(t) }
    elsif allowed_special.is_a?(Set)
      special = @special_tokens.select{|k, v| allowed_special.include?(k) }
    else
      raise "allowed_special=#{allowed_special} not understood"
    end

    return encode_ordinary(text) if special.none?

    special_pattern = "(" + special.keys.map{Regexp.escape(_1)}.join("|") + ")"
    special_chunks = text.split(special_pattern)

    ids = []

    special_chunks.each do |part|
      if special.key?(part)
        ids << special[part]
      else
        ids.concat(encode_ordinary(part))
      end
    end
    ids
  end

  def register_special_tokens(special_tokens)
    @special_tokens = special_tokens
    @inverse_special_tokens = special_tokens.invert
  end

  private

  def encode_ordinary(text)
    text_chunks = text.scan(@pattern)
    ids = []
    text_chunks.each do |chunk|
      chunk_bytes = chunk.bytes
      chunk_ids = encode_chunk(chunk_bytes)
      ids.concat(chunk_ids)
    end
    ids
  end

  # TODO very similar to BasicTokenizer, maybe can refactor?
  # @param text_bytes [Array<Integer>]
  def encode_chunk(text_bytes)
    ids = text_bytes
    while ids.size >= 2 do
      stats = get_stats(ids)
      pair = stats.min_by{|k, v| @merges[k] || Float::INFINITY}[0]
      if @merges[pair].nil?
        break
      end
      idx = @merges[pair]
      ids = merge(ids, pair, idx)
    end
    ids
  end
end
