class IcloudNosync < Formula
  desc "Prevent a file or directory from syncing with iCloud by adding the nosync extension."
  homepage "https://github.com/peterbrain/icloud-nosync"
  url "https://github.com/peterbrain/icloud-nosync/archive/0.1.0.tar.gz"
  sha256 "8dd789d48e282a0a820e97f0494a5a7e6045b1be3bb9192d36a186c5dc65c304"
  license "MIT"
  version "0.1.0"

  def install
    bin.install "nosync.sh" => "nosync"
  end

  test do
    system "#{bin}/nosync", "--version"
  end
end
