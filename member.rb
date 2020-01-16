require 'http'

class Member
  def initialize(adress)
    @adress = adress
  end

  def tell(message)
    return http.puts "http://#{@adress}/sync?data=#{message}"
  end
