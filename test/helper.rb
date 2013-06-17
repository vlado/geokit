# encoding: utf-8

begin
  require 'rubygems'
  require 'bundler'
  Bundler.setup
rescue LoadError => e
  puts "Error loading bundler (#{e.message}): \"gem install bundler\" for bundler support."
end

require 'test/unit'
require 'mocha/setup'
require 'net/http'

if ENV['COVERAGE']
  COVERAGE_THRESHOLD = 29
  require 'simplecov'
  require 'simplecov-rcov'
  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
  SimpleCov.start do
    add_filter '/test/'
    add_group 'lib', 'lib'
  end
  SimpleCov.at_exit do
    SimpleCov.result.format!
    percent = SimpleCov.result.covered_percent
    unless percent >= COVERAGE_THRESHOLD
      puts "Coverage must be above #{COVERAGE_THRESHOLD}%. It is #{"%.2f" % percent}%"
      Kernel.exit(1)
    end
  end
end

require File.join(File.dirname(__FILE__), "../lib/geokit.rb")


class MockSuccess < Net::HTTPSuccess #:nodoc: all
  def initialize
    @header = {}
  end
end

class MockFailure < Net::HTTPServiceUnavailable #:nodoc: all
  def initialize
    @header = {}
  end
end

# Base class for testing geocoders.
class BaseGeocoderTest < Test::Unit::TestCase #:nodoc: all

  class Geokit::Geocoders::TestGeocoder < Geokit::Geocoders::Geocoder
    def self.do_get(url)
      sleep(2)
    end
  end

  # Defines common test fixtures.
  def setup
    @address = 'San Francisco, CA'
    @full_address = '100 Spear St, San Francisco, CA, 94105-1522, US'
    @full_address_short_zip = '100 Spear St, San Francisco, CA, 94105, US'

    @latlng = Geokit::LatLng.new(37.7742, -122.417068)
    @success = Geokit::GeoLoc.new({:city=>"SAN FRANCISCO", :state=>"CA", :country_code=>"US", :lat=>@latlng.lat, :lng=>@latlng.lng})
    @success.success = true
  end

  def test_timeout_call_web_service
    url = "http://www.anything.com"
    Geokit::Geocoders::request_timeout = 1
    assert_nil Geokit::Geocoders::TestGeocoder.call_geocoder_service(url)
  end

  def test_successful_call_web_service
    url = "http://www.anything.com"
    Geokit::Geocoders::Geocoder.expects(:do_get).with(url).returns("SUCCESS")
    assert_equal "SUCCESS", Geokit::Geocoders::Geocoder.call_geocoder_service(url)
  end

  def test_find_geocoder_methods
    public_methods = Geokit::Geocoders::Geocoder.public_methods.map { |m| m.to_s }
    assert public_methods.include?("yahoo_geocoder")
    assert public_methods.include?("google_geocoder")
    assert public_methods.include?("ca_geocoder")
    assert public_methods.include?("us_geocoder")
    assert public_methods.include?("multi_geocoder")
    assert public_methods.include?("ip_geocoder")
  end
end
