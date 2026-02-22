build:
  cd mpr/build && ninja

setup:
  mkdir -p mpr/build
  cd mpr/build && cmake -GNinja ..

run: build
  cd mpr/build && ./gui/demo

clean:
  rm -rf mpr/build
