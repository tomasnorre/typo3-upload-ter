#!/bin/sh
# Replaces tailor in the entrypoint tests: records the arguments, publishes nothing.
printf "%s" "$*" > tailor-args.txt
