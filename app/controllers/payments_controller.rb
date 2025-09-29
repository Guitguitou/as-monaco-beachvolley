class PaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_payment, only: [:show]

  def index
    @payments = current_user.payments.recent
  end

  def show
  end

  def new
    @credit_packages = CreditPackage.active.ordered
    @selected_package = CreditPackage.find(params[:package_id]) if params[:package_id]
  end

  def create
    @credit_package = CreditPackage.find(params[:credit_package_id])
    
    @payment = current_user.payments.build(
      credit_package: @credit_package,
      status: 'pending'
    )

    if @payment.save
      # Initier le paiement avec LCL/Sherlock
      payment_service = LclPaymentService.new(@payment)
      result = payment_service.initiate_payment
      
      if result[:success]
        redirect_to result[:payment_url]
      else
        @payment.update!(status: 'failed')
        @credit_packages = CreditPackage.active.ordered
        flash.now[:alert] = "Erreur lors de l'initiation du paiement: #{result[:error]}"
        render :new, status: :unprocessable_entity
      end
    else
      @credit_packages = CreditPackage.active.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def callback
    # Callback de retour après paiement réussi
    payment_service = LclPaymentService.new(@payment)
    result = payment_service.handle_callback(params)
    
    if result[:success]
      case result[:status]
      when 'completed'
        redirect_to payments_path, notice: 'Paiement effectué avec succès ! Vos crédits ont été ajoutés.'
      when 'cancelled'
        redirect_to new_payment_path, alert: 'Paiement annulé.'
      when 'failed'
        redirect_to new_payment_path, alert: 'Le paiement a échoué. Veuillez réessayer.'
      end
    else
      redirect_to new_payment_path, alert: "Erreur lors du traitement du paiement: #{result[:error]}"
    end
  end

  def cancel
    # Redirection en cas d'annulation
    @payment.update!(status: 'cancelled')
    redirect_to new_payment_path, alert: 'Paiement annulé.'
  end

  def notify
    # Notification asynchrone de LCL (webhook)
    payment_service = LclPaymentService.new(@payment)
    result = payment_service.handle_callback(params)
    
    if result[:success]
      render json: { status: 'ok' }
    else
      render json: { status: 'error', message: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def set_payment
    @payment = current_user.payments.find(params[:id])
  end
end
