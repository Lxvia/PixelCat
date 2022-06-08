class OrdersController < ApplicationController
  before_action :authenticate_user!

  def create
    @order = Order.create

    # @event = Event.find(params[:event_id])
    @cartlist = params[:cartlist]
    @user = current_user
    @stripe_amount = params[:total_price]

    # puts "*"*50
 # Ici prévoir d'enregistrer la commande en base 
 begin
  @stripe_amount = 0
  current_user.carts.each do |cart_item|
    @stripe_amount += cart_item.item.price
  end
   puts "*"*50
   puts @stripe_amount
   puts "*"*50


  customer = Stripe::Customer.create({
   email: params[:stripeEmail],
   source: params[:stripeToken],
   })
  #  puts "*"*50
  #  puts params[:total_price]
  #  puts "*"*50
   charge = Stripe::Charge.create({
   customer: customer.id,
   amount: (@stripe_amount *100).to_i,
   description: "Achat sur la plateforme PixelCat",
   currency: 'eur',
   })
 rescue Stripe::CardError => e
   flash[:error] = e.message
   redirect_to new_order_path
 end
 # Ici prévoir le delete le panier 
    # puts "*"*50

    #modifier id_stripe
    @order = Order.create(id_stripe: 123,
                          user: @user,
                          date: DateTime.now,
                          total_price: @stripe_amount,
                          id_user: @user.id)

    if @order.save

      # add cart in jointable customer.id
      create_in_order

      # clear cart
      empty_cart

      redirect_to root_path

    else
      flash.now[:alert] = @order.errors.full_messages
      render 'new'
    end
  end

  private

  def create_in_order
    current_user.carts.each do |cart_item|
      OrderItem.create(order_id: @order.id, item_id: cart_item.item.id)
    end
  end

  def empty_cart
    current_user.carts.each do |cart_item|
      cart_item.destroy
    end
  end

end
