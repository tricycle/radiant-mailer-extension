require File.dirname(__FILE__) + '/../spec_helper'
require 'hpricot'

describe MailerPage do
  
  dataset :home_page
  
  context 'when recipients are specified as a hash' do
    before(:each) do
      create_page 'mailer', :class_name => MailerPage.name do
        create_page_part 'config', :content =>  <<-EOS
mailers:
  general-enquiry-form:
    subject: Online enquiry from spec
    from: noreply@example.com
    redirect_to: /Content_Common/pg-kennebunkport-maine-hotel-inn-enquiries-thankyou.seo
    recipient_list:
      'Foo enquiry': 'foo@example.com'
      'Bar enquiry': 'bar@example.com'
      'Baz application': 'baz@example.com'
    required_fields:
      - first-name
      - last-name
      - email: as_email
      - phone
      - city
      - country
      - zip-code
EOS
      end
    end
  
    describe '<r:mailer:selectrecipient>' do
          
      it "should render each recipent without necessarily preserving order" do
        # pages('mailer').should render('<r:mailer:form name="general-enquiry-form"><r:mailer:selectrecipient /></r:mailer:form>').matching(
        #   /<select name="mailer\[recipient_choice\]".*?>.*</)
        expected = ['Foo enquiry', 'Bar enquiry', 'Baz application']
        doc = Hpricot(pages(:mailer).send(:parse, '<r:mailer:form name="general-enquiry-form"><r:mailer:selectrecipient /></r:mailer:form>'))
        (doc/"form/select/option").each{|option|
          expected.should be_member(option['value'])
          expected.should be_member(option.inner_html)
        }
      end
      
      it "should be able to use recipient list to send mail" do
        page = pages(:mailer)
        page.instance_variable_set('@form_data', {:recipient_choice => 'Baz application'})
        form_conf = YAML.load(page_parts(:config).content)['mailers']['general-enquiry-form'].symbolize_keys
        page.instance_variable_set('@form_conf', form_conf)
        page.instance_variable_set('@form_name', 'general-enquiry-form')
        page.send(:recipients).should == ['baz@example.com']
        ActionMailer::Base.should_receive(:deliver_generic_mailer).with(hash_including(:recipients => ['baz@example.com']))
        page.send(:send_mail)
      end
      
    end
  end
  
  context 'when recipients are specified as an array of one element hashes' do
    before(:each) do
      create_page 'mailer', :class_name => MailerPage.name do
        create_page_part 'config', :content =>  <<-EOS
mailers:
  general-enquiry-form:
    subject: Online enquiry from spec
    from: noreply@example.com
    redirect_to: /Content_Common/pg-kennebunkport-maine-hotel-inn-enquiries-thankyou.seo
    recipient_list:
      - 'Foo enquiry': 'foo@example.com'
      - 'Bar enquiry': 'bar@example.com'
      - 'Baz application': 'baz@example.com'
    required_fields:
      - first-name
      - last-name
      - email: as_email
      - phone
      - city
      - country
      - zip-code
EOS
      end
    end
  
    describe '<r:mailer:selectrecipient>' do
          
      it "should render each recipent in order" do
        # pages('mailer').should render('<r:mailer:form name="general-enquiry-form"><r:mailer:selectrecipient /></r:mailer:form>').matching(
        #   /<select name="mailer\[recipient_choice\]".*?>.*</)
        doc = Hpricot(pages(:mailer).send(:parse, '<r:mailer:form name="general-enquiry-form"><r:mailer:selectrecipient /></r:mailer:form>'))
        
        (doc.at("form > select > option:nth(0)")['value']).should == 'Foo enquiry'
        (doc.at("form > select > option:nth(0)").inner_html).should == 'Foo enquiry'
        
        (doc.at("form > select > option:nth(1)")['value']).should == 'Bar enquiry'
        (doc.at("form > select > option:nth(1)").inner_html).should == 'Bar enquiry'
        
        (doc.at("form > select > option:nth(2)")['value']).should == 'Baz application'
        (doc.at("form > select > option:nth(2)").inner_html).should == 'Baz application'
        
      end
      
      it "should be able to use recipient list to send mail" do
        page = pages(:mailer)
        page.instance_variable_set('@form_data',
          {:recipient_choice => 'Baz application'})
        form_conf = YAML.load(page_parts(:config).content)['mailers']['general-enquiry-form'].symbolize_keys
        page.instance_variable_set('@form_conf', form_conf)
        page.instance_variable_set('@form_name', 'general-enquiry-form')
        page.send(:recipients).should == ['baz@example.com']
        ActionMailer::Base.should_receive(:deliver_generic_mailer).with(hash_including(:recipients => ['baz@example.com']))
        page.send(:send_mail)
      end
      
    end
  end
  
end