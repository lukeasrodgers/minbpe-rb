class BasicTokenizer < Tokenizer
  def decode(ids)
    ids.map{@vocab[_1]}.join("").force_encoding("utf-8")
  end

  def encode(text)
    ids = text.bytes
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

  def train(text, vocab_size, verbose: false)
    raise ArgumentError unless vocab_size >= 256
    num_merges = vocab_size - 256

    ids = text.bytes

    merges = {}
    a = (0..255).to_a
    vocab = a.zip(a.map {[_1].pack("C*")}).to_h
    num_merges.times do |i|
      stats = get_stats(ids)
      pair = stats.max_by{|k, v| v}[0]
      idx = 256 + i 
      ids = merge(ids, pair, idx)
      merges[pair] = idx
      vocab[idx] = vocab[pair[0]] + vocab[pair[1]]
      if verbose
        puts "merge #{i+1}/#{num_merges}: #{pair} -> #{idx} (#{vocab[idx]}) had #{stats[pair]} occurrences"
      end
    end

    @merges = merges
    @vocab = vocab
  end
end
