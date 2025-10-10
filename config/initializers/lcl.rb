# frozen_string_literal: true

# Initialisation du client LCL/Sherlock
# Charge automatiquement le module LCL au démarrage de Rails

require Rails.root.join('lib', 'lcl')

# Vérifier la configuration au démarrage (uniquement en production)
if Rails.env.production?
  begin
    Lcl.client.configured?
    Rails.logger.info "✓ LCL Client configured successfully"
  rescue Lcl::Client::ConfigurationError => e
    Rails.logger.warn "⚠ LCL Client configuration warning: #{e.message}"
    Rails.logger.warn "  Payment features may not work correctly"
  end
end

