module MailerTags
  include Radiant::Taggable
  TLDS = %w{com org net edu info mil gov biz ws}
  attr_reader :tag_attr
  
  class MailerTagError < StandardError; end
  
  begin # Mailer Tags:
    desc %{ All mailer-related tags live inside this one. }
    tag "mailer" do |tag|
      tag.expand
    end
    
    desc %{
    Generates a form for submitting email.  The 'name' attribute is required
    and should correspond with configuration given in the 'config' part/tab.
        
    The rendered form is followed by Javascript which is used to disable all form submit
    buttons on the page and show the hidden submit_placeholder div (if it exists).

    Usage:
    <pre><code>  <r:mailer:form name="contact">...</r:mailer:form></code></pre>}
    tag "mailer:form" do |tag|
      @tag_attr = { :class=>get_class_name('form') }.update( tag.attr.symbolize_keys )
      raise_error_if_name_missing 'mailer:form'
      mailer_name =  tag_attr[:name]
      tag.locals.mailer_name =  mailer_name
      # Build the html form tag...
      results =  %Q(<form action="#{ url }" method="post" class="#{tag_attr[:class]} #{add_attrs_to("", tag_attr)}" enctype="multipart/form-data">)
      results << %Q(<div><input type="hidden" name="mailer_name" value="#{mailer_name}" /></div>)
      results << %Q(<div class="mailer-error">#{form_error}</div>) if form_error
      results << tag.expand
      results << %Q(</form>)
      results << %Q(
        <script type="text/javascript">
          function disableSubmitButtons()
          {
            var buttons = document.getElementsByName("mailer[mailer-form-button]");
            for( var idx = 0; idx < buttons.length; idx++ )
            {
              buttons[idx].disabled = true;
            }
          }

          function showSubmitPlaceholder()
          {
            var submitplaceholder = document.getElementById("submit-placeholder-part");
            if (submitplaceholder != null)
            {
              submitplaceholder.style.display="";
            }
          }
        </script>)

    end

    # Build tags for all of the <input /> tags...  except submit/image
    %w(text password file reset checkbox radio hidden).each do |type|
      desc %{
      Renders a #{type} form control for a mailer form. #{"The 'name' attribute is required." unless %(submit reset).include? type}
      All unused attributes will be added as HTML attributes on the resulting tag.}
      tag "mailer:#{type}" do |tag|
        @tag_attr = tag.attr.symbolize_keys
        raise_error_if_name_missing "mailer:#{type}" unless %(submit reset).include? type
        input_tag_html( type )
      end      
    end

    desc %{
      Renders a submit form control for a mailer form.
    }
    tag "mailer:submit" do |tag|
      @tag_attr = tag.attr.symbolize_keys.merge(default_submit_attrs)
      input_tag_html( 'submit' )
    end
    
    desc %{
      Renders a image form control for a mailer form. The 'src' attribute is required.
    }
    tag "mailer:image" do |tag|
      @tag_attr = tag.attr.symbolize_keys.merge(default_submit_attrs)
      input_tag_html( 'image' )
    end
    
    desc %{
      Renders a hidden div containing the contents of the submit_placeholder page part. The
      div will be shown when a user submits a mailer form.
    }
    tag "mailer:submit_placeholder" do |tag|
      if part( :submit_placeholder ) then
        results =  %Q(<div id="submit-placeholder-part" style="display:none">)
        results << render_part( :submit_placeholder )
        results << %Q(</div>)
      end
    end


    desc %{
    Renders a @<select>...</select>@ tag for a mailer form.  The 'name' attribute is required.  @<r:option />@ tags may be nested
    inside the tag to automatically generate options.
    }
    tag 'mailer:select' do |tag|
      @tag_attr = { :id=>tag.attr['name'], :class=>get_class_name('select'), :size=>'1' }.update( tag.attr.symbolize_keys )
      raise_error_if_name_missing "mailer:select"
      tag.locals.parent_tag_name = tag_attr[:name]
      tag.locals.parent_tag_type = 'select'
      results =  %Q(<select name="mailer[#{tag_attr[:name]}]" #{add_attrs_to("")}>)
      results << tag.expand
      results << "</select>"
    end

    desc %{
    Renders a @<select>...</select>@ tag for a mailer form that allows the user
    to select a recipient for the form. The list of possible choices has to be
    specified in the 'config' pagepart like so:
    mailers:
      general_enquiry:
        recipient_list:
          'General questions': 'support@example.com'
          'Technical assistance': 'techsupport@example.com'
    }
    tag 'mailer:selectrecipient' do |tag|
      fieldname = 'recipient_choice'
      @tag_attr = {
        :id => fieldname, :class => get_class_name('select'),
      }.update( tag.attr.symbolize_keys )
      # require 'ruby-debug';debugger
      form_conf = tag.locals.page.config['mailers'][tag.locals.mailer_name].symbolize_keys
      options = if form_conf[:recipient_list]
        form_conf[:recipient_list].collect do |label, address|
          %Q{  <option value="#{label}">#{label}</option>\n}
        end
      else
        ''
      end
      results = <<-HTML
<select name="mailer[#{fieldname}]" #{add_attrs_to("")}>
#{options}
</select>
      HTML
    end
    
    desc %{
    Renders a @<select>...</select>@ tag for a mailer form that allows the user
    to select a recipient for the form. The list of possible choices has to be
    specified in the 'config' pagepart like so:
    mailers:
      general_enquiry:
        recipient_list:
          'General questions': 'support@example.com'
          'Technical assistance': 'techsupport@example.com'
    }
    tag 'mailer:selectrecipient' do |tag|
      fieldname = 'recipient_choice'
      @tag_attr = {
        :id => fieldname, :class => get_class_name('select'),
      }.update( tag.attr.symbolize_keys )
      # require 'ruby-debug';debugger
      form_conf = tag.locals.page.config['mailers'][tag.locals.mailer_name].symbolize_keys
      options = if form_conf[:recipient_list]
        form_conf[:recipient_list].collect do |label, address|
          %Q{  <option value="#{label}">#{label}</option>\n}
        end
      else
        ''
      end
      results = <<-HTML
<select name="mailer[#{fieldname}]" #{add_attrs_to("")}>
#{options}
</select>
      HTML
    end

    desc %{
    Renders a <pre><code><textarea>...</textarea></code></pre> tag for a mailer form. The `name' attribute is required. }
    tag 'mailer:textarea' do |tag|
      @tag_attr = { :id=>tag.attr['name'], :class=>get_class_name('textarea'), :rows=>'5', :cols=>'35' }.update( tag.attr.symbolize_keys )
      raise_error_if_name_missing "mailer:textarea"
      results =  %Q(<textarea name="mailer[#{tag_attr[:name]}]" #{add_attrs_to("")}>)
      results << tag.expand
      results << "</textarea>"
    end
    
    desc %{
    Renders a series of @<input type="radio" .../>@ tags for a mailer form.  The 'name' attribute is required.
    Nested @<r:option />@ tags will generate individual radio buttons with corresponding values.
    }
    tag 'mailer:radiogroup' do |tag|
      @tag_attr = tag.attr.symbolize_keys
      raise_error_if_name_missing "mailer:radiogroup"
      tag.locals.parent_tag_name = tag_attr[:name]
      tag.locals.parent_tag_type = 'radiogroup'
      tag.expand
    end

    desc %{ Renders an @<option/>@ tag if the parent is a 
    @<r:mailer:select>...</r:mailer:select>@ tag, an @<input type="radio"/>@ tag if 
    the parent is a @<r:mailer:radiogroup>...</r:mailer:radiogroup>@ }
    tag 'mailer:option' do |tag|
      @tag_attr = tag.attr.symbolize_keys
      raise_error_if_name_missing "mailer:option"
      result = ""
      if tag.locals.parent_tag_type == 'select'
        result << %Q|<option value="#{tag_attr.delete(:value) || tag_attr[:name]}" #{add_attrs_to("")}>#{tag_attr[:name]}</option>|
      elsif tag.locals.parent_tag_type == 'radiogroup'
        tag.globals.option_count = tag.globals.option_count.nil? ? 1 : tag.globals.option_count += 1
        options = tag_attr.clone.update({
          :id => "#{tag.locals.parent_tag_name}_#{tag.globals.option_count}",
          :value => tag_attr.delete(:value) || tag_attr[:name],
          :name => tag.locals.parent_tag_name
        })
        result << %Q|<label for="#{options[:id]}">|
        result << input_tag_html( 'radio', options )
        result << %Q|<span>#{tag_attr[:name]}</span></label>|
      end
    end

    desc %{
    Renders an obfuscated email address @<option />@ tag
    using the email.js file. Use nested @<r:address>...</r:address>@ to specify the email
    address and @<r:label>...</r:label>@ to specify what the content of the tag should be. }
    tag 'mailer:email_option' do |tag|
      hash = tag.locals.params = {}
      contents = tag.expand
      address = hash['address'].blank? ? contents : hash['address']
      label = hash['label']
      if address =~ /([\w.%-]+)@([\w.-]+)\.([A-z]{2,4})/
        user, domain, tld = $1, $2, $3
        tld_num = TLDS.index(tld)
        unless label.blank?
        %{<script type="text/javascript">
              // <![CDATA[
              mail4('#{user}', '#{domain}', #{tld_num}, "#{label}");
              // ]]>
              </script>
        }
        else
        %{<script type="text/javascript">
              // <![CDATA[
              mail4('#{user}', '#{domain}', #{tld_num}, '#{user}');
              // ]]>
              </script>
        }
        end      
      end
    end
    
    tag "mailer:email_option:label" do |tag|
      tag.locals.params['label'] = tag.expand.strip
    end
  
    tag "mailer:email_option:address" do |tag|
      tag.locals.params['address'] = tag.expand.strip
    end
  
    
    desc %{
    Renders the value of a datum submitted via a mailer form.  Used in the 'email', 'email_html', and 
    'config' parts to generate the resulting email. }
    tag 'mailer:get' do |tag|
      name = tag.attr['name']
      if name
        return form_data[name].to_sentence if form_data[name].is_a?(Array)
        return form_data[name].original_filename if form_data[name].respond_to? :original_filename
        return form_data[name]
      else
        form_data.to_hash.to_yaml.to_s
      end
    end
    
  end
  
  protected

  # Since several form tags use the <input type="X" /> format, let's do that work in one place
  def input_tag_html(type, opts=tag_attr)
    options = { :id => tag_attr[:name], :value => "", :class=>get_class_name(type) }.update(opts)
    results =  %Q(<input type="#{type}" )
    results << %Q(name="mailer[#{options[:name]}]" ) if tag_attr[:name]
    results << "#{add_attrs_to("", options)}/>"
  end
  
  def add_attrs_to(results, tag_attrs=tag_attr)
    # Well, turns out I stringify the keys so I can sort them so I can test the tag output
    tag_attrs.stringify_keys.sort.each do |name, value|
      results << %Q(#{name.to_s}="#{value.to_s}" ) unless name == 'name'
    end
    results
  end
  
  # Get the default css class based on type
  def get_class_name(type, class_name=nil)
    class_name = 'mailer-form' if class_name.nil? and %(form).include? type
    class_name = 'mailer-field' if class_name.nil? and %(text password file select textarea).include? type
    class_name = 'mailer-button' if class_name.nil? and %(submit reset).include? type
    class_name = 'mailer-option' if class_name.nil? and %(checkbox radio).include? type
    class_name
  end
  
  def default_submit_attrs
    {
      :name => "mailer-form-button",
      :onclick => "showSubmitPlaceholder()"
    }
  end
  
  # Raises a 'name missing' tag error
  def raise_name_error(tag_name)
    raise MailerTagError.new( "`#{tag_name}' tag requires a `name' attribute" )
  end
  
  def raise_error_if_name_missing(tag_name)
    raise_name_error( tag_name ) if tag_attr[:name].nil? or tag_attr[:name].empty?
  end
  
end
