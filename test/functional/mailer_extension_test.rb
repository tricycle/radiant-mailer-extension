require File.dirname(__FILE__) + '/../test_helper'

class MailerExtensionTest < Test::Unit::TestCase
  
  def test_initialization
    assert MailerExtension.root.match(%r{/vendor/extensions/mailer$})
    assert_equal 'Mailer', MailerExtension.extension_name
  end
  
end
