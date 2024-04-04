# ------------------------------------------------------------
# DIR build
# ------------------------------------------------------------
DIR_BUILD       := $(abspath build)


# ------------------------------------------------------------
# the target file name
# ------------------------------------------------------------
NAME 			= heartbleed
CLIENT			= hb_client

# DASICS_DIR
DIR_DASICS		= ./LibDASICS
LibDASICS		= $(DIR_DASICS)/build/LibDASICS.a

DIR_BUILD		= $(PWD)/build

# ------------------------------------------------------------
# the compile logic
# ------------------------------------------------------------
CROSS_COMPILE 		= riscv64-unknown-linux-gnu-
CFLAGS 				= -O2 -g -I$(DIR_DASICS)/include
SSL_FLAG 			= -I$(DIR_BUILD)/include -L$(DIR_BUILD)/lib -lssl -lcrypto -ldl
CC 					= $(CROSS_COMPILE)gcc
OBJDUMP 			= $(CROSS_COMPILE)objdump
HEXDUMP 			= hexdump


# heartbleed Target
HEARTBLEED_TARGET	= $(DIR_BUILD)/heartbleed
HEARTBLEED_SRC		= server.c


# attack client
ATTACK_CLIENT		= ./hb_client.c
ATTACK_TARGET		= $(DIR_BUILD)/attack-heartbleed

# runall.c
RUNALL_SRC = runall.c
RUNALL_TARGET  = $(DIR_BUILD)/runall
# ------------------------------------------------------------
# DASICS test file, include library
# ------------------------------------------------------------

.PHONY: all dirs
all: dirs openssl keygen crtgen heartbleed client runall

dirs:
	@mkdir -p $(DIR_BUILD)

# --------------------------------------------------------
# Variables and rules to build the openssl 1.0.1f
# --------------------------------------------------------

DIR_OPENSSL 		:= openssl
OPENSSL_HOST      	:= openssl
OPENSSL_TARGET    	:= $(DIR_BUILD)/bin/$(OPENSSL_HOST)
OPENSSL_CFG_FLAGS 	:= linux-generic64 no-asm no-threads shared\
                       --cross-compile-prefix=$(CROSS_COMPILE)\
					   --prefix=$(DIR_BUILD) --openssldir=$(DIR_BUILD)/openssl

.PHONY: openssl
openssl: $(OPENSSL_TARGET)

$(OPENSSL_TARGET):
ifeq ($(wildcard $(DIR_OPENSSL)/*),)
	git submodule update --init $(DIR_OPENSSL)
	cd $(DIR_OPENSSL) && git checkout OpenSSL_1_0_1f
endif
	cd $(DIR_OPENSSL) && ./Configure $(OPENSSL_CFG_FLAGS)
	# NOTE: DO NOT use multiple-threading to 'make' due to issue https://github.com/bilibili/ijkplayer/issues/5113
	make -C $(DIR_OPENSSL)
	# NOTE: 'make install' will fail due to issue https://github.com/openssl/openssl/issues/57
	make -C $(DIR_OPENSSL) install_sw


# --------------------------------------------------------
# Variables and rules to generate openssl key and certificate
# --------------------------------------------------------

KEY_TARGET := $(DIR_BUILD)/rsa_private.key
CRT_TARGET := $(DIR_BUILD)/cert.crt
CRT_INFO   := "/C=NL/ST=Some-State/O=Lupo Corp./CN=Server"

.PHONY: keygen crtgen
keygen: $(KEY_TARGET)

$(KEY_TARGET):
	$(OPENSSL_HOST) genrsa -out $(KEY_TARGET) 2048

crtgen: $(CRT_TARGET)

$(CRT_TARGET): $(KEY_TARGET)
	$(OPENSSL_HOST) req -new -x509 -key $(KEY_TARGET) -out $(CRT_TARGET) -subj $(CRT_INFO)

$(LibDASICS):
ifeq ($(wildcard $(DIR_DASICS)/*),)
	git submodule update --init $(DIR_DASICS)
endif
	make -C $(DIR_DASICS) -j16

heartbleed: $(HEARTBLEED_TARGET)

$(HEARTBLEED_TARGET): $(OPENSSL_TARGET) $(LibDASICS) $(HEARTBLEED_SRC)
	$(CC) $(CFLAGS) $(HEARTBLEED_SRC) -o $(HEARTBLEED_TARGET) $(LibDASICS) $(SSL_FLAG) -T$(DIR_DASICS)/ld.lds
	$(OBJDUMP) -d $(HEARTBLEED_TARGET) > $(DIR_BUILD)/heartbleed.txt

client:
	$(CC) -g -O2 $(ATTACK_CLIENT) -o $(ATTACK_TARGET)
	$(OBJDUMP) -d $(ATTACK_TARGET) > $(DIR_BUILD)/attack.txt

runall:
	$(CC) -g -O2 $(RUNALL_SRC) -o $(RUNALL_TARGET)

clean:
	rm -rf build


.PHONY: run-server run-client

HB_SERVER := $(HEARTBLEED_TARGET)
HB_CLIENT := $(ATTACK_TARGET)

HB_IP     ?= 127.0.0.1
HB_PORT   ?= 9878
run-server: $(HB_SERVER)
	$(HB_SERVER) $(HB_PORT) $(CRT_TARGET) $(KEY_TARGET)

run-client: $(HB_CLIENT)
	$(HB_CLIENT) $(HB_IP) -p $(HB_PORT)

distclean:
	make -C $(DIR_DASICS) clean 
	make -C $(DIR_OPENSSL) clean
	rm -rf build



