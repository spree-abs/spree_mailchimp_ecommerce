# frozen_string_literal: true

module SpreeMailchimpEcommerce
  module Presenters
    class OrderMailchimpPresenter
      include OrderMethods

      attr_reader :order

      def initialize(order)
        @order = order
        raise "Order in wrong state" unless order.completed?
      end

      def json
        order_json.merge(campaign_id).merge(processed_at)
      end

      private

      def campaign_id
        return {} unless order.mailchimp_campaign_id

        { campaign_id: order.mailchimp_campaign_id,
          landing_site: 'https://dev.worldabs.com',
          financial_status: 'paid',
          fulfillment_status: ''
         }.as_json
      end

      def user
        if order.user
          UserMailchimpPresenter.new(order.user).json
        elsif order.email
          {
            id: Digest::MD5.hexdigest(order.email.downcase),
            first_name: order.bill_address&.firstname || "",
            last_name: order.bill_address&.last_name || "",
            email_address: order.email || "",
            opt_in_status: false,
            address: address
          }
        end
      end

      def address
        return {} unless order.shipping_address

        AddressMailchimpPresenter.new(order.shipping_address).json
      end

      def processed_at
        { processed_at_foreign: order.completed_at.strftime("%Y%m%dT%H%M%S") }.as_json
      end
    end
  end
end
