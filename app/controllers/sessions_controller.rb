# frozen_string_literal: true

class SessionsController < ApplicationController
  def new
    @session_form = SessionForm.new
  end

  def create
    @session_form = SessionForm.new(session_params)

    if @session_form.valid?
      user = User.find_by(email: @session_form.email.to_s.downcase.strip)

      if user&.authenticate(@session_form.password)
        log_in(user)
        if @session_form.remember_me
          remember(user)
        else
          forget(user)
        end
        merge_cart!(user)
        redirect_back_or(after_login_path_for(user))
      else
        @session_form.errors.add(:base, "Invalid email or password.")
        flash.now[:error] = "Invalid email or password."
        render :new, status: :unprocessable_entity
      end
    else
      flash.now[:error] = @session_form.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    log_out
    redirect_to root_path, notice: "You have been logged out."
  end

  private

  def session_params
    params.require(:session_form).permit(:email, :password, :remember_me)
  end

  def after_login_path_for(user)
    user.admin? ? admin_root_path : root_path
  end
end
