# frozen_string_literal: true

require_relative "account_record"

# Encoder encoding weirdly the email field
module EmailEncoder
  extend self

  def self.caesar_cipher(str, shift = 13)
    str.chars.map { |c|
      if c =~ /[a-z]/
        (((c.ord - "a".ord + shift) % 26) + "a".ord).chr
      elsif c =~ /[A-Z]/
        (((c.ord - "A".ord + shift) % 26) + "A".ord).chr
      else
        c
      end
    }.join
  end

  def encode(email)
    return nil if email.nil?

    caesar_cipher(email)
  end

  def decode(email)
    return nil if email.nil?

    caesar_cipher(email)
  end
end

class AccountRepository < Verse::Model::InMemory::Repository
  # Use custom primary key
  primary_key :user_id

  encoder :email, EmailEncoder
end
