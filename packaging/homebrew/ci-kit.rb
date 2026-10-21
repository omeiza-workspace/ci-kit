class CiKit < Formula
  desc "Run your CI on your laptop, before you push"
  homepage "https://github.com/omeiza-workspace/ci-kit"
  version "0.1.0"
  license "MIT"

  head "https://github.com/omeiza-workspace/ci-kit.git", branch: "main"

  depends_on "node"

  def install
    libexec.install Dir["*"]
    bin.install_symlink libexec/"bin/ci"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/ci version")
    assert_match "local CI kit", shell_output("#{bin}/ci help")
  end
end
