{
  description =
    "NixOS compatible environment for Matt Keeter's Massively Parallel Rendering (mpr) project.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-old.url = "github:NixOS/nixpkgs/nixos-24.05";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-old, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        old-pkgs = import nixpkgs-old {
          inherit system;
          config.allowUnfree = true;
        };
        eigen337 = pkgs.eigen.overrideAttrs (oldAttrs: rec {
          version = "3.3.7";
          src = pkgs.fetchFromGitLab {
            owner = "libeigen";
            repo = "eigen";
            rev = "3.3.7";
            sha256 = "oXJ4V5rakL9EPtQF0Geptl0HMR8700FdSrOB09DbbMQ=";
          };
          nativeBuildInputs = [ old-pkgs.cmake pkgs.ninja ];

          # 2. Fix the broken .pc file path that Nix is complaining about
          # I believe it creates a path like: `//nix/store/...` and fails.
          postInstall = ''
            sed -i "s|Cflags:.*|Cflags: -I''${out}/include/eigen3|" $out/share/pkgconfig/eigen3.pc
          '';
        });
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            # CPP
            llvmPackages.clang
            llvmPackages.lldb
            llvmPackages.clang-tools

            # Cuda
            cudaPackages.cuda_nvcc
            gcc13

            # CMake
            old-pkgs.cmake # Old CMake to support libfive's 2.28 version.
            ninja

            # Scripts
            just
            pkg-config

          ];

          buildInputs = with pkgs; [
            # OpenGL
            glfw
            glew
            libGL

            # Libraries
            boost
            qt5.qtbase
            cudaPackages.cuda_cudart

            ### libraries for libfive
            guile
            eigen337

          ];

          shellHook = ''
            export CUDA_PATH=${pkgs.cudaPackages.cuda_cudart}
            export NVCC_CCBIN="${pkgs.gcc13}/bin/gcc"
            export CUDAFLAGS="-std=c++14"

            export CMAKE_ARGS="-DCMAKE_CUDA_ARCHITECTURES=native"

            export LD_LIBRARY_PATH=${pkgs.libGL}/lib:$LD_LIBRARY_PATH

            export LD_LIBRARY_PATH=/run/opengl-driver/lib:$LD_LIBRARY_PATH

            export CXXFLAGS="-std=c++17" 
            export CFLAGS="-std=c17"

            export CC=clang
            export CXX=clang++

            cmake --version
            $NVCC_CCBIN --version
            echo -n "ninja version: "
            ninja --version

          '';
        };
      });
}
