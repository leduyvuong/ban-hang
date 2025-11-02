# frozen_string_literal: true

class RegistrationsController < ApplicationController
  before_action :require_login!, only: %i[edit update]

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)

    if @user.save
      log_in(@user)
      merge_cart!(@user)
      redirect_to after_signup_path, notice: "Welcome to BanHang, #{@user.name}!"
    else
      flash.now[:error] = @user.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    attributes = profile_params.dup
    if attributes[:password].blank?
      attributes = attributes.except(:password, :password_confirmation)
    end

    if @user.update(attributes)
      redirect_to root_path, notice: "Profile updated successfully."
    else
      flash.now[:error] = @user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def profile_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def after_signup_path
    session.delete(:return_to) || root_path
  end
end
