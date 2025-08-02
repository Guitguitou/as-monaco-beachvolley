// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// import '@gouvfr/dsfr/dist/dsfr/dsfr.module';
// import '@gouvfr/dsfr/dist/dsfr/dsfr.module.min.css';

document.addEventListener('DOMContentLoaded', () => {
  window.dsfr?.start();
});
