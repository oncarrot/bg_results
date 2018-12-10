module BgResults
  class Batch
    def initialize bid
      @bid = bid
      @key = "RESULTS-#{@bid}"
    end

    def results
      data, _ = BgResults.redis do |conn|
        conn.multi do
          conn.hgetall @key
          conn.del @key
        end
      end
      data
    end

    def results_in_batches
      count = 100
      cursor = 0
      loop do
        cursor, data = scan cursor, count
        yield data.to_h
        break if cursor == 0
      end
      BgResults.redis do |conn|
        conn.del @key
      end
    end

    def results_each
      return unless block_given?
      results_in_batches do |batch|
        batch.each do |jid, res|
          yield jid, res
        end
      end
    end

  private
    def scan cursor, count
      new_cursor, data = BgResults.redis do |conn|
        conn.hscan @key, cursor, count: count
      end
      [new_cursor.to_i, data]
    end
  end
end