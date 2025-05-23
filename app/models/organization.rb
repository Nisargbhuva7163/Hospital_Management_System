class Organization < ApplicationRecord
  has_many :users, dependent: :destroy
  has_one_attached :qr_code

  def generate_qr_code!
    return if qr_code.attached?

    qr_data = Rails.application.routes.url_helpers.organization_url(self, host: "localhost:7000")
    qrcode = RQRCode::QRCode.new(qr_data)
    png = qrcode.as_png(size: 300)

    file = Tempfile.new(["qr_code_#{id}", ".png"])
    file.binmode
    file.write(png.to_s)
    file.rewind

    qr_code.attach(io: file, filename: "organization_qr_#{id}.png", content_type: "image/png")

    file.close
    file.unlink
  end
end
