# frozen_string_literal: true

class PasswordResetsController < ApplicationController
  before_action :load_user_from_token, only: %i[edit update]

  def new; end

  def create
    user = User.find_by(email: params[:password_reset][:email].to_s.downcase.strip)
    if user
      raw_token = user.generate_password_reset!
      PasswordMailer.with(user: user, token: raw_token).reset_email.deliver_later
    end

    redirect_to new_session_path, notice: "If your email is in our system, you will receive reset instructions shortly."
  end

  def edit
    @token = params[:token]
  end

  def update
    if @user.update(password_params)
      @user.clear_password_reset!
      log_in(@user)
      redirect_to root_path, notice: "Your password has been updated."
    else
      @token = params[:token]
      flash.now[:alert] = "Please correct the errors below."
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def load_user_from_token
    token = params[:token].to_s
    @user = User.find_by_reset_token(token)

    if @user.blank? || !@user.reset_token_authenticated?(token) || @user.password_reset_expired?
      redirect_to new_password_reset_path, alert: "Password reset link is invalid or has expired."
    end
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
