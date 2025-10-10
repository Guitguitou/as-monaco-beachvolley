class PaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_payment, only: [:show, :callback, :cancel, :notify]

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
    @payment = create_payment_for_package(@credit_package)

    if @payment.persisted?
      result = initiate_lcl_payment(@payment)
      
      if result[:success]
        redirect_to result[:payment_url], allow_other_host: true
      else
        handle_payment_error(result[:error])
      end
    else
      render_new_with_packages
    end
  end

  def callback
    result = process_payment_callback

    if result[:success]
      redirect_with_status_message(result[:status])
    else
      redirect_to new_payment_path, alert: "Erreur: #{result[:error]}"
    end
  end

  def cancel
    @payment.update!(status: 'cancelled')
    redirect_to new_payment_path, alert: 'Paiement annulé.'
  end

  def notify
    # Webhook LCL - Notification asynchrone
    result = process_payment_callback

    if result[:success]
      render json: { status: 'ok' }
    else
      render json: { status: 'error', message: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def set_payment
    @payment = if params[:id]
      current_user.payments.find(params[:id])
    elsif params[:order_id]
      current_user.payments.find_by!(id: params[:order_id])
    else
      current_user.payments.find_by!(sherlock_transaction_id: params[:transaction_id])
    end
  end

  def create_payment_for_package(credit_package)
    current_user.payments.create(
      credit_package: credit_package,
      status: 'pending'
    )
  end

  def initiate_lcl_payment(payment)
    LclPaymentService.new(payment).initiate_payment
  end

  def process_payment_callback
    LclPaymentService.new(@payment).handle_callback(params)
  end

  def handle_payment_error(error_message)
    @payment.update!(status: 'failed')
    @credit_packages = CreditPackage.active.ordered
    flash.now[:alert] = "Erreur lors de l'initiation du paiement: #{error_message}"
    render :new, status: :unprocessable_entity
  end

  def render_new_with_packages
    @credit_packages = CreditPackage.active.ordered
    render :new, status: :unprocessable_entity
  end

  def redirect_with_status_message(status)
    case status
    when 'completed'
      redirect_to payments_path, notice: 'Paiement effectué avec succès ! Vos crédits ont été ajoutés.'
    when 'cancelled'
      redirect_to new_payment_path, alert: 'Paiement annulé.'
    when 'failed'
      redirect_to new_payment_path, alert: 'Le paiement a échoué. Veuillez réessayer.'
    else
      redirect_to new_payment_path, alert: 'Statut de paiement inconnu.'
    end
  end
end
