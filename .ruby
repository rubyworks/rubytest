--- 
authors: 
- name: Thomas Sawyer
  email: transfire@gmail.com
copyrights: 
- holder: Thomas Sawyer, RubyWorks
  year: "2011"
  license: FreeBSD
replacements: []

conflicts: []

requirements: 
- name: ansi
- name: detroit
  groups: 
  - build
  development: true
dependencies: []

repositories: 
- uri: git@github.com:rubyworks/test.git
  scm: git
  name: upstream
resources: 
  home: http://rubyworks.github.com/test
  code: http://github.com/rubyworks/test
  mail: http://groups.google.com/group/rubyworks-mailinglist
load_path: 
- lib
extra: 
  manifest: MANIFEST
alternatives: []

revision: 0
name: test
title: Ruby Test
summary: Ruby Universal Test Harness
created: "2011-07-23"
description: Ruby Test is a universal test harness for Ruby. It can handle any compliant  test framework, even running tests from multiple frameworks in a single pass.
version: 0.1.0
date: "2011-07-29"
