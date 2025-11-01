# frozen_string_literal: true

class PasswordMailer < ApplicationMailer
  default from: "support@banhang.example"

  def reset_email
    @user = params[:user]
    @token = params[:token]
    @reset_url = edit_password_reset_url(token: @token)

    mail to: @user.email, subject: "Reset your BanHang password"
  end
end
