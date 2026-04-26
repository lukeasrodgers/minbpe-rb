class Tokenizer
  # https://stackoverflow.com/questions/56204309/how-to-remove-control-characters-in-ruby
  # Karpathy cribbed from SO so I guess I can too
  CONTROL_CHARS_REGEXP = /\e\[[^\x40-\x7E]*[\x40-\x7E]/

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
    model_file = file_prefix + ".model"
    File.open(model_file, "w") do |f|
      f.write("minbpe v1\n")
      f.write("#{@pattern}\n")
      f.write("#{@special_tokens.size}\n")
      @special_tokens.each { |k, v| f.write("#{k} #{v}\n")}
      @merges.keys.each { |k, v| f.write("#{k} #{v}\n")}
    end

    vocab_file = file_prefix + ".vocab"
    inverted_merges = @merges.invert
    File.open(vocab_file, "w") do |f|
      @vocab.each do |idx, token|
        s = render_token(token)
        if inverted_merges.key?(idx)
          idx0, idx1 = inverted_merges[idx]
          s0 = render_token(@vocab[idx0])
          s1 = render_token(@vocab[idx1])
          f.write("[#{s0}][#{s1}] -> [#{s}] #{idx}\n")
        else
          f.write("[#{s}] #{idx}\n")
        end
      end
    end
  end

  def load(model_file)
    raise "Model file should end with '.model'" unless model_file.end_with?(".model")

    merges = {}
    special_tokens = {}
    idx = 256

    File.open(model_file) do |f|
      version = f.readline.strip
      raise "unexpected version: #{version}" unless version == "minbpe v1"

      # TODO need to compile pattern
      @pattern = Regexp.new(f.readline.strip)
      num_special = f.readline.strip.to_i

      num_special.times do 
        special, special_idx = f.readline.strip.split
        special_tokens[special] = special_idx.to_i
      end

      f.readlines.each do |line|
        idx1, idx2 = line.split.map(&:to_i)
        key = [idx1, idx2]
        merges[key] = idx
        idx += 1
      end
    end
    @merges = merges
    @special_tokens = special_tokens
    @vocab = build_vocab
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

  def render_token(t)
    s = t.scrub
    replace_control_chars(s)
  end

  def replace_control_chars(s)
    # obviously not compatible with python minbpe, don't care
    s.gsub(CONTROL_CHARS_REGEXP, "WAT")
  end
end
