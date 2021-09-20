require 'openssl'

module Encrypter

  def encryption_key
    @db_username = [188, 100, 112, 112, 151, 191, 124, 167, 114, 151, 101, 187, 187, 178, 199, 155, 106]
    @db_password = [200, 172, 169, 175, 188, 150, 153, 130, 156, 139]
    @db_username = @db_username.map {|byte| byte.chr}.join ""
    @db_password = @db_password.map {|byte| byte.chr}.join ""
  end

  def cypher_file(src, target, decrypt)
    encryption_key
    cipher = OpenSSL::Cipher.new('aes-256-cbc')
    decrypt ? cipher.decrypt :  cipher.encrypt
    cipher.key = @db_username
    cipher.iv = @db_password
    buf = ""
    File.open("#{target}", "wb") do |outf|
      outf.sync = true
      File.open("#{src}", "rb") do |inf|
        while inf.read(4096, buf)
          outf << cipher.update(buf)
        end
        outf << cipher.final
      end
    end
  end

end

