#!/usr/bin/env python

def page_name(num):
    return "page%02d.md" % num

def page_contents(num):
    return """# Pagination Page %s

Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.

Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
""" % str(num)

def gen_page(num):
    with open(page_name(num), "w+") as f:
        f.write(page_contents(num))


for i in range(20):
    gen_page(i)
