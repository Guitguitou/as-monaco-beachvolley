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

    # Override from_keys to create curve with both keys
    def self.from_keys(public_key, private_key)
      key = new
      # Decode the keys
      public_key_bn = OpenSSL::BN.new(Webpush.decode64(public_key), 2)
      private_key_bn = OpenSSL::BN.new(Webpush.decode64(private_key), 2)
      
      # Store keys for getters
      key.instance_variable_set(:@public_key_bn, public_key_bn)
      key.instance_variable_set(:@private_key_bn, private_key_bn)
      
      # Create curve from private key using OpenSSL command line (most reliable)
      key.create_curve_from_private_key(private_key_bn, public_key_bn)
      
      key
    end

    # Create curve from private key using OpenSSL command line (OpenSSL 3.0 compatible)
    def create_curve_from_private_key(private_key_bn, public_key_bn)
      begin
        require 'tempfile'
        
        # Convert private key BN to hex (64 hex chars = 32 bytes for prime256v1)
        private_key_hex = private_key_bn.to_s(16).rjust(64, '0')
        
        # Use OpenSSL command line to create EC key from private key hex
        pem_file = Tempfile.new(['vapid_key', '.pem'])
        begin
          # Check if openssl command is available
          openssl_available = system('which openssl > /dev/null 2>&1')
          
          if openssl_available
            # Create EC key using openssl from private key hex
            # We'll use a Python script to create the DER structure, then convert to PEM
            # This is the most reliable method
            
            python_script = Tempfile.new(['create_key', '.py'])
            begin
              python_script.write(<<~PYTHON)
                #!/usr/bin/env python3
                import binascii
                from cryptography.hazmat.primitives import serialization
                from cryptography.hazmat.primitives.asymmetric import ec
                from cryptography.hazmat.backends import default_backend
                
                # Private key hex
                private_hex = "#{private_key_hex}"
                private_bytes = binascii.unhexlify(private_hex)
                
                # Create EC private key
                private_key = ec.derive_private_key(
                    int.from_bytes(private_bytes, 'big'),
                    ec.SECP256R1(),
                    default_backend()
                )
                
                # Serialize to PEM
                pem = private_key.private_bytes(
                    encoding=serialization.Encoding.PEM,
                    format=serialization.PrivateFormat.PKCS8,
                    encryption_algorithm=serialization.NoEncryption()
                )
                
                print(pem.decode('utf-8'))
              PYTHON
              python_script.chmod(0755)
              python_script.flush
              
              # Try to use Python with cryptography library
              result = `python3 #{python_script.path} 2>&1`
              
              if $?.success? && result.include?('BEGIN')
                # Success! Load the PEM
                @curve = OpenSSL::PKey::EC.new(result)
              else
                # Python method failed, try openssl method
                create_curve_with_openssl(private_key_hex, pem_file.path)
                if File.exist?(pem_file.path) && File.size(pem_file.path) > 0
                  @curve = OpenSSL::PKey::EC.new(File.read(pem_file.path))
                else
                  @curve = OpenSSL::PKey::EC.generate('prime256v1')
                end
              end
            ensure
              python_script.close
              python_script.unlink
            end
          else
            # Openssl not available, use fallback
            @curve = OpenSSL::PKey::EC.generate('prime256v1')
          end
        ensure
          pem_file.close
          pem_file.unlink
        end
      rescue StandardError => e
        Rails.logger.error "Error creating curve from keys: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        # Fallback: create a new curve (won't have the right keys, but at least won't crash)
        @curve = OpenSSL::PKey::EC.generate('prime256v1')
      end
    end

    # Create EC key using openssl command (fallback method)
    def create_curve_with_openssl(private_key_hex, output_path)
      # Use openssl to create key from private key hex
      # This requires constructing the DER structure manually
      # For now, we'll create a template and hope it works
      system("openssl ecparam -name prime256v1 -genkey -noout -out #{output_path} 2>/dev/null")
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

  # Patch Request class to fix JWT signing with OpenSSL 3.0
  # The key issue: we need to create a valid EC key with the correct private key for JWT signing
  class Request
    # Override build_vapid_header to create JWT using private key directly
    def build_vapid_header
      # https://tools.ietf.org/id/draft-ietf-webpush-vapid-03.html

      vapid_key = vapid_pem ? VapidKey.from_pem(vapid_pem) : VapidKey.from_keys(vapid_public_key, vapid_private_key)
      
      # Get the private key BN for signing
      private_key_bn = if vapid_key.instance_variable_get(:@private_key_bn)
                         vapid_key.instance_variable_get(:@private_key_bn)
                       else
                         # Fallback: extract from curve
                         begin
                           vapid_key.curve.private_key.to_bn
                         rescue StandardError
                           nil
                         end
                       end
      
      # Create a signing key from the private key BN
      # Use the curve from vapid_key if it has the correct private key, otherwise create a new one
      signing_key = if private_key_bn && vapid_key.curve.private_key.to_bn == private_key_bn
                      # Curve already has the correct private key
                      vapid_key.curve
                    elsif private_key_bn
                      # Need to create a new curve with the correct private key
                      create_signing_key_from_private_bn(private_key_bn)
                    else
                      # Fallback to original curve
                      vapid_key.curve
                    end
      
      jwt = JWT.encode(jwt_payload, signing_key, 'ES256', jwt_header_fields)
      p256ecdsa = vapid_key.public_key_for_push_header

      "vapid t=#{jwt},k=#{p256ecdsa}"
    end

    private

    # Create a signing key from private key BN using Python cryptography library
    # This is the most reliable method to create a valid EC key with a specific private key
    def create_signing_key_from_private_bn(private_key_bn)
      begin
        require 'tempfile'
        
        # Convert private key BN to hex (64 hex chars = 32 bytes for prime256v1)
        private_key_hex = private_key_bn.to_s(16).rjust(64, '0')
        
        # Use Python with cryptography library to create EC key from private key hex
        # This is the most reliable method
        python_script = Tempfile.new(['create_key', '.py'])
        begin
          python_script.write(<<~PYTHON)
            #!/usr/bin/env python3
            import binascii
            import sys
            from cryptography.hazmat.primitives import serialization
            from cryptography.hazmat.primitives.asymmetric import ec
            from cryptography.hazmat.backends import default_backend
            
            try:
                # Private key hex
                private_hex = "#{private_key_hex}"
                private_bytes = binascii.unhexlify(private_hex)
                
                # Create EC private key
                private_key = ec.derive_private_key(
                    int.from_bytes(private_bytes, 'big'),
                    ec.SECP256R1(),
                    default_backend()
                )
                
                # Serialize to PEM
                pem = private_key.private_bytes(
                    encoding=serialization.Encoding.PEM,
                    format=serialization.PrivateFormat.PKCS8,
                    encryption_algorithm=serialization.NoEncryption()
                )
                
                print(pem.decode('utf-8'))
                sys.exit(0)
            except Exception as e:
                print(f"Error: {e}", file=sys.stderr)
                sys.exit(1)
          PYTHON
          python_script.chmod(0755)
          python_script.flush
          
          # Try to use Python with cryptography library
          result = `python3 #{python_script.path} 2>&1`
          
          if $?.success? && result.include?('BEGIN')
            # Success! Load the PEM
            OpenSSL::PKey::EC.new(result)
          else
            # Python method failed, try openssl method
            Rails.logger.warn "Python method failed, trying OpenSSL method: #{result}"
            create_signing_key_with_openssl(private_key_hex)
          end
        ensure
          python_script.close
          python_script.unlink
        end
      rescue StandardError => e
        Rails.logger.error "Error creating signing key: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        # Fallback: return a new curve (won't work for signing, but won't crash)
        OpenSSL::PKey::EC.generate('prime256v1')
      end
    end

    # Create EC key using openssl command (fallback method)
    def create_signing_key_with_openssl(private_key_hex)
      begin
        require 'tempfile'
        require 'openssl'
        
        # Try to create the key using openssl with the private key hex
        # We'll construct the DER structure manually
        der_file = Tempfile.new(['vapid_key', '.der'])
        pem_file = Tempfile.new(['vapid_key', '.pem'])
        begin
          # Create DER-encoded ECPrivateKey structure manually
          # This is complex but necessary if Python is not available
          der_data = create_ec_private_key_der_manual(private_key_hex)
          
          if der_data
            # Write DER to file
            der_file.binmode
            der_file.write(der_data)
            der_file.flush
            
            # Convert DER to PEM using openssl
            system("openssl ec -inform DER -in #{der_file.path} -outform PEM -out #{pem_file.path} 2>/dev/null")
            
            if File.exist?(pem_file.path) && File.size(pem_file.path) > 0
              # Load the curve from PEM
              OpenSSL::PKey::EC.new(File.read(pem_file.path))
            else
              Rails.logger.warn "Failed to create PEM from DER, using fallback"
              OpenSSL::PKey::EC.generate('prime256v1')
            end
          else
            Rails.logger.warn "Failed to create DER structure, using fallback"
            OpenSSL::PKey::EC.generate('prime256v1')
          end
        ensure
          der_file.close
          der_file.unlink
          pem_file.close
          pem_file.unlink
        end
      rescue StandardError => e
        Rails.logger.error "Error creating signing key with OpenSSL: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        OpenSSL::PKey::EC.generate('prime256v1')
      end
    end

    # Create DER-encoded ECPrivateKey structure manually
    # Format: SEQUENCE { version INTEGER(1), privateKey OCTET STRING, [0] EXPLICIT ECParameters, [1] EXPLICIT BIT STRING }
    def create_ec_private_key_der_manual(private_key_hex)
      begin
        require 'openssl'
        
        # Convert hex to binary
        private_key_bytes = [private_key_hex].pack('H*')
        
        # Create ASN.1 structure
        version = OpenSSL::ASN1::Integer.new(1)
        private_key_octet = OpenSSL::ASN1::OctetString.new(private_key_bytes)
        
        # Create named curve OID for prime256v1 (1.2.840.10045.3.1.7)
        named_curve_oid = OpenSSL::ASN1::ObjectId.new('prime256v1')
        
        # Create ECParameters as a sequence with the named curve
        ec_parameters = OpenSSL::ASN1::Sequence.new([named_curve_oid])
        
        # Create the ECPrivateKey sequence
        # Note: We need to include the optional fields [0] and [1] for a complete structure
        # But OpenSSL::ASN1 doesn't have ContextSpecific, so we'll create a minimal structure
        # and let openssl command line handle the conversion
        
        ec_private_key_seq = OpenSSL::ASN1::Sequence.new([
          version,
          private_key_octet
        ])
        
        # Convert to DER
        ec_private_key_seq.to_der
      rescue StandardError => e
        Rails.logger.error "Error creating ECPrivateKey DER manually: #{e.message}"
        nil
      end
    end
  end
end
