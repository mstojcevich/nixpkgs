{ stdenv, fetchFromGitHub, rustPlatform, clang, llvmPackages, rustfmt, writeScriptBin,
  runtimeShell }:

rustPlatform.buildRustPackage rec {
  pname = "rust-bindgen";
  version = "0.49.3";

  src = fetchFromGitHub {
    owner = "rust-lang";
    repo = pname;
    rev = "v${version}";
    sha256 = "032sgg27pdxlmas67clqldvamd2ncdiw1hmk1hiprcxng7073f4y";
  };

  cargoSha256 = "1311d0wjjj99m59zd2n6r4aq6lwbbpyj54ha2z9g4yd1hn344r91";

  libclang = llvmPackages.libclang.lib; #for substituteAll

  buildInputs = [ libclang ];

  propagatedBuildInputs = [ clang ]; # to populate NIX_CXXSTDLIB_COMPILE

  configurePhase = ''
    export LIBCLANG_PATH="${libclang}/lib"
  '';

  postInstall = ''
    mv $out/bin/{bindgen,.bindgen-wrapped};
    substituteAll ${./wrapper.sh} $out/bin/bindgen
    chmod +x $out/bin/bindgen
  '';

  doCheck = true;
  checkInputs =
    let fakeRustup = writeScriptBin "rustup" ''
      #!${runtimeShell}
      shift
      shift
      exec "$@"
    '';
  in [
    rustfmt
    fakeRustup # the test suite insists in calling `rustup run nightly rustfmt`
    clang
  ];
  preCheck = ''
    # for the ci folder, notably
    patchShebangs .
  '';

  meta = with stdenv.lib; {
    description = "C and C++ binding generator";
    longDescription = ''
      Bindgen takes a c or c++ header file and turns them into
      rust ffi declarations.
      As with most compiler related software, this will only work
      inside a nix-shell with the required libraries as buildInputs.
    '';
    homepage = https://github.com/rust-lang/rust-bindgen;
    license = with licenses; [ bsd3 ];
    platforms = platforms.unix;
    maintainers = [ maintainers.ralith ];
  };
}
