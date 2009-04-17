require File.dirname(__FILE__) + '/spec_helper'

describe GoDaddyReseller::Domains do

  before(:each) do
  end

  it "decodes a sample check response correctly" do
    response = '<response c1TRID="reseller.0000000003"><result code="1000"/><resdata><check><domain name="example.com" avail="0" /><domain name="example.net" avail="0" /><domain name="example.org" avail="1"/><domain name="example.info" avail="-1" /><domain name="example.biz" avail="0" /><domain name="example.ws" avail="1" /><domain name="example.us" avail="1" /></check></resdata></response>'
    result = GoDaddyReseller::Connection.decode(response)
    answer = GoDaddyReseller::Domains.check_result_to_answer(result)
    answer.should == { 'example.com' => false, 'example.net' => false, 'example.org' => true, 'example.info' => :error, 'example.biz' => false, 'example.ws' => true, 'example.us' => true }
  end

  it "creates order xml correctly" do
    result = GoDaddyReseller::Connection.xml_encode_hash(
      :order => {
        :_attributes => { :roid => 1 },
        :shopper => {
          :_attributes => {
            :user => 'createNew',
            :pwd => 'password',
            :pwdhint => 'obvious',
            :email => 'jdoe@example.com',
            :firstname => 'John',
            :lastname => 'Doe',
            :phone => '+1.4805058857',
            :dbpuser => 'createNew',
            :dbppwd => 'password',
            :dbppwdhint => 'obvious',
            :dbpemail => 'jdoe@example.com'
          }  
        },
        :item => {
          :_attributes => {
            :productid => GoDaddyReseller::ProductTable::HASH['2 Year Domain New Registration .US'],
            :quantity => 1,
            :riid => 1
          },
          :domainRegistration => {
            :_attributes => {
              :sld => 'example',
              :tld => 'us',
              :period => 2
            },
            :nexus => {
              :_attributes => {
                :category => "citizen of US",
                :use => 'personal',
                :country => 'us'
              }
            },
            :ns => [ {:_attributes => {:name => 'ns1.example.com'}}, {:_attributes => {:name => 'ns2.example.com'}} ],
            :registrant => {
              :_attributes => {
                :fname => 'John',
                :lname => 'Doe',
                :org => 'Wild West Reseller',
                :email => 'jdoe@example.com',
                :sa1 => '14455 N. Hayden Rd.',
                :sa2 => 'Suite 219',
                :city => 'Scottsdale',
                :sp => 'Arizona',
                :pc => '85260',
                :cc => 'United States',
                :phone => '+1.4805058857',
                :fax => '+1.4808241499'
              }
            },
            :admin => {
              :_attributes => {
                :fname => 'Jane',
                :lname => 'Doe',
                :org => 'Wild West Reseller',
                :email => 'janed@example.com',
                :sa1 => '14455 N. Hayden Rd.',
                :sa2 => 'Suite 219',
                :city => 'Scottsdale',
                :sp => 'Arizona',
                :pc => '85260',
                :cc => 'United States',
                :phone => '+1.4805058857',
                :fax => '+1.4808241499'
              }
            },
            :billing => {
              :_attributes => {
                :fname => 'John',
                :lname => 'Doe',
                :org => 'Wild West Reseller',
                :email => 'jdoe@example.com',
                :sa1 => '14455 N. Hayden Rd.',
                :sa2 => 'Suite 219',
                :city => 'Scottsdale',
                :sp => 'Arizona',
                :pc => '85260',
                :cc => 'United States',
                :phone => '+1.4805058857',
                :fax => '+1.4808241499'
              }
            },
            :tech => {
              :_attributes => {
                :fname => 'John',
                :lname => 'Doe',
                :org => 'Wild West Reseller',
                :email => 'jdoe@example.com',
                :sa1 => '14455 N. Hayden Rd.',
                :sa2 => 'Suite 219',
                :city => 'Scottsdale',
                :sp => 'Arizona',
                :pc => '85260',
                :cc => 'United States',
                :phone => '+1.4805058857',
                :fax => '+1.4808241499'
              }
            }
          }
        }
      }
    )

    expected = '<?xml version="1.0"?><wapi clTRID="'+GoDaddyReseller::API.last_uid+'"><order roid="1"><shopper user="createNew" pwd="password"pwdhint="obvious" email="jdoe@example.com" firstname="John"lastname="Doe" phone="+1.4805058857" dbpuser="createNew"dbppwd="password" dbppwdhint="obvious"dbpemail="jdoe@example.com" /><item productid="350127" quantity="1" riid="1"><domainRegistration sld="example" tld="us"period="2"><nexus category="citizen of US" use="personal"country="us" /> <ns name="ns1.example.com" /> <ns name="ns2.example.com" /><registrant fname="John" lname="Doe" org="WildWest Reseller" email="jdoe@example.com" sa1="14455 N.Hayden Rd." sa2="Suite 219" city="Scottsdale" sp="Arizona"pc="85260" cc="United States" phone="+1.4805058857"fax="+1.4808241499" /><admin fname="Jane" lname="Doe" org="Wild WestReseller" email="janed@example.com" sa1="14455 N. HaydenRd." sa2="Suite 219" city="Scottsdale" sp="Arizona"pc="85260" cc="United States" phone="+1.4805058857"fax="+1.4808241499" /><billing fname="John" lname="Doe" org="WildWest Reseller" email="jdoe@example.com" sa1="14455 N.Hayden Rd." sa2="Suite 219" city="Scottsdale" sp="Arizona"pc="85260" cc="United States" phone="+1.4805058857"fax="+1.4808241499" /><tech fname="John" lname="Doe" org="Wild WestReseller" email="jdoe@example.com" sa1="14455 N. HaydenRd." sa2="Suite 219" city="Scottsdale" sp="Arizona"pc="85260" cc="United States" phone="+1.4805058857"fax="+1.4808241499" /></domainRegistration></item><item productid="377001" quantity="1" riid="2"duration="2"><domainByProxy sld="example" tld="us" /></item></order></wapi>'

    result.should == expected
  end

end