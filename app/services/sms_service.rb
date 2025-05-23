# app/services/sms_service.rb
require "twilio-ruby"

class SmsService
  TWILIO_ACC_ID = Rails.application.credentials.dig(:twilio, :acc_id)
  TWILIO_AUTH_TOKEN = Rails.application.credentials.dig(:twilio, :auth_token)
  TWILIO_SID = Rails.application.credentials.dig(:twilio, :sid)
  def self.send_otp(phone_number)
    begin
      @client = Twilio::REST::Client.new(TWILIO_ACC_ID, TWILIO_AUTH_TOKEN)
      @client.verify
             .v2
             .services(TWILIO_SID)
             .verifications
             .create(to: phone_number, channel: "sms")
      Rails.logger.info "✅ OTP sent to #{phone_number}"
      true
    rescue Twilio::REST::RestError => e
      Rails.logger.error "❌ Failed to send OTP: #{e.message}"
      false
    end
  end
  def self.verify_otp(phone_number, otp_code)
    begin
      @client = Twilio::REST::Client.new(TWILIO_ACC_ID, TWILIO_AUTH_TOKEN)
      verification_check = @client.verify
                                  .v2
                                  .services(TWILIO_SID)
                                  .verification_checks
                                  .create(to: phone_number, code: otp_code)

      if verification_check.status == "approved"
        Rails.logger.info "✅ OTP verified successfully for #{phone_number}"
        true
      else
        Rails.logger.warn "⚠️ OTP verification failed for #{phone_number}"
        false
      end
    rescue Twilio::REST::RestError => e
      Rails.logger.error "❌ OTP verification error: #{e.message}"
      false
    end
  end
end
