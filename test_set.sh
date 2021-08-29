#!/bin/bash

 set -o errtrace

function x {
    echo "X begins."
    false
    echo "X ends."
}

function y {
    echo "Y begins."
    false
    echo "Y ends."
}

trap 'echo "ERR trap called in ${FUNCNAME-main context}."' ERR
x
y
false
true
