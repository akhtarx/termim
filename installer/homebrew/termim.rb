class Termim < Formula
  desc "Directory & Context-aware terminal history and command intelligence"
  homepage "https://github.com/akhtarx/termim"
  url "https://github.com/akhtarx/termim/archive/refs/tags/v1.1.4.tar.gz"
  # Note: When releasing v1.1.4, update this SHA256 checksum with the value of the release tarball.
  # You can find it by running: curl -sSL https://github.com/akhtarx/termim/archive/refs/tags/v1.1.4.tar.gz | sha256sum
  sha256 "d40e11894d0ab02a11b5217ab9cbecbecbecbecbecbecbecbecbecbecbecbecb"
  license "MIT"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  def caveats
    <<~EOS
      To enable Termim context-aware tracking in your shell, add the integration command to your configuration:

      For Bash, add to your ~/.bashrc:
        eval "$(termim init bash)"

      For Zsh, add to your ~/.zshrc:
        eval "$(termim init zsh)"

      For Fish, add to your ~/.config/fish/config.fish:
        termim init fish | source
    EOS
  end

  test do
    assert_match "termim", shell_output("#{bin}/termim --version")
  end
end
