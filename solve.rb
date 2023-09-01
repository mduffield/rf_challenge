require "json"
require "net/http"
require "uri"


class Challenger

  def initialize(base_url)
    @base_url = base_url
  end

  def run
    get_with_redirects(@base_url)
  end

  private

  def try_json?(body)
    body.include?("You should try JSON")
  end

  def with_json(url)
    url_parts = url.split("?")
    if url_parts.count > 1
      return "#{url_parts.first}.json?#{url_parts.last}"
    end
    "#{url}.json"
  end

  def try_with_json(body)
    json_body = JSON.parse(body)
    if json_body.fetch("message") == "This is not the end"
      url = json_body.fetch("follow")
      get_with_redirects(url)
    else
      puts json_body.inspect
    end
  end

  def get_with_redirects(url, limit = 3)
    raise ArgumentError, 'Too many redirects' if limit == 0

    puts url.inspect
    uri = URI.parse(url)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
   
    response = http.request(Net::HTTP::Get.new(uri.request_uri))

    case response
    when Net::HTTPSuccess
      puts "HTTP Status Code: #{response.code}"
      puts "Response Body:"
      puts response.body
      try_with_json(response.body)
    when Net::HTTPRedirection
      location = response['location']
      puts "Redirected to: #{location}"
      get_with_redirects(location, limit - 1)
    else
      puts "HTTP Request Failed with Status Code: #{response.code}"
      puts "HTTP Request Failed with Status Code: #{response.body}"
      get_with_redirects(with_json(url), limit -1) if try_json?(response.body)
    end
  end
end

base_url = "https://letsrevolutionizetesting.com/challenge"
challenger = Challenger.new(base_url)
challenger.run
