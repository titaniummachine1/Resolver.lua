@echo off

node bundle.js
move /Y "Resolver.lua" "%localappdata%"
exit