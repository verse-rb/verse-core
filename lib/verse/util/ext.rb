# frozen_string_literal: true

# A very few monkey patching to make things easier.

class BigDecimal
  # Return a double precision representation of the big decimal number.
  def to_json(*opts)
    to_f.to_json(*opts)
  end
end
