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

    fakeresult = {12=>{
                        2014=>{
                                :total_amount=>7022, :num_charges=>2, :total_transfers=>6500, :num_transfers=>4,
                              },
                        2015=>{
                                :total_amount=>10022, :num_charges=>3, :total_transfers=>4000, :num_transfers=>2,
                                :diff=>{
                                  :total_amount=>3000, :num_charges=>1, :total_transfers=>-1500, :num_transfers=>-2
                                }
                              },
                        2016=>{
                                :total_amount=>6022, :num_charges=>5, :total_transfers=>6000, :num_transfers=>2,
                                :diff=>{
                                  :total_amount=>-4000, :num_charges=>2, :total_transfers=>2000, :num_transfers=>0
                                }
                              },
                        :total_amount=>23066, :num_charges=>10, :total_transfers=>18500, :num_transfers=>8
                      },
                  11=>{
                        2014=>{
                                :total_amount=>7000, :num_charges=>5, :total_transfers=>8000, :num_transfers=>3,
                              },
                        2015=>{
                                :total_amount=>10000, :num_charges=>8, :total_transfers=>3000, :num_transfers=>2,
                                :diff=>{
                                  :total_amount=>3000, :num_charges=>3, :total_transfers=>-5000, :num_transfers=>-1
                                }
                              },
                        2016=>{
                                :total_amount=>6000, :num_charges=>2, :total_transfers=>5000, :num_transfers=>1,
                                :diff=>{
                                  :total_amount=>-4000, :num_charges=>-6, :total_transfers=>2000, :num_transfers=>-1
                                }
                              },
                        :total_amount=>23000, :num_charges=>15, :total_transfers=>16000, :num_transfers=>6
                      },
                      :years=>[2014,2015,2016]}

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
      result[month][:volatility] = result[month][:total_transfers] * 100.0 / result[month][:total_amount]
    end

    result
  end
end