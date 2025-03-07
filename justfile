default: test

build:
    zig build

run:
    zig build run

test:
    zig build test --summary new

harness:
    ./tests/harness.sh

coverage:
    rm -rf zig-out
    mkdir -p zig-out/cover
    zig build cover

    
    
