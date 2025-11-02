# frozen_string_literal: true

module Admin
  class SessionsController < ApplicationController
    layout "admin_auth"

    skip_before_action :authenticate_admin_user!, only: %i[new create]
    before_action :redirect_if_authenticated, only: :new

    def new
      @session_form = Admin::SessionForm.new
    end

    def create
      @session_form = Admin::SessionForm.new(session_params)

      if @session_form.valid?
        admin_user = AdminUser.find_by(email: @session_form.normalized_email)

        if admin_user&.authenticate(@session_form.password)
          log_in_admin_user(admin_user)
          redirect_to admin_root_path, notice: "Logged in successfully."
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
      log_out_admin_user
      redirect_to admin_login_path, notice: "Logged out successfully."
    end

    private

    def session_params
      params.require(:admin_session_form).permit(:email, :password)
    end

    def redirect_if_authenticated
      redirect_to admin_root_path if admin_user_signed_in?
    end

    def log_in_admin_user(admin_user)
      session[:admin_user_id] = admin_user.id
    end

    def log_out_admin_user
      session.delete(:admin_user_id)
    end
  end
end
