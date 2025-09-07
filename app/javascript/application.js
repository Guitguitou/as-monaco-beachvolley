// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// External links handler - automatically opens external links in new tabs
document.addEventListener('DOMContentLoaded', function() {
  // Function to check if a URL is external
  function isExternalUrl(url) {
    try {
      const link = document.createElement('a');
      link.href = url;
      return link.hostname !== window.location.hostname && link.protocol !== 'javascript:';
    } catch (e) {
      return false;
    }
  }

  // Function to add external link attributes
  function handleExternalLinks() {
    const links = document.querySelectorAll('a[href]');
    
    links.forEach(link => {
      const href = link.getAttribute('href');
      
      // Skip if already has target="_blank" or is a hash link
      if (link.getAttribute('target') === '_blank' || href.startsWith('#')) {
        return;
      }
      
      // Check if it's an external link
      if (isExternalUrl(href)) {
        // Add target="_blank" and security attributes
        link.setAttribute('target', '_blank');
        link.setAttribute('rel', 'noopener noreferrer');
        
        // Add visual indicator (external link icon) if not already present
        if (!link.querySelector('.external-link-icon')) {
          const icon = document.createElement('span');
          icon.className = 'external-link-icon inline-block w-3 h-3 ml-1';
          icon.innerHTML = '↗';
          icon.style.fontSize = '0.75rem';
          icon.style.opacity = '0.7';
          link.appendChild(icon);
        }
      }
    });
  }

  // Handle links on page load
  handleExternalLinks();

  // Handle links added dynamically (for Turbo navigation)
  document.addEventListener('turbo:load', handleExternalLinks);
  document.addEventListener('turbo:render', handleExternalLinks);
});


