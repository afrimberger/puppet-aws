require 'rubygems'
require 'aws-sdk'
require "net/http"

module Facter::Util::AWSTags

  # Here we need to get server.id
  INSTANCE_HOST = '169.254.169.254'
  INSTANCE_ID_URL = '/latest/meta-data/instance-id'
  INSTANCE_REGION_URL = '/latest/meta-data/placement/availability-zone'

  def self.get_tags

    httpcall = Net::HTTP.new(INSTANCE_HOST)
    resp = httpcall.get2(INSTANCE_ID_URL)
    instance_id = resp.body

    resp = httpcall.get2(INSTANCE_REGION_URL)
    region = resp.body

    # Cut out availability zone marker.
    # For example if region == "us-east-1c" after cutting out it will be
    # "us-east-1"

    region = region[0..-2]

    # First we configure AWS sdk from amazon, region is
    # required if your instances are in other zone than the
    # gem's default one (us-east-1).

    creds = Aws::SharedCredentials.new
    ec2 = Aws::EC2::Resource.new(
        :credentials => creds,
        :region => region)

    tags = ec2.instance(instance_id).tags

    # tags is a hash so create a fact for each
    tags.each do | tag |
      symbol = "ec2_tag_#{tag.key.gsub(/\-|\//, '_')}".to_sym
      Facter.add(symbol) { setcode { tag.value } }
    end
  end

end 
