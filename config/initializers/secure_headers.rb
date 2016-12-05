SecureHeaders::Configuration.default do |config|
  config.cookies = {
    secure: true, # mark all cookies as "Secure"
    httponly: true, # mark all cookies as "HttpOnly"
    samesite: {
      lax: true # mark all cookies as SameSite=lax
    }
  }
  config.hsts = "max-age=#{20.years.to_i}; includeSubdomains; preload"
  config.x_frame_options = "DENY"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "1; mode=block"
  config.x_download_options = "noopen"
  config.x_permitted_cross_domain_policies = "none"
  config.referrer_policy = "origin-when-cross-origin"
  config.csp = {
    # "meta" values. these will shaped the header, but the values are not included in the header.
    # report_only: true,      # default: false [DEPRECATED from 3.5.0: instead, configure csp_report_only]
    preserve_schemes: true, # default: false. Schemes are removed from host sources to save bytes and discourage mixed content.

    # directive values: these values will directly translate into source directives
    # default_src: %w(https: 'self'),
    default_src: %w(https: 'self'),
    base_uri: %w('self'),
    block_all_mixed_content: true, # see http://www.w3.org/TR/mixed-content/
    child_src: %w('self' *.facebook.com *.facebook.net *.twitter.com *.disqus.com), # if child-src isn't supported, the value for frame-src will be set.
    connect_src: %w('self' wss:),
    font_src: %w('self' data:),
    # form_action: %w('self' github.com),
    form_action: %w('self'),
    frame_ancestors: %w('none'),
    img_src: %W('self' data: *.fbcdn.net *.facebook.net *.facebook.com *.twimg.com *.google-analytics.com *.twitter.com *.disqus.com *.apple.com.edgekey.net *.thawte.com #{ENV['S3_BUCKET']}.s3.amazonaws.com #{ENV['CLOUDFRONT_SERVER']}.cloudfront.net),
    # media_src: %w(utoob.com),
    object_src: %w('self' *.youtube.com *.vimeo.com),
    # plugin_types: %w(application/x-shockwave-flash),
    script_src: %w('self' 'unsafe-inline' 'unsafe-eval' *.google-analytics.com *.twitter.com *.twimg.com *.facebook.com *.facebook.net *.disqus.com *.thawte.com),
    style_src: %w('self' 'unsafe-inline' *.twitter.com *.twimg.com),
    upgrade_insecure_requests: true, # see https://www.w3.org/TR/upgrade-insecure-requests/
    report_uri: %W(#{ENV["REPORT_URI_CSP"]})
  }
  # This is available only from 3.5.0; use the `report_only: true` setting for 3.4.1 and below.
  config.csp_report_only = config.csp.merge({
    img_src: %W(#{ENV['CLOUDFRONT_SERVER']}.cloudfront.net),
    report_uri: %W(#{ENV["REPORT_URI_CSP_REPORT_ONLY"]})
  })
  config.hpkp = {
    report_only: false,
    max_age: 60.days.to_i,
    include_subdomains: true,
    report_uri: "#{ENV["REPORT_URI_PKP"]}",
    pins: [
      {sha256: "#{ENV["HPKP_FINGERPRINT"]}"},
      {sha256: "#{ENV["HPKP_FINGERPRINT_INTERMEDIATE"]}"},
      {sha256: "#{ENV["HPKP_FINGERPRINT_ROOT"]}"},
      {sha256: "#{ENV["HPKP_FINGERPRINT_CSR"]}"}
    ]
  }
  # byebug
end