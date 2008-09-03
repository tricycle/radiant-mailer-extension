require 'action_mailer'
class MailerPage < Page
  include MailerTags

  TLDS = %w{com org net edu info mil gov biz ws}

  class MailerTagError < StandardError; end

  attr_reader :form_name, :form_conf, :form_error, :form_data, :tag_attr

  def config
    string = render_part(:config)
    unless string.empty?
      YAML::load(string)
    else
      {}
    end
  end

  # Page processing. If the page has posted-back, it will try to deliver the emails
  # and redirect to a different page, if specified.
  def process(request, response)
    @request, @response = request, response
    @form_name, @form_error = nil, nil
    if request.post?
      @form_name = request.parameters[:mailer_name]
      @form_data = request.parameters[:mailer]
      @form_conf = config['mailers'][form_name].symbolize_keys || {}
      # If there are recipients defined, send email...
      if recipients
        if form_valid?
          if send_mail and form_conf.has_key? :redirect_to
            response.redirect( form_conf[:redirect_to], "302 Found" )
          else
            super(request, response)
          end
        else
          @form_error = "#{required_fields.keys.to_sentence.capitalize} #{required_fields.size == 1 ? 'is' : 'are'} required."
          super(request, response)
        end
      else
        @form_error = "Email wasn't sent because no recipients are defined"
        super(request, response)
      end
    else
      super(request, response)
    end
  end

  # We need to process the page everytime, so that we can send the email!
  def cache?
    false
  end  
  
  def form_valid? 
    required_fields.each do |field, validation|
      return false unless is_valid?(field, validation)
    end
    return true
  end

  protected

  def recipients
    chosen_recipient = form_data[:recipient_choice]
    if form_conf[:recipient_list] && chosen_address = form_conf[:recipient_list][chosen_recipient]
      [chosen_address]
        else
      form_conf[:recipients]
      end
    end
  
  def is_valid?(field, validation)
    case validation
      when 'as_email'  then form_data[field] =~ /^[^@]+@([^@.]+\.)[^@]+$/
      when 'not_blank' then !form_data[field].blank?
      else true
    end
  end
  
  def required_fields
    field_validations = {}
    (form_conf[:required_fields] || []).each do |field|
      if field.is_a? Hash
        field.each do |key, value|
          field_validations[key] = value
        end
      else
        field_validations[field] = 'not_blank'
      end
    end
    field_validations
  end

  def from
    form_data[form_conf[:from_field]] || form_conf[:from] || "no-reply@#{request.host}"
    end

  def cc
    form_data[form_conf[:cc_field]] || form_conf[:cc] || ""
    end

  def reply_to
    form_data[form_conf[:reply_to_field]] || form_conf[:reply_to] || from
      end

  def subject
    form_data[:subject] || form_conf[:subject] || "Form Mail from #{request.host}"
    end

  def html_body
    html_body = render_part( :email_html ) || nil
  end

  def plain_body
    part( :email ) ? render_part( :email ) : render_part( :email_plain )
  end

  def plain_or_default_body
    (plain_body.nil? || plain_body.empty?) ? default_body : plain_body
    end
  
  def default_body
    "The following information was posted:\n#{form_data.to_hash.to_yaml}"
  end

  def max_filesize
    form_conf[:max_filesize] || 0
  end

  def attached_files
    files = []
    form_data.each_value do |d|
      files << d if d.is_a?(Tempfile) || d.class == StringIO
  end
    files
  end

  
  # Does the work of actually sending the emails
  def send_mail
    create_actionmailer_deliver_method
    ActionMailer::Base.deliver_generic_mailer(
      :recipients => recipients,
      :from => from,
      :subject => subject,
      :plain_body => plain_or_default_body,
      :html_body => html_body,
      :cc => cc,
      :headers => { 'Reply-To' => reply_to },
      :files => attached_files,
      :filesize_limit => max_filesize
    )
    true
  rescue
    @form_error = "Error encountered while trying to send email. #{$!}"
    false
      end

      # Since we can't have a subclass of ActionMailer in our behavior file,
      # We add a generic mailer method to the ActionMailer::Base clase.
      # Is this a hack? Yes. Does it work? Yes.
  def create_actionmailer_deliver_method
      ActionMailer::Base.module_eval( <<-CODE ) unless ActionMailer::Base.respond_to? 'generic_mailer'
          def generic_mailer(options)
            @recipients = options[:recipients]
            @from = options[:from] || ""
            @cc = options[:cc] || ""
            @bcc = options[:bcc] || ""
            @subject = options[:subject] || ""
            @headers = options[:headers] || {}
            @charset = options[:charset] || "utf-8"
        @content_type = "multipart/mixed"            
              if options.has_key? :plain_body
                part :content_type => "text/plain", :body => (options[:plain_body] || "")
              end
              if options.has_key? :html_body and !options[:html_body].blank?
                part :content_type => "text/html", :body => (options[:html_body] || "")
              end
        # attchments
        options[:files].each do |a|
          # only attach files that are below the filesize limit
          if (options[:filesize_limit] == 0 || a.size <= options[:filesize_limit]) then
            attachment( :content_type => "application/octet-stream",
                        :body => a.read,
                        :filename => a.original_filename )
          else
            raise "The file " + a.original_filename + " is too large. The maximum size allowed is " + options[:filesize_limit].to_s + " bytes." 
          end
    end
  end
    CODE
  end
end
