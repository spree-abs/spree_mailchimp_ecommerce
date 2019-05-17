require 'spec_helper'

feature 'Abandoned Cart', js: true do
  SpreeMailchimpEcommerce.configure

  let!(:product)         { create(:product, name: 'spree_product') }
  let!(:variant)         { create(:variant, product: product) }
  let!(:state)           { create(:state, name: 'New York', abbr: 'NY', country: country_us) }
  let!(:shipping_method) { create(:shipping_method) }
  let!(:country_us) do
    create(
      :country,
      id: 232,
      iso_name: 'UNITED STATES',
      iso: 'US',
      iso3: 'USA',
      name: 'United States',
      numcode: 840,
      states_required: true
    )
  end

  before { variant.stock_items.first.update(count_on_hand: 10) }

  scenario 'For a guest user' do
    add_product_to_cart
    expect(current_path).to eq('/checkout/registration')

    fill_in 'order_email', with: 'spree@example.com'
    click_on 'Continue'
    expect(current_path).to eq('/checkout/address')

    fill_in_checkout_address
    expect(current_path).to eq('/checkout/delivery')
    
    click_on 'Save and Continue'
    expect(current_path).to eq('/checkout/payment')
    expect(SpreeMailchimpEcommerce::CreateOrderCartJob).to have_been_enqueued.exactly(:once)
  end

  scenario 'For an existing user' do
    user = create(:user, email: 'spree@example.com', password: 'Spree123', password_confirmation: 'Spree123')

    add_product_to_cart
    expect(current_path).to eq('/checkout/registration')
    click_on 'Login as Existing Customer'
    login
    expect(current_path).to eq('/checkout/address')

    fill_in_checkout_address
    expect(current_path).to eq('/checkout/delivery')
    
    click_on 'Save and Continue'
    expect(current_path).to eq('/checkout/payment')
    expect(SpreeMailchimpEcommerce::CreateOrderCartJob).to have_been_enqueued.exactly(:once)
  end

  scenario 'For a signed in user' do
    user = create(:user, email: 'spree@example.com', password: 'Spree123', password_confirmation: 'Spree123')
    visit '/login'
    login

    add_product_to_cart
    expect(current_path).to eq('/checkout/address')

    fill_in_checkout_address
    expect(current_path).to eq('/checkout/delivery')
    
    click_on 'Save and Continue'
    expect(current_path).to eq('/checkout/payment')
    expect(SpreeMailchimpEcommerce::CreateOrderCartJob).to have_been_enqueued.exactly(:once)
  end

  scenario 'For a signed up user' do
    add_product_to_cart
    expect(current_path).to eq('/checkout/registration')

    fill_in 'spree_user_email', with: 'spree@example.com'
    fill_in 'spree_user_password', with: 'Spree123'
    fill_in 'spree_user_password_confirmation', with: 'Spree123'
    click_on 'Create'
    expect(current_path).to eq('/checkout/address')

    fill_in_checkout_address
    expect(current_path).to eq('/checkout/delivery')
    
    click_on 'Save and Continue'
    expect(current_path).to eq('/checkout/payment')
    expect(SpreeMailchimpEcommerce::CreateOrderCartJob).to have_been_enqueued.exactly(:once)
  end

  def login
    fill_in 'spree_user_email', with: 'spree@example.com'
    fill_in 'spree_user_password', with: 'Spree123'
    click_on 'Login'
  end
  
  def add_product_to_cart
    visit '/'
    click_on 'spree_product'
    click_on 'Add To Cart'
    click_on 'Checkout'
  end

  def fill_in_checkout_address
    fill_in 'order_bill_address_attributes_firstname', with: 'John'
    fill_in 'order_bill_address_attributes_lastname', with: 'Doe'
    fill_in 'order_bill_address_attributes_address1', with: 'Broadway 1540'
    fill_in 'order_bill_address_attributes_city', with: 'New York'
    fill_in 'order_bill_address_attributes_zipcode', with: '10036'
    fill_in 'order_bill_address_attributes_phone', with: '123456789'
    select 'United States', from: 'order_bill_address_attributes_country_id'
    select 'New York', from: 'order_bill_address_attributes_state_id'
    click_on 'Save and Continue'
  end
end
