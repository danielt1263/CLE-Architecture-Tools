Pod::Spec.new do |spec|

  spec.name         = "Cause-Logic-Effect"
  spec.version      = "0.0.1"
  spec.summary      = "Tools for developing using the Cause-Logic-Effect architecture."
  spec.description  = <<-DESC
  The Cause-Logic-Effect architecture allows you to write code using a more functional style. The repo also have templates for creating view controllers using the CLE approach.
                   DESC

  spec.homepage     = "https://github.com/danielt1263/CLE-Architecture-Tools"
  spec.license      = "MIT"
  spec.author             = { "Daniel Tartaglia" => "danielt1263@gmail.com" }
  spec.platform     = :ios
  spec.platform     = :ios, "8.0"
  spec.source       = { :git => "https://github.com/danielt1263/CLE-Architecture-Tools.git", :tag => "#{spec.version}" }
  spec.source_files  = "Utilities/**/*.swift"
  spec.frameworks = "RxSwift", "RxCocoa"
end
