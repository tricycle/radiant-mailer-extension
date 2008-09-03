require File.dirname(__FILE__) + '/../spec_helper'

describe MailerPage do
  describe 'form validations' do
    before do
      @mp = MailerPage.new 
      @required_fields = []
      @form_conf = {:required_fields => @required_fields}
      @mp.stub!(:form_conf).and_return(@form_conf)
      @form_data = {}
      @mp.stub!(:form_data).and_return(@form_data)
    end
    
    describe 'no required fields' do
      it 'should be valid if field is empty' do
        @form_data['name'] = ''
        @mp.form_valid?.should be_true
      end
    
      it 'should be valid if field is not empty' do
        @form_data['name'] = 'My Name'
        @mp.form_valid?.should be_true
      end
    end
    
    describe 'simple required fields' do
      before do
        @required_fields << 'name'
      end
      it 'should be invalid if field is missing' do
        @mp.form_valid?.should be_false
      end
      it 'should be invalid if field is empty' do
        @form_data['name'] = ''
        @mp.form_valid?.should be_false
      end
      it 'should be invalid if field is blank' do
        @form_data['name'] = "  \t   \n "
        @mp.form_valid?.should be_false
      end
      it 'should be valid if field has content' do
        @form_data['name'] = "Jo Blo"
        @mp.form_valid?.should be_true
      end
    end
    
    describe 'as email' do
      before do
        @required_fields << {'email' => 'as_email'}
      end
      it 'should be invalid if field is missing' do
        @mp.form_valid?.should be_false
      end
      it 'should be invalid if field is empty' do
        @form_data['email'] = ''
        @mp.form_valid?.should be_false
      end
      it 'should be invalid if field is blank' do
        @form_data['email'] = "  \t   \n "
        @mp.form_valid?.should be_false
      end
      it 'should be invalid if field is invalid email' do
        @form_data['email'] = 'asdf@@'
        @mp.form_valid?.should be_false
      end
      it 'should be valid if field is valid email' do
        @form_data['email'] = "me@there.com"
        @mp.form_valid?.should be_true
      end
    end
  end
end