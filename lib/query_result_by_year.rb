module QueryResultByYear
  # Returns hash:
  #               month(int): {
  #                             total_amount(int), num_charges(int), total_transfers(int), num_transfers(int), volatility(float)
  #                           },
  #               years(array<int>)
  # => total_amount: Avg incoming amount in month
  # => num_charges: Number of charges in month
  # => total_transfers: Avg outcoming amount in month
  # => num_transfers: Number of transfers in month
  # => volatility: Percentage of outcomings over incoming
  def self.query(user_id, year)
    result = QueryResultByYear.query_charges(user_id, year, {})
    result = QueryResultByYear.query_transfers(user_id, year, result)
    result = QueryResultByYear.calculate_volatility(result)

    result
  end

  private

  def self.query_charges(user_id, year, result)
    sql = %{
      SELECT COUNT(id) as count,
           data ->> 'month' AS month,
           data ->> 'year' AS year,
           AVG(CAST(data ->> 'amount' AS integer)) AS total,
           AVG(CAST(data ->> 'amount_refunded' AS integer)) AS total_refunded
      FROM charges
      WHERE user_id = #{user_id}
            AND CAST(data ->> 'year' AS integer) = #{year}
            AND data ->> 'paid' = 'true'
      GROUP BY month, year
      ORDER BY month
    }.gsub(/\s+/, " ").strip

    data = ActiveRecord::Base.connection.execute(sql)
    return result if data.count.zero?

    data.each do |elem|
      unless elem['month'].nil?
        result[elem['month'].to_i] ||= {}
        result[elem['month'].to_i][:total_amount] = elem['total'].to_i - elem['total_refunded'].to_i
        result[elem['month'].to_i][:num_charges] = elem['count'].to_i
      end
    end

    result
  end

  def self.query_transfers(user_id, year, result)
    sql = %{
      SELECT COUNT(id) as count,
           data ->> 'month' AS month,
           data ->> 'year' AS year,
           AVG(CAST(data ->> 'amount' AS integer)) AS total,
           AVG(CAST(data ->> 'amount_reversed' AS integer)) AS total_reversed
      FROM transfers
      WHERE user_id = #{user_id}
            AND CAST(data ->> 'year' AS integer) = #{year}
      GROUP BY month, year
      ORDER BY month
    }.gsub(/\s+/, " ").strip

    data = ActiveRecord::Base.connection.execute(sql)
    return result if data.count.zero?

    data.each do |elem|
      unless elem['month'].nil?
        result[elem['month'].to_i] ||= {}
        result[elem['month'].to_i][:total_transfers] = elem['total'].to_i - elem['total_reversed'].to_i
        result[elem['month'].to_i][:num_transfers] = elem['count'].to_i
      end
    end

    result
  end

  def self.calculate_volatility(result)
    result.keys.each do |month|
      result[month][:volatility] = result[month].fetch(:total_transfers, 0) * 100.0 / result[month].fetch(:total_amount, 0)
    end

    result
  end
end