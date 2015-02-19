### OPTIONS ###
# export the following variables to use the system libraries
# instead of the bundled ones:
USE_SYSTEM_SSL=1
#   USE_SYSTEM_LUAJIT=1
USE_SYSTEM_ZLIB=1
#   USE_SYSTEM_YAJL=1
#
# default is to use the bundled libraries
#
# disable debug symbols:
#   DEBUG=0
#
## disable -Werror:
#   WERROR=0


VERSION=$(shell git describe --tags)
LUADIR=deps/luajit
LUAJIT_VERSION=$(shell git --git-dir ${LUADIR}/.git describe --tags)
YAJLDIR=deps/yajl
YAJL_VERSION=$(shell git --git-dir ${YAJLDIR}/.git describe --tags)
UVDIR=deps/uv
UV_VERSION=$(shell git --git-dir ${UVDIR}/.git describe --all --long | cut -f 3 -d -)
HTTPDIR=deps/http-parser
HTTP_VERSION=$(shell git --git-dir ${HTTPDIR}/.git describe --tags)
ZLIBDIR=deps/zlib
SSLDIR=deps/openssl
BUILDDIR=build
CRYPTODIR=deps/luacrypto
CARESDIR=deps/cares

BUILD_NUMBER?=0

PREFIX?=/usr/local
BINDIR?=${DESTDIR}${PREFIX}/bin
INCDIR?=${DESTDIR}${PREFIX}/include/luvit
LIBDIR?=${DESTDIR}${PREFIX}/lib/luvit
RANLIB?=ranlib

USE_SYSTEM_SSL?=0
USE_SYSTEM_LUAJIT?=0
USE_SYSTEM_ZLIB?=0
USE_SYSTEM_YAJL?=0

DEBUG ?= 1
ifeq (${DEBUG},1)
CFLAGS += -g
endif

WERROR ?= 1
ifeq (${WERROR},1)
CFLAGS += -Werror
endif

ifneq (${WIN32_TARGET},)
LUAMAKEFLAGS=HOST_CC='gcc -m32' CROSS=$(WIN32_TARGET)- TARGET_SYS=Windows BUILDMODE=static
CARESFLAGS=OS="mingw"
UVFLAGS=PLATFORM="mingw" PREFIX=$(WIN32_TARGET)-
CFLAGS += -DWIN32
LUAJITEXE=luajit.exe
else
OS_NAME=$(shell uname -s)
MH_NAME=$(shell uname -m)
LUAJITEXE=luajit
ifeq (${OS_NAME},Darwin)
ifeq (${MH_NAME},x86_64)
LDFLAGS+=-framework CoreServices -framework Carbon -pagezero_size 10000 -image_base 100000000
else
LDFLAGS+=-framework CoreServices
endif
else ifeq (${OS_NAME},Linux)
LDFLAGS+=-Wl,-E
else ifeq (${OS_NAME},FreeBSD)
LDFLAGS+=-lkvm -Wl,-E
ifeq "$(shell which gcc)" ""
export CC=cc
MAKEFLAGS+=-e
endif
else ifeq (${OS_NAME},SunOS)
CFLAGS+=-D__EXTENSIONS__
LUAMAKEFLAGS=-e
endif
endif
# LUAJIT CONFIGURATION #
#XCFLAGS=-g
#XCFLAGS+=-DLUAJIT_DISABLE_JIT
XCFLAGS+=-DLUAJIT_ENABLE_LUA52COMPAT
#XCFLAGS+=-DLUA_USE_APICHECK
export XCFLAGS
# verbose build
export Q=
#MAKEFLAGS+=-e
YAJLA_CFLAGS="--std=c99"

LDFLAGS+=-L${BUILDDIR}
LIBS += -lluvit -lpthread

ifeq (${USE_SYSTEM_ZLIB},1)
CPPFLAGS+=-I../zlib
LIBS+=../zlib/libz.a
else
CPPFLAGS+=-I${ZLIBDIR}
LIBS+=${ZLIBDIR}/libz.a
endif

ifeq (${USE_SYSTEM_YAJL},1)
CPPFLAS+=$(shell pkg-config --cflags yajl)
LIBS+=$(shell pkg-config --libs yajl)
else
CPPFLAGS += -I${YAJLDIR}/src -I${YAJLDIR}/src/api
LIBS+=${YAJLDIR}/yajl.a
endif

LIBS += ${UVDIR}/libuv.a
LIBS += ${CARESDIR}/libcares.a

ifeq (${USE_SYSTEM_LUAJIT},1)
CPPFLAGS+=$(shell pkg-config --cflags luajit)
LIBS+=$(shell pkg-config --libs luajit)
else
CPPFLAGS+=-I${LUADIR}/src
LIBS+=${LUADIR}/src/libluajit.a
endif

LIBS += -lm

ifeq (${USE_SYSTEM_SSL},1)
CFLAGS+=-Wall -w
CPPFLAGS+=-I../openssl/include
LIBS+=../openssl/libssl.a ../openssl/libcrypto.a
else
CPPFLAGS+=-I${SSLDIR}/openssl/include
LIBS+=${SSLDIR}/libopenssl.a
endif

ifeq (${OS_NAME},Linux)
LIBS+=-lrt -ldl
else ifeq (${OS_NAME},SunOS)
LIBS+=-lsocket -lkstat -lnsl -lsendfile
else ifneq (${WIN32_TARGET},)
LIBS+=-lws2_32 -lpsapi -liphlpapi -lgdi32
endif

CPPFLAGS += -DUSE_OPENSSL
CPPFLAGS += -DL_ENDIAN
CPPFLAGS += -DOPENSSL_THREADS
CPPFLAGS += -DPURIFY
CPPFLAGS += -D_REENTRANT
CPPFLAGS += -DOPENSSL_NO_ASM
CPPFLAGS += -DOPENSSL_NO_INLINE_ASM
CPPFLAGS += -DOPENSSL_NO_RC2
CPPFLAGS += -DOPENSSL_NO_RC5
CPPFLAGS += -DOPENSSL_NO_MD4
CPPFLAGS += -DOPENSSL_NO_HW
CPPFLAGS += -DOPENSSL_NO_GOST
CPPFLAGS += -DOPENSSL_NO_CAMELLIA
CPPFLAGS += -DOPENSSL_NO_CAPIENG
CPPFLAGS += -DOPENSSL_NO_CMS
CPPFLAGS += -DOPENSSL_NO_FIPS
CPPFLAGS += -DOPENSSL_NO_IDEA
CPPFLAGS += -DOPENSSL_NO_MDC2
CPPFLAGS += -DOPENSSL_NO_MD2
CPPFLAGS += -DOPENSSL_NO_SEED
CPPFLAGS += -DOPENSSL_NO_SOCK
CPPFLAGS += -DOPENSSL_NO_SCTP
CPPFLAGS += -DOPENSSL_NO_EC2M

ifeq (${MH_NAME},x86_64)
CPPFLAGS += -I${SSLDIR}/openssl-configs/x64
else ifeq (${MH_NAME},amd64)
CPPFLAGS += -I${SSLDIR}/openssl-configs/x64
else
CPPFLAGS += -I${SSLDIR}/openssl-configs/ia32
endif

LUVLIBS=${BUILDDIR}/utils.o          \
        ${BUILDDIR}/luv_fs.o         \
        ${BUILDDIR}/luv_dns.o        \
        ${BUILDDIR}/luv_debug.o      \
        ${BUILDDIR}/luv_handle.o     \
        ${BUILDDIR}/luv_udp.o        \
        ${BUILDDIR}/luv_fs_watcher.o \
        ${BUILDDIR}/luv_timer.o      \
        ${BUILDDIR}/luv_process.o    \
        ${BUILDDIR}/luv_signal.o     \
        ${BUILDDIR}/luv_stream.o     \
        ${BUILDDIR}/luv_tcp.o        \
        ${BUILDDIR}/luv_tls.o        \
        ${BUILDDIR}/luv_tls_conn.o   \
        ${BUILDDIR}/luv_pipe.o       \
        ${BUILDDIR}/luv_poll.o       \
        ${BUILDDIR}/luv_tty.o        \
        ${BUILDDIR}/luv_misc.o       \
        ${BUILDDIR}/luv.o            \
        ${BUILDDIR}/luvit_init.o     \
        ${BUILDDIR}/lconstants.o     \
        ${BUILDDIR}/lenv.o           \
        ${BUILDDIR}/lyajl.o          \
        ${BUILDDIR}/los.o            \
        ${BUILDDIR}/luv_zlib.o       \
        ${BUILDDIR}/lhttp_parser.o

DEPS= ${UVDIR}/libuv.a             \
		${CARESDIR}/libcares.a \
		${HTTPDIR}/http_parser.o

ifeq (${USE_SYSTEM_LUAJIT},0)
DEPS+=${LUADIR}/src/libluajit.a
endif

ifeq (${USE_SYSTEM_SSL},0)
DEPS+=${SSLDIR}/libopenssl.a
endif

ifeq (${USE_SYSTEM_ZLIB},0)
DEPS+=${ZLIBDIR}/libz.a
endif

ifeq (${USE_SYSTEM_YAJL},0)
DEPS+=${YAJLDIR}/yajl.a
endif

BUNDLE_LIBS= $(shell ls lib/luvit/*.lua)


all: ${BUILDDIR}/luvit

${LUADIR}/Makefile:
	git submodule update --init ${LUADIR}

${LUADIR}/src/libluajit.a: ${LUADIR}/Makefile
	touch -c ${LUADIR}/src/*.h
	$(MAKE) -C ${LUADIR} ${LUAMAKEFLAGS}

${YAJLDIR}/CMakeLists.txt:
	git submodule update --init ${YAJLDIR}

${YAJLDIR}/Makefile: deps/Makefile.yajl ${YAJLDIR}/CMakeLists.txt
	cp deps/Makefile.yajl ${YAJLDIR}/Makefile

${YAJLDIR}/yajl.a: ${YAJLDIR}/Makefile
	rm -rf ${YAJLDIR}/src/yajl
	cp -r ${YAJLDIR}/src/api ${YAJLDIR}/src/yajl
	CFLAGS="${CFLAGS} ${YAJLA_CFLAGS}" CC=$(CC) AR=$(AR) $(MAKE) -C ${YAJLDIR}

${UVDIR}/Makefile:
	git submodule update --init ${UVDIR}

${UVDIR}/libuv.a: ${UVDIR}/Makefile
	$(MAKE) $(UVFLAGS) -C ${UVDIR}

${CARESDIR}/Makefile:
	git submodule update --init --recursive

${CARESDIR}/libcares.a: ${CARESDIR}/Makefile
	 CC=$(CC) AR=$(AR) $(CARESFLAGS) $(MAKE) -C ${CARESDIR}

${HTTPDIR}/Makefile:
	git submodule update --init ${HTTPDIR}

${HTTPDIR}/http_parser.o: ${HTTPDIR}/Makefile
	 CC=$(CC) AR=$(AR) $(MAKE) -C ${HTTPDIR} http_parser.o

${ZLIBDIR}/zlib.gyp:
	git submodule update --init ${ZLIBDIR}

${ZLIBDIR}/libz.a: ${ZLIBDIR}/zlib.gyp
	cd ${ZLIBDIR} && ${CC} -c *.c && \
	$(AR) rvs libz.a *.o && \
	$(RANLIB) libz.a

${SSLDIR}/Makefile.openssl:
	git submodule update --init ${SSLDIR}

${SSLDIR}/libopenssl.a: ${SSLDIR}/Makefile.openssl
	$(MAKE) -C ${SSLDIR} -f Makefile.openssl

${BUILDDIR}/%.o: src/%.c ${DEPS}
	mkdir -p ${BUILDDIR}
	$(CC) ${CPPFLAGS} ${CFLAGS} --std=c89 -D_GNU_SOURCE -Wall -c $< -o $@ \
		-I${CARESDIR}/include \
		-I${HTTPDIR} -I${UVDIR}/include -I${CRYPTODIR}/src \
		-D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 \
		-DUSE_SYSTEM_SSL=${USE_SYSTEM_SSL} \
		-DHTTP_VERSION=\"${HTTP_VERSION}\" \
		-DUV_VERSION=\"${UV_VERSION}\" \
		-DYAJL_VERSIONISH=\"${YAJL_VERSION}\" \
		-DLUVIT_BASE_VERSION=\"${VERSION}\" \
		-DLUVIT_VERSION=\"${VERSION}:${BUILD_NUMBER}\" \
		-DLUAJIT_VERSION=\"${LUAJIT_VERSION}\"

${BUILDDIR}/libluvit.a: ${CRYPTODIR}/Makefile ${LUVLIBS} ${DEPS}
	$(AR) rvs ${BUILDDIR}/libluvit.a ${LUVLIBS} ${DEPS}
	$(RANLIB) ${BUILDDIR}/libluvit.a

${CRYPTODIR}/Makefile:
	git submodule update --init ${CRYPTODIR}

${CRYPTODIR}/src/lcrypto.o: ${CRYPTODIR}/Makefile
	${CC} ${CPPFLAGS} -c -o ${CRYPTODIR}/src/lcrypto.o -I${CRYPTODIR}/src/ \
		 -I${LUADIR}/src/ ${CRYPTODIR}/src/lcrypto.c

${BUILDDIR}/luvit: ${BUILDDIR}/libluvit.a ${BUILDDIR}/luvit_main.o ${BUILDDIR}/luvit_newmain.o ${CRYPTODIR}/src/lcrypto.o
	$(CC) ${CPPFLAGS} ${CFLAGS} ${LDFLAGS} -o ${BUILDDIR}/luvit ${BUILDDIR}/luvit_main.o ${BUILDDIR}/luvit_newmain.o ${BUILDDIR}/libluvit.a \
		${CRYPTODIR}/src/lcrypto.o ${LIBS}

clean:
	${MAKE} -C ${LUADIR} clean
	${MAKE} -C ${SSLDIR} -f Makefile.openssl clean
	${MAKE} -C ${HTTPDIR} clean
	${MAKE} -C ${YAJLDIR} clean
	${MAKE} -C ${UVDIR} distclean
	${MAKE} -C examples/native clean
	-rm ${ZLIBDIR}/*.o ${ZLIBDIR}/*.a
	-rm ${CARESDIR}/src/*.o ${CARESDIR}/*.a
	-rm ${CRYPTODIR}/src/lcrypto.o
	rm -rf build bundle

install: all
	mkdir -p ${BINDIR}
	install ${BUILDDIR}/luvit ${BINDIR}/luvit
	mkdir -p ${LIBDIR}
	cp lib/luvit/*.lua ${LIBDIR}
	mkdir -p ${INCDIR}/http_parser
	cp ${HTTPDIR}/http_parser.h ${INCDIR}/http_parser/
	mkdir -p ${INCDIR}/uv
	cp -r ${UVDIR}/include/* ${INCDIR}/uv/
	cp src/*.h ${INCDIR}/
ifeq (${USE_SYSTEM_LUAJIT},0)
	mkdir -p ${INCDIR}/luajit
	cp ${LUADIR}/src/lua.h ${INCDIR}/luajit/
	cp ${LUADIR}/src/lauxlib.h ${INCDIR}/luajit/
	cp ${LUADIR}/src/luaconf.h ${INCDIR}/luajit/
	cp ${LUADIR}/src/luajit.h ${INCDIR}/luajit/
	cp ${LUADIR}/src/lualib.h ${INCDIR}/luajit/
endif

uninstall:
	test -f ${BINDIR}/luvit && rm -f ${BINDIR}/luvit
	test -d ${LIBDIR} && rm -rf ${LIBDIR}
	test -d ${INCDIR} && rm -rf ${INCDIR}

bundle: bundle/luvit

bundle/luvit: build/luvit ${BUILDDIR}/libluvit.a ${BUNDLE_LIBS}
	mkdir 755 bundle
	@for f in `ls lib/luvit/*.lua`; do ./deps/luajit/src/$(LUAJITEXE) -bg $${f} bundle/`basename $${f}|sed 's/\.lua/\.c/'`; done
	cd bundle; $(CC) --std=c89 -g -Wall -Werror -c *.c
	$(CC) --std=c89 -D_GNU_SOURCE -g -Wall -Werror -DBUNDLE -c src/luvit_exports.c -o bundle/luvit_exports.o -I${HTTPDIR} -I${UVDIR}/include -I${LUADIR}/src -I${YAJLDIR}/src/api -I${YAJLDIR}/src -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -DHTTP_VERSION=\"${HTTP_VERSION}\" -DUV_VERSION=\"${UV_VERSION}\" -DYAJL_VERSIONISH=\"${YAJL_VERSION}\" -DLUVIT_VERSION=\"${VERSION}:${BUILD_NUMBER}\" -DLUAJIT_VERSION=\"${LUAJIT_VERSION}\"
	$(CC) --std=c89 -D_GNU_SOURCE -g -Wall -Werror -DBUNDLE -c src/luvit_main.c -o bundle/luvit_main.o -I${HTTPDIR} -I${UVDIR}/include -I${LUADIR}/src -I${YAJLDIR}/src/api -I${YAJLDIR}/src -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -DHTTP_VERSION=\"${HTTP_VERSION}\" -DUV_VERSION=\"${UV_VERSION}\" -DYAJL_VERSIONISH=\"${YAJL_VERSION}\" -DLUVIT_VERSION=\"${VERSION}:${BUILD_NUMBER}\" -DLUAJIT_VERSION=\"${LUAJIT_VERSION}\" -I${CARESDIR}/include
	$(CC) --std=c89 -D_GNU_SOURCE -g -Wall -Werror -DBUNDLE -c src/luvit_newmain.c -o bundle/luvit_newmain.o -I${HTTPDIR} -I${UVDIR}/include -I${LUADIR}/src -I${YAJLDIR}/src/api -I${YAJLDIR}/src -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -DHTTP_VERSION=\"${HTTP_VERSION}\" -DUV_VERSION=\"${UV_VERSION}\" -DYAJL_VERSIONISH=\"${YAJL_VERSION}\" -DLUVIT_VERSION=\"${VERSION}:${BUILD_NUMBER}\" -DLUAJIT_VERSION=\"${LUAJIT_VERSION}\" -I${CARESDIR}/include
	$(CC) ${LDFLAGS} -g -o bundle/luvit ${BUILDDIR}/libluvit.a `ls bundle/*.o` ${CRYPTODIR}/src/lcrypto.o ${LIBS}

# Test section

test: test-lua test-install test-uninstall

test-lua: ${BUILDDIR}/luvit
	cd tests && ../${BUILDDIR}/luvit runner.lua

ifeq ($(MAKECMDGOALS),test)
DESTDIR=test_install
endif

test-install: install
	test -f ${BINDIR}/luvit
	test -d ${INCDIR}
	test -d ${LIBDIR}

test-uninstall: uninstall
	test ! -f ${BINDIR}/luvit
	test ! -d ${INCDIR}
	test ! -d ${LIBDIR}

api: api.markdown

api.markdown: $(wildcard lib/*.lua)
	find lib -name "*.lua" | grep -v "luvit.lua" | sort | xargs -l luvit tools/doc-parser.lua > $@

DIST_DIR?=${HOME}/luvit.io/dist
DIST_NAME=luvit-${VERSION}
DIST_FOLDER=${DIST_DIR}/${VERSION}/${DIST_NAME}
DIST_FILE=${DIST_FOLDER}.tar.gz
dist_build:
	sed -e 's/^VERSION=.*/VERSION=${VERSION}/' \
            -e 's/^LUAJIT_VERSION=.*/LUAJIT_VERSION=${LUAJIT_VERSION}/' \
            -e 's/^UV_VERSION=.*/UV_VERSION=${UV_VERSION}/' \
            -e 's/^HTTP_VERSION=.*/HTTP_VERSION=${HTTP_VERSION}/' \
            -e 's/^YAJL_VERSION=.*/YAJL_VERSION=${YAJL_VERSION}/' < Makefile > Makefile.dist
	sed -e 's/LUVIT_VERSION=".*/LUVIT_VERSION=\"${VERSION}\"'\'',/' \
            -e 's/LUAJIT_VERSION=".*/LUAJIT_VERSION=\"${LUAJIT_VERSION}\"'\'',/' \
            -e 's/UV_VERSION=".*/UV_VERSION=\"${UV_VERSION}\"'\'',/' \
            -e 's/HTTP_VERSION=".*/HTTP_VERSION=\"${HTTP_VERSION}\"'\'',/' \
            -e 's/YAJL_VERSIONISH=".*/YAJL_VERSIONISH=\"${YAJL_VERSION}\"'\'',/' < luvit.gyp > luvit.gyp.dist

tarball: dist_build
	rm -rf ${DIST_FOLDER} ${DIST_FILE}
	mkdir -p ${DIST_FOLDER}
	cp -a . ${DIST_FOLDER}
	cd ${DIST_FOLDER}
	find ${DIST_FOLDER} -name ".git*" | xargs rm -r
	mv Makefile.dist ${DIST_FOLDER}/Makefile
	mv luvit.gyp.dist ${DIST_FOLDER}/luvit.gyp
	tar -czf ${DIST_FILE} -C ${DIST_DIR}/${VERSION} ${DIST_NAME}
	rm -rf ${DIST_FOLDER}

.PHONY: test install uninstall all api.markdown bundle tarball
