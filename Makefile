ifndef DC
    $(error DC variable is not defined)
endif

ifndef DVER
    $(error DVER variable is not defined)
endif

.PHONY: all
all: test

.PHONY: test
# We need to specify -of because dmd1 will fail trying to create the temporary
# file as 'test' which is already a directory name
test:
	$(DC) -oftest.d.bin -run test/test.d

.PHONY: d2conv
d2conv:
	test "$(DVER)" = 2
