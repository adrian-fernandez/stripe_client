module QueryResultByMonth
  # Returns hash:
  #               month(int): {
  #                             year(int): {
  #                               total_amount(int), num_charges(int), total_transfers(int), num_transfers(int),
  #                               diff: {
  #                                 total_amount(int), num_charges(int), total_transfers(int), num_transfers(int)
  #                               }
  #                             }
  #                           }
  #               years(array<int>)
  #
  # => total_amount: Avg incoming amount in month
  # => num_charges: Number of charges in month
  # => total_transfers: Avg outcoming amount in month
  # => num_transfers: Number of transfers in month
  # => diff: Differente between current year and previous year
  def self.query(user_id)
    result = QueryResultByMonth.query_charges(user_id, {})
    result = QueryResultByMonth.query_transfers(user_id, result)

    years = result.values.map(&:keys).flatten.uniq

    fields_to_sum = [:total_amount, :num_charges, :total_transfers, :num_transfers]
    result_totals = {}

    result.keys.each do |month|
      result_totals[month] = {}
      fields_to_sum.each do |field|
        result_totals[month][field] = result[month].values.inject(0) {|sum,hash| (sum || 0) + (hash[field] || 0)}
      end
    end

    result = QueryResultByMonth.merge_result_partial_with_total(result, result_totals)

    result.keys.each do |month|
      years.each do |year|
        unless year = result.keys.first
          result[month][year][:diff] = {}
          fields_to_sum.each do |field|
            result[month][year][:diff][field] = result[month][year][field] - result[month][year - 1][field]
          end
        end
      end
    end

    result[:years] = years
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
    # fakeresult
  end

  private

  def self.query_charges(user_id, result)
    sql = %{
      SELECT COUNT(id) as count,
             data ->> 'month' AS month,
             data ->> 'year' AS year, 
             SUM(CAST(data ->> 'amount' AS integer)) AS total,
             SUM(CAST(data ->> 'amount_refunded' AS integer)) AS total_refunded
      FROM charges
      WHERE user_id = #{user_id}
            AND data ->> 'paid' = 'true'
      GROUP BY month, year
      ORDER BY year, month
    }.gsub(/\s+/, " ").strip

    data = ActiveRecord::Base.connection.execute(sql)
    return result if data.count.zero?

    data.each do |elem|
      unless elem['month'].nil?
        result[elem['month'].to_i] ||= {}
        result[elem['month'].to_i][elem['year'].to_i] ||= {}
        result[elem['month'].to_i][elem['year'].to_i][:total_amount] = elem['total'].to_i - elem['total_refunded'].to_i
        result[elem['month'].to_i][elem['year'].to_i][:num_charges] = elem['count'].to_i
      end
    end

    result
  end

  def self.query_transfers(user_id, result)
    sql = %{
      SELECT COUNT(id) as count,
             data ->> 'month' AS month,
             data ->> 'year' AS year, 
             SUM(CAST(data ->> 'amount' AS integer)) AS total,
             SUM(CAST(data ->> 'amount_reversed' AS integer)) AS total_reversed
      FROM transfers
      WHERE user_id = #{user_id}
      GROUP BY month, year
      ORDER BY year, month
    }.gsub(/\s+/, " ").strip

    data = ActiveRecord::Base.connection.execute(sql)
    return result if data.count.zero?

    data.each do |elem|
      unless elem['month'].nil?
        result[elem['month'].to_i] ||= {}
        result[elem['month'].to_i][elem['year'].to_i] ||= {}
        result[elem['month'].to_i][elem['year'].to_i][:total_transfers] = elem['total'].to_i - elem['total_reversed'].to_i
        result[elem['month'].to_i][elem['year'].to_i][:num_transfers] = elem['count'].to_i
      end
    end

    result
  end

  def self.merge_result_partial_with_total(partial_res, total_res)
    partial_res.keys.each do |k|
      total_res.fetch(k, {}).keys.each do |k_total|
        partial_res[k][k_total] = total_res[k][k_total]
      end
    end

    partial_res
  end
end