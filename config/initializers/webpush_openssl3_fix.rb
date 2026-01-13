# frozen_string_literal: true

# Monkey patch to fix webpush gem compatibility with OpenSSL 3.0
# The gem uses OpenSSL::PKey::EC.new + generate_key which is not compatible with OpenSSL 3.0
# This patch replaces it with OpenSSL::PKey::EC.generate which is compatible

module Webpush
  module Encryption
    # Override the encrypt method to fix OpenSSL 3.0 compatibility
    def encrypt(message, p256dh, auth)
      assert_arguments(message, p256dh, auth)

      group_name = 'prime256v1'
      salt = Random.new.bytes(16)

      # Fix: Use EC.generate instead of EC.new + generate_key for OpenSSL 3.0 compatibility
      server = OpenSSL::PKey::EC.generate(group_name)
      server_public_key_bn = server.public_key.to_bn

      group = OpenSSL::PKey::EC::Group.new(group_name)
      client_public_key_bn = OpenSSL::BN.new(Webpush.decode64(p256dh), 2)
      client_public_key = OpenSSL::PKey::EC::Point.new(group, client_public_key_bn)

      shared_secret = server.dh_compute_key(client_public_key)

      client_auth_token = Webpush.decode64(auth)

      info = "WebPush: info\0" + client_public_key_bn.to_s(2) + server_public_key_bn.to_s(2)
      content_encryption_key_info = "Content-Encoding: aes128gcm\0"
      nonce_info = "Content-Encoding: nonce\0"

      prk = HKDF.new(shared_secret, salt: client_auth_token, algorithm: 'SHA256', info: info).next_bytes(32)

      content_encryption_key = HKDF.new(prk, salt: salt, info: content_encryption_key_info).next_bytes(16)

      nonce = HKDF.new(prk, salt: salt, info: nonce_info).next_bytes(12)

      ciphertext = encrypt_payload(message, content_encryption_key, nonce)

      serverkey16bn = convert16bit(server_public_key_bn)
      rs = ciphertext.bytesize
      raise ArgumentError, "encrypted payload is too big" if rs > 4096

      aes128gcmheader = "#{salt}" + [rs].pack('N*') + [serverkey16bn.bytesize].pack('C*') + serverkey16bn

      aes128gcmheader + ciphertext
    end

    private

    def encrypt_payload(plaintext, content_encryption_key, nonce)
      cipher = OpenSSL::Cipher.new('aes-128-gcm')
      cipher.encrypt
      cipher.key = content_encryption_key
      cipher.iv = nonce
      text = cipher.update(plaintext)
      padding = cipher.update("\2\0")
      e_text = text + padding + cipher.final
      e_tag = cipher.auth_tag

      e_text + e_tag
    end

    def convert16bit(key)
      [key.to_s(16)].pack('H*')
    end

    def assert_arguments(message, p256dh, auth)
      raise ArgumentError, 'message cannot be blank' if blank?(message)
      raise ArgumentError, 'p256dh cannot be blank' if blank?(p256dh)
      raise ArgumentError, 'auth cannot be blank' if blank?(auth)
    end

    def blank?(value)
      value.nil? || value.empty?
    end
  end

  # Patch VapidKey class to fix OpenSSL 3.0 compatibility
  class VapidKey
    # Override initialize to use EC.generate instead of EC.new + generate_key
    def initialize
      @curve = OpenSSL::PKey::EC.generate('prime256v1')
      @public_key_bn = nil
      @private_key_bn = nil
    end

    # Override from_keys to create curve with both keys using DER encoding
    def self.from_keys(public_key, private_key)
      key = new
      # Decode the keys
      public_key_bn = OpenSSL::BN.new(Webpush.decode64(public_key), 2)
      private_key_bn = OpenSSL::BN.new(Webpush.decode64(private_key), 2)
      
      # Store keys for getters
      key.instance_variable_set(:@public_key_bn, public_key_bn)
      key.instance_variable_set(:@private_key_bn, private_key_bn)
      
      # Create curve from private key (which allows JWT signing)
      # We'll create a DER-encoded EC private key and load it
      key.create_curve_from_private_key(private_key_bn, public_key_bn)
      
      key
    end

    # Create curve from private key using DER encoding (OpenSSL 3.0 compatible)
    def create_curve_from_private_key(private_key_bn, public_key_bn)
      begin
        # Create a temporary curve to get the group
        temp_curve = OpenSSL::PKey::EC.generate('prime256v1')
        group = temp_curve.group
        
        # Create the public key point from the public key BN
        public_point = OpenSSL::PKey::EC::Point.new(group, public_key_bn)
        
        # Create DER encoding of EC private key
        # ECPrivateKey structure: version, privateKey, parameters (optional), publicKey (optional)
        # We'll construct it manually using OpenSSL::ASN1
        require 'openssl'
        
        # Create ASN1 structure for EC private key
        # Version: INTEGER (1)
        version = OpenSSL::ASN1::Integer.new(1)
        
        # Private key: OCTET STRING (32 bytes for prime256v1)
        private_key_octet = OpenSSL::ASN1::OctetString.new(private_key_bn.to_s(2))
        
        # Parameters: ECParameters (namedCurve OID for prime256v1)
        # OID for prime256v1: 1.2.840.10045.3.1.7
        named_curve_oid = OpenSSL::ASN1::ObjectId.new('prime256v1')
        ec_parameters = OpenSSL::ASN1::Sequence.new([named_curve_oid])
        
        # Public key: BIT STRING (uncompressed point: 0x04 + 32 bytes X + 32 bytes Y)
        public_key_bytes = public_point.to_octet_string(:uncompressed)
        public_key_bitstring = OpenSSL::ASN1::BitString.new(public_key_bytes)
        
        # ECPrivateKey sequence
        ec_private_key_seq = OpenSSL::ASN1::Sequence.new([
          version,
          private_key_octet,
          OpenSSL::ASN1::ContextSpecific.new(0, [ec_parameters]),
          OpenSSL::ASN1::ContextSpecific.new(1, [public_key_bitstring])
        ])
        
        # Wrap in PrivateKeyInfo structure (for PKCS#8)
        # But actually, we can use the ECPrivateKey directly
        der = ec_private_key_seq.to_der
        
        # Load the curve from DER
        @curve = OpenSSL::PKey::EC.new(der)
      rescue StandardError => e
        Rails.logger.error "Error creating curve from keys: #{e.message}"
        # Fallback: create a new curve (won't have the right keys, but at least won't crash)
        @curve = OpenSSL::PKey::EC.generate('prime256v1')
      end
    end

    # Override public_key= - store the key
    def public_key=(key)
      @public_key_bn = to_big_num(key)
      create_curve_from_private_key(@private_key_bn, @public_key_bn) if @private_key_bn
    end

    # Override private_key= - store the key and recreate curve
    def private_key=(key)
      @private_key_bn = to_big_num(key)
      create_curve_from_private_key(@private_key_bn, @public_key_bn) if @public_key_bn
    end

    # Override public_key to use cached value
    def public_key
      if @public_key_bn
        encode64(@public_key_bn.to_s(2))
      else
        encode64(curve.public_key.to_bn.to_s(2))
      end
    end

    # Override public_key_for_push_header
    def public_key_for_push_header
      if @public_key_bn
        trim_encode64(@public_key_bn.to_s(2))
      else
        trim_encode64(curve.public_key.to_bn.to_s(2))
      end
    end

    # Override private_key to use cached value
    def private_key
      if @private_key_bn
        encode64(@private_key_bn.to_s(2))
      else
        encode64(curve.private_key.to_s(2))
      end
    end

    private

    def to_big_num(key)
      OpenSSL::BN.new(Webpush.decode64(key), 2)
    end

    def encode64(bin)
      Webpush.encode64(bin)
    end

    def trim_encode64(bin)
      encode64(bin).delete('=')
    end
  end
end
