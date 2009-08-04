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

    describe 'attached files' do
      it 'should default to empty' do
        @form_data.clear
        @mp.send(:attached_files).should be_empty
      end
      it 'should not contain String, Bool or Array objects' do
        @form_data[:boolean] = true
        @form_data[:not_a_file] = "not a file"
        @form_data[:an_array] = [:an, :array]
        @mp.send(:attached_files).should be_empty
      end
      it 'should contain StringIO objects' do
        @form_data[:a_file] = file = StringIO.new()
        @mp.send(:attached_files).should include(file)
      end
      it 'should contain Tempfile objects' do
        @form_data[:a_file] = file = ::Tempfile.new("foo")
        @mp.send(:attached_files).should include(file)
      end
      it 'should work with any class that responds to read' do
        @form_data[:a_file] = file = mock('fake file', :read => "foo")
        @mp.send(:attached_files).should include(file)
      end
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

  describe "#cache" do
    it "should be true" do
      MailerPage.new.cache?.should be_true
    end
  end

  describe "#recipients" do

    before do
      @mp = MailerPage.new
      @required_fields = []
      @form_conf = {:required_fields => @required_fields}
      @mp.stub!(:form_conf).and_return(@form_conf)
      @form_data = {}
      @mp.stub!(:form_data).and_return(@form_data)
    end

    it "returns false if recipient is unknown" do
      @form_data[:recipient_choice] = 'Unknown Recipient'

      @mp.send(:recipients).should == false
    end

    describe "specified as an array of one element hashes" do

      it "returns the chosen_recipient" do
        @form_data[:recipient_choice] = 'Recipient Choice'
        @form_conf[:recipient_list] = [
          { 'A Choice' => 'a_choice@example.com' },
          { 'Another Choice' => 'another_choice@example.com' },
          { 'Recipient Choice' => 'recipient_choice@example.com' },
        ]

        @mp.send(:recipients).should == ['recipient_choice@example.com']
      end

      it "handles HTML entities in the recipient name" do
        @form_data[:recipient_choice] = 'Choice & Choice'
        @form_conf[:recipient_list] = [
          { 'A Choice' => 'a_choice@example.com' },
          { 'Choice &amp; Choice' => 'another_choice@example.com' },
          { 'Recipient Choice' => 'recipient_choice@example.com' },
        ]

        @mp.send(:recipients).should == ['another_choice@example.com']
      end

    end

    describe "specified as a hash" do

      it "returns the chosen_recipient" do
        @form_data[:recipient_choice] = 'Another Choice'
        @form_conf[:recipient_list] = {
          'A Choice' => 'a_choice@example.com',
          'Another Choice' => 'another_choice@example.com',
          'Recipient Choice' => 'recipient_choice@example.com'
        }
        @mp.send(:recipients).should == ['another_choice@example.com']
      end

    end

    describe "specified as an array" do

      it "returns the list of recipients" do
        @form_conf[:recipients] = [
          'a_choice@example.com',
          'another_choice@example.com',
        ]

        @mp.send(:recipients).should == ['a_choice@example.com', 'another_choice@example.com']
      end

    end

  end
end
