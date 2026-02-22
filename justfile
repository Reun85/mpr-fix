run: build
  cd mpr/build && ./gui/demo

build:
  cd mpr/build && ninja

setup:
  mkdir -p mpr/build
  cd mpr/build && cmake -GNinja ..

clean:
  rm -rf mpr/build
