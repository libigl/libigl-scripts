#!/bin/bash

fswatch -o include/ -o docs/ | while read f; do
    doxygen docs/doxygen.conf
done
