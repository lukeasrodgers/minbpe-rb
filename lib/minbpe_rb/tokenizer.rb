class Tokenizer
  def initialize(pattern: nil)
    # TODO maybe Hash.new(Float::INFINITY) ? or maybe only for encode lookup fallback if nil
    @merges = {}
    @special_tokens = {}
    @vocab = build_vocab
  end

  def train(text, vocab_size, verbose: false)
    raise NotImplementedError
  end

  def encode(text)
    raise NotImplementedError
  end

  def decode(ids)
    raise NotImplementedError
  end

  def save(file_prefix)
    # TODO
    raise NotImplementedError
  end

  def load(file_prefix)
    # TODO
    raise NotImplementedError
  end

  private

  def build_vocab
    a = (0..255).to_a
    vocab = a.zip(a.map {[_1].pack("C*")}).to_h
    @merges.each do |k, v|
      p0, p1 = k
      vocab[v] = vocab[p0] + vocab[p1]
    end
    @special_tokens.each do |k, v|
      vocab[v] = k.encode("utf-8") # TODO what is this?
    end
    @vocab = vocab
  end

  # TODO could rename, since it actually mutates stats, doesn't just "get" them
  # Given a list of integers, return a dictionary of counts of consecutive pairs
  # Example: [1, 2, 3, 1, 2] -> {(1, 2): 2, (2, 3): 1, (3, 1): 1}
  # Optionally allows to update an existing dictionary of counts
  def get_stats(ids, counts: Hash.new(0))
    arr = ids.zip(ids[1..])[0..-2]
    arr.each do |pair|
      counts[pair] += 1
    end
    counts
  end

  # In the list of integers (ids), replace all consecutive occurrences
  # of pair with the new integer token idx
  # Example: ids=[1, 2, 3, 1, 2], pair=(1, 2), idx=4 -> [4, 3, 4]
  def merge(ids, pair, idx)
    new_ids = []
    i = 0
    while i < ids.size do
      if ids[i] == pair[0] && (i < ids.size - 1) && (ids[i+1] == pair[1])
        new_ids << idx
        i += 2
      else
        new_ids << ids[i]
        i += 1
      end
    end
    new_ids
  end
end
