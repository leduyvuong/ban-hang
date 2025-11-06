# frozen_string_literal: true

module PageLayouts
  Component = Struct.new(
    :type,
    :label,
    :description,
    :component_class,
    :preview_partial,
    :form_partial,
    :default_config,
    :areas,
    keyword_init: true
  )

  class ComponentRegistry
    COMPONENTS = [
      Component.new(
        type: "hero_banner",
        label: "Hero Banner",
        description: "Large hero section with background image and primary message.",
        component_class: PageLayouts::HeroBannerComponent,
        preview_partial: "admin/page_layouts/components/previews/hero_banner",
        form_partial: "admin/page_layouts/components/forms/hero_banner",
        default_config: {
          "title" => "Chào mừng đến với cửa hàng của bạn",
          "subtitle" => "Khám phá bộ sưu tập mới nhất ngay hôm nay",
          "background_color" => "#0f172a",
          "text_color" => "#f8fafc",
          "image_url" => "https://images.unsplash.com/photo-1521572267360-ee0c2909d518",
          "primary_button_text" => "Khám phá ngay",
          "primary_button_url" => "#products",
          "secondary_button_text" => "Bộ sưu tập",
          "secondary_button_url" => "#collections"
        },
        areas: []
      ),
      Component.new(
        type: "product_grid",
        label: "Product Grid",
        description: "Lưới sản phẩm nổi bật với tối đa 6 sản phẩm.",
        component_class: PageLayouts::ProductGridComponent,
        preview_partial: "admin/page_layouts/components/previews/product_grid",
        form_partial: "admin/page_layouts/components/forms/product_grid",
        default_config: {
          "title" => "Sản phẩm nổi bật",
          "subtitle" => "Những mặt hàng bán chạy nhất tuần này",
          "background_color" => "#ffffff",
          "text_color" => "#0f172a",
          "product_ids" => []
        },
        areas: []
      ),
      Component.new(
        type: "testimonials",
        label: "Testimonials",
        description: "Hiển thị các đánh giá tiêu biểu của khách hàng.",
        component_class: PageLayouts::TestimonialsComponent,
        preview_partial: "admin/page_layouts/components/previews/testimonials",
        form_partial: "admin/page_layouts/components/forms/testimonials",
        default_config: {
          "title" => "Khách hàng nói gì",
          "subtitle" => "Những phản hồi chân thành từ khách hàng của bạn",
          "background_color" => "#f8fafc",
          "text_color" => "#0f172a",
          "testimonials" => [
            { "quote" => "Sản phẩm tuyệt vời và dịch vụ hỗ trợ nhanh chóng!", "name" => "Nguyễn Văn A", "role" => "Doanh nhân" },
            { "quote" => "Giao hàng nhanh và chất lượng vượt mong đợi.", "name" => "Trần Thị B", "role" => "Nội trợ" }
          ]
        },
        areas: []
      ),
      Component.new(
        type: "newsletter_signup",
        label: "Newsletter Signup",
        description: "Biểu mẫu đăng ký nhận bản tin với lời mời hấp dẫn.",
        component_class: PageLayouts::NewsletterSignupComponent,
        preview_partial: "admin/page_layouts/components/previews/newsletter_signup",
        form_partial: "admin/page_layouts/components/forms/newsletter_signup",
        default_config: {
          "title" => "Nhận ưu đãi độc quyền",
          "subtitle" => "Đăng ký để cập nhật ưu đãi mới nhất.",
          "background_color" => "#0f172a",
          "text_color" => "#f8fafc",
          "button_text" => "Đăng ký"
        },
        areas: []
      ),
      Component.new(
        type: "feature_section",
        label: "Feature Section",
        description: "Danh sách các điểm mạnh/tiện ích chính của cửa hàng.",
        component_class: PageLayouts::FeatureSectionComponent,
        preview_partial: "admin/page_layouts/components/previews/feature_section",
        form_partial: "admin/page_layouts/components/forms/feature_section",
        default_config: {
          "title" => "Tại sao chọn chúng tôi",
          "subtitle" => "Cam kết mang đến giá trị tốt nhất cho khách hàng",
          "background_color" => "#ffffff",
          "text_color" => "#0f172a",
          "features" => [
            { "title" => "Miễn phí giao hàng", "description" => "Áp dụng cho đơn hàng trên 500.000đ" },
            { "title" => "Hỗ trợ 24/7", "description" => "Luôn đồng hành cùng khách hàng" }
          ]
        },
        areas: []
      ),
      Component.new(
        type: "call_to_action",
        label: "Call to Action",
        description: "Kêu gọi hành động rõ ràng với nút bấm nổi bật.",
        component_class: PageLayouts::CallToActionComponent,
        preview_partial: "admin/page_layouts/components/previews/call_to_action",
        form_partial: "admin/page_layouts/components/forms/call_to_action",
        default_config: {
          "title" => "Sẵn sàng trải nghiệm?",
          "subtitle" => "Đăng ký ngay để nhận ưu đãi đặc biệt đầu tiên.",
          "background_color" => "#1d4ed8",
          "text_color" => "#f8fafc",
          "button_text" => "Bắt đầu ngay",
          "button_url" => "/products"
        },
        areas: []
      ),
      Component.new(
        type: "two_column_section",
        label: "Bố cục 2 cột",
        description: "Chứa tối đa 2 nhóm component với bố cục song song.",
        component_class: PageLayouts::TwoColumnSectionComponent,
        preview_partial: "admin/page_layouts/components/previews/two_column_section",
        form_partial: "admin/page_layouts/components/forms/two_column_section",
        default_config: {
          "background_color" => "#ffffff",
          "gap" => "lg"
        },
        areas: [
          { "key" => "left", "label" => "Cột trái" },
          { "key" => "right", "label" => "Cột phải" }
        ]
      )
    ].freeze

    def self.all
      COMPONENTS
    end

    def self.find(type)
      COMPONENTS.find { |component| component.type == type }
    end

    def self.default_config_for(type)
      find(type)&.default_config&.deep_dup
    end

    def self.build_component(component_config)
      return unless component_config.is_a?(Hash)

      component = find(component_config["type"])
      return unless component

      component.component_class.new(
        config: component_config["config"] || component.default_config.deep_dup,
        children: component_config["children"] || {}
      )
    end
  end
end
