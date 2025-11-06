# frozen_string_literal: true

module Admin
  class PageLayoutsController < ApplicationController
    before_action :set_shop
    before_action :set_page_layout
    before_action :set_component_catalog

    def edit
      set_admin_page(
        title: "Homepage Builder",
        subtitle: "Kéo thả để tạo trang chủ theo ý bạn"
      )
      @published_page = @shop.pages.published.order(published_at: :desc).first
    end

    def update
      parsed_config = parse_layout_config
      respond_to do |format|
        if parsed_config && @page_layout.update(layout_config: parsed_config)
          publish_layout if publishing?
          format.html do
            redirect_to edit_admin_page_layout_path, notice: (publishing? ? "Trang chủ đã được xuất bản." : "Bản nháp đã được lưu.")
          end
        else
          format.html do
            flash.now[:alert] = "Không thể lưu cấu hình. Vui lòng kiểm tra lại."
            render :edit, status: :unprocessable_entity
          end
        end
      end
    end

    private

    def set_shop
      @shop = Shop.first || raise(ActiveRecord::RecordNotFound, "Chưa có cửa hàng nào được cấu hình")
    end

    def set_page_layout
      @page_layout = @shop.page_layout || @shop.build_page_layout(layout_config: PageLayout::DEFAULT_CONFIG)
      @page_layout.save! if @page_layout.new_record?
    end

    def set_component_catalog
      @components_catalog = PageLayouts::ComponentRegistry.all
    end

    def parse_layout_config
      raw_config = page_layout_params[:layout_config]
      return raw_config if raw_config.is_a?(Hash)

      JSON.parse(raw_config)
    rescue JSON::ParserError
      @page_layout.errors.add(:layout_config, :invalid)
      nil
    end

    def publishing?
      params[:publish].present?
    end

    def publish_layout
      ActiveRecord::Base.transaction do
        @page_layout.update!(published_at: Time.current)
        @shop.pages.create!(layout_config: @page_layout.layout_config, published_at: Time.current)
      end
    end

    def page_layout_params
      params.require(:page_layout).permit(:layout_config)
    end
  end
end
