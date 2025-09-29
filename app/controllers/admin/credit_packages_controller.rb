class Admin::CreditPackagesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_credit_package, only: [:show, :edit, :update, :destroy]

  def index
    @credit_packages = CreditPackage.ordered
  end

  def show
  end

  def new
    @credit_package = CreditPackage.new
  end

  def create
    @credit_package = CreditPackage.new(credit_package_params)
    
    if @credit_package.save
      redirect_to admin_credit_packages_path, notice: 'Forfait créé avec succès.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @credit_package.update(credit_package_params)
      redirect_to admin_credit_packages_path, notice: 'Forfait mis à jour avec succès.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @credit_package.payments.any?
      redirect_to admin_credit_packages_path, alert: 'Impossible de supprimer un forfait qui a des paiements associés.'
    else
      @credit_package.destroy
      redirect_to admin_credit_packages_path, notice: 'Forfait supprimé avec succès.'
    end
  end

  private

  def set_credit_package
    @credit_package = CreditPackage.find(params[:id])
  end

  def credit_package_params
    params.require(:credit_package).permit(:name, :description, :credits, :price_cents, :active)
  end

  def ensure_admin!
    redirect_to root_path unless current_user&.admin?
  end
end
