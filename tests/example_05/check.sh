#!/bin/sh
$SORT -t"(" -k2 -n -r | $DIFF $TEST_PATH/out -
