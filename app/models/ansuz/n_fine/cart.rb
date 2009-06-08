#require 'aasm'
class Cart < ActiveRecord::Base

=begin aasm stuff.
  include AASM

  ORDER_NUMBER_OFFSET = 24998
  CREDIT_CARD_TYPES   = ["Visa", "Mastercard", "Discover", "American Express"]
  MONTHS              = [
                          ["January", "01"], ["February", "02"], ["March", "03"],
                          ["April", "04"], ["May", "05"], ["June", "06"], ["July", "07"],
                          ["August", "08"], ["September", "09"], ["October", "10"],
                          ["November", "11"], ["December", "12"]
                        ]
  YEARS               = (2008..2020)
  SHIPPING_METHODS    = ["ground", "twoday", "overnight"]
  SHIPPING_LOOKUP     = {
    "ground" => "Standard Ground - Within 3-7 Business Days (after shipping)",
    "twoday" => "Two Day - 2 Business Days (after shipping)",
    "overnight" => "Standard Overnight - Next Business Day (after shipping)"
  }
  ARCHIVE_FEE_IN_CENTS = 895

  aasm_column :status
  aasm_initial_state :pending

  aasm_state :pending
  aasm_state :shipped
  aasm_state :canceled

  aasm_event :ship do
    transitions :to => :shipped, :from => [:pending]
  end

  aasm_event :duplicate do
    # aasm isn't firing the on_transition for cancel!, so we need to call zero_out_totals to clear the values for the canceled order
    transitions :from => [:pending, :shipped], :on_transition => lambda{|order| order.reissue! }
  end

  aasm_event :cancel do
    transitions :to => :canceled, :from => [:pending, :shipped], :on_transition => lambda{|order| order.zero_out_totals! }
  end
=end

=begin my running list of sportgraphics code removed from this cart model.
coupons
events
acts_as_commentable
to xml
=end

  belongs_to    :user
  has_one       :person
  has_many      :line_items,        :dependent => :destroy
  has_many      :coupon_line_items
  has_many      :photos,            :through   => :line_items
  has_many      :products,          :through   => :line_items
  has_many      :cart_event_links,  :dependent => :destroy

  before_save   :update_archive_line_items, :update_subtotal, :reapply_coupons, :rescue_coupons, :update_sales_tax, :update_total
  serialize     :response
  attr_accessor :gateway, :duplicating


  named_scope   :ordered, :conditions => [ 'ordered_at IS NOT NULL' ], :order => [ 'ordered_at DESC' ]
  named_scope   :unordered, :conditions => [ 'ordered_at IS NULL' ], :order => [ 'ordered_at DESC' ]
   
  def visible_status
    if( self.status == "pending" )
      "In Process"
    else
      self.status
    end
  end

  def reissue!
    new_order = Cart.new( self.attributes )
    new_order.ordered_at        = Time.now
    new_order.person            = self.proper_person.clone
    new_order.duplicated        = true # important to do this so totals will not get re-calculated if the order gets saved in the future ( adding a comment, etc)
    self.proper_person.addresses.each do |address|
      new_order.person.addresses.build( address.attributes )
    end
    new_order.zero_out_totals!
    self.line_items.each do |line_item|
      line_item = line_item.clone
      line_item.cart_id = nil
      new_order.line_items.build( line_item.attributes.merge(:cart => new_order) )
    end
    self.cart_event_links.each do |cart_event_link|
      new_order.cart_event_links.build( cart_event_link.attributes )
    end
    new_order.shipped_on = nil
    new_order.tracking_number = nil
    new_order.ship_carrier = nil
    new_order.status = 'pending'
    new_order.save!
    new_order
  end

  def zero_out_totals!
    self.duplicating = true
    self.update_attributes(:subtotal => 0.00, :total => 0.00, :cart_coupon_links => [], :coupon_line_items => [])
  end

  def update_archive_line_items
    return if duplicated? || duplicating
    fee = (Site.default.archive_fee || ARCHIVE_FEE_IN_CENTS)
    # First, remove all existing archive line items
    ArchiveFeeLineItem.find(:all, :conditions => { :cart_id => self.id }).map(&:destroy)
    #self.line_items.archived.map(&:destroy) # Can't go through the association because we can't reload mid-save
    # Second, create a line item for ARCHIVE_FEE with qty num_archived_photos
    self.line_items.reject!{|li| li.type == 'ArchiveFeeLineItem' }
    if number_of_archived_photos > 0
      archive_li = self.line_items.build(
        :descriptive_text => "Archive fee (for photos older than 4 years)",
        :quantity         => number_of_archived_photos,
        :price_in_cents   => fee,
        :amount           => (fee * number_of_archived_photos) / 100.0
      )
      archive_li.type = "ArchiveFeeLineItem"
      archive_li.skip_save_cart = true
    end
  end

  def update_sales_tax
    return if duplicated? || duplicating
    if calculate_sales_tax? && (status != 'canceled')
      self.sales_tax = calculate_ma_sales_tax
    else
      self.sales_tax = 0
    end
  end

#TODO make this ansuz admin configurable  
#  def calculate_sales_tax?
#    # Determine state from shipping_address
#    # if it matches MA or Massachusetts, return true
#    # else, meh
#    shipping_address && (shipping_address.state_province =~ /(^MA$|^Massachusetts$)/i)
#  end


  def gateway
    if @gateway
      @gateway
    else
      @gateway = BILLING_GATEWAY
      def @gateway.get_post_data action, parameters={}
        post_data(action, parameters)
      end
      @gateway
    end
  end

  def total_in_cents
    (total * 100).to_i if total
  end

  def total_without_discounts
    discount = line_items.select{|li| li.amount < 0}.inject(0.0){|sum, li| sum += li.amount}
    total - BigDecimal("#{discount}")
  end

  def total_without_discounts_and_credits
    total_without_discounts - total_credits
  end

  def total_credits
    line_items.select{|li| li.is_purchased_credit? }.inject(0.0){ |sum, li| sum += li.amount }
  end

  def calculated_subtotal
    calc = line_items.inject(0.0) do |sum, li| 
      sum += li.amount 
    end
    calc.nil? ? 0.0.to_d : calc
  end

  def calculated_subtotal_without_coupons
    calc = (line_items - coupon_line_items).inject(0.0) do |sum, li|
      sum += li.amount
    end
    calc.nil? ? 0.0.to_d : calc
  end

  def calculated_total
    begin
      subtotal + shipping_rate + rush_rate + sales_tax
    rescue
      subtotal
    end
  end

  def update_subtotal
    return if duplicated? || duplicating
    self.subtotal = calculated_subtotal if (status != 'canceled' )
  end

  def update_subtotal!
    update_subtotal
    save
  end

  def update_total
    return if duplicated? || duplicating
    self.total = calculated_total if (status != 'canceled' )
  end

  def update_total!
    update_total
    save
  end

  def order!
    self.ordered_at = Time.now
    transaction do
      save!
      attach_cart_to_applicable_events!
      attach_line_items_to_applicable_events!
    end
    UserMailer.deliver_cart_order_notification(self)
    AdminMailer.deliver_cart_order_notification(self)
  end

  def ordered?
    ordered_at ? true : false
  end

#TODO make this ansuz admin configurable
#  def invoice_number
#    "SGO-#{order_number}"
#  end

  def order_number
    id + ORDER_NUMBER_OFFSET
  end

  def self.find_by_order_number number
    find_by_id(number.to_i - ORDER_NUMBER_OFFSET)
  end

=begin authorize.net stuff TODO: braintree processing
  # This method sends information to authorize.net
  # action is one of :purchase, :authorize, etc for authorize.net's various
  # possible actions.
  def order_and action, options={}
    if total_in_cents > 0
      credit_card     = options[:credit_card]
      billing_address = options[:billing_address]
      raise "You must pass in an ActiveMerchant credit card" unless credit_card
      raise "You must pass in a billing address" unless billing_address
      logger.info "Billing address was: " + billing_address.inspect

      transaction_options = {
        :address         => billing_address,
        :billing_address => billing_address,
        :order_id        => invoice_number
      }

      if credit_card.valid?
        logger.info("valid credit card")
        logger.info "Charging credit card for #{total_in_cents} cents."
        self.response = gateway.send(action, total_in_cents, credit_card, transaction_options)
        save
        if response && response.success?
          order!
        end
        response
      else
        logger.info("invalid credit card")
        credit_card.errors.each do |err|
          err[1].each do |err1|
            self.errors.add(err[0], err1)
          end
        end
      end
      if response
        response.success?
      else
        false
      end
    else
      true
    end
  end
=end

  def line_item_for product
    line_items.select{|s| s.product == product}.first
  end

  def add product, options = {}
    options = { :quantity => 1 }.merge(options)
    options[:cart_id] = self.id
    li = LineItem.new(options)
    li.product = product
    li.calculate_total
    li.save
  end

  def self.search string
    by_order_number = /^SG-/i
    if string =~ by_order_number
      order_number = string.gsub(/[^\d]/, '')
      the_id = order_number.to_i - ORDER_NUMBER_OFFSET
      find_by_id(the_id)
    end
  end

  def proper_person
    if user
      user.person
    else
      person
    end
  end

  # FIXME: This needs to be attached to the cart, because if I order one thing 
  # to be shipped one place and another to be shipped elsewhere, this will cause problems
  def billing_address
    if proper_person
      proper_person.addresses.find_by_address_type('Billing', :order => 'id DESC')
    end
  end

  def email_address
    # Get the email address on the billing address
    billing_address.email if billing_address
  end

  def shipping_address
    if proper_person
      proper_person.addresses.find_by_address_type('Shipping', :order => 'id DESC')
    end
  end

  def shipping_address_xml
    [Proc.new { |options| options[:builder].tag!('shipping-line1', self.shipping_address.line1) },
     Proc.new { |options| options[:builder].tag!('shipping-line2', self.shipping_address.line2) },
     Proc.new { |options| options[:builder].tag!('shipping-line3', self.shipping_address.line3) },
     Proc.new { |options| options[:builder].tag!('shipping-city',  self.shipping_address.city) },
     Proc.new { |options| options[:builder].tag!('shipping-state', self.shipping_address.state_province) },
     Proc.new { |options| options[:builder].tag!('shipping-zip', self.shipping_address.zip_postal) },
     Proc.new { |options| options[:builder].tag!('shipping-country', self.shipping_address.country) },
     Proc.new { |options| options[:builder].tag!('shipping-first-name', self.shipping_address.first_name) },
     Proc.new { |options| options[:builder].tag!('shipping-last-name', self.shipping_address.last_name) },
     Proc.new { |options| options[:builder].tag!('shipping-phone-number', self.shipping_address.phone_number) },
     Proc.new { |options| options[:builder].tag!('shipping-extension', self.shipping_address.extension) },
     Proc.new { |options| options[:builder].tag!('shipping-email', self.shipping_address.email) },
     Proc.new { |options| options[:builder].tag!('shipping-company-name', self.shipping_address.company_name) }
    ]
 
  end

  def rush_rate
    if rush_shipping
      subtotal
    else
      0
    end
  end

  def domestic_shipping_rate
    ShippingRate.charge_for(self.subtotal, :domestic)
  end

  def international_shipping_rate
    ShippingRate.charge_for(self.subtotal, :international)
  end

  # These can go away eventually. Would be nice to keep them around in case wonkiness happens with the ShippingRate model
  def old_domestic_shipping_rate
    case subtotal_without_coupon
    when (0..23)
      3.95
    when (23..35)
      4.95
    when (35..50)
      6.95
    when (50..80)
      7.95
    else
      subtotal_without_coupon * 0.1
    end
  end

  def old_international_shipping_rate
    case subtotal_without_coupon 
    when (0..23)
      7.90
    when (23..35)
      9.90
    when (35..50)
      13.90
    when (50..80)
      14.90
    else
      subtotal_without_coupon * 0.2
    end
  end

  def free_ground_shipping?
    Site.find(:first).free_ground_shipping == true
  end

  def shipping_rate
    return 0 if status == 'canceled'
    case shipping_method
    when 'ground'
      ground_shipping_rate
    when 'twoday'
      two_day_shipping_rate
    when 'overnight'
      overnight_shipping_rate
    else
      ground_shipping_rate
    end
  end

  def ground_shipping_rate
    if shipping_address
      if shipping_address.country == "United States"
        if( free_ground_shipping? )
          0.00
        else
          domestic_shipping_rate
        end
      else
        international_shipping_rate
      end
    else
      raise "Can't calculate shipping without a shipping address"
    end
  end

  def two_day_shipping_rate
    ground_shipping_rate + two_day_ship_rate_additional
  end

  def overnight_shipping_rate
    ground_shipping_rate + overnight_ship_rate_additional
  end

  def two_day_ship_rate_additional
    if shipping_address
      if shipping_address.country == "United States"
        domestic_two_day_ship_rate_additional
      else
        international_two_day_ship_rate_additional
      end
    else
      raise "Can't calculate shipping without a shipping address"
    end
  end

  def overnight_ship_rate_additional
    if shipping_address
      if shipping_address.country == "United States"
        domestic_overnight_ship_rate_additional
      else
        international_overnight_ship_rate_additional
      end
    else
      raise "Can't calculate shipping without a shipping address"
    end
  end

  def domestic_two_day_ship_rate_additional
    25
  end

  def international_two_day_ship_rate_additional
    50
  end

  def domestic_overnight_ship_rate_additional
    30
  end

  def international_overnight_ship_rate_additional
    60
  end

  def to_csv
    CartExporter.new(self).to_csv
  end

  private
  # Called when a line item is removed and the subtotal dips below 0
  def rescue_coupons
    return if duplicated?
    if(self.calculated_subtotal.to_f < 0.00)
      self.coupon_line_items.each do |coupon_line_item|
        self.subtotal -= coupon_line_item.amount #Remove the coupon amounts applied to the subtotal
      end
      self.cart_coupon_links.destroy_all # Reset the coupon uses
      self.coupon_line_items.destroy_all # Remove all coupon line items
      
    end

    # Examine coupons and see if any have a minimum threshold.
    # Remove these coupons if the subtotal doesn't meet the requirement
    self.coupons.each do |coupon|
      if(coupon.minimum_order_threshold.to_f > 0.00)
        unless(self.meets_minimum_threshold?(coupon))
          self.coupon_line_items.find(:all, :conditions => ["descriptive_text = ?", coupon.description]).map(&:destroy)
          self.coupons.delete(coupon)
        end
      end
    end
  end
end
