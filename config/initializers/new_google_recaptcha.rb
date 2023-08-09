if Object.const_defined?('NewGoogleRecaptcha')
  NewGoogleRecaptcha.setup do |config|
    config.site_key   = "6LfCVo8nAAAAAEtIYrKdZeWNCNF12j4OTgMbpLpA"
    config.secret_key = "6LfCVo8nAAAAAFGFpgy-PY7nuPtL7pDX1yydAMsz"
    config.minimum_score = 0.5
  end
end
