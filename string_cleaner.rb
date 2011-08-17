module StringCleaner
  def digits
    self.gsub(/\D/, "")
  end
end