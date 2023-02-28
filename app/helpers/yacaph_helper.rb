module Yacaph
   def self.random_image
      @files ||= Dir.entries(RAILS_ROOT + '/public/images/captcha')[2..-1].grep(/\.#{Yacaph::EXT}$/)
      @files[rand(@files.size)]
   end
end

module YacaphHelper
   
   def yacaph_image
      @yacaph_image ||= Yacaph::random_image
      image_tag('captcha/' + @yacaph_image)
   end
   
   def yacaph_input_text(label, options={})
      @yacaph_image ||= Yacaph::random_image
      content_tag('label', label, :for => options[:prefix] + 'captcha') + 
      text_field_tag(options[:prefix] + 'captcha')
   end
   
   def yacaph_hidden_text(options)
      @yacaph_image ||= Yacaph::random_image
      hidden_field_tag(options[:prefix] + 'captcha_validation', @yacaph_image.gsub(/\.#{Yacaph::EXT}$/,''))
   end
   
   def yacaph_block(label = 'Please type the characters in the image below', options={})
      options[:prefix] ||= ''
      content_tag('div', yacaph_hidden_text(options) + yacaph_input_text(label, options) + yacaph_image, {:class => 'yacaph'})
   end
   
   def yacaph_validated?(options={})
      options[:prefix] ||= ''
      text3 = Yacaph::encrypt_string(params[options[:prefix] + 'captcha'] || '') == params[options[:prefix] + 'captcha_validation']
   end
end
