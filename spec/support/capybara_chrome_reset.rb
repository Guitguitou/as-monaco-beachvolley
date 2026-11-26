# frozen_string_literal: true

# Capybara 3.40 vide cookies et stockage entre deux tests système via
# `Storage.clearDataForOrigin` avec l'origine `*`, que Chrome 158 refuse
# (« * is not a valid URL »). On retombe alors sur l'effacement des cookies
# et du stockage de l'origine du serveur de test.
module CapybaraChromeReset
  def execute_cdp(cmd, **args)
    super
  rescue ::Selenium::WebDriver::Error::InvalidArgumentError
    raise unless cmd == "Storage.clearDataForOrigin" && args[:origin] == "*"

    super("Network.clearBrowserCookies")
    server = Capybara.current_session.server
    super(cmd, **args, origin: server.base_url) if server
  end
end

Capybara::Selenium::Driver::ChromeDriver.prepend(CapybaraChromeReset)
