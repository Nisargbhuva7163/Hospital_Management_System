class Organization < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :appointments, dependent: :destroy
  has_many :booking_windows, dependent: :destroy
  has_one_attached :qr_code

  enum :doctor_status, { checked_out: "checked_out", checked_in: "checked_in" }


  def generate_qr_code!
    return if qr_code.attached?

    qr_data = Rails.application.routes.url_helpers.new_organization_appointment_url(self, host: "localhost:7000")
    qrcode = RQRCode::QRCode.new(qr_data)
    png = qrcode.as_png(size: 300)

    file = Tempfile.new([ "qr_code_#{id}", ".png" ])
    file.binmode
    file.write(png.to_s)
    file.rewind

    qr_code.attach(io: file, filename: "organization_qr_#{id}.png", content_type: "image/png")

    file.close
    file.unlink
  end

  def within_booking_window?
    return true if booking_windows.empty?

    now = Time.current
    now_time = now.seconds_since_midnight

    booking_windows.any? do |window|
      puts "Now: #{now_time}"


      start_time = window.start_time.seconds_since_midnight
      end_time = window.end_time.seconds_since_midnight

      puts "Window: #{start_time} - #{end_time}"
      now_time.between?(start_time, end_time)
    end
  end
end
