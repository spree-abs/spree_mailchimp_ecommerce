require "spec_helper"

describe Spree::Order, type: :model do
  before { allow_any_instance_of(SpreeMailchimpEcommerce::Configuration).to receive(:cart_url) { "test.com/cart" } }
  describe "json" do
    context "order with user" do
      let (:user) { create(:user_with_addresses) }
      describe ".mailchimp_order" do
        let(:shipment) { create(:shipment) }
        subject { create(:completed_order_with_totals, user: user, shipments: [shipment]) }
        it "returns valid schema" do
          expect(subject.mailchimp_order).to match_json_schema("order")
        end
      end

      describe ".mailchimp_cart" do
        subject { create(:order_with_line_items, user: user) }
        it "returns valid schema" do
          expect(subject.mailchimp_cart).to match_json_schema("cart")
        end
      end
    end

    context "order without user" do
      let(:shipment) { create(:shipment) }
      subject { create(:completed_order_with_totals, user: nil, email: "test@test.test", shipments: [shipment]) }
      describe ".mailchimp_order" do
        it "returns valid schema" do
          expect(subject.mailchimp_order).to match_json_schema("order")
        end
      end
    end
  end

  describe "mailchimp order" do
    subject { create(:order, state: "confirm") }
    it "schedules mailchimp Order Invoice notification on paid order complete" do
      subject.next
      expect(SpreeMailchimpEcommerce::CreateOrderJob).to have_been_enqueued.with(subject.mailchimp_order)
      expect(SpreeMailchimpEcommerce::DeleteCartJob).to have_been_enqueued.with(subject.number)
      expect(subject.mailchimp_order["financial_status"]).to eq("paid")
    end

    it "schedules mailchimp Order Confirmation notification on not paid order complete" do
      create(:payment, order: subject, state: "failed")
      subject.next
      expect(SpreeMailchimpEcommerce::CreateOrderJob).to have_been_enqueued.with(subject.mailchimp_order)
      expect(SpreeMailchimpEcommerce::DeleteCartJob).to have_been_enqueued.with(subject.number)
      expect(subject.mailchimp_order["financial_status"]).to eq("pending")
    end

    it "schedules mailchimp Cancellation Confirmation notification on order cancel" do
      order = create(:completed_order_with_totals)
      order.cancel

      expect(SpreeMailchimpEcommerce::UpdateOrderJob).to have_been_enqueued.with(order)
      expect(order.mailchimp_order["financial_status"]).to eq("cancelled")
    end

    it "schedules mailchimp Shipping Confirmation notification on order shipped" do
      order = create(:order_ready_to_ship)
      order.shipments.first.ship!

      expect(SpreeMailchimpEcommerce::UpdateOrderJob).to have_been_enqueued.with(order)
      expect(order.mailchimp_order["fulfillment_status"]).to eq("shipped")
    end

    it "schedules mailchimp Refund Confirmation notification on order refund" do
      order = create(:shipped_order)
      create(:refund, payment: order.payments.first)

      expect(SpreeMailchimpEcommerce::UpdateOrderJob).to have_been_enqueued.with(order)
      expect(order.mailchimp_order["financial_status"]).to eq("refunded")
    end
  end
end
