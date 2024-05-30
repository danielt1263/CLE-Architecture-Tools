Pod::Spec.new do |spec|

  spec.name         = "Cause-Logic-Effect"
  spec.version      = "7.2.1"
  spec.summary      = "Tools for developing using the Cause-Logic-Effect architecture."
  spec.description  = <<-DESC
  The Cause-Logic-Effect architecture allows you to write code using a more functional style. The repo also have templates for creating view controllers using the CLE approach.
                   DESC

  spec.homepage     = "https://github.com/danielt1263/CLE-Architecture-Tools"
  spec.license      = "MIT"
  spec.requires_arc = true
  spec.author       = { "Daniel Tartaglia" => "danielt1263@gmail.com" }
  spec.platform     = :ios
  spec.platform     = :ios, "15.6"
  spec.source       = { :git => "https://github.com/danielt1263/CLE-Architecture-Tools.git", :tag => "#{spec.version}" }
  spec.source_files  = "Utilities/**/*.swift"
  spec.dependency "RxSwift", "~> 6.0"
  spec.dependency "RxCocoa", "~> 6.0"
  spec.swift_version = '5.5'
  
end
