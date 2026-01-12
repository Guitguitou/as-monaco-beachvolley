# frozen_string_literal: true

namespace :vapid do
  desc "Generate VAPID keys for push notifications"
  task generate: :environment do
    require "base64"
    require "openssl"

    # Generate EC key pair using OpenSSL directly (compatible with OpenSSL 3.0)
    ec_key = OpenSSL::PKey::EC.generate("prime256v1")
    
    # Private key: 32 bytes (raw binary)
    private_key_raw = ec_key.private_key.to_s(2)
    private_key_b64 = Base64.urlsafe_encode64(private_key_raw, padding: false)

    # Public key: VAPID requires uncompressed format (65 bytes: 0x04 + 32 bytes X + 32 bytes Y)
    # Get the public key in uncompressed format
    public_key_point = ec_key.public_key
    public_key_octet = public_key_point.to_octet_string(:uncompressed)
    
    # Ensure it's exactly 65 bytes (0x04 prefix + 32 bytes X + 32 bytes Y)
    if public_key_octet.length != 65
      raise "Invalid public key length: expected 65 bytes, got #{public_key_octet.length}"
    end
    
    public_key_b64 = Base64.urlsafe_encode64(public_key_octet, padding: false)

    puts "\n=== VAPID Keys Generated ==="
    puts "\nPublic Key:"
    puts public_key_b64
    puts "\nPrivate Key:"
    puts private_key_b64
    puts "\n=== Configuration ==="
    puts "\n📝 Add these to your .env file:"
    puts <<~ENV
      VAPID_PUBLIC_KEY=#{public_key_b64}
      VAPID_PRIVATE_KEY=#{private_key_b64}
      VAPID_SUBJECT=mailto:your-email@example.com
    ENV
    puts "\nOr add to your Rails credentials (alternative):"
    puts "EDITOR='code --wait' bin/rails credentials:edit"
    puts "\nThen add:"
    puts <<~YAML
      vapid:
        public_key: #{public_key_b64}
        private_key: #{private_key_b64}
        subject: mailto:your-email@example.com
    YAML
    puts "\n💡 Note: The system checks .env first, then Rails credentials."
    puts "\n"
  end
end
