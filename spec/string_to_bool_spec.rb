RSpec.describe String do

  it "return true if one of these ['true', 't', 'yes', 'y',  '1']" do
    truth_patterns = ['true', 't', 'yes', 'y',  '1']
    truth_patterns.each {|pat| expect(pat.to_bool).to be_truthy }
    truth_patterns.each {|pat| expect(pat.upcase.to_bool).to be_truthy }
  end

  it "return false if one of these ['false', 'f', 'no', 'n',  '0']" do
    false_patterns = ['false', 'f', 'no', 'n',  '0']
    false_patterns.each {|pat| expect(pat.to_bool).to be_falsy }
    false_patterns.each {|pat| expect(pat.upcase.to_bool).to be_falsy }
  end

end
