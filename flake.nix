{
  description = "Modern C++ Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url =
      "github:NixOS/nixpkgs/nixos-24.05"; # Still has CMake 3.31
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-stable, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        stable-pkgs = import nixpkgs-stable {
          inherit system;
          config.allowUnfree = true;
        };
        eigen337 = pkgs.eigen.overrideAttrs (oldAttrs: rec {
          version = "3.3.7";
          src = pkgs.fetchFromGitLab {
            owner = "libeigen";
            repo = "eigen";
            rev = "3.3.7";
            sha256 =
              "oXJ4V5rakL9EPtQF0Geptl0HMR8700FdSrOB09DbbMQ="; # Verify this hash
          };
          nativeBuildInputs = with stable-pkgs; [ cmake ninja ];
          # 2. Fix the broken .pc file path that Nix is complaining about
          # This replaces the broken line with a clean include path
          postInstall = ''
            sed -i "s|Cflags:.*|Cflags: -I''${out}/include/eigen3|" $out/share/pkgconfig/eigen3.pc
          '';
        });
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            llvmPackages.clang
            llvmPackages.lldb
            stable-pkgs.cmake
            ninja
            gcc13
            just
            llvmPackages.clang-tools
            pkg-config
            cudaPackages.cuda_nvcc

            #wayland
            xorg.libXcursor
            xorg.libXrandr
            xorg.libXi
            wayland
            wayland-protocols
            wayland-utils
            libxkbcommon
            mesa
            glfw
            glew
            libGL
          ];

          buildInputs = with pkgs; [
            gtest
            glfw
            glew
            libGL
            # stable-pkgs.nixGL
            boost
            qt5.qtbase
            guile # Added to satisfy libfive-guile dependency
            eigen337
            libpng
            zlib
            cudaPackages.cuda_cudart
            vcpkg

            #wayland
            xorg.libXcursor
            xorg.libXrandr
            xorg.libXi
            wayland
            wayland-protocols
            wayland-utils
            libxkbcommon
          ];

          shellHook = ''
            export VCPKG_ROOT=${pkgs.vcpkg}/share/vcpkg
            export CUDA_PATH=${pkgs.cudaPackages.cuda_cudart}
            export NVCC_CCBIN="${pkgs.gcc13}/bin/gcc"
            export CUDAFLAGS="-std=c++14"

            export CMAKE_ARGS="-DCMAKE_CUDA_ARCHITECTURES=native"

            export LD_LIBRARY_PATH=${pkgs.wayland}/lib:${pkgs.libxkbcommon}/lib:${pkgs.libGL}/lib:$LD_LIBRARY_PATH

            export LD_LIBRARY_PATH=/run/opengl-driver/lib:$LD_LIBRARY_PATH

            export CXXFLAGS="-std=c++17" 
            export CFLAGS="-std=c17"

            export CC=clang
            export CXX=clang++

            echo "C++ Environment Loaded with C++17 and Clang"

          '';
        };
      });
}
