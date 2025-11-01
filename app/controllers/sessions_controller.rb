# frozen_string_literal: true

class SessionsController < ApplicationController
  def new; end

  def create
    user = User.find_by(email: session_params[:email].to_s.downcase.strip)

    if user&.authenticate(session_params[:password])
      log_in(user)
      if ActiveModel::Type::Boolean.new.cast(session_params[:remember_me])
        remember(user)
      else
        forget(user)
      end
      merge_cart!(user)
      redirect_back_or(after_login_path_for(user))
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    log_out
    redirect_to root_path, notice: "You have been logged out."
  end

  private

  def session_params
    params.require(:session).permit(:email, :password, :remember_me)
  end

  def after_login_path_for(user)
    user.admin? ? admin_root_path : root_path
  end
end
