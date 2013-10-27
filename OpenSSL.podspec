Pod::Spec.new do |s|
  s.name         = "OpenSSL"
  s.version      = "1.0.1e"
  s.summary      = "Pre-built OpenSSL for iOS and OSX"
  s.description  = "Supports OSX and iOS Simulator (armv7,armv7s,arm64,i386,x86_64)."
  s.homepage     = "https://github.com/krzak/OpenSSL"
  s.license	     = 'OpenSSL (OpenSSL/SSLeay)'
  s.source       = { :git => "https://github.com/krzak/OpenSSL.git", :tag => "#{s.version}" }

  s.authors       =  {'Mark J. Cox' => 'mark@openssl.org',
                     'Ralf S. Engelschall' => 'rse@openssl.org',
                     'Dr. Stephen Henson' => 'steve@openssl.org',
                     'Ben Laurie' => 'ben@openssl.org',
                     'Lutz Jänicke' => 'jaenicke@openssl.org',
                     'Nils Larsch' => 'nils@openssl.org',
                     'Richard Levitte' => 'nils@openssl.org',
                     'Bodo Möller' => 'bodo@openssl.org',
                     'Ulf Möller' => 'ulf@openssl.org',
                     'Andy Polyakov' => 'appro@openssl.org',
                     'Geoff Thorpe' => 'geoff@openssl.org',
                     'Holger Reif' => 'holger@openssl.org',
                     'Paul C. Sutton' => 'geoff@openssl.org',
                     'Eric A. Young' => 'eay@cryptsoft.com',
                     'Tim Hudson' => 'tjh@cryptsoft.com',
                     'Justin Plouffe' => 'plouffe.justin@gmail.com'}
  
  s.ios.platform          = :ios, '5.1.1'
  s.ios.deployment_target = '5.1.1'
  s.ios.public_header_files = 'include-ios/openssl/**/.h'
  s.ios.preserve_paths      = 'lib-ios/libcrypto.a', 'lib-ios/libssl.a'
  s.ios.vendored_libraries  = 'lib-ios/libcrypto.a', 'lib-ios/libssl.a'

  s.osx.platform          = :osx, '10.9'
  s.osx.deployment_target = '10.7'
  s.osx.public_header_files = 'include-osx/openssl/**/*.h'
  s.osx.preserve_paths      = 'lib-osx/libcrypto.a', 'lib-osx/libssl.a'
  s.osx.vendored_libraries  = 'lib-osx/libcrypto.a', 'lib-osx/libssl.a'

  s.libraries = 'ssl', 'crypto'
end