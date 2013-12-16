CC = gcc
CFLAGS = -O0 -g -Wall -Wextra -std=c99 -pedantic-errors -shared -fPIC -Ilib/sqlite3 -Ilib/parson

.PHONY: parse_json
all: parse_json.c lib/parson/parson.c
	$(CC) $(CFLAGS) -o parse_json.so parse_json.c lib/parson/parson.c
init:
		git clone https://github.com/kgabis/parson.git lib/parson
test:
		perl ./t/test.pl
clean:
	rm -fr parse_json.so*
	rm -fr lib/parson
