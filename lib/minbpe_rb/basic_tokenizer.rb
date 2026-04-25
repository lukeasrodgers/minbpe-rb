class BasicTokenizer < Tokenizer

  def train(text, vocab_size, verbose: false)
  end

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

end
