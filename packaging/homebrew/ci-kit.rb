class CiKit < Formula
  desc "Run your CI on your laptop, before you push"
  homepage "https://github.com/omeiza-workspace/ci-kit"
  url "https://github.com/omeiza-workspace/ci-kit/releases/download/v0.1.0/ci-kit-v0.1.0.tar.gz"
  version "0.1.0"
  license "MIT"
  sha256 "9d6e72cece7f40e4651b951f454cc8070e2b39bba3866b1469a981337cbda5e0"

  depends_on "node"

  def install
    # The kit installs into share/, because a repository's .ci/ci.mk looks
    # for it in a handful of standard places, and share/ci-kit is one of
    # them.
    (share/"ci-kit").install Dir["*"]
    bin.install_symlink share/"ci-kit"/"bin/ci"
  end

  def caveats
    <<~EOS
      The kit finds itself in several standard places, and a repository's
      .ci/ci.mk looks in all of them. To point it somewhere else, build with:

        make CI_KIT=/path/to/ci-kit ci
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/ci version")
    assert_match "local CI kit", shell_output("#{bin}/ci help")
  end
end
