require "intacct/version"
require 'net/http'
require 'nokogiri'
require "intacct/base"
require "intacct/customer"
require "intacct/vendor"

class Object
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end

  def present?
    !blank?
  end
end

module Intacct
  extend self

  attr_accessor :xml_sender_id, :xml_password,
    :app_user_id, :app_company_id, :app_password

  def setup
    yield self
  end
end
