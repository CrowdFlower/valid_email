require 'active_model'
require 'active_model/validations'
require 'mail'
class EmailValidator < ActiveModel::EachValidator
  def validate_each(record,attribute,value)
    begin
      return if options[:allow_nil] && value.nil?
      return if options[:allow_blank] && value.blank?

      m = Mail::Address.new(value)
      # We must check that value contains a domain and that value is an email address
      r = m.domain && m.address == value
      r &&= (m.domain.split('.').length > 1)
      # Check if domain has DNS MX record
      if r && options[:mx]
        require 'valid_email/mx_validator'
        r &&= MxValidator.new(:attributes => attributes).validate(record)
      end
      # Check if domain is disposable
      if r && options[:ban_disposable_email]
        require 'valid_email/ban_disposable_email_validator'
        r &&= BanDisposableEmailValidator.new(:attributes => attributes).validate(record)
      end
      if r && options[:ban_free_email]
        require 'valid_email/ban_free_email_validator'
        r &&= BanFreeEmailValidator.new(:attributes => attributes).validate(record)
      end
    rescue Exception => e
      r = false
    end
    record.errors.add attribute, (options[:message] || I18n.t(:invalid, :scope => "valid_email.validations.email")) unless r
  end
end
