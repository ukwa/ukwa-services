#!/bin/sh
structurizr-cli export -o arch-dc -w arch-dc.dsl -f plantuml
plantuml -tsvg -o . arch-dc/*.puml
